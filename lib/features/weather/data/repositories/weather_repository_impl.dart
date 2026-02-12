
import 'package:hunting_calls_perfection/features/weather/domain/weather_entities.dart';
import 'package:hunting_calls_perfection/features/weather/domain/weather_repository.dart';
import 'package:hunting_calls_perfection/features/weather/data/datasources/weather_remote_data_source.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherRemoteDataSource remoteDataSource;

  WeatherRepositoryImpl({required this.remoteDataSource});

  @override
  Future<WeatherData> getCurrentWeather(double lat, double lon) async {
    return await remoteDataSource.getCurrentWeather(lat, lon);
  }

  @override
  Future<SolunarData> getSolunarData(double lat, double lon, DateTime date) async {
    return await remoteDataSource.getSolunarData(lat, lon, date);
  }
}
