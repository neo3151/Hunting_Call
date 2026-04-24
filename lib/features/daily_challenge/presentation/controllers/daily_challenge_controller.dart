import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/features/library/domain/reference_call_model.dart';
import 'package:outcall/features/daily_challenge/domain/providers.dart';
import 'package:outcall/features/profile/presentation/controllers/profile_controller.dart';
import 'package:outcall/core/utils/app_logger.dart';

/// Provides the daily challenge call via Riverpod Future.
/// Returns null if there's an error getting the challenge.
final dailyChallengeProvider = FutureProvider<ReferenceCall?>((ref) async {
  final useCase = ref.watch(getDailyChallengeUseCaseProvider);
  final isPremium = ref.watch(profileNotifierProvider).profile?.isPremium ?? false;
  final result = await useCase.execute(isUserPremium: isPremium);

  return result.fold(
    (failure) {
      AppLogger.d('error fetching challenge: ${failure.message}');
      return null;
    },
    (challenge) => challenge,
  );
});
