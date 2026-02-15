import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../library/domain/providers.dart';
import 'usecases/get_daily_challenge_use_case.dart';

/// Provider for GetDailyChallengeUseCase
final getDailyChallengeUseCaseProvider = Provider<GetDailyChallengeUseCase>((ref) {
  final getAllCalls = ref.watch(getAllCallsUseCaseProvider);
  final checkLockStatus = ref.watch(checkCallLockStatusUseCaseProvider);
  
  return GetDailyChallengeUseCase(getAllCalls, checkLockStatus);
});
