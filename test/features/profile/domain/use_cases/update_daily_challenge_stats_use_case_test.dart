import 'package:flutter_test/flutter_test.dart';
import 'package:hunting_calls_perfection/features/profile/domain/use_cases/update_daily_challenge_stats_use_case.dart';
import 'package:hunting_calls_perfection/features/profile/domain/entities/daily_challenge_stats.dart';

void main() {
  late UpdateDailyChallengeStatsUseCase useCase;

  setUp(() {
    useCase = UpdateDailyChallengeStatsUseCase();
  });

  group('UpdateDailyChallengeStatsUseCase', () {
    test('first challenge ever starts streak at 1', () {
      // Arrange
      final today = DateTime.now();
      final todayDay = DateTime(today.year, today.month, today.day);

      // Act
      final result = useCase.execute(
        lastChallengeDate: null,
        currentStreak: 0,
        longestStreak: 0,
        now: today,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (stats) {
          expect(stats.newStreak, 1);
          expect(stats.newLongest, 1);
          expect(stats.shouldIncrement, true);
        },
      );
    });

    test('consecutive day challenge increments streak', () {
      // Arrange
      final today = DateTime(2024, 1, 15);
      final yesterday = DateTime(2024, 1, 14);

      // Act
      final result = useCase.execute(
        lastChallengeDate: yesterday,
        currentStreak: 5,
        longestStreak: 10,
        now: today,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (stats) {
          expect(stats.newStreak, 6); // 5 + 1
          expect(stats.newLongest, 10); // Unchanged (6 < 10)
          expect(stats.shouldIncrement, true);
        },
      );
    });

    test('consecutive day challenge sets new longest streak', () {
      // Arrange
      final today = DateTime(2024, 1, 15);
      final yesterday = DateTime(2024, 1, 14);

      // Act
      final result = useCase.execute(
        lastChallengeDate: yesterday,
        currentStreak: 12,
        longestStreak: 10,
        now: today,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (stats) {
          expect(stats.newStreak, 13); // 12 + 1
          expect(stats.newLongest, 13); // New record!
          expect(stats.shouldIncrement, true);
        },
      );
    });

    test('non-consecutive day challenge resets streak to 1', () {
      // Arrange
      final today = DateTime(2024, 1, 15);
      final threeDaysAgo = DateTime(2024, 1, 12);

      // Act
      final result = useCase.execute(
        lastChallengeDate: threeDaysAgo,
        currentStreak: 5,
        longestStreak: 10,
        now: today,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (stats) {
          expect(stats.newStreak, 1); // Reset
          expect(stats.newLongest, 10); // Unchanged
          expect(stats.shouldIncrement, true);
        },
      );
    });

    test('same day challenge does not increment', () {
      // Arrange
      final today = DateTime(2024, 1, 15, 10, 30);
      final earlierToday = DateTime(2024, 1, 15, 8, 0);

      // Act
      final result = useCase.execute(
        lastChallengeDate: earlierToday,
        currentStreak: 5,
        longestStreak: 10,
        now: today,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (stats) {
          expect(stats.shouldIncrement, false); // No increment
        },
      );
    });

    test('handles edge case of exactly 24 hours (same calendar day)', () {
      // Arrange
      final now = DateTime(2024, 1, 15, 23, 59);
      final lastChallenge = DateTime(2024, 1, 15, 0, 1);

      // Act
      final result = useCase.execute(
        lastChallengeDate: lastChallenge,
        currentStreak: 3,
        longestStreak: 5,
        now: now,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (stats) {
          expect(stats.shouldIncrement, false); // Same calendar day
        },
      );
    });

    test('handles edge case of midnight boundary (consecutive days)', () {
      // Arrange
      final today = DateTime(2024, 1, 15, 0, 1); // Just after midnight
      final yesterday = DateTime(2024, 1, 14, 23, 59); // Just before midnight

      // Act
      final result = useCase.execute(
        lastChallengeDate: yesterday,
        currentStreak: 7,
        longestStreak: 10,
        now: today,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (stats) {
          expect(stats.newStreak, 8); // Consecutive
          expect(stats.shouldIncrement, true);
        },
      );
    });
  });
}
