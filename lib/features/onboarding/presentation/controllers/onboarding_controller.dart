import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final prefs = GetIt.I<SharedPreferences>();
  return OnboardingNotifier(prefs);
});

class OnboardingNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _key = 'has_seen_onboarding';

  OnboardingNotifier(this._prefs) : super(_prefs.getBool(_key) ?? false);

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_key, true);
    state = true;
  }
  
  // For testing: reset onboarding
  Future<void> resetOnboarding() async {
    await _prefs.setBool(_key, false);
    state = false;
  }
}
