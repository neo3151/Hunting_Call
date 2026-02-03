import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/profile/data/local_profile_data_source.dart';
import 'features/auth/data/mock_auth_repository.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/recording/data/real_audio_recorder_service.dart';
import 'features/recording/domain/audio_recorder_service.dart';
import 'features/rating/domain/rating_service.dart';
import 'features/analysis/data/real_rating_service.dart';
import 'features/analysis/data/fftea_frequency_analyzer.dart';
import 'features/analysis/domain/frequency_analyzer.dart';

import 'features/profile/data/profile_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Features - Auth
  sl.registerLazySingleton<AuthRepository>(() => MockAuthRepository());

  // Features - Recording
  sl.registerLazySingleton<AudioRecorderService>(() => RealAudioRecorderService());

  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Features - Profile
  sl.registerLazySingleton<ProfileDataSource>(() => LocalProfileDataSource(sharedPreferences: sl()));
  sl.registerLazySingleton<ProfileRepository>(() => LocalProfileRepository(dataSource: sl()));

  // Features - Rating
  sl.registerLazySingleton<FrequencyAnalyzer>(() => FFTEAFrequencyAnalyzer());
  sl.registerLazySingleton<RatingService>(() => RealRatingService(
    analyzer: sl<FrequencyAnalyzer>(), 
    profileRepository: sl<ProfileRepository>()
  ));

  // Core
  // ... add core services here later (e.g. NavigationService)
}
