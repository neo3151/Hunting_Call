import 'package:hunting_calls_perfection/core/services/simple_storage.dart';

/// Data source for onboarding persistence.
/// Wraps SharedPreferences access for the onboarding flag.
class OnboardingLocalDataSource {
  final ISimpleStorage _storage;
  static const _key = 'has_seen_onboarding';

  OnboardingLocalDataSource({required ISimpleStorage storage})
      : _storage = storage;

  /// Returns true if the user has completed onboarding.
  Future<bool> hasSeenOnboarding() async {
    return await _storage.getBool(_key) ?? false;
  }

  /// Marks onboarding as completed.
  Future<void> completeOnboarding() async {
    await _storage.setBool(_key, true);
  }

  /// Resets onboarding state (for testing).
  Future<void> resetOnboarding() async {
    await _storage.setBool(_key, false);
  }
}
