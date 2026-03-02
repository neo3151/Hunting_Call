import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/profile/domain/entities/daily_challenge_stats.dart';
import 'package:outcall/features/profile/domain/use_cases/update_daily_challenge_stats_use_case.dart';

void main() {
  late UpdateDailyChallengeStatsUseCase useCase;

  setUp(() {
    useCase = UpdateDailyChallengeStatsUseCase();
  });

  group('DailyChallengeStats', () {
    test('initial() creates zeroed stats', () {
      const stats = DailyChallengeStats.initial();
      expect(stats.challengesCompleted, 0);
      expect(stats.lastChallengeDate, isNull);
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 0);
    });

    test('copyWith preserves unmodified fields', () {
      final stats = DailyChallengeStats(
        challengesCompleted: 5,
        lastChallengeDate: DateTime(2026, 3, 1),
        currentStreak: 3,
        longestStreak: 7,
      );
      final updated = stats.copyWith(currentStreak: 4);
      expect(updated.challengesCompleted, 5);
      expect(updated.currentStreak, 4);
      expect(updated.longestStreak, 7);
    });
  });

  group('UpdateDailyChallengeStatsUseCase', () {
    test('first challenge ever sets all to 1', () {
      const initial = DailyChallengeStats.initial();
      final result = useCase.execute(initial, DateTime(2026, 3, 1));

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (stats) {
          expect(stats.challengesCompleted, 1);
          expect(stats.currentStreak, 1);
          expect(stats.longestStreak, 1);
          expect(stats.lastChallengeDate, isNotNull);
        },
      );
    });

    test('same day does not increment', () {
      final stats = DailyChallengeStats(
        challengesCompleted: 3,
        lastChallengeDate: DateTime(2026, 3, 1, 10, 0),
        currentStreak: 2,
        longestStreak: 5,
      );
      // Complete again same day, different time
      final result = useCase.execute(stats, DateTime(2026, 3, 1, 18, 0));

      result.fold(
        (_) => fail('Should be Right'),
        (updated) {
          expect(updated.challengesCompleted, 3); // same
          expect(updated.currentStreak, 2); // same
        },
      );
    });

    test('consecutive day increments streak', () {
      final stats = DailyChallengeStats(
        challengesCompleted: 3,
        lastChallengeDate: DateTime(2026, 3, 1),
        currentStreak: 3,
        longestStreak: 5,
      );
      final result = useCase.execute(stats, DateTime(2026, 3, 2));

      result.fold(
        (_) => fail('Should be Right'),
        (updated) {
          expect(updated.challengesCompleted, 4);
          expect(updated.currentStreak, 4);
          expect(updated.longestStreak, 5); // didn't beat longest
        },
      );
    });

    test('consecutive day updates longest streak when beaten', () {
      final stats = DailyChallengeStats(
        challengesCompleted: 5,
        lastChallengeDate: DateTime(2026, 3, 1),
        currentStreak: 5,
        longestStreak: 5,
      );
      final result = useCase.execute(stats, DateTime(2026, 3, 2));

      result.fold(
        (_) => fail('Should be Right'),
        (updated) {
          expect(updated.currentStreak, 6);
          expect(updated.longestStreak, 6); // new record
        },
      );
    });

    test('gap of 2+ days resets streak to 1', () {
      final stats = DailyChallengeStats(
        challengesCompleted: 10,
        lastChallengeDate: DateTime(2026, 3, 1),
        currentStreak: 5,
        longestStreak: 8,
      );
      final result = useCase.execute(stats, DateTime(2026, 3, 5)); // 4 day gap

      result.fold(
        (_) => fail('Should be Right'),
        (updated) {
          expect(updated.challengesCompleted, 11);
          expect(updated.currentStreak, 1); // reset
          expect(updated.longestStreak, 8); // preserved
        },
      );
    });

    test('month boundary handling (March 31 → April 1)', () {
      final stats = DailyChallengeStats(
        challengesCompleted: 3,
        lastChallengeDate: DateTime(2026, 3, 31),
        currentStreak: 3,
        longestStreak: 3,
      );
      final result = useCase.execute(stats, DateTime(2026, 4, 1));

      result.fold(
        (_) => fail('Should be Right'),
        (updated) {
          expect(updated.currentStreak, 4); // streak continues across months
        },
      );
    });

    test('year boundary handling (Dec 31 → Jan 1)', () {
      final stats = DailyChallengeStats(
        challengesCompleted: 30,
        lastChallengeDate: DateTime(2026, 12, 31),
        currentStreak: 30,
        longestStreak: 30,
      );
      final result = useCase.execute(stats, DateTime(2027, 1, 1));

      result.fold(
        (_) => fail('Should be Right'),
        (updated) {
          expect(updated.currentStreak, 31);
          expect(updated.longestStreak, 31);
        },
      );
    });
  });
}
