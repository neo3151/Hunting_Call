import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hunting_calls_perfection/di_providers.dart';
import '../../data/onboarding_repository_impl.dart';
import '../../data/onboarding_local_data_source.dart';
import 'usecases/check_onboarding_status_use_case.dart';
import 'usecases/complete_onboarding_use_case.dart';

/// Provider for OnboardingRepository implementation
final onboardingRepositoryProvider = Provider((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final dataSource = OnboardingLocalDataSource(sharedPreferences: prefs);
  return OnboardingRepositoryImpl(dataSource);
});

/// Provider for CheckOnboardingStatusUseCase
final checkOnboardingStatusUseCaseProvider = Provider((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return CheckOnboardingStatusUseCase(repository);
});

/// Provider for CompleteOnboardingUseCase
final completeOnboardingUseCaseProvider = Provider((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return CompleteOnboardingUseCase(repository);
});
