import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../profile/domain/profile_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'package:hunting_calls_perfection/core/utils/app_logger.dart';

// ─── State ──────────────────────────────────────────────────────────────────

/// Represents the home screen's derived state.
class HomeState {
  final String userName;
  final String activeUserId;
  final UserProfile? profile;
  final bool isLoading;
  final String? error;
  final bool isCloudMode;

  const HomeState({
    this.userName = 'Hunter',
    this.activeUserId = '',
    this.profile,
    this.isLoading = true,
    this.error,
    this.isCloudMode = false,
  });

  HistoryItem? get mostRecentActivity {
    if (profile != null && profile!.history.isNotEmpty) {
      return profile!.history.first;
    }
    return null;
  }

  HomeState copyWith({
    String? userName,
    String? activeUserId,
    UserProfile? profile,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isCloudMode,
  }) {
    return HomeState(
      userName: userName ?? this.userName,
      activeUserId: activeUserId ?? this.activeUserId,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isCloudMode: isCloudMode ?? this.isCloudMode,
    );
  }
}

// ─── Controller ─────────────────────────────────────────────────────────────

/// Thin controller that derives [HomeState] from profile and auth providers.
class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() {
    // React to profile changes
    final profileState = ref.watch(profileNotifierProvider);
    final isCloud = ref.watch(firebaseEnabledProvider);

    final profile = profileState.profile;

    return HomeState(
      userName: profile?.name ?? 'Hunter',
      activeUserId: profile?.id ?? '',
      profile: profile,
      isLoading: profileState.isProfileLoading,
      error: profileState.error,
      isCloudMode: isCloud,
    );
  }

  /// Trigger initial profile load or refresh.
  void loadProfile(String userId) {
    final currentProfile = ref.read(profileNotifierProvider).profile;
    final profileId = (currentProfile != null && currentProfile.id != 'guest')
        ? currentProfile.id
        : userId;
    AppLogger.d('HomeController: Loading profile for $profileId');
    ref.read(profileNotifierProvider.notifier).loadProfile(profileId);
  }

  /// Sign out — delegates to auth controller.
  Future<void> signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
  }
}

final homeNotifierProvider = NotifierProvider<HomeNotifier, HomeState>(() {
  return HomeNotifier();
});
