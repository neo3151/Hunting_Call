import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/features/weather/domain/weather_entities.dart';

class TemperatureUnitNotifier extends Notifier<TemperatureUnit> {
  @override
  TemperatureUnit build() => TemperatureUnit.celsius;

  void toggleUnit() {
    state = state == TemperatureUnit.celsius ? TemperatureUnit.fahrenheit : TemperatureUnit.celsius;
  }
}

final temperatureUnitProvider = NotifierProvider<TemperatureUnitNotifier, TemperatureUnit>(TemperatureUnitNotifier.new);
