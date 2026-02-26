import 'package:outcall/features/weather/domain/weather_entities.dart';
import 'package:outcall/features/weather/domain/weather_repository.dart';

class GetLocalWeather {
  final WeatherRepository repository;

  GetLocalWeather(this.repository);

  Future<WeatherData> call(double lat, double lon) {
    return repository.getCurrentWeather(lat, lon);
  }
}
