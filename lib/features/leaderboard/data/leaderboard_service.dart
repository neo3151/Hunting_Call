import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/leaderboard_entry.dart';

abstract class LeaderboardService {
  Future<bool> submitScore({
    required String animalId,
    required LeaderboardEntry entry,
  });

  Stream<List<LeaderboardEntry>> getTopScores(String animalId);
}

class FirebaseLeaderboardService implements LeaderboardService {
  final FirebaseFirestore _firestore;

  FirebaseLeaderboardService(this._firestore);

  @override
  Future<bool> submitScore({
    required String animalId,
    required LeaderboardEntry entry,
  }) async {
    final docRef = _firestore.collection('leaderboards').doc(animalId);
    
    // Using a transaction to ensure atomic updates to the top 10 list
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      
      List<LeaderboardEntry> currentScores = [];
      
      if (snapshot.exists && snapshot.data() != null && snapshot.data()!.containsKey('scores')) {
        final List<dynamic> rawList = snapshot.data()!['scores'];
        currentScores = rawList
            .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Check if user already has a better score? 
      // Simplified: Just add and sort for now. Real world: check if user improved.
      // We will allow multiple entries from same user for now if they are top 10, 
      // but ideally we should filter unique users. Let's do unique user filter.
      
      int existingIndex = currentScores.indexWhere((e) => e.userId == entry.userId);
      if (existingIndex != -1) {
        if (currentScores[existingIndex].score >= entry.score) {
          return false; // Existing score is better or equal
        }
        currentScores.removeAt(existingIndex); // Remove old lower score
      }
      
      currentScores.add(entry);
      
      // Sort descending by score
      currentScores.sort((a, b) => b.score.compareTo(a.score));
      
      // Keep top 20 (extra buffer)
      if (currentScores.length > 20) {
        currentScores = currentScores.sublist(0, 20);
      }
      
      // Save back
      transaction.set(docRef, {
        'scores': currentScores.map((e) => e.toJson()).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      return true;
    });
  }

  @override
  Stream<List<LeaderboardEntry>> getTopScores(String animalId) {
    return _firestore.collection('leaderboards').doc(animalId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null || !snapshot.data()!.containsKey('scores')) {
        return [];
      }
      final List<dynamic> rawList = snapshot.data()!['scores'];
      return rawList
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }
}
