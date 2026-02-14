/// Sealed class for all onboarding failures
sealed class OnboardingFailure {
  const OnboardingFailure();
  
  String get message;
}

/// Storage operation failed (SharedPreferences error)
class StorageError extends OnboardingFailure {
  final String details;
  
  const StorageError(this.details);
  
  @override
  String get message => 'Storage error: $details';
}
