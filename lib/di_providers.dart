import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:outcall/firebase_options.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/core/services/api_gateway.dart';
import 'package:outcall/core/services/cloud_audio_service.dart';
import 'package:outcall/core/services/file_service.dart';
import 'package:outcall/core/services/simple_storage.dart';
import 'package:outcall/core/services/version_check_service.dart';
import 'package:outcall/core/services/remote_config/remote_config_service.dart';
import 'package:outcall/features/analysis/data/comprehensive_audio_analyzer.dart';
import 'package:outcall/features/analysis/data/real_rating_service.dart';
import 'package:outcall/features/analysis/domain/frequency_analyzer.dart';
import 'package:outcall/features/analysis/domain/providers.dart'; // Use case providers
import 'package:outcall/features/auth/data/firebase_auth_repository.dart';
import 'package:outcall/features/auth/data/mock_auth_repository.dart';
import 'package:outcall/features/auth/domain/repositories/auth_repository.dart';
import 'package:outcall/features/daily_challenge/domain/providers.dart';
import 'package:outcall/features/hunting_log/data/local_hunting_log_repository.dart';
import 'package:outcall/features/hunting_log/domain/repositories/hunting_log_repository.dart';
import 'package:outcall/features/leaderboard/data/cloud_function_leaderboard_service.dart';
import 'package:outcall/features/leaderboard/data/unified_leaderboard_service.dart';
import 'package:outcall/features/leaderboard/domain/repositories/leaderboard_service.dart';
import 'package:outcall/features/profile/data/datasources/local_profile_data_source.dart';
import 'package:outcall/features/profile/data/datasources/migrating_profile_data_source.dart';
import 'package:outcall/features/profile/data/datasources/secure_profile_data_source.dart';
import 'package:outcall/features/profile/data/repositories/local_profile_repository.dart'; // LocalProfileRepository
import 'package:outcall/features/profile/data/repositories/unified_profile_repository.dart';
import 'package:outcall/features/profile/domain/repositories/profile_repository.dart';
import 'package:outcall/features/rating/domain/rating_service.dart';
import 'package:outcall/features/recording/data/repositories/mock_audio_recorder_service.dart';
import 'package:outcall/features/recording/data/repositories/real_audio_recorder_service.dart';
import 'package:outcall/features/recording/domain/audio_recorder_service.dart';
import 'package:outcall/core/services/notification_service.dart';

import 'package:outcall/core/services/app_rating_service.dart';
import 'package:outcall/features/progress_map/data/progress_map_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// â”€â”€â”€ Platform Environment â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Asynchronously initializes Platform info, Firebase, and SharedPreferences.
/// Other entry points or isolates can simply `await ref.read(asyncPlatformEnvironmentProvider.future)`
final asyncPlatformEnvironmentProvider = FutureProvider<PlatformEnvironment>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final isDesktop = Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  
  bool firebaseReady = false;
  try {
    if (Platform.isAndroid) {
      await Firebase.initializeApp();
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    // Skip App Check in debug mode or on desktop
    if (!kDebugMode && !Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: const AndroidPlayIntegrityProvider(),
      );
    }
    firebaseReady = true;
  } catch (e, st) {
    _logWarning(e, st);
  }

  return PlatformEnvironment(
    isFirebaseEnabled: firebaseReady,
    isDesktop: isDesktop,
    useMocks: false,
    sharedPreferences: prefs,
  );
});

void _logWarning(dynamic e, StackTrace st) {
    try { AppLogger.e('Firebase init failed', e, st); } catch (_) {}
}

/// Provides the synchronous [PlatformEnvironment].
/// Safely unpacks the async provider. An entrypoint running without
/// `overrideWithValue` MUST await `asyncPlatformEnvironmentProvider.future` first.
final platformEnvironmentProvider = Provider<PlatformEnvironment>((ref) {
  return ref.watch(asyncPlatformEnvironmentProvider).requireValue;
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
  final bool isDesktop;
  final bool useMocks;
  final SharedPreferences sharedPreferences;

  /// Pre-initialized auth repository (e.g. FiredartAuthRepository on Linux)
  final AuthRepository? preInitializedAuthRepo;

  const PlatformEnvironment({
    required this.isFirebaseEnabled,
    required this.isDesktop,
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
  if (env.isDesktop) return RestFirestoreApiGateway(FirebaseFirestore.instance); // Note: we'll implement this to use official auth to connect to REST
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
/// On mobile, uses the Cloud Function for writes (server-side transactions).
/// On desktop (Firedart), falls back to direct Firestore writes.
final leaderboardServiceProvider = Provider<LeaderboardService?>((ref) {
  final env = ref.watch(platformEnvironmentProvider);
  final apiGateway = ref.watch(apiGatewayProvider);
  if (apiGateway == null) return null;

  // Mobile (Firebase SDK) → route writes through the Cloud Function
  if (env.isFirebaseEnabled && !env.isDesktop) {
    return CloudFunctionLeaderboardService(apiGateway);
  }

  // Desktop (Firedart) → direct Firestore writes
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
    backendBaseUrl: ref.watch(remoteConfigServiceProvider).aiCoachUrl,
  );
});

// â”€â”€â”€ Hunting Log â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Provides [HuntingLogRepository].
final huntingLogRepositoryProvider = Provider<HuntingLogRepository>((ref) {
  return LocalHuntingLogRepository();
});

// ─── New Audit Services ─────────────────────────────────────────────────────

/// Provides [NotificationService].
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(simpleStorageProvider));
});



/// Provides [AppRatingService].
final appRatingServiceProvider = Provider<AppRatingService>((ref) {
  return AppRatingService(ref.watch(simpleStorageProvider));
});

/// Provides [ProgressMapRepository].
final progressMapRepositoryProvider = Provider<ProgressMapRepository>((ref) {
  return ProgressMapRepository(ref.watch(simpleStorageProvider));
});
