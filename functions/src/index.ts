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
