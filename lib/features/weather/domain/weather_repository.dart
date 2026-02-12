import 'package:hunting_calls_perfection/features/weather/domain/weather_entities.dart';

abstract class WeatherRepository {
  Future<WeatherData> getCurrentWeather(double lat, double lon);
  Future<SolunarData> getSolunarData(double lat, double lon, DateTime date);
}
