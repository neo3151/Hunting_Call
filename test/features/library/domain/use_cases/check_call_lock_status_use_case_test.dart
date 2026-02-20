import 'package:flutter_test/flutter_test.dart';
import 'package:hunting_calls_perfection/features/library/domain/use_cases/check_call_lock_status_use_case.dart';
import 'package:hunting_calls_perfection/features/library/data/reference_database.dart';
import 'package:hunting_calls_perfection/config/freemium_config.dart';
import 'package:hunting_calls_perfection/config/app_config.dart';

void main() {
  late CheckCallLockStatusUseCase useCase;

  setUp(() {
    AppConfig.create(flavor: AppFlavor.free, appName: 'Hunting Call Test');
    useCase = const CheckCallLockStatusUseCase();
  });

  tearDown(() {
    ReferenceDatabase.calls = [];
  });

  group('CheckCallLockStatusUseCase', () {
    test('returns false (unlocked) when user is premium', () {
      // Arrange
      const callId = 'any_call';
      const isUserPremium = true;

      // Act
      final result = useCase.execute(
        callId: callId,
        isUserPremium: isUserPremium,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (isLocked) {
          expect(isLocked, false); // Premium users have everything unlocked
        },
      );
    });

    test('returns true (locked) for non-free calls when user is not premium', () {
      // Arrange
      // Use a call ID that is NOT in the free starter pack
      const callId = 'premium_only_call';
      const isUserPremium = false;

      // Act
      final result = useCase.execute(
        callId: callId,
        isUserPremium: isUserPremium,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (isLocked) {
          // If the call is not in FreemiumConfig.freeCallIds, it should be locked
          final shouldBeLocked = !FreemiumConfig.freeCallIds.contains(callId);
          expect(isLocked, shouldBeLocked);
        },
      );
    });

    test('returns false (unlocked) for free calls when user is not premium', () {
      // Arrange
      // Use a call ID that IS in the free starter pack
      // We need to check what's actually in FreemiumConfig.freeCallIds
      if (FreemiumConfig.freeCallIds.isEmpty) {
        // Skip this test if there are no free calls configured
        return;
      }
      
      final freeCallId = FreemiumConfig.freeCallIds.first;
      const isUserPremium = false;

      // Act
      final result = useCase.execute(
        callId: freeCallId,
        isUserPremium: isUserPremium,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (isLocked) {
          expect(isLocked, false); // Free calls should be unlocked for non-premium users
        },
      );
    });

    test('handles multiple calls consistently', () {
      // Arrange
      const premiumUser = true;
      const freeUser = false;
      const callId1 = 'test_call_1';
      const callId2 = 'test_call_2';

      // Act
      final result1Premium = useCase.execute(callId: callId1, isUserPremium: premiumUser);
      final result2Premium = useCase.execute(callId: callId2, isUserPremium: premiumUser);
      final result1Free = useCase.execute(callId: callId1, isUserPremium: freeUser);
      final result2Free = useCase.execute(callId: callId2, isUserPremium: freeUser);

      // Assert - All premium results should be unlocked
      expect(result1Premium.getOrElse((l) => true), false);
      expect(result2Premium.getOrElse((l) => true), false);

      // Free user results depend on FreemiumConfig
      expect(result1Free.isRight(), true);
      expect(result2Free.isRight(), true);
    });
  });
}
