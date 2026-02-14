import 'package:fpdart/fpdart.dart';
import '../onboarding_repository.dart';
import '../failures/onboarding_failure.dart';

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
