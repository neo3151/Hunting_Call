import 'package:equatable/equatable.dart';

enum TemperatureUnit { celsius, fahrenheit }

class WeatherData extends Equatable {
  final double temperature;
  final String condition;
  final String iconCode;
  final double windSpeed;
  final double windDegree;
  final int humidity;
  final DateTime timestamp;

  const WeatherData({
    required this.temperature,
    required this.condition,
    required this.iconCode,
    required this.windSpeed,
    required this.windDegree,
    required this.humidity,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        temperature,
        condition,
        iconCode,
        windSpeed,
        windDegree,
        humidity,
        timestamp,
      ];
}

class SolunarData extends Equatable {
  final double moonIllumination;
  final String moonPhaseName;
  final DateTime sunrise;
  final DateTime sunset;
  final List<ActivityPeriod> majorPeriods;
  final List<ActivityPeriod> minorPeriods;
  final int overallRating; // 1-5 stars

  const SolunarData({
    required this.moonIllumination,
    required this.moonPhaseName,
    required this.sunrise,
    required this.sunset,
    required this.majorPeriods,
    required this.minorPeriods,
    required this.overallRating,
  });

  @override
  List<Object?> get props => [
        moonIllumination,
        moonPhaseName,
        sunrise,
        sunset,
        majorPeriods,
        minorPeriods,
        overallRating,
      ];
}

class ActivityPeriod extends Equatable {
  final DateTime start;
  final DateTime end;
  final String type; // 'Major' or 'Minor'

  const ActivityPeriod({
    required this.start,
    required this.end,
    required this.type,
  });

  @override
  List<Object?> get props => [start, end, type];
}
