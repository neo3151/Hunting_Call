import '../domain/profile_model.dart';
import '../data/local_profile_data_source.dart'; // import the interface definition if simpler
import '../../rating/domain/rating_model.dart';


abstract class ProfileRepository {
  Future<UserProfile> getProfile([String? userId]);
  Future<List<UserProfile>> getAllProfiles();
  Future<UserProfile> createProfile(String name);
  Future<void> saveResultForUser(String userId, RatingResult result, String animalId);
  Future<void> saveAchievements(String userId, List<String> achievementIds);
  Future<void> updateDailyChallengeStats(String userId);
}

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
  Future<UserProfile> createProfile(String name) async {
    final id = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final newProfile = UserProfile(
      id: id,
      name: name,
      joinedDate: DateTime.now(),
    );
    await dataSource.saveProfile(newProfile);
    await dataSource.addProfileId(id);
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
      int newLongest = newStreak > profile.longestStreak ? newStreak : profile.longestStreak;

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
}
