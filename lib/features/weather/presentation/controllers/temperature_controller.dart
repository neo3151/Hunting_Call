import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/weather_entities.dart';

final temperatureUnitProvider = StateProvider<TemperatureUnit>((ref) {
  return TemperatureUnit.celsius;
});
