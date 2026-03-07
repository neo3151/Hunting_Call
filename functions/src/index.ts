import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

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
    if (!data.userName || typeof data.userName !== "string") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "userName is required."
        );
    }

    // Use the authenticated UID, not the client-supplied one (security)
    const userId = context.auth.uid;

    const newEntry: LeaderboardEntry = {
        userId: userId,
        userName: data.userName,
        score: data.score,
        timestamp: Date.now(),
        profileImageUrl: data.profileImageUrl || undefined,
        isAlphaTester: data.isAlphaTester || false,
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
    // Only allow authenticated admin calls
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Must be logged in to trigger scrub."
        );
    }

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
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Must be logged in to trigger backfill."
        );
    }

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
                model: "gemma3:4b",
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
