import '../domain/onboarding_repository.dart';
import 'onboarding_local_data_source.dart';

/// Implementation of OnboardingRepository using local storage
class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingLocalDataSource _dataSource;

  const OnboardingRepositoryImpl(this._dataSource);

  @override
  bool hasSeenOnboarding() {
    return _dataSource.hasSeenOnboarding();
  }

  @override
  Future<void> completeOnboarding() async {
    await _dataSource.completeOnboarding();
  }

  @override
  Future<void> resetOnboarding() async {
    await _dataSource.resetOnboarding();
  }
}
