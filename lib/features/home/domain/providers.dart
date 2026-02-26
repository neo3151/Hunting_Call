import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/features/daily_challenge/data/daily_challenge_service.dart';
import 'package:outcall/features/library/domain/reference_call_model.dart';

/// Provides today's daily challenge call.
final dailyChallengeCallProvider = Provider<ReferenceCall>((ref) {
  return DailyChallengeService.getDailyChallengeStatic();
});
