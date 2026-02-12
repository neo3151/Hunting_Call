
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hunting_calls_perfection/features/weather/domain/weather_entities.dart';
import 'package:hunting_calls_perfection/features/weather/domain/usecases/get_local_weather.dart';
import 'package:hunting_calls_perfection/features/weather/domain/usecases/get_solunar_info.dart';
import 'package:hunting_calls_perfection/features/weather/data/repositories/weather_repository_impl.dart';
import 'package:hunting_calls_perfection/features/weather/data/datasources/weather_remote_data_source.dart';
import 'package:hunting_calls_perfection/features/weather/domain/weather_repository.dart';
import 'package:hunting_calls_perfection/features/weather/data/location_service.dart';

// --- Dependency Injection ---

final weatherRemoteDataSourceProvider = Provider<WeatherRemoteDataSource>((ref) {
  return OpenMeteoWeatherDataSource();
});

final weatherRepositoryImplProvider = Provider<WeatherRepository>((ref) {
  final dataSource = ref.watch(weatherRemoteDataSourceProvider);
  return WeatherRepositoryImpl(remoteDataSource: dataSource);
});

final getLocalWeatherUseCaseProvider = Provider<GetLocalWeather>((ref) {
  final repository = ref.watch(weatherRepositoryImplProvider);
  return GetLocalWeather(repository);
});

final getSolunarInfoUseCaseProvider = Provider<GetSolunarInfo>((ref) {
  final repository = ref.watch(weatherRepositoryImplProvider);
  return GetSolunarInfo(repository);
});

// --- Controllers ---

class WeatherState {
  final AsyncValue<WeatherData> weather;
  final AsyncValue<SolunarData> solunar;

  WeatherState({required this.weather, required this.solunar});
  
  WeatherState copyWith({
    AsyncValue<WeatherData>? weather,
    AsyncValue<SolunarData>? solunar,
  }) {
    return WeatherState(
      weather: weather ?? this.weather,
      solunar: solunar ?? this.solunar,
    );
  }
}

final weatherControllerProvider = StateNotifierProvider<WeatherController, WeatherState>((ref) {
  return WeatherController(ref);
});

class WeatherController extends StateNotifier<WeatherState> {
  final Ref ref;
  
  WeatherController(this.ref) : super(WeatherState(
    weather: const AsyncValue.loading(),
    solunar: const AsyncValue.loading(),
  )) {
    loadData();
  }

  Future<void> loadData() async {
    try {
      final location = await ref.read(locationProvider.future);
      fetchWeather(location);
      fetchSolunar(location);
    } catch (e, st) {
      state = state.copyWith(
        weather: AsyncValue.error(e, st),
        solunar: AsyncValue.error(e, st),
      );
    }
  }

  Future<void> fetchWeather(Position location) async {
    state = state.copyWith(weather: const AsyncValue.loading());
    try {
      final useCase = ref.read(getLocalWeatherUseCaseProvider);
      final result = await useCase(location.latitude, location.longitude);
      state = state.copyWith(weather: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(weather: AsyncValue.error(e, st));
    }
  }

  Future<void> fetchSolunar(Position location) async {
    state = state.copyWith(solunar: const AsyncValue.loading());
    try {
      final useCase = ref.read(getSolunarInfoUseCaseProvider);
      final result = await useCase(location.latitude, location.longitude, DateTime.now());
      state = state.copyWith(solunar: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(solunar: AsyncValue.error(e, st));
    }
  }
  
  Future<void> refresh() async {
    await loadData();
  }
}
