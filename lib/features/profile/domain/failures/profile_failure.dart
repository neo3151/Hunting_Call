/// Sealed class for profile-related failures
/// 
/// Provides type-safe error handling for profile operations
sealed class ProfileFailure {
  final String message;
  
  const ProfileFailure(this.message);
}

/// Profile was not found for the given user ID
class ProfileNotFound extends ProfileFailure {
  const ProfileNotFound(String userId) 
      : super('Profile not found for user: $userId');
}

/// Failed to create a new profile
class ProfileCreationFailed extends ProfileFailure {
  const ProfileCreationFailed(String reason) 
      : super('Failed to create profile: $reason');
}

/// Failed to update profile data
class ProfileUpdateFailed extends ProfileFailure {
  const ProfileUpdateFailed(String reason) 
      : super('Failed to update profile: $reason');
}

/// Failed to calculate achievements
class AchievementCalculationFailed extends ProfileFailure {
  const AchievementCalculationFailed(String reason) 
      : super('Failed to calculate achievements: $reason');
}

/// Failed to calculate daily challenge stats
class DailyChallengeStatsFailed extends ProfileFailure {
  const DailyChallengeStatsFailed(String reason) 
      : super('Failed to calculate daily challenge stats: $reason');
}
