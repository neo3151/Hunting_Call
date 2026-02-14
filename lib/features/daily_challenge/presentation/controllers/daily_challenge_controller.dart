import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hunting_calls_perfection/features/library/domain/reference_call_model.dart';
import 'package:hunting_calls_perfection/features/daily_challenge/domain/providers.dart';

/// Provides the daily challenge call via Riverpod.
/// Returns null if there's an error getting the challenge.
final dailyChallengeProvider = Provider<ReferenceCall?>((ref) {
  final useCase = ref.watch(getDailyChallengeUseCaseProvider);
  final result = useCase.execute();
  
  return result.fold(
    (failure) {
      // Log error but return null to allow UI to handle gracefully
      return null;
    },
    (challenge) => challenge,
  );
});
