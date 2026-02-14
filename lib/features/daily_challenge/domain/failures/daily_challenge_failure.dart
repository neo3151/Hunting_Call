/// Sealed class for all daily challenge failures
sealed class DailyChallengeFailure {
  const DailyChallengeFailure();
  
  String get message;
}

/// No calls available for daily challenge selection
class NoChallengesAvailable extends DailyChallengeFailure {
  const NoChallengesAvailable();
  
  @override
  String get message => 'No challenges available at this time.';
}

/// Error calculating date for challenge selection
class InvalidDateFormat extends DailyChallengeFailure {
  final String details;
  
  const InvalidDateFormat(this.details);
  
  @override
  String get message => 'Error calculating today\'s challenge: $details';
}
