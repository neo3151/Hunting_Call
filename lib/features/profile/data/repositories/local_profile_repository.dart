import 'package:hunting_calls_perfection/features/profile/domain/repositories/profile_repository.dart';
import 'package:hunting_calls_perfection/features/profile/domain/entities/user_profile.dart';
import 'package:hunting_calls_perfection/features/rating/domain/rating_model.dart';
import 'package:hunting_calls_perfection/features/profile/data/datasources/local_profile_data_source.dart';

class LocalProfileRepository implements ProfileRepository {
  final ProfileDataSource dataSource;

  LocalProfileRepository({required this.dataSource});
  @override
  Future<UserProfile> getProfile([String? userId]) async {
    // ... same
    final targetId = userId ?? 'guest';
    return dataSource.getProfile(targetId);
  }

  @override
  Future<List<UserProfile>> getAllProfiles() async {
    final ids = await dataSource.getProfileIds();
    final List<UserProfile> profiles = [];
    for (final id in ids) {
      profiles.add(await dataSource.getProfile(id));
    }
    // Ensure at least guest is there if empty
    if (profiles.isEmpty) {
      profiles.add(await dataSource.getProfile('guest'));
    }
    return profiles;
  }
  
  @override
  Future<List<UserProfile>> getProfilesByEmail(String email) async {
    final allProfiles = await getAllProfiles();
    return allProfiles.where((p) => p.email == email).toList();
  }

  @override
  Future<UserProfile> createProfile(String name, {String? id, DateTime? birthday, String? email}) async {
    final finalId = id ?? 'local_${DateTime.now().millisecondsSinceEpoch}';
    final newProfile = UserProfile(
      id: finalId,
      name: name,
      joinedDate: DateTime.now(),
      birthday: birthday,
      email: email,
    );
    await dataSource.saveProfile(newProfile);
    await dataSource.addProfileId(finalId);
    return newProfile;
  }

  @override
  Future<void> saveResultForUser(String userId, RatingResult result, String animalId) async {
    final newItem = HistoryItem(
      result: result,
      timestamp: DateTime.now(),
      animalId: animalId,
    );
    await dataSource.addHistoryItem(userId, newItem);
  }

  @override
  Future<void> saveAchievements(String userId, List<String> achievementIds) async {
    final profile = await dataSource.getProfile(userId);
    final updatedProfile = profile.copyWith(
      achievements: {...profile.achievements, ...achievementIds}.toList(),
    );
    await dataSource.saveProfile(updatedProfile);
  }

  @override
  Future<void> updateDailyChallengeStats(String userId) async {
    // Basic local implementation
    final profile = await dataSource.getProfile(userId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    bool shouldIncrement = false;
    if (profile.lastDailyChallengeDate == null) {
      shouldIncrement = true;
    } else {
      final lastDate = profile.lastDailyChallengeDate!;
      final lastDateDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      if (lastDateDay.isBefore(today)) {
        shouldIncrement = true;
      }
    }
    
    if (shouldIncrement) {
      final isConsecutive = profile.lastDailyChallengeDate != null && 
        now.difference(profile.lastDailyChallengeDate!).inHours < 48 && // Allow 48h to account for "yesterday"
        (today.difference(DateTime(profile.lastDailyChallengeDate!.year, profile.lastDailyChallengeDate!.month, profile.lastDailyChallengeDate!.day)).inDays == 1);
      
      int newStreak = isConsecutive ? profile.currentStreak + 1 : 1;
      final int newLongest = newStreak > profile.longestStreak ? newStreak : profile.longestStreak;

      // Handle first ever or if current streak was 0 for some reason
      if(profile.currentStreak == 0) newStreak = 1; 

      final updatedProfile = profile.copyWith(
        dailyChallengesCompleted: profile.dailyChallengesCompleted + 1,
        lastDailyChallengeDate: now,
        currentStreak: newStreak,
        longestStreak: newLongest
      );
      await dataSource.saveProfile(updatedProfile);
    }
  }

  @override
  Future<void> setPremiumStatus(String userId, bool isPremium) async {
    final profile = await dataSource.getProfile(userId);
    final updated = profile.copyWith(isPremium: isPremium);
    await dataSource.saveProfile(updated);
  }

  @override
  Future<List<UserProfile>> getTopGlobalUsers({int limit = 50}) async {
    final allProfiles = await getAllProfiles();
    // Filter profiles with at least 1 call to avoid showing empty users
    final validProfiles = allProfiles.where((p) => p.totalCalls > 0).toList();
    
    // Sort by average score descending
    validProfiles.sort((a, b) => b.averageScore.compareTo(a.averageScore));
    
    if (validProfiles.length > limit) {
      return validProfiles.sublist(0, limit);
    }
    return validProfiles;
  }
}
