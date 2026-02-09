import 'dart:math';
import '../domain/weather_models.dart';
import 'weather_repository.dart';

class MockWeatherRepository implements WeatherRepository {
  @override
  Future<WeatherData> getCurrentWeather(double lat, double lon) async {
    // Simulating API delay
    await Future.delayed(const Duration(milliseconds: 500));

    return WeatherData(
      temperature: 18.5,
      condition: 'Clear',
      iconCode: '01d',
      windSpeed: 12.0,
      windDegree: 45.0, // North-East
      humidity: 40,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<SolunarData> getSolunarData(double lat, double lon, DateTime date) async {
    // Simulating local calculation
    await Future.delayed(const Duration(milliseconds: 300));

    final sunrise = DateTime(date.year, date.month, date.day, 6, 30);
    final sunset = DateTime(date.year, date.month, date.day, 18, 45);

    return SolunarData(
      moonIllumination: 0.85,
      moonPhaseName: 'Waxing Gibbous',
      sunrise: sunrise,
      sunset: sunset,
      majorPeriods: [
        ActivityPeriod(
          start: DateTime(date.year, date.month, date.day, 10, 0),
          end: DateTime(date.year, date.month, date.day, 12, 0),
          type: 'Major',
        ),
        ActivityPeriod(
          start: DateTime(date.year, date.month, date.day, 22, 0),
          end: DateTime(date.year, date.month, date.day, 0, 0).add(const Duration(days: 1)),
          type: 'Major',
        ),
      ],
      minorPeriods: [
        ActivityPeriod(
          start: DateTime(date.year, date.month, date.day, 4, 30),
          end: DateTime(date.year, date.month, date.day, 5, 30),
          type: 'Minor',
        ),
        ActivityPeriod(
          start: DateTime(date.year, date.month, date.day, 16, 0),
          end: DateTime(date.year, date.month, date.day, 17, 0),
          type: 'Minor',
        ),
      ],
      overallRating: 4,
    );
  }
}
