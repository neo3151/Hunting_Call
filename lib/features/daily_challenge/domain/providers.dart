import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/features/library/domain/providers.dart';
import 'package:outcall/features/daily_challenge/domain/usecases/get_daily_challenge_use_case.dart';
import 'package:outcall/features/daily_challenge/data/unified_daily_challenge_service.dart';
import 'package:outcall/features/daily_challenge/domain/daily_challenge_repository.dart';
import 'package:outcall/di_providers.dart';

/// Provides the DailyChallengeRepository implementation.
final dailyChallengeRepositoryProvider = Provider<DailyChallengeRepository>((ref) {
  return UnifiedDailyChallengeService(
    ref.watch(apiGatewayProvider),
    ref.watch(simpleStorageProvider),
  );
});

/// Provider for GetDailyChallengeUseCase
final getDailyChallengeUseCaseProvider = Provider<GetDailyChallengeUseCase>((ref) {
  final getAllCalls = ref.watch(getAllCallsUseCaseProvider);
  final checkLockStatus = ref.watch(checkCallLockStatusUseCaseProvider);
  final repository = ref.watch(dailyChallengeRepositoryProvider);
  
  return GetDailyChallengeUseCase(getAllCalls, checkLockStatus, repository);
});
