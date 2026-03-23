import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/weather/data/models/weather_model.dart';

void main() {
  group('WeatherModel.fromJson', () {
    Map<String, dynamic> makeJson({
      double temperature = 22.5,
      int weatherCode = 0,
      double windSpeed = 10.0,
      double windDirection = 180.0,
      int humidity = 65,
    }) {
      return {
        'current': {
          'temperature_2m': temperature,
          'weather_code': weatherCode,
          'wind_speed_10m': windSpeed,
          'wind_direction_10m': windDirection,
          'relative_humidity_2m': humidity,
        },
      };
    }

    test('parses all numeric fields correctly', () {
      final model = WeatherModel.fromJson(makeJson(
        temperature: 32.7,
        windSpeed: 15.3,
        windDirection: 270.0,
        humidity: 42,
      ));

      expect(model.temperature, 32.7);
      expect(model.windSpeed, 15.3);
      expect(model.windDegree, 270.0);
      expect(model.humidity, 42);
    });

    test('handles integer values as num → double', () {
      final model = WeatherModel.fromJson(makeJson(
        temperature: 20,
        windSpeed: 5,
        windDirection: 90,
      ));

      expect(model.temperature, 20.0);
      expect(model.windSpeed, 5.0);
      expect(model.windDegree, 90.0);
    });

    test('WMO code 0 → Clear', () {
      final model = WeatherModel.fromJson(makeJson(weatherCode: 0));
      expect(model.condition, 'Clear');
      expect(model.iconCode, '01d');
    });

    test('WMO code 1-3 → Partly Cloudy', () {
      for (final code in [1, 2, 3]) {
        final model = WeatherModel.fromJson(makeJson(weatherCode: code));
        expect(model.condition, 'Partly Cloudy', reason: 'code=$code');
        expect(model.iconCode, '02d');
      }
    });

    test('WMO code 45-48 → Fog', () {
      for (final code in [45, 46, 48]) {
        final model = WeatherModel.fromJson(makeJson(weatherCode: code));
        expect(model.condition, 'Fog', reason: 'code=$code');
        expect(model.iconCode, '50d');
      }
    });

    test('WMO code 51-67 → Rain', () {
      for (final code in [51, 55, 61, 67]) {
        final model = WeatherModel.fromJson(makeJson(weatherCode: code));
        expect(model.condition, 'Rain', reason: 'code=$code');
        expect(model.iconCode, '10d');
      }
    });

    test('WMO code 71-77 → Snow', () {
      for (final code in [71, 73, 77]) {
        final model = WeatherModel.fromJson(makeJson(weatherCode: code));
        expect(model.condition, 'Snow', reason: 'code=$code');
        expect(model.iconCode, '13d');
      }
    });

    test('WMO code 80-82 → Showers', () {
      for (final code in [80, 81, 82]) {
        final model = WeatherModel.fromJson(makeJson(weatherCode: code));
        expect(model.condition, 'Showers', reason: 'code=$code');
        expect(model.iconCode, '09d');
      }
    });

    test('WMO code 95-99 → Thunderstorm', () {
      for (final code in [95, 96, 99]) {
        final model = WeatherModel.fromJson(makeJson(weatherCode: code));
        expect(model.condition, 'Thunderstorm', reason: 'code=$code');
        expect(model.iconCode, '11d');
      }
    });

    test('unknown WMO code → Unknown / default icon', () {
      final model = WeatherModel.fromJson(makeJson(weatherCode: 200));
      expect(model.condition, 'Unknown');
      expect(model.iconCode, '01d');
    });

    test('gap WMO codes (4-44) → Unknown', () {
      final model = WeatherModel.fromJson(makeJson(weatherCode: 10));
      expect(model.condition, 'Unknown');
    });

    test('timestamp is populated', () {
      final before = DateTime.now();
      final model = WeatherModel.fromJson(makeJson());
      final after = DateTime.now();

      expect(model.timestamp.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(model.timestamp.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('negative temperature', () {
      final model = WeatherModel.fromJson(makeJson(temperature: -15.3));
      expect(model.temperature, -15.3);
    });

    test('zero wind speed', () {
      final model = WeatherModel.fromJson(makeJson(windSpeed: 0.0));
      expect(model.windSpeed, 0.0);
    });
  });
}
