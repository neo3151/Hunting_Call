import '../domain/weather_models.dart';

abstract class WeatherRepository {
  Future<WeatherData> getCurrentWeather(double lat, double lon);
  Future<SolunarData> getSolunarData(double lat, double lon, DateTime date);
}
