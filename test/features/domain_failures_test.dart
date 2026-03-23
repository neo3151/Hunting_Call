import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/leaderboard/domain/failures/leaderboard_failure.dart';
import 'package:outcall/features/library/domain/failures/library_failure.dart';
import 'package:outcall/features/profile/domain/failures/profile_failure.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════
  // LEADERBOARD FAILURES
  // ═══════════════════════════════════════════════════════════════
  group('LeaderboardFailure', () {
    test('ScoreNotHighEnough includes user and score', () {
      const f = ScoreNotHighEnough('user_1', 42.0);
      expect(f.message, contains('42'));
      expect(f.message, contains('user_1'));
    });

    test('ExistingScoreBetter includes both scores', () {
      const f = ExistingScoreBetter('user_1', 90.0, 85.0);
      expect(f.message, contains('90'));
      expect(f.message, contains('85'));
    });

    test('LeaderboardUpdateFailed includes reason', () {
      const f = LeaderboardUpdateFailed('Network error');
      expect(f.message, contains('Network error'));
    });

    test('LeaderboardNotFound includes animalId', () {
      const f = LeaderboardNotFound('elk_bugle');
      expect(f.message, contains('elk_bugle'));
    });

    test('all are LeaderboardFailure subtypes', () {
      const failures = <LeaderboardFailure>[
        ScoreNotHighEnough('u', 1.0),
        ExistingScoreBetter('u', 2.0, 1.0),
        LeaderboardUpdateFailed('test'),
        LeaderboardNotFound('test'),
      ];
      for (final f in failures) {
        expect(f, isA<LeaderboardFailure>());
        expect(f.message.isNotEmpty, true);
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // LIBRARY FAILURES
  // ═══════════════════════════════════════════════════════════════
  group('LibraryFailure', () {
    test('LibraryNotInitialized message', () {
      const f = LibraryNotInitialized();
      expect(f.message, contains('not initialized'));
    });

    test('CallNotFound includes callId', () {
      const f = CallNotFound('elk_bugle');
      expect(f.message, contains('elk_bugle'));
      expect(f.callId, 'elk_bugle');
    });

    test('JsonLoadError includes details', () {
      const f = JsonLoadError('Malformed JSON');
      expect(f.message, contains('Malformed JSON'));
    });

    test('all are LibraryFailure subtypes', () {
      const failures = <LibraryFailure>[
        LibraryNotInitialized(),
        CallNotFound('test'),
        JsonLoadError('test'),
      ];
      for (final f in failures) {
        expect(f, isA<LibraryFailure>());
        expect(f.message.isNotEmpty, true);
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // PROFILE FAILURES
  // ═══════════════════════════════════════════════════════════════
  group('ProfileFailure', () {
    test('ProfileNotFound includes userId', () {
      const f = ProfileNotFound('user_999');
      expect(f.message, contains('user_999'));
    });

    test('ProfileCreationFailed includes reason', () {
      const f = ProfileCreationFailed('Firestore timeout');
      expect(f.message, contains('Firestore timeout'));
    });

    test('ProfileUpdateFailed includes reason', () {
      const f = ProfileUpdateFailed('Auth expired');
      expect(f.message, contains('Auth expired'));
    });

    test('AchievementCalculationFailed includes reason', () {
      const f = AchievementCalculationFailed('Null profile');
      expect(f.message, contains('Null profile'));
    });

    test('DailyChallengeStatsFailed includes reason', () {
      const f = DailyChallengeStatsFailed('Invalid date');
      expect(f.message, contains('Invalid date'));
    });

    test('all are ProfileFailure subtypes', () {
      const failures = <ProfileFailure>[
        ProfileNotFound('id'),
        ProfileCreationFailed('r'),
        ProfileUpdateFailed('r'),
        AchievementCalculationFailed('r'),
        DailyChallengeStatsFailed('r'),
      ];
      for (final f in failures) {
        expect(f, isA<ProfileFailure>());
        expect(f.message.isNotEmpty, true);
      }
    });
  });
}
