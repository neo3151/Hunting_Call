import 'package:fpdart/fpdart.dart';
import 'package:hunting_calls_perfection/features/leaderboard/domain/leaderboard_entry.dart';
import 'package:hunting_calls_perfection/features/leaderboard/domain/failures/leaderboard_failure.dart';

/// Result of a score submission attempt
class SubmitScoreResult {
  final bool wasAccepted;
  final List<LeaderboardEntry> updatedEntries;
  final String? reason;

  const SubmitScoreResult({
    required this.wasAccepted,
    required this.updatedEntries,
    this.reason,
  });

  const SubmitScoreResult.accepted(List<LeaderboardEntry> entries)
      : wasAccepted = true,
        updatedEntries = entries,
        reason = null;

  const SubmitScoreResult.rejected(String rejectionReason)
      : wasAccepted = false,
        updatedEntries = const [],
        reason = rejectionReason;
}

/// Use case for managing leaderboard score submissions
/// 
/// Extracted from FirebaseLeaderboardService (40+ lines of business logic)
/// This is a PURE function with no side effects - perfect for testing
class SubmitScoreUseCase {
  /// Process a new score submission
  /// 
  /// Business rules:
  /// - If user already exists, only accept if new score is better
  /// - Add new score to list
  /// - Sort descending by score
  /// - Keep top 20 entries
  /// 
  /// Returns updated entries if accepted, failure otherwise
  Either<LeaderboardFailure, SubmitScoreResult> execute(
    List<LeaderboardEntry> currentEntries,
    LeaderboardEntry newEntry,
  ) {
    try {
      // Make a mutable copy for manipulation
      final entries = List<LeaderboardEntry>.from(currentEntries);

      // Check if user already has a score
      final existingIndex = entries.indexWhere((e) => e.userId == newEntry.userId);

      if (existingIndex != -1) {
        final existingScore = entries[existingIndex].score;
        
        // If existing score is better or equal, reject
        if (existingScore >= newEntry.score) {
          return Left(ExistingScoreBetter(
            newEntry.userId,
            existingScore,
            newEntry.score,
          ));
        }
        
        // Remove old lower score
        entries.removeAt(existingIndex);
      }

      // Add new entry
      entries.add(newEntry);

      // Sort descending by score
      entries.sort((a, b) => b.score.compareTo(a.score));

      // Keep top 20
      final topEntries = entries.length > 20 
          ? entries.sublist(0, 20) 
          : entries;

      return Right(SubmitScoreResult.accepted(topEntries));
    } catch (e) {
      return Left(LeaderboardUpdateFailed(e.toString()));
    }
  }
}
