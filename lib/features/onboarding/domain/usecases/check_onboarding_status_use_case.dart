import 'package:fpdart/fpdart.dart';
import '../onboarding_repository.dart';
import '../failures/onboarding_failure.dart';

/// Use case: Check if user has completed onboarding
/// 
/// Returns true if onboarding has been completed, false otherwise
class CheckOnboardingStatusUseCase {
  final OnboardingRepository _repository;

  const CheckOnboardingStatusUseCase(this._repository);

  /// Execute the use case
  /// 
  /// Returns the onboarding status or a failure if storage fails
  Either<OnboardingFailure, bool> execute() {
    try {
      final hasCompleted = _repository.hasSeenOnboarding();
      return right(hasCompleted);
    } catch (e) {
      return left(StorageError(e.toString()));
    }
  }
}
