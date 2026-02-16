import 'package:flutter_test/flutter_test.dart';
import 'package:hunting_calls_perfection/features/profile/domain/entities/daily_challenge_stats.dart';
import 'package:hunting_calls_perfection/features/profile/domain/use_cases/update_daily_challenge_stats_use_case.dart';

void main() {
  late UpdateDailyChallengeStatsUseCase useCase;

  setUp(() {
    useCase = UpdateDailyChallengeStatsUseCase();
  });

  group('UpdateDailyChallengeStatsUseCase', () {
    test('first challenge ever starts streak at 1', () {
      final today = DateTime.now();
      const stats = DailyChallengeStats.initial();

      final result = useCase.execute(stats, today);

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (newStats) {
          expect(newStats.currentStreak, 1);
          expect(newStats.longestStreak, 1);
          expect(newStats.challengesCompleted, 1);
        },
      );
    });

    test('consecutive day challenge increments streak', () {
      final today = DateTime(2024, 1, 15);
      final stats = DailyChallengeStats(
        challengesCompleted: 5,
        lastChallengeDate: DateTime(2024, 1, 14),
        currentStreak: 5,
        longestStreak: 10,
      );

      final result = useCase.execute(stats, today);

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (newStats) {
          expect(newStats.currentStreak, 6); // 5 + 1
          expect(newStats.longestStreak, 10); // Unchanged (6 < 10)
          expect(newStats.challengesCompleted, 6);
        },
      );
    });

    test('consecutive day challenge sets new longest streak', () {
      final today = DateTime(2024, 1, 15);
      final stats = DailyChallengeStats(
        challengesCompleted: 12,
        lastChallengeDate: DateTime(2024, 1, 14),
        currentStreak: 12,
        longestStreak: 10,
      );

      final result = useCase.execute(stats, today);

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (newStats) {
          expect(newStats.currentStreak, 13); // 12 + 1
          expect(newStats.longestStreak, 13); // New record!
        },
      );
    });

    test('non-consecutive day challenge resets streak to 1', () {
      final today = DateTime(2024, 1, 15);
      final stats = DailyChallengeStats(
        challengesCompleted: 10,
        lastChallengeDate: DateTime(2024, 1, 12), // 3 days ago
        currentStreak: 5,
        longestStreak: 10,
      );

      final result = useCase.execute(stats, today);

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (newStats) {
          expect(newStats.currentStreak, 1); // Reset
          expect(newStats.longestStreak, 10); // Unchanged
        },
      );
    });

    test('same day challenge does not increment', () {
      final today = DateTime(2024, 1, 15, 10, 30);
      final stats = DailyChallengeStats(
        challengesCompleted: 5,
        lastChallengeDate: DateTime(2024, 1, 15, 8, 0), // Earlier same day
        currentStreak: 5,
        longestStreak: 10,
      );

      final result = useCase.execute(stats, today);

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (newStats) {
          // Same day — stats should be unchanged
          expect(newStats.challengesCompleted, 5);
        },
      );
    });

    test('handles edge case of exactly 24 hours (same calendar day)', () {
      final now = DateTime(2024, 1, 15, 23, 59);
      final stats = DailyChallengeStats(
        challengesCompleted: 3,
        lastChallengeDate: DateTime(2024, 1, 15, 0, 1),
        currentStreak: 3,
        longestStreak: 5,
      );

      final result = useCase.execute(stats, now);

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (newStats) {
          // Same calendar day — no increment
          expect(newStats.challengesCompleted, 3);
        },
      );
    });

    test('handles edge case of midnight boundary (consecutive days)', () {
      final today = DateTime(2024, 1, 15, 0, 1); // Just after midnight
      final stats = DailyChallengeStats(
        challengesCompleted: 7,
        lastChallengeDate: DateTime(2024, 1, 14, 23, 59), // Just before midnight
        currentStreak: 7,
        longestStreak: 10,
      );

      final result = useCase.execute(stats, today);

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (newStats) {
          expect(newStats.currentStreak, 8); // Consecutive
          expect(newStats.challengesCompleted, 8);
        },
      );
    });
  });
}
