import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/auth/data/firebase_auth_repository.dart';
import 'features/auth/data/mock_auth_repository.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/profile/data/local_profile_data_source.dart';
import 'features/profile/data/profile_repository.dart';
import 'features/profile/data/firestore_profile_repository.dart';
import 'features/recording/data/real_audio_recorder_service.dart';
import 'features/recording/data/mock_audio_recorder_service.dart';
import 'features/recording/domain/audio_recorder_service.dart';
import 'features/rating/domain/rating_service.dart';
import 'features/analysis/data/real_rating_service.dart';
import 'features/analysis/data/comprehensive_audio_analyzer.dart';
import 'features/analysis/domain/frequency_analyzer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firedart/firedart.dart' as fd;
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'core/auth/firedart_file_store.dart';
import 'firebase_options.dart';
import 'features/auth/data/firedart_auth_repository.dart';
import 'features/profile/data/firedart_profile_repository.dart';
import 'features/leaderboard/data/leaderboard_service.dart';
import 'features/leaderboard/data/firedart_leaderboard_service.dart';
import 'features/hunting_log/data/hunting_log_repository.dart';
import 'features/hunting_log/data/local_hunting_log_repository.dart';
import 'features/weather/data/weather_repository.dart';
import 'features/weather/data/open_meteo_weather_repository.dart';

final sl = GetIt.instance;
bool _isInitializing = false;

Future<void> init({bool useMocks = false}) async {
  if (_isInitializing) return;
  _isInitializing = true;
  await sl.reset();
  
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Check if Firebase is actually initialized (has apps)
  bool isFirebaseEnabled = false;
  
  if (Platform.isLinux) {
    try {
      final options = DefaultFirebaseOptions.windows; 
      final appDir = await getApplicationSupportDirectory();
      if (!appDir.existsSync()) {
        await appDir.create(recursive: true);
      }
      final tokenFile = File(p.join(appDir.path, 'auth_token.json'));
      print("Firebase: Using token file at ${tokenFile.path}");
      
      fd.FirebaseAuth.initialize(options.apiKey, FiredartFileStore(tokenFile.path));
      fd.Firestore.initialize(options.projectId);
      
      // Auto-sign in anonymously on Linux if not already signed in 
      final auth = fd.FirebaseAuth.instance;
      if (!auth.isSignedIn) {
        print("Firebase: Performing initial anonymous sign-in on Linux...");
        await auth.signInAnonymously();
      }
      
      // Wait a bit to ensure Firestore/Auth state is synchronized
      int authRetries = 10;
      while (!auth.isSignedIn && authRetries > 0) {
        print("Firebase: Waiting for auth synchronization... ($authRetries left)");
        await Future.delayed(const Duration(milliseconds: 100));
        authRetries--;
      }
      
      print("Firebase: Final startup sign-in check - isSignedIn: ${auth.isSignedIn}, userId: ${auth.userId}");
      
      isFirebaseEnabled = auth.isSignedIn;
      print("Firebase: Firedart initialized with FileStore for Linux. isEnabled: $isFirebaseEnabled");
    } catch (e) {
      print("Firebase: Firedart initialization failed: $e");
      isFirebaseEnabled = false;
    }
  } else {
    try {
      isFirebaseEnabled = Firebase.apps.isNotEmpty;
    } catch (_) {
      isFirebaseEnabled = false;
    }
  }

  // Features - Auth
  debugPrint("DI Initializing: isFirebaseEnabled = $isFirebaseEnabled");

  if (isFirebaseEnabled) {
    if (Platform.isLinux) {
      sl.registerLazySingleton<AuthRepository>(() => FiredartAuthRepository());
    } else {
      sl.registerLazySingleton<AuthRepository>(() => FirebaseAuthRepository());
    }
  } else {
    sl.registerLazySingleton<AuthRepository>(() => MockAuthRepository());
  }

  // Features - Recording
  if (useMocks) {
    sl.registerLazySingleton<AudioRecorderService>(() => MockAudioRecorderService());
  } else {
    sl.registerLazySingleton<AudioRecorderService>(() => RealAudioRecorderService());
  }

  // Features - Profile
  sl.registerLazySingleton<ProfileDataSource>(() => LocalProfileDataSource(sharedPreferences: sl()));
  
  if (isFirebaseEnabled) {
    if (Platform.isLinux) {
      sl.registerLazySingleton<ProfileRepository>(() => FiredartProfileRepository());
      sl.registerLazySingleton<LeaderboardService>(() => FiredartLeaderboardService(fd.Firestore.instance));
    } else {
      sl.registerLazySingleton<ProfileRepository>(() => FirestoreProfileRepository());
      sl.registerLazySingleton<LeaderboardService>(() => FirebaseLeaderboardService(FirebaseFirestore.instance));
    }
  } else {
    sl.registerLazySingleton<ProfileRepository>(() => LocalProfileRepository(dataSource: sl()));
  }

  // Features - Rating
  sl.registerLazySingleton<FrequencyAnalyzer>(() => ComprehensiveAudioAnalyzer());
  sl.registerLazySingleton<RatingService>(() => RealRatingService(
    analyzer: sl<FrequencyAnalyzer>(), 
    profileRepository: sl<ProfileRepository>(),
    leaderboardService: isFirebaseEnabled ? sl<LeaderboardService>() : null,
  ));

  // Core
  // ... add core services here later (e.g. NavigationService)
  // Features - Hunting Log
  sl.registerLazySingleton<HuntingLogRepository>(() => LocalHuntingLogRepository());
  // Initialize the repository immediately to create tables
  sl<HuntingLogRepository>().initialize();

  // Features - Weather
  sl.registerLazySingleton<WeatherRepository>(() => OpenMeteoWeatherRepository());

  _isInitializing = false;
}
