
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:outcall/features/weather/data/models/solunar_model.dart';
import 'package:outcall/features/weather/data/models/weather_model.dart';

abstract class WeatherRemoteDataSource {
  Future<WeatherModel> getCurrentWeather(double lat, double lon);
  Future<SolunarModel> getSolunarData(double lat, double lon, DateTime date);
}

class OpenMeteoWeatherDataSource implements WeatherRemoteDataSource {
  final http.Client client;

  OpenMeteoWeatherDataSource({http.Client? client}) : client = client ?? http.Client();

  @override
  Future<WeatherModel> getCurrentWeather(double lat, double lon) async {
    try {
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,wind_direction_10m');
      
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherModel.fromJson(data);
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Failed to load weather data: $e');
    }
  }

  @override
  Future<SolunarModel> getSolunarData(double lat, double lon, DateTime date) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&daily=sunrise,sunset,moonrise,moonset,moon_phase,moon_illumination&start_date=$formattedDate&end_date=$formattedDate&timezone=auto');

      final response = await client.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SolunarModel.fromOpenMeteo(data, date);
      } else {
        throw Exception('Failed to load solunar data');
      }
    } catch (e) {
      throw Exception('Failed to load solunar data: $e');
    }
  }
}
