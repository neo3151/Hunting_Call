/// Abstract interface for daily challenge operations.
/// Lives in the domain layer — implementations go in data/.
abstract class DailyChallengeRepository {
  /// Get the daily challenge call ID for today.
  Future<String?> getDailyChallengeId();
}
