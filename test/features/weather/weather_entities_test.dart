import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/weather/domain/weather_entities.dart';

void main() {
  group('TemperatureUnit', () {
    test('has celsius and fahrenheit', () {
      expect(TemperatureUnit.values, contains(TemperatureUnit.celsius));
      expect(TemperatureUnit.values, contains(TemperatureUnit.fahrenheit));
      expect(TemperatureUnit.values.length, 2);
    });
  });

  group('WeatherData', () {
    final now = DateTime(2026, 3, 13);

    test('stores all fields', () {
      final weather = WeatherData(
        temperature: 72.0,
        condition: 'Sunny',
        iconCode: '01d',
        windSpeed: 5.0,
        windDegree: 180.0,
        humidity: 45,
        timestamp: now,
      );
      expect(weather.temperature, 72.0);
      expect(weather.condition, 'Sunny');
      expect(weather.iconCode, '01d');
      expect(weather.windSpeed, 5.0);
      expect(weather.windDegree, 180.0);
      expect(weather.humidity, 45);
      expect(weather.timestamp, now);
    });

    test('equality via Equatable', () {
      final a = WeatherData(
        temperature: 72, condition: 'Sunny', iconCode: '01d',
        windSpeed: 5, windDegree: 180, humidity: 45, timestamp: now,
      );
      final b = WeatherData(
        temperature: 72, condition: 'Sunny', iconCode: '01d',
        windSpeed: 5, windDegree: 180, humidity: 45, timestamp: now,
      );
      expect(a, equals(b));
    });

    test('inequality when fields differ', () {
      final a = WeatherData(
        temperature: 72, condition: 'Sunny', iconCode: '01d',
        windSpeed: 5, windDegree: 180, humidity: 45, timestamp: now,
      );
      final b = WeatherData(
        temperature: 75, condition: 'Cloudy', iconCode: '04d',
        windSpeed: 10, windDegree: 90, humidity: 60, timestamp: now,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('ActivityPeriod', () {
    test('stores start, end, and type', () {
      final period = ActivityPeriod(
        start: DateTime(2026, 3, 13, 6, 0),
        end: DateTime(2026, 3, 13, 8, 0),
        type: 'Major',
      );
      expect(period.start.hour, 6);
      expect(period.end.hour, 8);
      expect(period.type, 'Major');
    });

    test('equality via Equatable', () {
      final a = ActivityPeriod(
        start: DateTime(2026, 3, 13, 6, 0),
        end: DateTime(2026, 3, 13, 8, 0),
        type: 'Major',
      );
      final b = ActivityPeriod(
        start: DateTime(2026, 3, 13, 6, 0),
        end: DateTime(2026, 3, 13, 8, 0),
        type: 'Major',
      );
      expect(a, equals(b));
    });
  });

  group('SolunarData', () {
    test('stores all fields', () {
      final sunrise = DateTime(2026, 3, 13, 6, 30);
      final sunset = DateTime(2026, 3, 13, 18, 45);
      final solunar = SolunarData(
        moonIllumination: 0.75,
        moonPhaseName: 'Waxing Gibbous',
        sunrise: sunrise,
        sunset: sunset,
        majorPeriods: [
          ActivityPeriod(
            start: DateTime(2026, 3, 13, 6, 0),
            end: DateTime(2026, 3, 13, 8, 0),
            type: 'Major',
          ),
        ],
        minorPeriods: [],
        overallRating: 4,
      );
      expect(solunar.moonIllumination, 0.75);
      expect(solunar.moonPhaseName, 'Waxing Gibbous');
      expect(solunar.sunrise, sunrise);
      expect(solunar.sunset, sunset);
      expect(solunar.majorPeriods.length, 1);
      expect(solunar.minorPeriods, isEmpty);
      expect(solunar.overallRating, 4);
    });

    test('equality via Equatable', () {
      final args = {
        'moonIllumination': 0.5,
        'moonPhaseName': 'Full Moon',
        'sunrise': DateTime(2026, 3, 13, 6, 30),
        'sunset': DateTime(2026, 3, 13, 18, 45),
        'majorPeriods': <ActivityPeriod>[],
        'minorPeriods': <ActivityPeriod>[],
        'overallRating': 3,
      };
      final a = SolunarData(
        moonIllumination: args['moonIllumination'] as double,
        moonPhaseName: args['moonPhaseName'] as String,
        sunrise: args['sunrise'] as DateTime,
        sunset: args['sunset'] as DateTime,
        majorPeriods: args['majorPeriods'] as List<ActivityPeriod>,
        minorPeriods: args['minorPeriods'] as List<ActivityPeriod>,
        overallRating: args['overallRating'] as int,
      );
      final b = SolunarData(
        moonIllumination: args['moonIllumination'] as double,
        moonPhaseName: args['moonPhaseName'] as String,
        sunrise: args['sunrise'] as DateTime,
        sunset: args['sunset'] as DateTime,
        majorPeriods: args['majorPeriods'] as List<ActivityPeriod>,
        minorPeriods: args['minorPeriods'] as List<ActivityPeriod>,
        overallRating: args['overallRating'] as int,
      );
      expect(a, equals(b));
    });
  });
}
