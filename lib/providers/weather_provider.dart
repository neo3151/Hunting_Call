import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:geolocator/geolocator.dart';
import '../features/weather/domain/weather_models.dart';
import '../features/weather/data/weather_repository.dart';

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return GetIt.I<WeatherRepository>();
});

final locationProvider = FutureProvider<Position>((ref) async {
  // Linux fallback since geolocator doesn't support it well/at all in some environments
  if (Platform.isLinux) {
    return Position(
      longitude: -96.7970, // Dallas, TX
      latitude: 32.7767,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw 'Location services are disabled.';
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw 'Location permissions are denied';
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw 'Location permissions are permanently denied.';
  }

  return await Geolocator.getCurrentPosition();
});

final currentWeatherProvider = FutureProvider<WeatherData>((ref) async {
  final location = await ref.watch(locationProvider.future);
  final repository = ref.watch(weatherRepositoryProvider);
  return await repository.getCurrentWeather(location.latitude, location.longitude);
});

final solunarDataProvider = FutureProvider<SolunarData>((ref) async {
  final location = await ref.watch(locationProvider.future);
  final repository = ref.watch(weatherRepositoryProvider);
  return await repository.getSolunarData(location.latitude, location.longitude, DateTime.now());
});

final temperatureUnitProvider = StateProvider<TemperatureUnit>((ref) {
  return TemperatureUnit.celsius;
});
