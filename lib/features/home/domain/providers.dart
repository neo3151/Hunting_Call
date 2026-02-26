import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:outcall/features/library/domain/reference_call_model.dart';
import 'package:outcall/features/daily_challenge/domain/providers.dart';
import 'package:outcall/features/daily_challenge/domain/failures/daily_challenge_failure.dart';

/// Provides today's daily challenge call (async, uses the proper use case).
final dailyChallengeCallProvider =
    FutureProvider<Either<DailyChallengeFailure, ReferenceCall>>((ref) async {
  final useCase = ref.watch(getDailyChallengeUseCaseProvider);
  return useCase.execute();
});
