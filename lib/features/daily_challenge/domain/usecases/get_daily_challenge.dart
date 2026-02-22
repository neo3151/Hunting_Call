import 'package:hunting_calls_perfection/features/daily_challenge/domain/daily_challenge_repository.dart';
import 'package:hunting_calls_perfection/features/library/domain/reference_call_model.dart';

/// Use case: Get today's daily challenge call.
class GetDailyChallenge {
  final DailyChallengeRepository repository;

  GetDailyChallenge({required this.repository});

  ReferenceCall call() {
    return repository.getDailyChallenge();
  }
}
