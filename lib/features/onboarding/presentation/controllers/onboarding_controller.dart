import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers.dart';
import '../../domain/usecases/check_onboarding_status_use_case.dart';
import '../../domain/usecases/complete_onboarding_use_case.dart';

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final checkStatusUseCase = ref.watch(checkOnboardingStatusUseCaseProvider);
  final completeUseCase = ref.watch(completeOnboardingUseCaseProvider);
  return OnboardingNotifier(checkStatusUseCase, completeUseCase);
});

class OnboardingNotifier extends StateNotifier<bool> {
  final CheckOnboardingStatusUseCase _checkStatusUseCase;
  final CompleteOnboardingUseCase _completeUseCase;

  OnboardingNotifier(this._checkStatusUseCase, this._completeUseCase)
      : super(false) {
    // Initialize state from use case
    final result = _checkStatusUseCase.execute();
    state = result.getOrElse((failure) => false);
  }

  Future<void> completeOnboarding() async {
    final result = await _completeUseCase.execute();
    
    result.fold(
      (failure) {
        // Log error but don't break UI
        // In production, could show error to user
      },
      (_) {
        state = true;
      },
    );
  }

  // For testing: reset onboarding (would need a reset use case for production)
  Future<void> resetOnboarding() async {
    // This would require a ResetOnboardingUseCase for proper implementation
    // For now, just update state
    state = false;
  }
}
