import 'package:outcall/features/profile/domain/entities/user_profile.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';

abstract class ProfileRepository {
  Future<UserProfile> getProfile([String? userId]);
  Future<List<UserProfile>> getAllProfiles();
  Future<List<UserProfile>> getProfilesByEmail(String email);
  Future<UserProfile> createProfile(String name, {String? id, DateTime? birthday, String? email});
  Future<void> saveResultForUser(String userId, RatingResult result, String animalId);
  Future<void> saveAchievements(String userId, List<String> achievementIds);
  Future<void> updateDailyChallengeStats(String userId);
  Future<void> setPremiumStatus(String userId, bool isPremium);
  Future<List<UserProfile>> getTopGlobalUsers({int limit = 50});
  Future<void> updateProfileDetails(String userId, {String? nickname, String? avatarUrl});
  Future<void> toggleFavoriteCall(String userId, String callId, bool isFavorite);

  /// Logs a profanity violation attempt for admin review.
  Future<void> logProfanityViolation({
    required String userId,
    required String attemptedName,
    required String matchedTerm,
  });

  /// Returns the total number of profanity violations for a user.
  Future<int> getViolationCount(String userId);

  /// Permanently restricts a user's ability to change their name.
  Future<void> restrictUserName(String userId);
}
