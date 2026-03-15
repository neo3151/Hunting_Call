import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/onboarding/domain/failures/onboarding_failure.dart';

void main() {
  group('OnboardingFailure', () {
    test('StorageError includes details', () {
      const f = StorageError('SharedPreferences unavailable');
      expect(f.message, contains('SharedPreferences unavailable'));
      expect(f.details, 'SharedPreferences unavailable');
    });

    test('StorageError is OnboardingFailure subtype', () {
      const f = StorageError('test');
      expect(f, isA<OnboardingFailure>());
      expect(f.message.isNotEmpty, true);
    });
  });
}
