
import '../../domain/weather_entities.dart';

class WeatherModel extends WeatherData {
  const WeatherModel({
    required super.temperature,
    required super.condition,
    required super.iconCode,
    required super.windSpeed,
    required super.windDegree,
    required super.humidity,
    required super.timestamp,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    return WeatherModel(
      temperature: (current['temperature_2m'] as num).toDouble(),
      condition: _mapWmoCodeToCondition(current['weather_code'] as int),
      iconCode: _mapWmoCodeToIcon(current['weather_code'] as int),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      windDegree: (current['wind_direction_10m'] as num).toDouble(),
      humidity: current['relative_humidity_2m'] as int,
      timestamp: DateTime.now(),
    );
  }

  static String _mapWmoCodeToCondition(int code) {
    if (code == 0) return 'Clear';
    if (code >= 1 && code <= 3) return 'Partly Cloudy';
    if (code >= 45 && code <= 48) return 'Fog';
    if (code >= 51 && code <= 67) return 'Rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Showers';
    if (code >= 95 && code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  static String _mapWmoCodeToIcon(int code) {
    if (code == 0) return '01d';
    if (code >= 1 && code <= 3) return '02d';
    if (code >= 45 && code <= 48) return '50d';
    if (code >= 51 && code <= 67) return '10d';
    if (code >= 71 && code <= 77) return '13d';
    if (code >= 80 && code <= 82) return '09d';
    if (code >= 95 && code <= 99) return '11d';
    return '01d';
  }
}
