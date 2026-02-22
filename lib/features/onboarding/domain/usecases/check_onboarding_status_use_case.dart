import 'package:fpdart/fpdart.dart';
import 'package:hunting_calls_perfection/features/onboarding/domain/onboarding_repository.dart';
import 'package:hunting_calls_perfection/features/onboarding/domain/failures/onboarding_failure.dart';

/// Use case: Check if user has completed onboarding
/// 
/// Returns true if onboarding has been completed, false otherwise
class CheckOnboardingStatusUseCase {
  final OnboardingRepository _repository;

  const CheckOnboardingStatusUseCase(this._repository);

  /// Execute the use case
  /// 
  /// Returns the onboarding status or a failure if storage fails
  Future<Either<OnboardingFailure, bool>> execute() async {
    try {
      final hasCompleted = await _repository.hasSeenOnboarding();
      return right(hasCompleted);
    } catch (e) {
      return left(StorageError(e.toString()));
    }
  }
}
