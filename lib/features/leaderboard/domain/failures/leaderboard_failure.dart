/// Sealed class for leaderboard-related failures
/// 
/// Provides type-safe error handling for leaderboard operations
sealed class LeaderboardFailure {
  final String message;
  
  const LeaderboardFailure(this.message);
}

/// Score was not high enough to make the leaderboard
class ScoreNotHighEnough extends LeaderboardFailure {
  const ScoreNotHighEnough(String userId, double score) 
      : super('Score $score from user $userId did not make the leaderboard');
}

/// User's existing score is better than the new submission
class ExistingScoreBetter extends LeaderboardFailure {
  const ExistingScoreBetter(String userId, double existingScore, double newScore) 
      : super('User $userId already has better score ($existingScore vs $newScore)');
}

/// Failed to update leaderboard
class LeaderboardUpdateFailed extends LeaderboardFailure {
  const LeaderboardUpdateFailed(String reason) 
      : super('Failed to update leaderboard: $reason');
}

/// Leaderboard was not found
class LeaderboardNotFound extends LeaderboardFailure {
  const LeaderboardNotFound(String animalId) 
      : super('Leaderboard not found for animal: $animalId');
}
