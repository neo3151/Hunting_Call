import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:outcall/features/auth/domain/repositories/auth_repository.dart';
import 'package:outcall/features/auth/data/firebase_auth_repository.dart';
import 'package:outcall/features/auth/data/mock_auth_repository.dart';

import 'package:outcall/features/recording/domain/audio_recorder_service.dart';
import 'package:outcall/features/recording/data/repositories/real_audio_recorder_service.dart';
import 'package:outcall/features/recording/data/repositories/mock_audio_recorder_service.dart';


import 'package:outcall/features/profile/data/datasources/local_profile_data_source.dart';
import 'package:outcall/features/profile/data/datasources/secure_profile_data_source.dart';
import 'package:outcall/features/profile/data/datasources/migrating_profile_data_source.dart';
import 'package:outcall/features/profile/domain/repositories/profile_repository.dart';
import 'package:outcall/features/profile/data/repositories/local_profile_repository.dart'; // LocalProfileRepository
import 'package:outcall/features/profile/data/repositories/unified_profile_repository.dart';

import 'package:outcall/features/leaderboard/domain/repositories/leaderboard_service.dart';
import 'package:outcall/features/leaderboard/data/unified_leaderboard_service.dart';

import 'package:outcall/features/analysis/domain/frequency_analyzer.dart';
import 'package:outcall/features/analysis/data/comprehensive_audio_analyzer.dart';
import 'package:outcall/features/analysis/domain/providers.dart'; // Use case providers

import 'package:outcall/features/rating/domain/rating_service.dart';
import 'package:outcall/features/analysis/data/real_rating_service.dart';

import 'package:outcall/features/hunting_log/domain/repositories/hunting_log_repository.dart';
import 'package:outcall/features/hunting_log/data/local_hunting_log_repository.dart';

import 'package:outcall/features/daily_challenge/domain/providers.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firedart/firedart.dart' as fd;
import 'package:outcall/core/services/api_gateway.dart';
import 'package:outcall/core/services/simple_storage.dart';
import 'package:outcall/core/services/file_service.dart';
import 'package:outcall/core/services/version_check_service.dart';
import 'package:outcall/core/services/cloud_audio_service.dart';

// â”€â”€â”€ Platform Environment â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Must be overridden with a [PlatformEnvironment] at app startup.
final platformEnvironmentProvider = Provider<PlatformEnvironment>((ref) {
  throw UnimplementedError(
    'platformEnvironmentProvider must be overridden in ProviderScope',
  );
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  return ref.watch(platformEnvironmentProvider).sharedPreferences;
});

/// Provides [VersionCheckService].
final versionCheckServiceProvider = Provider<VersionCheckService>((ref) {
  return VersionCheckServiceImpl(
    apiGateway: ref.watch(apiGatewayProvider),
  );
});
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

// â”€â”€â”€ Core Providers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Provides the unified [ApiGateway].
final apiGatewayProvider = Provider<ApiGateway?>((ref) {
  final env = ref.watch(platformEnvironmentProvider);
  if (!env.isFirebaseEnabled) return null;
  if (env.isLinux) return FiredartApiGateway(fd.Firestore.instance);
  return FirebaseApiGateway(FirebaseFirestore.instance);
});

/// Provides unified [ISimpleStorage].
final simpleStorageProvider = Provider<ISimpleStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPrefsStorage(prefs);
});

/// Provides [FileService] implementation.
final fileServiceProvider = Provider<FileService>((ref) {
  return FileServiceImpl();
});

// â”€â”€â”€ Auth â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€â”€ Recording â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Provides Real or Mock [AudioRecorderService].
final audioRecorderServiceProvider = Provider<AudioRecorderService>((ref) {
  final env = ref.watch(platformEnvironmentProvider);
  if (env.useMocks) return MockAudioRecorderService();
  return RealAudioRecorderService(ref.watch(simpleStorageProvider));
});

// â”€â”€â”€ Daily Challenge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// NOTE: dailyChallengeRepositoryProvider lives in
// features/daily_challenge/domain/providers.dart

// â”€â”€â”€ Profile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Provides the local data source for profiles.
final profileDataSourceProvider = Provider<ProfileDataSource>((ref) {
  return MigratingProfileDataSource(
    localDataSource: LocalProfileDataSource(
      storage: ref.watch(simpleStorageProvider),
    ),
    secureDataSource: SecureProfileDataSource(),
  );
});

/// Provides the correct [ProfileRepository] based on platform + Firebase state.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final env = ref.watch(platformEnvironmentProvider);
  final apiGateway = ref.watch(apiGatewayProvider);
  
  if (env.isFirebaseEnabled && apiGateway != null) {
    return UnifiedProfileRepository(
      apiGateway,
      localDataSource: ref.watch(profileDataSourceProvider),
    );
  }
  return LocalProfileRepository(
    dataSource: ref.watch(profileDataSourceProvider),
  );
});

// â”€â”€â”€ Leaderboard â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Provides [LeaderboardService] if Firebase is available, null otherwise.
final leaderboardServiceProvider = Provider<LeaderboardService?>((ref) {
  final apiGateway = ref.watch(apiGatewayProvider);
  if (apiGateway == null) return null;
  return UnifiedLeaderboardService(apiGateway);
});

// â”€â”€â”€ Analysis & Rating â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Provides [FrequencyAnalyzer] implementation.
final frequencyAnalyzerProvider = Provider<FrequencyAnalyzer>((ref) {
  return ComprehensiveAudioAnalyzer();
});

/// Provides [RatingService] with all dependencies injected.
final ratingServiceProvider = Provider<RatingService>((ref) {
  return RealRatingService(
    analyzeUseCase: ref.watch(analyzeAudioUseCaseProvider),
    calculateUseCase: ref.watch(calculateScoreUseCaseProvider),
    getDailyChallengeUseCase: ref.watch(getDailyChallengeUseCaseProvider),
    analyzer: ref.watch(frequencyAnalyzerProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
    leaderboardService: ref.watch(leaderboardServiceProvider),
    cloudAudioService: ref.watch(cloudAudioServiceProvider),
  );
});

// â”€â”€â”€ Hunting Log â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Provides [HuntingLogRepository].
final huntingLogRepositoryProvider = Provider<HuntingLogRepository>((ref) {
  return LocalHuntingLogRepository();
});
