import '../daily_challenge_repository.dart';
import '../../../library/domain/reference_call_model.dart';

/// Use case: Get today's daily challenge call.
class GetDailyChallenge {
  final DailyChallengeRepository repository;

  GetDailyChallenge({required this.repository});

  ReferenceCall call() {
    return repository.getDailyChallenge();
  }
}
