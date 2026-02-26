
import 'package:outcall/features/weather/domain/weather_entities.dart';

class SolunarModel extends SolunarData {
  const SolunarModel({
    required super.moonIllumination,
    required super.moonPhaseName,
    required super.sunrise,
    required super.sunset,
    required super.majorPeriods,
    required super.minorPeriods,
    required super.overallRating,
  });

  factory SolunarModel.fromOpenMeteo(Map<String, dynamic> json, DateTime date) {
    final daily = json['daily'];
    
    // Safety check handled by caller/datasource usually, but good practice
    if ((daily['time'] as List).isEmpty) throw Exception('No data available');

    final sunrise = DateTime.parse(daily['sunrise'][0]);
    final sunset = DateTime.parse(daily['sunset'][0]);
    final moonriseStr = daily['moonrise'][0];
    final moonsetStr = daily['moonset'][0];
    
    final DateTime? moonrise = moonriseStr != null ? DateTime.parse(moonriseStr) : null;
    DateTime? moonset = moonsetStr != null ? DateTime.parse(moonsetStr) : null;
    
    final moonPhase = daily['moon_phase'][0] as double; // 0-1
    final illumination = (daily['moon_illumination'][0] as num).toDouble();

    // Logic extracted from original repository
    final List<ActivityPeriod> majorPeriods = [];
    final List<ActivityPeriod> minorPeriods = [];

    // Major Period 1: Moon Overhead
    if (moonrise != null && moonset != null) {
      if (moonset.isBefore(moonrise)) moonset = moonset.add(const Duration(days: 1));
      final midpoint = moonrise.add(moonset.difference(moonrise) ~/ 2);
      
      majorPeriods.add(ActivityPeriod(
        start: midpoint.subtract(const Duration(hours: 1)),
        end: midpoint.add(const Duration(hours: 1)),
        type: 'Major',
      ));
      
      final underfoot = midpoint.add(const Duration(hours: 12, minutes: 25));
       if (underfoot.day == date.day) {
          majorPeriods.add(ActivityPeriod(
            start: underfoot.subtract(const Duration(hours: 1)),
            end: underfoot.add(const Duration(hours: 1)),
            type: 'Major',
          )); 
       }
    }

    // Minor Periods
    if (moonrise != null && moonrise.day == date.day) {
      minorPeriods.add(ActivityPeriod(
        start: moonrise.subtract(const Duration(minutes: 30)),
        end: moonrise.add(const Duration(minutes: 30)),
        type: 'Minor',
      ));
    }
    if (moonset != null && moonset.day == date.day) {
       minorPeriods.add(ActivityPeriod(
        start: moonset.subtract(const Duration(minutes: 30)),
        end: moonset.add(const Duration(minutes: 30)),
        type: 'Minor',
      ));
    }

    return SolunarModel(
      moonIllumination: illumination,
      moonPhaseName: _getMoonPhaseName(moonPhase),
      sunrise: sunrise,
      sunset: sunset,
      majorPeriods: majorPeriods,
      minorPeriods: minorPeriods,
      overallRating: _calculateRating(moonPhase, illumination),
    );
  }

  static String _getMoonPhaseName(double phase) {
    if (phase == 0 || phase == 1) return 'New Moon';
    if (phase < 0.25) return 'Waxing Crescent';
    if (phase == 0.25) return 'First Quarter';
    if (phase < 0.5) return 'Waxing Gibbous';
    if (phase == 0.5) return 'Full Moon';
    if (phase < 0.75) return 'Waning Gibbous';
    if (phase == 0.75) return 'Last Quarter';
    return 'Waning Crescent';
  }

  static int _calculateRating(double phase, double illumination) {
    if (illumination > 90 || illumination < 10) return 5;
    if (illumination > 70 || illumination < 30) return 4;
    return 3;
  }
}
