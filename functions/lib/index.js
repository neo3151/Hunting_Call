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
exports.submitScore = void 0;
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
//# sourceMappingURL=index.js.map