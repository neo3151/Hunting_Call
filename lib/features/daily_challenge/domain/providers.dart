import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hunting_calls_perfection/features/library/domain/providers.dart';
import 'package:hunting_calls_perfection/features/daily_challenge/domain/usecases/get_daily_challenge_use_case.dart';
import 'package:hunting_calls_perfection/features/daily_challenge/domain/daily_challenge_repository.dart';

/// Provider for the Daily Challenge Repository
final dailyChallengeRepositoryProvider = Provider<DailyChallengeRepository>((ref) {
  throw UnimplementedError('dailyChallengeRepositoryProvider must be overridden');
});

/// Provider for GetDailyChallengeUseCase
final getDailyChallengeUseCaseProvider = Provider<GetDailyChallengeUseCase>((ref) {
  final getAllCalls = ref.watch(getAllCallsUseCaseProvider);
  final checkLockStatus = ref.watch(checkCallLockStatusUseCaseProvider);
  final repository = ref.watch(dailyChallengeRepositoryProvider);
  
  return GetDailyChallengeUseCase(getAllCalls, checkLockStatus, repository);
});
