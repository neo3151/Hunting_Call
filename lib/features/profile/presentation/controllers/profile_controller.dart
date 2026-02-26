import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/features/profile/domain/repositories/profile_repository.dart';
import 'package:outcall/features/profile/domain/entities/user_profile.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';
import 'package:outcall/features/profile/domain/providers.dart';
import 'package:outcall/di_providers.dart';
import 'package:outcall/core/utils/app_logger.dart';

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
    // AppLogger.d("ProfileNotifier: Loading all profiles...");
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final profiles = await _repo.getAllProfiles();
      state = state.copyWith(allProfiles: profiles, isLoading: false);
    } catch (e) {
      final errorStr = e.toString();
      AppLogger.d('ProfileNotifier: getAllProfiles failed: $errorStr');
      state = state.copyWith(error: errorStr, isLoading: false);
    }
  }

  /// Load a specific user's profile
  Future<void> loadProfile(String userId) async {
    // AppLogger.d("ProfileNotifier: loadProfile called for $userId");
    state = state.copyWith(isProfileLoading: true, error: null);
    try {
      final profile = await _repo.getProfile(userId);
      // AppLogger.d("ProfileNotifier: loadProfile success for $userId");
      state = state.copyWith(profile: profile, isProfileLoading: false);
    } catch (e) {
      AppLogger.d('ProfileNotifier: loadProfile failed for $userId: $e');
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
        // Use domain use case for achievement calculation
        final achievementUseCase = ref.read(calculateNewAchievementsUseCaseProvider);
        final achievementsResult = achievementUseCase.execute(
          currentProfile,
          currentProfile.achievements,
        );
        
        achievementsResult.fold(
          (failure) {
            AppLogger.d('Achievement calculation failed: ${failure.message}');
          },
          (newAchievements) async {
            if (newAchievements.isNotEmpty) {
              await _repo.saveAchievements(userId, newAchievements);
              // Reload again to get badges
              await loadProfile(userId);
            }
          },
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update the profile's nickname and avatar
  Future<void> updateProfile({String? nickname, String? avatarUrl}) async {
    final currentProfile = state.profile;
    if (currentProfile == null) return;
    
    state = state.copyWith(error: null);
    try {
      await _repo.updateProfileDetails(currentProfile.id, nickname: nickname, avatarUrl: avatarUrl);
      
      // Update local state immediately for snappy UI
      final updatedProfile = currentProfile.copyWith(nickname: nickname, avatarUrl: avatarUrl);
      state = state.copyWith(profile: updatedProfile);
      
      // Also update in allProfiles if it exists
      final updatedAll = state.allProfiles.map((p) => p.id == updatedProfile.id ? updatedProfile : p).toList();
      state = state.copyWith(allProfiles: updatedAll);
      
      // Optionally reload from repo to ensure sync
      // await loadProfile(currentProfile.id);
    } catch (e) {
      AppLogger.d('ProfileNotifier: updateProfile failed: $e');
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
