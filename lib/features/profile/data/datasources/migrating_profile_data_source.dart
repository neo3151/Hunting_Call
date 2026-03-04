import 'package:outcall/features/profile/data/datasources/local_profile_data_source.dart';
import 'package:outcall/features/profile/data/datasources/secure_profile_data_source.dart';
import 'package:outcall/features/profile/domain/entities/user_profile.dart';
import 'package:outcall/core/utils/app_logger.dart';

/// A [ProfileDataSource] that migrates data from [LocalProfileDataSource]
/// (SharedPreferences) to [SecureProfileDataSource] (Keystore/Keychain)
/// if it doesn't already exist in secure storage.
class MigratingProfileDataSource implements ProfileDataSource {
  final LocalProfileDataSource localDataSource;
  final SecureProfileDataSource secureDataSource;

  MigratingProfileDataSource({
    required this.localDataSource,
    required this.secureDataSource,
  });

  @override
  Future<UserProfile> getProfile(String userId) async {
    // 1. Try secure storage first
    try {
      final secureProfile = await secureDataSource.getProfile(userId);
      // SecureProfileDataSource returns a 'New Hunter' profile if not found, 
      // but its 'joinedDate' will be 'now'. We can check if it has real data.
      // However, a better check is if the key actually exists in secure storage.
      // Looking at SecureProfileDataSource.getProfile, it doesn't expose exists().
      // Let's check for guest or real ID.
      
      if (secureProfile.id != 'guest') {
         // Check if this profile has any history.
         // If it's the default 'New Hunter' (no history),
         // we should check if local storage has something better.
         // NOTE: isPremium is NOT checked here — Firestore is the 
         // source of truth for premium status, not local storage.
         if (secureProfile.history.isEmpty) {
            final localProfile = await localDataSource.getProfile(userId);
            if (localProfile.history.isNotEmpty) {
              AppLogger.d('📦 MigratingProfileDataSource: Migrating profile $userId from local to secure storage.');
              // Migrate history but DON'T migrate isPremium (cloud is source of truth)
              final migratedProfile = localProfile.copyWith(isPremium: false);
              await secureDataSource.saveProfile(migratedProfile);
              return migratedProfile;
            }
         }
      }
      return secureProfile;
    } catch (e) {
      AppLogger.d('📦 MigratingProfileDataSource: Error reading from secure storage: $e');
      return localDataSource.getProfile(userId);
    }
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    // Always save to secure storage from now on.
    await secureDataSource.saveProfile(profile);
    
    // Optional: Could clear from local storage here, but safer to keep 
    // it until we are 100% sure migration is stable.
  }

  @override
  Future<List<String>> getProfileIds() async {
    // Return combined unique IDs
    final secureIds = await secureDataSource.getProfileIds();
    final localIds = await localDataSource.getProfileIds();
    return {...secureIds, ...localIds}.toList();
  }

  @override
  Future<void> addProfileId(String id) async {
    await secureDataSource.addProfileId(id);
    // Also add to local if we want to maintain parity, but secure is priority.
  }

  @override
  Future<void> addHistoryItem(String userId, HistoryItem item) async {
    final profile = await getProfile(userId);
    final updatedHistory = List<HistoryItem>.from(profile.history)..insert(0, item);
    
    // Recalculate stats
    double totalScore = 0;
    for (var h in updatedHistory) {
      totalScore += h.result.score;
    }
    final double newAvg = updatedHistory.isEmpty ? 0 : totalScore / updatedHistory.length;
    
    final updatedProfile = profile.copyWith(
      history: updatedHistory,
      totalCalls: updatedHistory.length,
      averageScore: newAvg,
    );
    
    await saveProfile(updatedProfile);
  }
}
