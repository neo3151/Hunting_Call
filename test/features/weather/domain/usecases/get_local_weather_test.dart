import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:outcall/features/weather/domain/usecases/get_local_weather.dart';
import 'package:outcall/features/weather/domain/weather_repository.dart';
import 'package:outcall/features/weather/domain/weather_entities.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

void main() {
  late GetLocalWeather useCase;
  late MockWeatherRepository mockRepo;

  setUp(() {
    mockRepo = MockWeatherRepository();
    useCase = GetLocalWeather(mockRepo);
  });

  final testWeather = WeatherData(
    temperature: 72.0,
    condition: 'Clear',
    iconCode: '01d',
    windSpeed: 5.5,
    windDegree: 180,
    humidity: 45,
    timestamp: DateTime(2026, 2, 25),
  );

  group('GetLocalWeather', () {
    test('returns WeatherData on success', () async {
      // Arrange
      when(() => mockRepo.getCurrentWeather(35.0, -97.0))
          .thenAnswer((_) async => testWeather);

      // Act
      final result = await useCase.call(35.0, -97.0);

      // Assert
      expect(result, testWeather);
      expect(result.temperature, 72.0);
      expect(result.condition, 'Clear');
      expect(result.humidity, 45);
      verify(() => mockRepo.getCurrentWeather(35.0, -97.0)).called(1);
    });

    test('throws when repository fails', () async {
      // Arrange
      when(() => mockRepo.getCurrentWeather(any(), any()))
          .thenThrow(Exception('Network unreachable'));

      // Act & Assert
      expect(
        () => useCase.call(35.0, -97.0),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('GetSolunarData', () {
    final testSolunar = SolunarData(
      moonIllumination: 0.75,
      moonPhaseName: 'Waxing Gibbous',
      sunrise: DateTime(2026, 2, 25, 6, 45),
      sunset: DateTime(2026, 2, 25, 18, 15),
      majorPeriods: [
        ActivityPeriod(
          start: DateTime(2026, 2, 25, 10, 0),
          end: DateTime(2026, 2, 25, 12, 0),
          type: 'Major',
        ),
      ],
      minorPeriods: [
        ActivityPeriod(
          start: DateTime(2026, 2, 25, 6, 0),
          end: DateTime(2026, 2, 25, 7, 0),
          type: 'Minor',
        ),
      ],
      overallRating: 4,
    );

    test('returns SolunarData on success', () async {
      // Arrange
      when(() => mockRepo.getSolunarData(35.0, -97.0, any()))
          .thenAnswer((_) async => testSolunar);

      // Act
      final result = await mockRepo.getSolunarData(35.0, -97.0, DateTime(2026, 2, 25));

      // Assert
      expect(result.moonPhaseName, 'Waxing Gibbous');
      expect(result.overallRating, 4);
      expect(result.majorPeriods.length, 1);
      expect(result.minorPeriods.length, 1);
    });

    test('throws when solunar data fetch fails', () async {
      // Arrange
      when(() => mockRepo.getSolunarData(any(), any(), any()))
          .thenThrow(Exception('API timeout'));

      // Act & Assert
      expect(
        () => mockRepo.getSolunarData(35.0, -97.0, DateTime.now()),
        throwsA(isA<Exception>()),
      );
    });
  });
}
