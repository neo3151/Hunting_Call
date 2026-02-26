import 'package:outcall/features/leaderboard/domain/leaderboard_entry.dart';
import 'package:outcall/features/leaderboard/domain/repositories/leaderboard_service.dart';
import 'package:outcall/core/services/api_gateway.dart';

class UnifiedLeaderboardService implements LeaderboardService {
  final ApiGateway _apiGateway;

  UnifiedLeaderboardService(this._apiGateway);

  @override
  Future<bool> submitScore({
    required String animalId,
    required LeaderboardEntry entry,
  }) async {
    // Note: Firedart doesn't have true transactions, but ApiGateway unifies 
    // the read-modify-write approach to work across both platforms.
    
    final docData = await _apiGateway.getDocument('leaderboards', animalId);
    
    List<LeaderboardEntry> currentScores = [];
    if (docData != null && docData.containsKey('scores')) {
      final List<dynamic> rawList = docData['scores'];
      currentScores = rawList
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final int existingIndex = currentScores.indexWhere((e) => e.userId == entry.userId);
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
    
    await _apiGateway.setDocument('leaderboards', animalId, {
      'scores': currentScores.map((e) => e.toJson()).toList(),
      'lastUpdated': DateTime.now().toIso8601String(),
    });
    
    return true;
  }

  @override
  Stream<List<LeaderboardEntry>> getTopScores(String animalId) {
    return _apiGateway.streamDocument('leaderboards', animalId).map((data) {
      if (data == null || !data.containsKey('scores')) {
        return [];
      }
      final List<dynamic> rawList = data['scores'];
      return rawList
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }
}
