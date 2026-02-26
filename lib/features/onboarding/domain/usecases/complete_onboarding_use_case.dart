import 'package:fpdart/fpdart.dart';
import 'package:outcall/features/onboarding/domain/onboarding_repository.dart';
import 'package:outcall/features/onboarding/domain/failures/onboarding_failure.dart';

/// Use case: Mark onboarding as completed
/// 
/// Persists the onboarding completion state
class CompleteOnboardingUseCase {
  final OnboardingRepository _repository;

  const CompleteOnboardingUseCase(this._repository);

  /// Execute the use case
  /// 
  /// Returns success (void) or a failure if storage fails
  Future<Either<OnboardingFailure, void>> execute() async {
    try {
      await _repository.completeOnboarding();
      return right(null);
    } catch (e) {
      return left(StorageError(e.toString()));
    }
  }
}
