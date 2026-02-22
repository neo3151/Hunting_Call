import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hunting_calls_perfection/di_providers.dart';
import 'package:hunting_calls_perfection/features/onboarding/data/onboarding_repository_impl.dart';
import 'package:hunting_calls_perfection/features/onboarding/data/onboarding_local_data_source.dart';
import 'package:hunting_calls_perfection/features/onboarding/domain/usecases/check_onboarding_status_use_case.dart';
import 'package:hunting_calls_perfection/features/onboarding/domain/usecases/complete_onboarding_use_case.dart';

/// Provider for OnboardingRepository implementation
final onboardingRepositoryProvider = Provider((ref) {
  final storage = ref.watch(simpleStorageProvider);
  final dataSource = OnboardingLocalDataSource(storage: storage);
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
