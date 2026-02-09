import 'package:firedart/firedart.dart';
import '../domain/leaderboard_entry.dart';
import 'leaderboard_service.dart';

class FiredartLeaderboardService implements LeaderboardService {
  final Firestore _firestore;

  FiredartLeaderboardService(this._firestore);

  @override
  Future<bool> submitScore({
    required String animalId,
    required LeaderboardEntry entry,
  }) async {
    final docRef = _firestore.collection('leaderboards').document(animalId);
    
    // Firedart doesn't have transactions in the same way. We use get-modify-update.
    final doc = await docRef.get();
    
    List<LeaderboardEntry> currentScores = [];
    Map<String, dynamic> data = doc?.map ?? {};

    if (data.containsKey('scores')) {
      final List<dynamic> rawList = data['scores'];
      currentScores = rawList
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    int existingIndex = currentScores.indexWhere((e) => e.userId == entry.userId);
    if (existingIndex != -1) {
      if (currentScores[existingIndex].score >= entry.score) {
        return false;
      }
      currentScores.removeAt(existingIndex);
    }
    
    currentScores.add(entry);
    currentScores.sort((a, b) => b.score.compareTo(a.score));
    
    if (currentScores.length > 20) {
      currentScores = currentScores.sublist(0, 20);
    }
    
    await docRef.set({
      'scores': currentScores.map((e) => e.toJson()).toList(),
      'lastUpdated': DateTime.now().toIso8601String(),
    });
    
    return true;
  }

  @override
  Stream<List<LeaderboardEntry>> getTopScores(String animalId) {
    return _firestore.collection('leaderboards').document(animalId).stream.map((doc) {
      if (doc == null || !doc.map.containsKey('scores')) {
        return [];
      }
      final List<dynamic> rawList = doc.map['scores'];
      return rawList
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }
}
