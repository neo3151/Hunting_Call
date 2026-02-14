import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/leaderboard_entry.dart';
import '../domain/repositories/leaderboard_service.dart';
import '../domain/use_cases/submit_score_use_case.dart';


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
      
      // Parse current entries from Firestore
      List<LeaderboardEntry> currentScores = [];
      if (snapshot.exists && snapshot.data() != null && snapshot.data()!.containsKey('scores')) {
        final List<dynamic> rawList = snapshot.data()!['scores'];
        currentScores = rawList
            .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Use domain use case for score management (pure business logic)
      final useCase = SubmitScoreUseCase();
      final result = useCase.execute(currentScores, entry);
      
      return result.fold(
        (failure) {
          // Score was rejected (user has better score or other failure)
          return false;
        },
        (submitResult) {
          if (submitResult.wasAccepted) {
            // Save updated leaderboard to Firestore
            transaction.set(docRef, {
              'scores': submitResult.updatedEntries.map((e) => e.toJson()).toList(),
              'lastUpdated': FieldValue.serverTimestamp(),
            });
            return true;
          }
          return false;
        },
      );
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
