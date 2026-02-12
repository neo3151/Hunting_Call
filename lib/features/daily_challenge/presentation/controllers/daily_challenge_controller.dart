import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hunting_calls_perfection/features/library/domain/reference_call_model.dart';
import 'package:hunting_calls_perfection/features/daily_challenge/data/daily_challenge_service.dart';

/// Provides the daily challenge call via Riverpod.
final dailyChallengeProvider = Provider<ReferenceCall>((ref) {
  return DailyChallengeService.getDailyChallengeStatic();
});
