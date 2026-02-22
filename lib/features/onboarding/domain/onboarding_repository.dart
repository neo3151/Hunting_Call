/// Abstract interface for onboarding operations.
/// Lives in the domain layer — implementations go in data/.
abstract class OnboardingRepository {
  /// Returns true if the user has completed onboarding.
  Future<bool> hasSeenOnboarding();

  /// Marks onboarding as completed.
  Future<void> completeOnboarding();

  /// Resets onboarding state (for testing).
  Future<void> resetOnboarding();
}
