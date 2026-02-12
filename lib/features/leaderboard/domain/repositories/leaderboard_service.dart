import '../leaderboard_entry.dart';

/// Abstract interface for leaderboard operations.
/// Lives in the domain layer — implementations go in data/.
abstract class LeaderboardService {
  Future<bool> submitScore({
    required String animalId,
    required LeaderboardEntry entry,
  });

  Stream<List<LeaderboardEntry>> getTopScores(String animalId);
}
