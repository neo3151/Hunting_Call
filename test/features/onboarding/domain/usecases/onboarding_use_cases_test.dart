import 'package:flutter_test/flutter_test.dart';
import 'package:hunting_calls_perfection/features/onboarding/domain/usecases/check_onboarding_status_use_case.dart';
import 'package:hunting_calls_perfection/features/onboarding/domain/usecases/complete_onboarding_use_case.dart';
import 'package:hunting_calls_perfection/features/onboarding/domain/failures/onboarding_failure.dart';
import 'package:hunting_calls_perfection/features/onboarding/domain/onboarding_repository.dart';

// Mock repository for testing
class MockOnboardingRepository implements OnboardingRepository {
  bool _hasSeenOnboarding = false;
  bool _shouldThrowError = false;

  void setShouldThrowError(bool value) {
    _shouldThrowError = value;
  }

  @override
  Future<bool> hasSeenOnboarding() async {
    if (_shouldThrowError) throw Exception('Storage failed');
    return _hasSeenOnboarding;
  }

  @override
  Future<void> completeOnboarding() async {
    if (_shouldThrowError) throw Exception('Storage failed');
    _hasSeenOnboarding = true;
  }

  @override
  Future<void> resetOnboarding() async {
    if (_shouldThrowError) throw Exception('Storage failed');
    _hasSeenOnboarding = false;
  }

  void reset() {
    _hasSeenOnboarding = false;
    _shouldThrowError = false;
  }
}

void main() {
  late MockOnboardingRepository mockRepository;

  setUp(() {
    mockRepository = MockOnboardingRepository();
  });

  tearDown(() {
    mockRepository.reset();
  });

  group('CheckOnboardingStatusUseCase', () {
    test('returns false when onboarding not completed', () async {
      // Arrange
      final useCase = CheckOnboardingStatusUseCase(mockRepository);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (hasCompleted) => expect(hasCompleted, false),
      );
    });

    test('returns true when onboarding completed', () async {
      // Arrange
      final useCase = CheckOnboardingStatusUseCase(mockRepository);
      await mockRepository.completeOnboarding();

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (hasCompleted) => expect(hasCompleted, true),
      );
    });

    test('returns StorageError when operation fails', () async {
      // Arrange
      final useCase = CheckOnboardingStatusUseCase(mockRepository);
      mockRepository.setShouldThrowError(true);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<StorageError>());
          expect(failure.message, contains('Storage error'));
        },
        (hasCompleted) => fail('Should fail'),
      );
    });
  });

  group('CompleteOnboardingUseCase', () {
    test('successfully marks onboarding as complete', () async {
      // Arrange
      final useCase = CompleteOnboardingUseCase(mockRepository);
      expect(await mockRepository.hasSeenOnboarding(), false);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.isRight(), true);
      expect(await mockRepository.hasSeenOnboarding(), true);
    });

    test('returns StorageError when operation fails', () async {
      // Arrange
      final useCase = CompleteOnboardingUseCase(mockRepository);
      mockRepository.setShouldThrowError(true);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<StorageError>());
          expect(failure.message, contains('Storage error'));
        },
        (_) => fail('Should fail'),
      );
    });
  });

  group('Integration - Onboarding Flow', () {
    test('complete onboarding flow works correctly', () async {
      // Arrange
      final checkUseCase = CheckOnboardingStatusUseCase(mockRepository);
      final completeUseCase = CompleteOnboardingUseCase(mockRepository);

      // Act & Assert - Initially not completed
      var checkResult = await checkUseCase.execute();
      expect(checkResult.isRight(), true);
      checkResult.fold(
        (_) => fail('Should succeed'),
        (hasCompleted) => expect(hasCompleted, false),
      );

      // Act & Assert - Complete onboarding
      final completeResult = await completeUseCase.execute();
      expect(completeResult.isRight(), true);

      // Act & Assert - Check again (should be completed)
      checkResult = await checkUseCase.execute();
      checkResult.fold(
        (_) => fail('Should succeed'),
        (hasCompleted) => expect(hasCompleted, true),
      );
    });
  });
}
