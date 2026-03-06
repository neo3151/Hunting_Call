import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/features/profile/domain/repositories/profile_repository.dart';
import 'package:outcall/features/profile/domain/entities/user_profile.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';
import 'package:outcall/features/profile/domain/providers.dart';
import 'package:outcall/di_providers.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/core/utils/input_sanitizer.dart';
import 'package:outcall/core/utils/profanity_filter.dart';

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
    // Sanitize and filter the name
    final cleanName = InputSanitizer.sanitizeName(name);

    state = state.copyWith(isProfileLoading: true, error: null);
    try {
      final profile = await _repo.createProfile(cleanName, id: id, birthday: birthday);
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

  /// Update the profile's nickname and avatar.
  ///
  /// Returns `true` if the update succeeded, `false` if blocked
  /// (e.g. inappropriate content or account restricted).
  Future<bool> updateProfile({String? nickname, String? avatarUrl}) async {
    final currentProfile = state.profile;
    if (currentProfile == null) return false;

    // Check if user is name-restricted due to past violations
    if (nickname != null && currentProfile.nameRestricted) {
      state = state.copyWith(
        error: 'Your name has been permanently locked due to repeated violations.',
      );
      return false;
    }

    // Block inappropriate nicknames — local profanity filter
    if (nickname != null &&
        InputSanitizer.containsInappropriateContent(nickname)) {
      AppLogger.d('⚠️ ProfileNotifier: blocked inappropriate nickname "$nickname"');

      // Log the violation and apply strike system
      final strikeCount = await _logAndApplyStrikes(currentProfile.id, nickname);

      final errorMsg = strikeCount >= 3
          ? 'Your name has been permanently locked due to repeated violations.'
          : 'That name contains inappropriate content. Please choose another. '
            '(Strike $strikeCount/3)';

      state = state.copyWith(error: errorMsg);
      return false;
    }

    // Sanitize the nickname (XSS, length, etc.)
    final cleanNickname = nickname != null ? InputSanitizer.sanitizeName(nickname) : null;

    state = state.copyWith(error: null);
    try {
      await _repo.updateProfileDetails(currentProfile.id, nickname: cleanNickname, avatarUrl: avatarUrl);
      
      // Update local state immediately for snappy UI
      final updatedProfile = currentProfile.copyWith(nickname: nickname, avatarUrl: avatarUrl);
      state = state.copyWith(profile: updatedProfile);
      
      // Also update in allProfiles if it exists
      final updatedAll = state.allProfiles.map((p) => p.id == updatedProfile.id ? updatedProfile : p).toList();
      state = state.copyWith(allProfiles: updatedAll);
      
      return true;
    } catch (e) {
      AppLogger.d('ProfileNotifier: updateProfile failed: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Logs the violation, increments strikes, and applies restriction if needed.
  /// Returns the new total strike count.
  Future<int> _logAndApplyStrikes(String userId, String attemptedName) async {
    try {
      final match = ProfanityFilter.getFirstMatch(attemptedName);

      // Log the individual violation
      await _repo.logProfanityViolation(
        userId: userId,
        attemptedName: attemptedName,
        matchedTerm: match ?? 'unknown',
      );

      // Get total violation count for this user
      final violationCount = await _repo.getViolationCount(userId);
      AppLogger.d('📝 Profanity violation #$violationCount: user=$userId name="$attemptedName" match="$match"');

      // Strike limit: 3 violations → permanent name restriction
      if (violationCount >= 3) {
        await _repo.restrictUserName(userId);
        // Force local state update
        final profile = state.profile;
        if (profile != null && profile.id == userId) {
          state = state.copyWith(
            profile: profile.copyWith(nameRestricted: true, nickname: null),
          );
        }
        AppLogger.d('🚫 User $userId permanently name-restricted after $violationCount violations');
      }

      return violationCount;
    } catch (e) {
      AppLogger.d('⚠️ Failed to process profanity strike: $e');
      return 0;
    }
  }

  /// Toggles the favorite status of a call
  Future<void> toggleFavorite(String callId) async {
    final currentProfile = state.profile;
    if (currentProfile == null) return;

    final currentFavorites = List<String>.from(currentProfile.favoriteCallIds);
    final isFavorite = currentFavorites.contains(callId);
    
    // Toggle locally for instant UI update
    if (isFavorite) {
      currentFavorites.remove(callId);
    } else {
      currentFavorites.add(callId);
    }
    
    final updatedProfile = currentProfile.copyWith(favoriteCallIds: currentFavorites);
    state = state.copyWith(profile: updatedProfile);
    
    // Update allProfiles list
    final updatedAll = state.allProfiles.map((p) => p.id == updatedProfile.id ? updatedProfile : p).toList();
    state = state.copyWith(allProfiles: updatedAll);

    // Persist
    try {
      await _repo.toggleFavoriteCall(currentProfile.id, callId, !isFavorite);
    } catch (e) {
      AppLogger.d('ProfileNotifier: toggleFavorite failed: $e');
      state = state.copyWith(error: e.toString());
      // Optionally rollback here if needed
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
