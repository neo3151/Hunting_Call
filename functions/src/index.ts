import { createHash } from "crypto";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { GoogleAuth } from "google-auth-library";

admin.initializeApp();
const db = admin.firestore();

// ─── Types ──────────────────────────────────────────────────────────

interface LeaderboardEntry {
    userId: string;
    userName: string;
    score: number;
    timestamp: number;
    profileImageUrl?: string;
    isAlphaTester?: boolean;
}

interface SubmitScoreRequest {
    animalId: string;
    userId: string;
    userName: string;
    score: number;
    profileImageUrl?: string;
    isAlphaTester?: boolean;
}

// ─── submitScore ────────────────────────────────────────────────────
//
// Callable Cloud Function that serializes leaderboard writes.
// Runs a Firestore transaction server-side with up to 25 retries
// (vs 5 on the client), eliminating contention failures.
//
// Business rules (same as the original client-side logic):
//   1. If user already has a score, only accept if the new one is better
//   2. Add new entry to the list
//   3. Sort descending by score
//   4. Keep top 20 entries
//

const ADMIN_EMAILS = new Set(["benchmarkappsllc@gmail.com", "pongownsyou@gmail.com"]);

function verifyIsAdmin(context: functions.https.CallableContext): void {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Must be logged in."
        );
    }
    const email = context.auth.token.email;
    const isAdminClaim = context.auth.token.admin === true;
    const isEmailAdmin = typeof email === "string" && ADMIN_EMAILS.has(email.toLowerCase());

    if (!isAdminClaim && !isEmailAdmin) {
        throw new functions.https.HttpsError(
            "permission-denied",
            "Admin privileges required."
        );
    }
}

export const submitScore = functions.https.onCall(async (data: SubmitScoreRequest, context) => {
    // ── Auth check ──
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Must be logged in to submit scores."
        );
    }

    // ── Input validation ──
    if (!data.animalId || typeof data.animalId !== "string") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "animalId is required and must be a string."
        );
    }
    if (typeof data.score !== "number" || data.score < 0 || data.score > 100) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "score must be a number between 0 and 100."
        );
    }

    // Use the authenticated UID, not the client-supplied one (security)
    const userId = context.auth.uid;

    // Fetch actual server-side profile to prevent username/avatar/alpha forgery
    const profileSnap = await db.collection("profiles").doc(userId).get();
    const profileData = profileSnap.exists ? profileSnap.data() : null;
    const userName = (profileData?.name as string) || data.userName || "Hunter";
    const profileImageUrl = (profileData?.avatarUrl as string) || (profileData?.profileImageUrl as string) || data.profileImageUrl || undefined;
    const isAlphaTester = (profileData?.isAlphaTester as boolean) === true;

    const newEntry: LeaderboardEntry = {
        userId: userId,
        userName: userName,
        score: data.score,
        timestamp: Date.now(),
        profileImageUrl: profileImageUrl,
        isAlphaTester: isAlphaTester,
    };

    const docRef = db.collection("leaderboards").doc(data.animalId);

    // ── Transaction with server-side retries ──
    const result = await db.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(docRef);

        let scores: LeaderboardEntry[] = [];
        if (snapshot.exists) {
            const docData = snapshot.data();
            scores = (docData?.scores || []) as LeaderboardEntry[];
        }

        // Check for existing score by this user
        const existingIndex = scores.findIndex((e) => e.userId === userId);
        if (existingIndex !== -1) {
            const existingScore = scores[existingIndex].score;
            if (existingScore >= newEntry.score) {
                return {
                    accepted: false,
                    reason: `Existing score (${existingScore}) is better or equal`,
                };
            }
            // Remove old lower score
            scores.splice(existingIndex, 1);
        }

        // Add new entry
        scores.push(newEntry);

        // Sort descending
        scores.sort((a, b) => b.score - a.score);

        // Keep top 20
        if (scores.length > 20) {
            scores = scores.slice(0, 20);
        }

        // Write back
        transaction.set(docRef, {
            scores: scores,
            lastUpdated: new Date().toISOString(),
        });

        return { accepted: true, reason: null };
    }, { maxAttempts: 25 }); // 25 retries vs client's 5

    return result;
});

// ─── scrubInactiveProfiles ──────────────────────────────────────────
//
// Scheduled Cloud Function that deletes stale user profiles.
//
// Rules:
//   1. Skip profiles where isPremium === true or isAlphaTester === true
//   2. Determine last activity from: lastActiveAt → latest history timestamp → joinedDate
//   3. If inactive for 90+ days → delete the profile document
//   4. Also remove the deleted user from all leaderboard scores arrays
//   5. Log a summary of actions taken
//

const INACTIVITY_THRESHOLD_DAYS = 90;

/**
 * Core scrubbing logic — shared between the scheduled and callable triggers.
 */
async function runProfileScrub(): Promise<{
    scanned: number;
    deleted: number;
    skippedPremium: number;
    skippedAlpha: number;
    skippedActive: number;
    leaderboardsCleaned: number;
}> {
    const now = Date.now();
    const cutoffMs = INACTIVITY_THRESHOLD_DAYS * 24 * 60 * 60 * 1000;
    const cutoffDate = now - cutoffMs;

    const profilesSnap = await db.collection("profiles").get();

    let deleted = 0;
    let skippedPremium = 0;
    let skippedAlpha = 0;
    let skippedActive = 0;
    const deletedUserIds: string[] = [];

    for (const doc of profilesSnap.docs) {
        const data = doc.data();

        // Skip premium users
        if (data.isPremium === true) {
            skippedPremium++;
            continue;
        }

        // Skip alpha testers
        if (data.isAlphaTester === true) {
            skippedAlpha++;
            continue;
        }

        // Determine last activity timestamp
        let lastActivityMs = 0;

        // 1. Check lastActiveAt field (set by client on each session)
        if (data.lastActiveAt) {
            const ts = toTimestampMs(data.lastActiveAt);
            if (ts > lastActivityMs) lastActivityMs = ts;
        }

        // 2. Check latest history entry
        if (Array.isArray(data.history) && data.history.length > 0) {
            for (const item of data.history) {
                const ts = toTimestampMs(item.timestamp);
                if (ts > lastActivityMs) lastActivityMs = ts;
            }
        }

        // 3. Fall back to joinedDate
        if (lastActivityMs === 0 && data.joinedDate) {
            lastActivityMs = toTimestampMs(data.joinedDate);
        }

        // If still no timestamp, treat as ancient (delete)
        if (lastActivityMs > cutoffDate) {
            skippedActive++;
            continue;
        }

        // Delete the stale profile
        await doc.ref.delete();
        deleted++;
        deletedUserIds.push(doc.id);
    }

    // Clean deleted users from leaderboard scores
    let leaderboardsCleaned = 0;
    if (deletedUserIds.length > 0) {
        const leaderboardsSnap = await db.collection("leaderboards").get();
        for (const lbDoc of leaderboardsSnap.docs) {
            const lbData = lbDoc.data();
            if (!Array.isArray(lbData.scores)) continue;

            const originalLen = lbData.scores.length;
            const filtered = lbData.scores.filter(
                (entry: LeaderboardEntry) => !deletedUserIds.includes(entry.userId)
            );

            if (filtered.length < originalLen) {
                await lbDoc.ref.update({
                    scores: filtered,
                    lastUpdated: new Date().toISOString(),
                });
                leaderboardsCleaned++;
            }
        }
    }

    return {
        scanned: profilesSnap.size,
        deleted,
        skippedPremium,
        skippedAlpha,
        skippedActive,
        leaderboardsCleaned,
    };
}

/**
 * Convert Firestore timestamp / ISO string / epoch ms to milliseconds.
 */
function toTimestampMs(value: unknown): number {
    if (!value) return 0;
    // Firestore Timestamp object
    if (typeof value === "object" && value !== null && "toMillis" in value) {
        return (value as { toMillis: () => number }).toMillis();
    }
    // ISO date string
    if (typeof value === "string") {
        const parsed = Date.parse(value);
        return isNaN(parsed) ? 0 : parsed;
    }
    // Epoch milliseconds
    if (typeof value === "number") {
        return value;
    }
    return 0;
}

// ── Scheduled trigger: runs every Sunday at 3:00 AM UTC ──
export const scrubInactiveProfiles = functions.pubsub
    .schedule("every sunday 03:00")
    .timeZone("UTC")
    .onRun(async () => {
        functions.logger.info("🧹 Starting scheduled profile scrub...");
        const result = await runProfileScrub();
        functions.logger.info("🧹 Profile scrub complete", result);
        return null;
    });

// ── Manual trigger: callable from Firebase console or client ──
export const scrubInactiveProfilesManual = functions.https.onCall(async (_data, context) => {
    verifyIsAdmin(context);

    functions.logger.info("🧹 Starting manual profile scrub...");
    const result = await runProfileScrub();
    functions.logger.info("🧹 Manual profile scrub complete", result);
    return result;
});

// ─── backfillAverageScores ──────────────────────────────────────────
//
// One-time callable Cloud Function to recalculate averageScore for
// all existing profiles from their history arrays.
// Fixes the bug where averageScore was never updated on cloud writes.
//

export const backfillAverageScores = functions.https.onCall(async (_data, context) => {
    verifyIsAdmin(context);

    const profilesSnap = await db.collection("profiles").get();
    let updated = 0;
    let skipped = 0;

    for (const doc of profilesSnap.docs) {
        const data = doc.data();
        const history = data.history as Array<{ result?: { score?: number } }> | undefined;

        if (!history || history.length === 0) {
            skipped++;
            continue;
        }

        let totalScore = 0;
        let scoredItems = 0;

        for (const item of history) {
            if (item.result && typeof item.result.score === "number") {
                totalScore += item.result.score;
                scoredItems++;
            }
        }

        if (scoredItems === 0) {
            skipped++;
            continue;
        }

        const averageScore = totalScore / scoredItems;

        // Only update if the current value is wrong
        const currentAvg = (data.averageScore as number) || 0;
        if (Math.abs(currentAvg - averageScore) > 0.01) {
            await doc.ref.update({ averageScore });
            updated++;
            functions.logger.info(
                `✅ ${doc.id}: ${currentAvg.toFixed(1)} → ${averageScore.toFixed(1)} (${scoredItems} entries)`
            );
        } else {
            skipped++;
        }
    }

    const result = { total: profilesSnap.size, updated, skipped };
    functions.logger.info("📊 Backfill complete", result);
    return result;
});

// ─── getCoachingFeedback ────────────────────────────────────────────
//
// Callable Cloud Function that generates personalized coaching feedback
// from Gemma 3 4B via the Ollama REST API.
//
// Input: { animalName, callType, score, pitchHz, idealPitchHz, metrics, proTips }
// Output: { coaching: string }
//

const OLLAMA_URL = process.env.OLLAMA_URL || "http://localhost:11434";

interface CoachingRequest {
    animalName: string;
    callType: string;
    score: number;
    pitchHz: number;
    idealPitchHz: number;
    metrics: Record<string, number>;
    proTips?: string;
}

export const getCoachingFeedback = functions.https.onCall(async (data: CoachingRequest, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Must be logged in to get coaching feedback."
        );
    }

    // Validate input
    if (!data.animalName || typeof data.score !== "number") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "animalName and score are required."
        );
    }

    // Build the coaching prompt
    const pitchDiff = Math.abs(data.pitchHz - data.idealPitchHz);
    const pitchDirection = data.pitchHz > data.idealPitchHz ? "too high" : "too low";

    const metricsBreakdown = data.metrics
        ? Object.entries(data.metrics)
            .map(([key, val]) => `  - ${key}: ${typeof val === "number" ? val.toFixed(1) : val}`)
            .join("\n")
        : "  No detailed metrics available.";

    const systemPrompt = `You are a master hunting call coach with decades of field experience. You give warm, encouraging, practical advice to hunters learning to perfect their animal calls. You speak with authority but never condescension. Keep your coaching concise — 2-3 short paragraphs max. Use specific, actionable tips. Never use markdown formatting, emojis, or bullet points — just clean conversational text.`;

    const userPrompt = `A hunter just practiced their ${data.callType} call for ${data.animalName} and scored ${data.score.toFixed(0)}%.

Their pitch was ${data.pitchHz.toFixed(0)} Hz (target: ${data.idealPitchHz.toFixed(0)} Hz — ${pitchDiff < 10 ? "right on target" : `${pitchDiff.toFixed(0)} Hz ${pitchDirection}`}).

Detailed metrics:
${metricsBreakdown}

${data.proTips ? `Reference tips for this call: ${data.proTips}` : ""}

Give them personalized coaching feedback. What are they doing well? What's the #1 thing they should focus on improving? Give one specific, practical drill or technique they can try right now.`;

    try {
        const response = await fetch(`${OLLAMA_URL}/api/generate`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                model: "outcall-coach",
                prompt: userPrompt,
                system: systemPrompt,
                stream: false,
                options: {
                    temperature: 0.7,
                    top_p: 0.9,
                    num_predict: 300,
                },
            }),
        });

        if (!response.ok) {
            functions.logger.warn(`Ollama returned ${response.status}`);
            return { coaching: getFallbackCoaching(data.score) };
        }

        const result = await response.json() as { response?: string };
        const coaching = result.response?.trim();

        if (!coaching || coaching.length < 20) {
            return { coaching: getFallbackCoaching(data.score) };
        }

        return { coaching };
    } catch (error) {
        functions.logger.warn("Ollama unreachable, using fallback", { error });
        return { coaching: getFallbackCoaching(data.score) };
    }
});

function getFallbackCoaching(score: number): string {
    if (score >= 85) {
        return "Excellent work! Your call is sounding very natural. Focus on consistency now — try making five calls in a row at this quality level. Small variations in pitch will actually make your calling sound more realistic in the field.";
    } else if (score >= 70) {
        return "Good foundation! Your technique is solid but there's room to tighten things up. Focus on matching the target pitch more precisely — try humming the pitch before making the call. Record yourself and compare side-by-side with the reference.";
    } else if (score >= 50) {
        return "You're making progress! The key right now is to slow down and focus on one element at a time. Start with pitch accuracy — get that dialed in before worrying about duration or rhythm. Listen to the reference call three times before each attempt.";
    } else {
        return "Every expert started right where you are. The most important thing is repetition with intention. Listen carefully to the reference call, then try to mimic just the opening note. Once that sounds right, add the next part. Build the call piece by piece.";
    }
}

const ANDROID_PACKAGE_NAME = "com.neo3151.huntingcalls";
const PREMIUM_PRODUCT_IDS = new Set([
    "outcall_premium_monthly",
    "outcall_premium_yearly",
]);
const androidPublisherAuth = new GoogleAuth({
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
});

type AndroidSubscriptionLineItem = {
    productId?: string | null;
    expiryTime?: string | null;
    latestSuccessfulOrderId?: string | null;
};

type AndroidSubscription = {
    subscriptionState?: string | null;
    lineItems?: AndroidSubscriptionLineItem[] | null;
};

type AndroidEntitlement = {
    entitled: boolean;
    status: string;
    productId: string;
    expiresAt: string | null;
    subscriptionState: string;
    latestOrderId: string | null;
};

export function entitlementFromSubscription(
    subscription: AndroidSubscription,
    expectedProductId: string
): AndroidEntitlement {
    const matchingItems = (subscription.lineItems || []).filter(
        (item) => item.productId === expectedProductId
    );
    if (matchingItems.length === 0) {
        throw new functions.https.HttpsError(
            "failed-precondition",
            "The purchase does not match the selected OUTCALL product."
        );
    }

    const expiresAt = matchingItems
        .map((item) => item.expiryTime)
        .filter((value): value is string => Boolean(value))
        .sort()
        .pop() || null;
    const unexpired = expiresAt !== null && Date.parse(expiresAt) > Date.now();
    const subscriptionState = subscription.subscriptionState || "SUBSCRIPTION_STATE_UNSPECIFIED";
    const latestOrderId = matchingItems
        .map((item) => item.latestSuccessfulOrderId)
        .find((value): value is string => Boolean(value)) || null;

    switch (subscriptionState) {
        case "SUBSCRIPTION_STATE_ACTIVE":
            return {
                entitled: unexpired,
                status: unexpired ? "active" : "expired",
                productId: expectedProductId,
                expiresAt,
                subscriptionState,
                latestOrderId: latestOrderId,
            };
        case "SUBSCRIPTION_STATE_IN_GRACE_PERIOD":
            return {
                entitled: unexpired,
                status: unexpired ? "grace" : "expired",
                productId: expectedProductId,
                expiresAt,
                subscriptionState,
                latestOrderId: latestOrderId,
            };
        case "SUBSCRIPTION_STATE_CANCELED":
            return {
                entitled: unexpired,
                status: unexpired ? "canceled_pending" : "expired",
                productId: expectedProductId,
                expiresAt,
                subscriptionState,
                latestOrderId: latestOrderId,
            };
        case "SUBSCRIPTION_STATE_ON_HOLD":
            return {
                entitled: false,
                status: "on_hold",
                productId: expectedProductId,
                expiresAt,
                subscriptionState,
                latestOrderId: latestOrderId,
            };
        case "SUBSCRIPTION_STATE_PAUSED":
            return {
                entitled: false,
                status: "paused",
                productId: expectedProductId,
                expiresAt,
                subscriptionState,
                latestOrderId: latestOrderId,
            };
        case "SUBSCRIPTION_STATE_PENDING":
            return {
                entitled: false,
                status: "pending",
                productId: expectedProductId,
                expiresAt,
                subscriptionState,
                latestOrderId: latestOrderId,
            };
        default:
            return {
                entitled: false,
                status: "expired",
                productId: expectedProductId,
                expiresAt,
                subscriptionState,
                latestOrderId: latestOrderId,
            };
    }
}

async function verifyAndroidPurchase(
    purchaseToken: string,
    expectedProductId: string
): Promise<AndroidEntitlement> {
    const packageName = encodeURIComponent(ANDROID_PACKAGE_NAME);
    const token = encodeURIComponent(purchaseToken);
    const response = await androidPublisherAuth.request<AndroidSubscription>({
        method: "GET",
        url: `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/subscriptionsv2/tokens/${token}`,
    });
    return entitlementFromSubscription(response.data, expectedProductId);
}

function defaultProfile(uid: string, email: string | null, name: string | null): Record<string, unknown> {
    return {
        id: uid,
        name: name || email?.split("@")[0] || "Hunter",
        email,
        joinedDate: new Date().toISOString(),
        totalCalls: 0,
        averageScore: 0,
        currentStreak: 0,
        longestStreak: 0,
        dailyChallengesCompleted: 0,
        achievements: [],
        history: [],
        isPremium: false,
    };
}

export const ensureUserProfile = functions.https.onCall(async (_data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in.");
    }

    const uid = context.auth.uid;
    const email = typeof context.auth.token.email === "string" ? context.auth.token.email : null;
    const emailVerified = context.auth.token.email_verified === true;
    const name = typeof context.auth.token.name === "string" ? context.auth.token.name : null;
    const targetRef = db.collection("profiles").doc(uid);
    const targetSnapshot = await targetRef.get();

    let legacySnapshot: admin.firestore.QueryDocumentSnapshot | null = null;
    if (email && emailVerified) {
        const matches = await db.collection("profiles").where("email", "==", email).limit(5).get();
        legacySnapshot = matches.docs.find((doc) => doc.id !== uid) || null;
    }

    if (!targetSnapshot.exists && legacySnapshot) {
        const legacyData = { ...legacySnapshot.data() };
        delete legacyData.isPremium;
        delete legacyData.premiumExpiresAt;
        await targetRef.set({
            ...legacyData,
            id: uid,
            email,
            isPremium: false,
            migratedFromProfileId: legacySnapshot.id,
            migratedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { profileId: uid, migratedFrom: legacySnapshot.id };
    }

    if (!targetSnapshot.exists) {
        await targetRef.set(defaultProfile(uid, email, name));
        return { profileId: uid, migratedFrom: null };
    }

    if (legacySnapshot) {
        const targetData = targetSnapshot.data() || {};
        const legacyData = legacySnapshot.data();
        const updates: Record<string, unknown> = {
            id: uid,
            email,
            migratedFromProfileId: legacySnapshot.id,
            migratedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        for (const [key, value] of Object.entries(legacyData)) {
            if (["id", "email", "isPremium", "premiumExpiresAt"].includes(key)) continue;
            const currentValue = targetData[key];
            const isEmptyArray = Array.isArray(currentValue) && currentValue.length === 0;
            const isDefaultNumber = typeof currentValue === "number" && currentValue === 0;
            const isDefaultName = key === "name" && ["Hunter", "New Hunter"].includes(currentValue);
            if (currentValue == null || isEmptyArray || isDefaultNumber || isDefaultName) {
                updates[key] = value;
            }
        }
        await targetRef.set(updates, { merge: true });
        return { profileId: uid, migratedFrom: legacySnapshot.id };
    }

    await targetRef.set({ id: uid, email }, { merge: true });
    return { profileId: uid, migratedFrom: null };
});

async function persistAndroidEntitlement(
    uid: string,
    purchaseToken: string,
    entitlement: AndroidEntitlement,
    email: string | null = null,
    name: string | null = null
): Promise<void> {
    const tokenHash = createHash("sha256").update(purchaseToken).digest("hex");
    const entitlementRef = db.collection("androidEntitlements").doc(tokenHash);
    const profileRef = db.collection("profiles").doc(uid);
    const activeQuery = db.collection("androidEntitlements")
        .where("uid", "==", uid);

    await db.runTransaction(async (transaction) => {
        const existing = await transaction.get(entitlementRef);
        const activeEntitlements = await transaction.get(activeQuery);
        const profile = await transaction.get(profileRef);
        const boundUid = existing.data()?.uid;
        if (existing.exists && boundUid !== uid) {
            throw new functions.https.HttpsError(
                "permission-denied",
                "This Google Play purchase is linked to another account."
            );
        }

        if (entitlement.entitled || existing.exists) {
            transaction.set(entitlementRef, {
                uid,
                platform: "android",
                packageName: ANDROID_PACKAGE_NAME,
                purchaseToken,
                tokenHash,
                createdAt: existing.data()?.createdAt || admin.firestore.FieldValue.serverTimestamp(),
                ...entitlement,
                lastVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
        }

        const supportGrantSnap = await transaction.get(db.collection("supportGrants").doc(uid));
        const supportGrantData = supportGrantSnap.exists ? supportGrantSnap.data() : null;
        const supportExpiresAt = typeof supportGrantData?.expiresAt === "string" ? supportGrantData.expiresAt : null;
        const hasValidSupportGrant = supportGrantData?.active === true && (supportExpiresAt === null || Date.parse(supportExpiresAt) > Date.now());

        const otherActive = activeEntitlements.docs.filter((doc) => {
            if (doc.id === tokenHash || doc.data().entitled !== true) return false;
            const expiresAt = doc.data().expiresAt;
            return typeof expiresAt === "string" && Date.parse(expiresAt) > Date.now();
        });
        const premiumExpiresAt = [
            ...(entitlement.entitled && entitlement.expiresAt ? [entitlement.expiresAt] : []),
            ...(hasValidSupportGrant && supportExpiresAt ? [supportExpiresAt] : []),
            ...otherActive
                .map((doc) => doc.data().expiresAt)
                .filter((value): value is string => typeof value === "string"),
        ].sort().pop() || null;
        const isPremium = entitlement.entitled || hasValidSupportGrant || otherActive.length > 0;
        const premiumFields = {
            id: uid,
            isPremium,
            premiumExpiresAt: premiumExpiresAt || admin.firestore.FieldValue.delete(),
        };
        transaction.set(profileRef, profile.exists
            ? premiumFields
            : { ...defaultProfile(uid, email, name), ...premiumFields }, { merge: true });
    });
}

export const verifyAndroidEntitlement = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in.");
    }

    const purchaseToken = typeof data?.purchaseToken === "string" ? data.purchaseToken.trim() : "";
    const productId = typeof data?.productId === "string" ? data.productId.trim() : "";
    if (purchaseToken.length < 16 || !PREMIUM_PRODUCT_IDS.has(productId)) {
        throw new functions.https.HttpsError("invalid-argument", "Invalid purchase verification data.");
    }

    let entitlement: AndroidEntitlement;
    try {
        entitlement = await verifyAndroidPurchase(purchaseToken, productId);
    } catch (error) {
        if (error instanceof functions.https.HttpsError) throw error;
        functions.logger.error("Google Play verification failed", { uid: context.auth.uid, error });
        throw new functions.https.HttpsError("unavailable", "Google Play verification failed.");
    }

    const uid = context.auth.uid;
    const email = typeof context.auth.token.email === "string" ? context.auth.token.email : null;
    const name = typeof context.auth.token.name === "string" ? context.auth.token.name : null;
    await persistAndroidEntitlement(uid, purchaseToken, entitlement, email, name);

    return {
        entitled: entitlement.entitled,
        status: entitlement.status,
        productId: entitlement.productId,
        expiresAt: entitlement.expiresAt,
    };
});

export const reconcileAndroidEntitlements = functions.pubsub
    .schedule("every 24 hours")
    .timeZone("UTC")
    .onRun(async () => {
        const snapshots = await db.collection("androidEntitlements").get();
        let verified = 0;
        let failed = 0;

        for (const snapshot of snapshots.docs) {
            const data = snapshot.data();
            const purchaseToken = typeof data.purchaseToken === "string" ? data.purchaseToken : "";
            const productId = typeof data.productId === "string" ? data.productId : "";
            if (!purchaseToken || !PREMIUM_PRODUCT_IDS.has(productId)) {
                failed++;
                continue;
            }

            const uid = typeof data.uid === "string" ? data.uid : "";
            if (!uid) {
                failed++;
                continue;
            }

            try {
                const entitlement = await verifyAndroidPurchase(purchaseToken, productId);
                await persistAndroidEntitlement(uid, purchaseToken, entitlement);
                verified++;
            } catch (error) {
                const expiresAt = typeof data.expiresAt === "string" ? data.expiresAt : null;
                if (expiresAt && Date.parse(expiresAt) <= Date.now()) {
                    await persistAndroidEntitlement(uid, purchaseToken, {
                        entitled: false,
                        status: "expired",
                        productId,
                        expiresAt,
                        subscriptionState: "SUBSCRIPTION_STATE_EXPIRED",
                        latestOrderId: typeof data.latestOrderId === "string"
                            ? data.latestOrderId
                            : null,
                    });
                }
                failed++;
                functions.logger.error("Scheduled Google Play verification failed", {
                    uid,
                    error,
                });
            }
        }

        // Reconcile manual support grants that have expired
        const supportGrantsSnap = await db.collection("supportGrants").get();
        for (const grantDoc of supportGrantsSnap.docs) {
            const data = grantDoc.data();
            const uid = grantDoc.id;
            const expiresAt = typeof data.expiresAt === "string" ? data.expiresAt : null;
            if (data.active === true && expiresAt && Date.parse(expiresAt) <= Date.now()) {
                await grantDoc.ref.update({ active: false });
                const profileRef = db.collection("profiles").doc(uid);
                const profileSnap = await profileRef.get();
                if (profileSnap.exists) {
                    const profileData = profileSnap.data();
                    if (profileData?.isPremium === true) {
                        await profileRef.update({
                            isPremium: false,
                            premiumExpiresAt: admin.firestore.FieldValue.delete(),
                        });
                    }
                }
            }
        }

        functions.logger.info("Android entitlement & support grant reconciliation complete", {
            scanned: snapshots.size,
            verified,
            failed,
        });
        return null;
    });

// ─── grantSupportPremium ────────────────────────────────────────────
//
// Admin-only Callable Cloud Function to grant temporary Pro access for support.
// Prevents direct raw database manipulation of profile.isPremium.
//

export const grantSupportPremium = functions.https.onCall(async (data, context) => {
    verifyIsAdmin(context);

    const targetUid = typeof data?.targetUid === "string" ? data.targetUid.trim() : "";
    const durationDays = typeof data?.durationDays === "number" && data.durationDays > 0 ? data.durationDays : 30;
    const reason = typeof data?.reason === "string" ? data.reason.trim() : "Support grant";

    if (!targetUid) {
        throw new functions.https.HttpsError("invalid-argument", "targetUid is required.");
    }

    const expiresAt = new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000).toISOString();

    await db.collection("supportGrants").doc(targetUid).set({
        uid: targetUid,
        active: true,
        durationDays,
        reason,
        expiresAt,
        grantedBy: context.auth?.token.email || context.auth?.uid,
        grantedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection("profiles").doc(targetUid).set({
        id: targetUid,
        isPremium: true,
        premiumExpiresAt: expiresAt,
    }, { merge: true });

    functions.logger.info(`🎁 Support grant issued to ${targetUid} until ${expiresAt} (${reason})`);
    return { success: true, targetUid, expiresAt };
});

// ─── deleteUserAccount ──────────────────────────────────────────────
//
// Callable Cloud Function that executes complete deletion of a user's data:
// 1. Profile document (/profiles/{uid})
// 2. Storage objects under users/{uid}/
// 3. Removes user entries from all leaderboards
// 4. Android entitlement documents tied to this user
// 5. Firebase Auth user account
//

export const deleteUserAccount = functions.https.onCall(async (_data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Must be logged in to delete your account."
        );
    }

    const uid = context.auth.uid;
    functions.logger.info(`🗑️ Starting account deletion for user: ${uid}`);

    try {
        // 1. Delete profile document
        await db.collection("profiles").doc(uid).delete();

        // 2. Remove user from all leaderboards
        const leaderboardsSnap = await db.collection("leaderboards").get();
        for (const lbDoc of leaderboardsSnap.docs) {
            const lbData = lbDoc.data();
            if (!Array.isArray(lbData.scores)) continue;

            const originalLen = lbData.scores.length;
            const filtered = lbData.scores.filter(
                (entry: LeaderboardEntry) => entry.userId !== uid
            );

            if (filtered.length < originalLen) {
                await lbDoc.ref.update({
                    scores: filtered,
                    lastUpdated: new Date().toISOString(),
                });
            }
        }

        // 3. Delete android entitlements tied to UID
        const entitlementsSnap = await db.collection("androidEntitlements").where("uid", "==", uid).get();
        for (const doc of entitlementsSnap.docs) {
            await doc.ref.delete();
        }

        // 4. Delete user files in Firebase Storage
        try {
            const bucket = admin.storage().bucket();
            await bucket.deleteFiles({ prefix: `users/${uid}/` });
        } catch (storageErr) {
            functions.logger.warn(`Storage deletion cleanup notice for ${uid}:`, storageErr);
        }

        // 5. Delete Firebase Auth user
        await admin.auth().deleteUser(uid);

        functions.logger.info(`✅ Account deletion completed successfully for user: ${uid}`);
        return { success: true };
    } catch (error) {
        functions.logger.error(`❌ Account deletion failed for user ${uid}:`, error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to complete account deletion. Please try again or contact support."
        );
    }
});
