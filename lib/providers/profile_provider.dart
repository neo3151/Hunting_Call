import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/data/local_profile_data_source.dart';
import '../features/profile/domain/profile_model.dart';
import '../features/rating/domain/rating_model.dart';

/// Provides the ProfileDataSource instance
final profileDataSourceProvider = Provider<LocalProfileDataSource>((ref) {
  return LocalProfileDataSource();
});

/// Provides the ProfileRepository instance
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dataSource = ref.watch(profileDataSourceProvider);
  return LocalProfileRepository(dataSource: dataSource);
});

/// State for user profile operations
class ProfileState {
  final UserProfile? profile;
  final List<UserProfile> allProfiles;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.profile,
    this.allProfiles = const [],
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    UserProfile? profile,
    List<UserProfile>? allProfiles,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      allProfiles: allProfiles ?? this.allProfiles,
      isLoading: isLoading ?? this.isLoading,
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

  /// Load all profiles for login screen
  Future<void> loadAllProfiles() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profiles = await _repo.getAllProfiles();
      state = state.copyWith(allProfiles: profiles, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Load a specific user's profile
  Future<void> loadProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _repo.getProfile(userId);
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Create a new profile
  Future<UserProfile> createProfile(String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _repo.createProfile(name);
      final updatedProfiles = [...state.allProfiles, profile];
      state = state.copyWith(
        profile: profile,
        allProfiles: updatedProfiles,
        isLoading: false,
      );
      return profile;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  /// Save a rating result to the user's history
  Future<void> saveResult(String userId, RatingResult result, String animalId) async {
    try {
      await _repo.saveResultForUser(userId, result, animalId);
      // Reload profile to get updated history
      await loadProfile(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final profileNotifierProvider = NotifierProvider<ProfileNotifier, ProfileState>(() {
  return ProfileNotifier();
});
