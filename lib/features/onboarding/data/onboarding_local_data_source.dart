import 'package:shared_preferences/shared_preferences.dart';

/// Data source for onboarding persistence.
/// Wraps SharedPreferences access for the onboarding flag.
class OnboardingLocalDataSource {
  final SharedPreferences _prefs;
  static const _key = 'has_seen_onboarding';

  OnboardingLocalDataSource({required SharedPreferences sharedPreferences})
      : _prefs = sharedPreferences;

  /// Returns true if the user has completed onboarding.
  bool hasSeenOnboarding() {
    return _prefs.getBool(_key) ?? false;
  }

  /// Marks onboarding as completed.
  Future<void> completeOnboarding() async {
    await _prefs.setBool(_key, true);
  }

  /// Resets onboarding state (for testing).
  Future<void> resetOnboarding() async {
    await _prefs.setBool(_key, false);
  }
}
