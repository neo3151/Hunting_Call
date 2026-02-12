import '../../library/domain/reference_call_model.dart';

/// Abstract interface for daily challenge operations.
/// Lives in the domain layer — implementations go in data/.
abstract class DailyChallengeRepository {
  /// Get the daily challenge call for today.
  ReferenceCall getDailyChallenge();
}
