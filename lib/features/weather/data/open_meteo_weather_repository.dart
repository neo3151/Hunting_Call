import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../domain/weather_models.dart';
import 'weather_repository.dart';

class OpenMeteoWeatherRepository implements WeatherRepository {
  final http.Client client = http.Client();

  @override
  Future<WeatherData> getCurrentWeather(double lat, double lon) async {
    try {
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,wind_direction_10m');
      
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];

        return WeatherData(
          temperature: (current['temperature_2m'] as num).toDouble(),
          condition: _mapWmoCodeToCondition(current['weather_code'] as int),
          iconCode: _mapWmoCodeToIcon(current['weather_code'] as int),
          windSpeed: (current['wind_speed_10m'] as num).toDouble(),
          windDegree: (current['wind_direction_10m'] as num).toDouble(),
          humidity: current['relative_humidity_2m'] as int,
          timestamp: DateTime.now(),
        );
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Failed to load weather data: $e');
    }
  }

  @override
  Future<SolunarData> getSolunarData(double lat, double lon, DateTime date) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&daily=sunrise,sunset,moonrise,moonset,moon_phase,moon_illumination&start_date=$formattedDate&end_date=$formattedDate&timezone=auto');

      final response = await client.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final daily = data['daily'];

        if ((daily['time'] as List).isEmpty) throw Exception('No data available');

        final sunrise = DateTime.parse(daily['sunrise'][0]);
        final sunset = DateTime.parse(daily['sunset'][0]);
        final moonriseStr = daily['moonrise'][0];
        final moonsetStr = daily['moonset'][0];
        
        DateTime? moonrise = moonriseStr != null ? DateTime.parse(moonriseStr) : null;
        DateTime? moonset = moonsetStr != null ? DateTime.parse(moonsetStr) : null;
        
        final moonPhase = daily['moon_phase'][0] as double; // 0-1
        final illumination = (daily['moon_illumination'][0] as num).toDouble();

        // Calculate Periods
        List<ActivityPeriod> majorPeriods = [];
        List<ActivityPeriod> minorPeriods = [];

        // Major Period 1: Moon Overhead (approx midway between rise and set)
        if (moonrise != null && moonset != null) {
          // Keep it simple finding midpoint
          if (moonset.isBefore(moonrise)) moonset = moonset.add(const Duration(days: 1));
          final midpoint = moonrise.add(moonset.difference(moonrise) ~/ 2);
          
          majorPeriods.add(ActivityPeriod(
            start: midpoint.subtract(const Duration(hours: 1)),
            end: midpoint.add(const Duration(hours: 1)),
            type: 'Major',
          ));
          
          // Major Period 2: Moon Underfoot (approx 12.4 hours from overhead)
           final underfoot = midpoint.add(const Duration(hours: 12, minutes: 25));
           // If it falls within the same day... otherwise ignore for simplicty of this one-day view
           if (underfoot.day == date.day) {
              majorPeriods.add(ActivityPeriod(
                start: underfoot.subtract(const Duration(hours: 1)),
                end: underfoot.add(const Duration(hours: 1)),
                type: 'Major',
              )); 
           }
        }

        // Minor Periods: Moonrise and Moonset
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

        return SolunarData(
          moonIllumination: illumination,
          moonPhaseName: _getMoonPhaseName(moonPhase),
          sunrise: sunrise,
          sunset: sunset,
          majorPeriods: majorPeriods,
          minorPeriods: minorPeriods,
          overallRating: _calculateRating(moonPhase, illumination),
        );
      } else {
        throw Exception('Failed to load solunar data');
      }
    } catch (e) {
      throw Exception('Failed to load solunar data: $e');
    }
  }

  String _mapWmoCodeToCondition(int code) {
    if (code == 0) return 'Clear';
    if (code >= 1 && code <= 3) return 'Partly Cloudy';
    if (code >= 45 && code <= 48) return 'Fog';
    if (code >= 51 && code <= 67) return 'Rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Showers';
    if (code >= 95 && code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  String _mapWmoCodeToIcon(int code) {
    if (code == 0) return '01d';
    if (code >= 1 && code <= 3) return '02d';
    if (code >= 45 && code <= 48) return '50d';
    if (code >= 51 && code <= 67) return '10d';
    if (code >= 71 && code <= 77) return '13d';
    if (code >= 80 && code <= 82) return '09d';
    if (code >= 95 && code <= 99) return '11d';
    return '01d';
  }

  String _getMoonPhaseName(double phase) {
    if (phase == 0 || phase == 1) return 'New Moon';
    if (phase < 0.25) return 'Waxing Crescent';
    if (phase == 0.25) return 'First Quarter';
    if (phase < 0.5) return 'Waxing Gibbous';
    if (phase == 0.5) return 'Full Moon';
    if (phase < 0.75) return 'Waning Gibbous';
    if (phase == 0.75) return 'Last Quarter';
    return 'Waning Crescent';
  }

  int _calculateRating(double phase, double illumination) {
    // Simple rating based on fullness (Full/New is best for solunar activity usually)
    if (illumination > 90 || illumination < 10) return 5;
    if (illumination > 70 || illumination < 30) return 4;
    return 3;
  }
}
