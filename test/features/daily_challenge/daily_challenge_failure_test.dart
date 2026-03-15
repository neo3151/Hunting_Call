import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/daily_challenge/domain/failures/daily_challenge_failure.dart';

void main() {
  group('DailyChallengeFailure', () {
    test('NoChallengesAvailable message', () {
      const f = NoChallengesAvailable();
      expect(f.message, contains('No challenges'));
      expect(f, isA<DailyChallengeFailure>());
    });

    test('InvalidDateFormat includes details', () {
      const f = InvalidDateFormat('Leap year calc failed');
      expect(f.message, contains('Leap year calc failed'));
      expect(f.details, 'Leap year calc failed');
    });

    test('all are DailyChallengeFailure subtypes', () {
      const failures = <DailyChallengeFailure>[
        NoChallengesAvailable(),
        InvalidDateFormat('test'),
      ];
      for (final f in failures) {
        expect(f, isA<DailyChallengeFailure>());
        expect(f.message.isNotEmpty, true);
      }
    });
  });
}
