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
import 'features/recording/domain/audio_recorder_service.dart';
import 'features/rating/domain/rating_service.dart';
import 'features/analysis/data/real_rating_service.dart';
import 'features/analysis/data/comprehensive_audio_analyzer.dart';
import 'features/analysis/domain/frequency_analyzer.dart';
import 'features/leaderboard/data/leaderboard_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final sl = GetIt.instance;

Future<void> init() async {
  await sl.reset();
  
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  
  // Check if Firebase is actually initialized (has apps)
  bool isFirebaseEnabled = false;
  try {
    isFirebaseEnabled = Firebase.apps.isNotEmpty;
  } catch (_) {
    isFirebaseEnabled = false;
  }

  // Features - Auth
  debugPrint("DI Initializing: isFirebaseEnabled = $isFirebaseEnabled");

  if (isFirebaseEnabled) {
    sl.registerLazySingleton<AuthRepository>(() => FirebaseAuthRepository());
  } else {
    sl.registerLazySingleton<AuthRepository>(() => MockAuthRepository());
  }

  // Features - Recording
  sl.registerLazySingleton<AudioRecorderService>(() => RealAudioRecorderService());

  // Features - Profile
  sl.registerLazySingleton<ProfileDataSource>(() => LocalProfileDataSource(sharedPreferences: sl()));
  
  if (isFirebaseEnabled) {
    sl.registerLazySingleton<ProfileRepository>(() => FirestoreProfileRepository());
    sl.registerLazySingleton<LeaderboardService>(() => LeaderboardService(FirebaseFirestore.instance));
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
}
