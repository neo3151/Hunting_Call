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
  List<Object?> get props => [temperature, condition, iconCode, windSpeed, windDegree, humidity, timestamp];

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'condition': condition,
    'iconCode': iconCode,
    'windSpeed': windSpeed,
    'windDegree': windDegree,
    'humidity': humidity,
    'timestamp': timestamp.toIso8601String(),
  };

  factory WeatherData.fromJson(Map<String, dynamic> json) => WeatherData(
    temperature: (json['temperature'] as num).toDouble(),
    condition: json['condition'] as String,
    iconCode: json['iconCode'] as String,
    windSpeed: (json['windSpeed'] as num).toDouble(),
    windDegree: (json['windDegree'] as num).toDouble(),
    humidity: json['humidity'] as int,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
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
  List<Object?> get props => [moonIllumination, moonPhaseName, sunrise, sunset, majorPeriods, minorPeriods, overallRating];

  Map<String, dynamic> toJson() => {
    'moonIllumination': moonIllumination,
    'moonPhaseName': moonPhaseName,
    'sunrise': sunrise.toIso8601String(),
    'sunset': sunset.toIso8601String(),
    'majorPeriods': majorPeriods.map((e) => e.toJson()).toList(),
    'minorPeriods': minorPeriods.map((e) => e.toJson()).toList(),
    'overallRating': overallRating,
  };

  factory SolunarData.fromJson(Map<String, dynamic> json) => SolunarData(
    moonIllumination: (json['moonIllumination'] as num).toDouble(),
    moonPhaseName: json['moonPhaseName'] as String,
    sunrise: DateTime.parse(json['sunrise'] as String),
    sunset: DateTime.parse(json['sunset'] as String),
    majorPeriods: (json['majorPeriods'] as List).map((e) => ActivityPeriod.fromJson(e)).toList(),
    minorPeriods: (json['minorPeriods'] as List).map((e) => ActivityPeriod.fromJson(e)).toList(),
    overallRating: json['overallRating'] as int,
  );
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

  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'type': type,
  };

  factory ActivityPeriod.fromJson(Map<String, dynamic> json) => ActivityPeriod(
    start: DateTime.parse(json['start'] as String),
    end: DateTime.parse(json['end'] as String),
    type: json['type'] as String,
  );
}
