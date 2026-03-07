"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.scrubInactiveProfilesManual = exports.scrubInactiveProfiles = exports.submitScore = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
admin.initializeApp();
const db = admin.firestore();
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
exports.submitScore = functions.https.onCall(async (data, context) => {
    // ── Auth check ──
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in to submit scores.");
    }
    // ── Input validation ──
    if (!data.animalId || typeof data.animalId !== "string") {
        throw new functions.https.HttpsError("invalid-argument", "animalId is required and must be a string.");
    }
    if (typeof data.score !== "number" || data.score < 0 || data.score > 100) {
        throw new functions.https.HttpsError("invalid-argument", "score must be a number between 0 and 100.");
    }
    if (!data.userName || typeof data.userName !== "string") {
        throw new functions.https.HttpsError("invalid-argument", "userName is required.");
    }
    // Use the authenticated UID, not the client-supplied one (security)
    const userId = context.auth.uid;
    const newEntry = {
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
        let scores = [];
        if (snapshot.exists) {
            const docData = snapshot.data();
            scores = ((docData === null || docData === void 0 ? void 0 : docData.scores) || []);
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
async function runProfileScrub() {
    const now = Date.now();
    const cutoffMs = INACTIVITY_THRESHOLD_DAYS * 24 * 60 * 60 * 1000;
    const cutoffDate = now - cutoffMs;
    const profilesSnap = await db.collection("profiles").get();
    let deleted = 0;
    let skippedPremium = 0;
    let skippedAlpha = 0;
    let skippedActive = 0;
    const deletedUserIds = [];
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
            if (ts > lastActivityMs)
                lastActivityMs = ts;
        }
        // 2. Check latest history entry
        if (Array.isArray(data.history) && data.history.length > 0) {
            for (const item of data.history) {
                const ts = toTimestampMs(item.timestamp);
                if (ts > lastActivityMs)
                    lastActivityMs = ts;
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
            if (!Array.isArray(lbData.scores))
                continue;
            const originalLen = lbData.scores.length;
            const filtered = lbData.scores.filter((entry) => !deletedUserIds.includes(entry.userId));
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
function toTimestampMs(value) {
    if (!value)
        return 0;
    // Firestore Timestamp object
    if (typeof value === "object" && value !== null && "toMillis" in value) {
        return value.toMillis();
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
exports.scrubInactiveProfiles = functions.pubsub
    .schedule("every sunday 03:00")
    .timeZone("UTC")
    .onRun(async () => {
    functions.logger.info("🧹 Starting scheduled profile scrub...");
    const result = await runProfileScrub();
    functions.logger.info("🧹 Profile scrub complete", result);
    return null;
});
// ── Manual trigger: callable from Firebase console or client ──
exports.scrubInactiveProfilesManual = functions.https.onCall(async (_data, context) => {
    // Only allow authenticated admin calls
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in to trigger scrub.");
    }
    functions.logger.info("🧹 Starting manual profile scrub...");
    const result = await runProfileScrub();
    functions.logger.info("🧹 Manual profile scrub complete", result);
    return result;
});
//# sourceMappingURL=index.js.map