import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/auth/data/mock_auth_repository.dart';

import 'features/recording/domain/audio_recorder_service.dart';
import 'features/recording/data/real_audio_recorder_service.dart';
import 'features/recording/data/mock_audio_recorder_service.dart';

import 'features/profile/data/local_profile_data_source.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'features/profile/data/profile_repository.dart'; // LocalProfileRepository
import 'features/profile/data/firestore_profile_repository.dart';
import 'features/profile/data/firedart_profile_repository.dart';

import 'features/leaderboard/domain/repositories/leaderboard_service.dart';
import 'features/leaderboard/data/leaderboard_service.dart'; // FirebaseLeaderboardService
import 'features/leaderboard/data/firedart_leaderboard_service.dart';

import 'features/analysis/domain/frequency_analyzer.dart';
import 'features/analysis/data/comprehensive_audio_analyzer.dart';
import 'features/analysis/domain/providers.dart'; // Use case providers

import 'features/rating/domain/rating_service.dart';
import 'features/analysis/data/real_rating_service.dart';

import 'features/hunting_log/domain/repositories/hunting_log_repository.dart';
import 'features/hunting_log/data/local_hunting_log_repository.dart';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firedart/firedart.dart' as fd;
import 'core/services/file_service.dart';

// ─── Platform Environment ───────────────────────────────────────────────────

/// Holds the platform and Firebase state determined at app startup.
/// Must be overridden in [ProviderScope] before the app runs.
class PlatformEnvironment {
  final bool isFirebaseEnabled;
  final bool isLinux;
  final bool useMocks;
  final SharedPreferences sharedPreferences;
  /// Pre-initialized auth repository (e.g. FiredartAuthRepository on Linux)
  final AuthRepository? preInitializedAuthRepo;

  const PlatformEnvironment({
    required this.isFirebaseEnabled,
    required this.isLinux,
    required this.useMocks,
    required this.sharedPreferences,
    this.preInitializedAuthRepo,
  });
}

/// Must be overridden with a [PlatformEnvironment] at app startup.
final platformEnvironmentProvider = Provider<PlatformEnvironment>((ref) {
  throw UnimplementedError(
    'platformEnvironmentProvider must be overridden in ProviderScope',
  );
});

// ─── Core Providers ─────────────────────────────────────────────────────────

/// SharedPreferences instance — sourced from the environment.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  return ref.watch(platformEnvironmentProvider).sharedPreferences;
});

/// Provides [FileService] implementation.
final fileServiceProvider = Provider<FileService>((ref) {
  return FileServiceImpl();
});

// ─── Auth ───────────────────────────────────────────────────────────────────

/// Provides the correct [AuthRepository] based on platform + Firebase state.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final env = ref.watch(platformEnvironmentProvider);
  // Use pre-initialized repo if available (e.g. FiredartAuthRepository on Linux)
  if (env.preInitializedAuthRepo != null) return env.preInitializedAuthRepo!;
  if (env.isFirebaseEnabled) {
    return FirebaseAuthRepository();
  }
  return MockAuthRepository();
});

// ─── Recording ──────────────────────────────────────────────────────────────

/// Provides Real or Mock [AudioRecorderService].
final audioRecorderServiceProvider = Provider<AudioRecorderService>((ref) {
  final env = ref.watch(platformEnvironmentProvider);
  if (env.useMocks) return MockAudioRecorderService();
  return RealAudioRecorderService();
});

// ─── Profile ────────────────────────────────────────────────────────────────

/// Provides the local data source for profiles.
final profileDataSourceProvider = Provider<ProfileDataSource>((ref) {
  return LocalProfileDataSource(
    sharedPreferences: ref.watch(sharedPreferencesProvider),
  );
});

/// Provides the correct [ProfileRepository] based on platform + Firebase state.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final env = ref.watch(platformEnvironmentProvider);
  if (env.isFirebaseEnabled) {
    if (env.isLinux) return FiredartProfileRepository();
    return FirestoreProfileRepository(
      localDataSource: ref.watch(profileDataSourceProvider),
    );
  }
  return LocalProfileRepository(
    dataSource: ref.watch(profileDataSourceProvider),
  );
});

// ─── Leaderboard ────────────────────────────────────────────────────────────

/// Provides [LeaderboardService] if Firebase is available, null otherwise.
final leaderboardServiceProvider = Provider<LeaderboardService?>((ref) {
  final env = ref.watch(platformEnvironmentProvider);
  if (!env.isFirebaseEnabled) return null;
  if (env.isLinux) {
    return FiredartLeaderboardService(fd.Firestore.instance);
  }
  return FirebaseLeaderboardService(FirebaseFirestore.instance);
});

// ─── Analysis & Rating ──────────────────────────────────────────────────────

/// Provides [FrequencyAnalyzer] implementation.
final frequencyAnalyzerProvider = Provider<FrequencyAnalyzer>((ref) {
  return ComprehensiveAudioAnalyzer();
});

/// Provides [RatingService] with all dependencies injected.
final ratingServiceProvider = Provider<RatingService>((ref) {
  return RealRatingService(
    analyzeUseCase: ref.watch(analyzeAudioUseCaseProvider),
    calculateUseCase: ref.watch(calculateScoreUseCaseProvider),
    analyzer: ref.watch(frequencyAnalyzerProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
    leaderboardService: ref.watch(leaderboardServiceProvider),
  );
});

// ─── Hunting Log ────────────────────────────────────────────────────────────

/// Provides [HuntingLogRepository].
final huntingLogRepositoryProvider = Provider<HuntingLogRepository>((ref) {
  return LocalHuntingLogRepository();
});
