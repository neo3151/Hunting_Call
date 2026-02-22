import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hunting_calls_perfection/features/profile/domain/use_cases/update_daily_challenge_stats_use_case.dart';
import 'package:hunting_calls_perfection/features/profile/domain/use_cases/calculate_new_achievements_use_case.dart';

/// Provider for UpdateDailyChallengeStatsUseCase
/// 
/// Pure use case with no dependencies
final updateDailyChallengeStatsUseCaseProvider = Provider<UpdateDailyChallengeStatsUseCase>((ref) {
  return UpdateDailyChallengeStatsUseCase();
});

/// Provider for CalculateNewAchievementsUseCase
final calculateNewAchievementsUseCaseProvider = Provider<CalculateNewAchievementsUseCase>((ref) {
  return CalculateNewAchievementsUseCase();
});
