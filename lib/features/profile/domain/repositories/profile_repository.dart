import 'package:hunting_calls_perfection/features/profile/domain/entities/user_profile.dart';
import 'package:hunting_calls_perfection/features/rating/domain/rating_model.dart';

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
}
