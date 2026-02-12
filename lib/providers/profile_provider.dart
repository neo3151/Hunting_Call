import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/profile/data/local_profile_data_source.dart';
import '../features/profile/domain/profile_model.dart';
import '../features/rating/domain/rating_model.dart';
import '../features/profile/domain/achievement_service.dart';

/// Provides the ProfileDataSource instance
final profileDataSourceProvider = Provider<LocalProfileDataSource>((ref) {
  return LocalProfileDataSource(sharedPreferences: GetIt.I<SharedPreferences>());
});

/// Provides the ProfileRepository instance
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return GetIt.I<ProfileRepository>();
});

/// State for user profile operations
class ProfileState {
  final UserProfile? profile;
  final List<UserProfile> allProfiles;
  final bool isLoading; // For loading list of profiles
  final bool isProfileLoading; // For loading specific profile
  final String? error;

  const ProfileState({
    this.profile,
    this.allProfiles = const [],
    this.isLoading = false,
    this.isProfileLoading = false,
    this.error,
  });

  ProfileState copyWith({
    UserProfile? profile,
    List<UserProfile>? allProfiles,
    bool? isLoading,
    bool? isProfileLoading,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      allProfiles: allProfiles ?? this.allProfiles,
      isLoading: isLoading ?? this.isLoading,
      isProfileLoading: isProfileLoading ?? this.isProfileLoading,
      error: error,
    );
  }
}

/// Notifier for profile operations
class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    return const ProfileState();
  }

  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  Future<UserProfile> fetchProfile(String userId) => _repo.getProfile(userId);

  /// Load all profiles for login screen
  Future<void> loadAllProfiles() async {
    debugPrint("ProfileNotifier: Loading all profiles...");
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final profiles = await _repo.getAllProfiles();
      state = state.copyWith(allProfiles: profiles, isLoading: false);
    } catch (e) {
      final errorStr = e.toString();
      debugPrint("ProfileNotifier: getAllProfiles failed: $errorStr");
      state = state.copyWith(error: errorStr, isLoading: false);
    }
  }

  /// Load a specific user's profile
  Future<void> loadProfile(String userId) async {
    debugPrint("ProfileNotifier: loadProfile called for $userId");
    state = state.copyWith(isProfileLoading: true, error: null);
    try {
      final profile = await _repo.getProfile(userId);
      debugPrint("ProfileNotifier: loadProfile success for $userId");
      state = state.copyWith(profile: profile, isProfileLoading: false);
    } catch (e) {
      debugPrint("ProfileNotifier: loadProfile failed for $userId: $e");
      state = state.copyWith(error: e.toString(), isProfileLoading: false);
    }
  }

  /// Create a new profile
  Future<UserProfile> createProfile(String name, {String? id, DateTime? birthday}) async {
    state = state.copyWith(isProfileLoading: true, error: null);
    try {
      final profile = await _repo.createProfile(name, id: id, birthday: birthday);
      final updatedProfiles = [...state.allProfiles, profile];
      state = state.copyWith(
        profile: profile,
        allProfiles: updatedProfiles,
        isProfileLoading: false,
      );
      return profile;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isProfileLoading: false);
      rethrow;
    }
  }


  /// Save a rating result to the user's history
  Future<void> saveResult(String userId, RatingResult result, String animalId) async {
    try {
      await _repo.saveResultForUser(userId, result, animalId);
      // Reload profile to get updated history
      await loadProfile(userId);
      
      final currentProfile = state.profile;
      if (currentProfile != null && userId != 'guest') {
        final newAchievements = AchievementService.getNewAchievementIds(
          currentProfile, 
          currentProfile.achievements
        );
        
        if (newAchievements.isNotEmpty) {
          await _repo.saveAchievements(userId, newAchievements);
          // Reload again to get badges
          await loadProfile(userId);
        }
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Resets the profile state to its initial, unauthenticated state.
  void reset() {
    state = const ProfileState();
  }
}

final profileNotifierProvider = NotifierProvider<ProfileNotifier, ProfileState>(() {
  return ProfileNotifier();
});
