import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/features/onboarding/domain/providers.dart';

final onboardingProvider = AsyncNotifierProvider<OnboardingNotifier, bool>(() {
  return OnboardingNotifier();
});

class OnboardingNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final checkStatusUseCase = ref.watch(checkOnboardingStatusUseCaseProvider);
    final result = await checkStatusUseCase.execute();
    return result.getOrElse((failure) => false);
  }

  Future<void> completeOnboarding() async {
    final completeUseCase = ref.read(completeOnboardingUseCaseProvider);
    final result = await completeUseCase.execute();
    
    result.fold(
      (failure) {},
      (_) {
        state = const AsyncValue.data(true);
      },
    );
  }

  // For testing: reset onboarding
  Future<void> resetOnboarding() async {
    state = const AsyncValue.data(false);
  }
}
