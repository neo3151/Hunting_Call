import 'package:outcall/features/weather/domain/weather_entities.dart';
import 'package:outcall/features/weather/domain/weather_repository.dart';

class GetSolunarInfo {
  final WeatherRepository repository;

  GetSolunarInfo(this.repository);

  Future<SolunarData> call(double lat, double lon, DateTime date) {
    return repository.getSolunarData(lat, lon, date);
  }
}
