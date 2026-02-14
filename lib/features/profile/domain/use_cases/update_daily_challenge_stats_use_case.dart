import 'package:fpdart/fpdart.dart';
import '../entities/daily_challenge_stats.dart';
import '../failures/profile_failure.dart';

/// Pure use case for calculating daily challenge streak logic
/// 
/// Extracted from FirestoreProfileRepository (60+ lines of business logic)
/// This is a PURE function with no side effects - perfect for testing
class UpdateDailyChallengeStatsUseCase {
  /// Calculate new daily challenge stats based on completion date
  /// 
  /// Business rules:
  /// - If same day as last challenge, don't increment
  /// - If consecutive day, increment streak
  /// - If non-consecutive, reset streak to 1
  /// - Track longest streak ever achieved
  Either<ProfileFailure, DailyChallengeStats> execute(
    DailyChallengeStats currentStats,
    DateTime challengeCompletedDate,
  ) {
    try {
      final today = DateTime(
        challengeCompletedDate.year,
        challengeCompletedDate.month,
        challengeCompletedDate.day,
      );

      // First challenge ever
      if (currentStats.lastChallengeDate == null) {
        return Right(DailyChallengeStats(
          challengesCompleted: 1,
          lastChallengeDate: challengeCompletedDate,
          currentStreak: 1,
          longestStreak: 1,
        ));
      }

      final lastDate = currentStats.lastChallengeDate!;
      final lastDateDay = DateTime(lastDate.year, lastDate.month, lastDate.day);

      // Same day - don't increment
      if (lastDateDay.isAtSameMomentAs(today)) {
        return Right(currentStats);
      }

      // Check if consecutive (exactly 1 day apart)
      final daysDifference = today.difference(lastDateDay).inDays;
      final isConsecutive = daysDifference == 1;

      final newStreak = isConsecutive ? currentStats.currentStreak + 1 : 1;
      final newLongest = newStreak > currentStats.longestStreak 
          ? newStreak 
          : currentStats.longestStreak;

      return Right(DailyChallengeStats(
        challengesCompleted: currentStats.challengesCompleted + 1,
        lastChallengeDate: challengeCompletedDate,
        currentStreak: newStreak,
        longestStreak: newLongest,
      ));
    } catch (e) {
      return Left(DailyChallengeStatsFailed(e.toString()));
    }
  }
}
