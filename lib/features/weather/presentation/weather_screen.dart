import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/background_wrapper.dart';
import 'package:hunting_calls_perfection/features/weather/presentation/controllers/temperature_controller.dart';
import '../domain/weather_entities.dart';
import '../presentation/weather_controller.dart';
import 'widgets/wind_compass.dart';

class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherState = ref.watch(weatherControllerProvider);
    final weatherAsync = weatherState.weather;
    final solunarAsync = weatherState.solunar;
    final unit = ref.watch(temperatureUnitProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('HUNT FORECAST', style: GoogleFonts.oswald(letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: () {
                ref.read(temperatureUnitProvider.notifier).state = 
                  unit == TemperatureUnit.celsius ? TemperatureUnit.fahrenheit : TemperatureUnit.celsius;
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                unit == TemperatureUnit.celsius ? '°C' : '°F',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: BackgroundWrapper(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWeatherCard(weatherAsync, unit),
                const SizedBox(height: 24),
                _buildWindCard(weatherAsync),
                const SizedBox(height: 24),
                _buildSolunarCard(solunarAsync),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard(AsyncValue weatherAsync, TemperatureUnit unit) {
    return weatherAsync.when(
      data: (weather) {
        double temp = weather.temperature;
        String unitLabel = '°C';
        if (unit == TemperatureUnit.fahrenheit) {
          temp = (temp * 9 / 5) + 32;
          unitLabel = '°F';
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${temp.toStringAsFixed(1)}$unitLabel',
                    style: GoogleFonts.oswald(fontSize: 48, color: Colors.white),
                  ),
                  Text(
                    weather.condition.toUpperCase(),
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
              const Icon(Icons.wb_sunny, color: Colors.yellowAccent, size: 64),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildWindCard(AsyncValue weatherAsync) {
    return weatherAsync.when(
      data: (weather) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Text('WIND & SCENT TRACKER', style: GoogleFonts.oswald(color: Colors.white70)),
            const SizedBox(height: 20),
            WindCompass(windDegree: weather.windDegree, windSpeed: weather.windSpeed),
            const SizedBox(height: 12),
            const Text(
              'Stay downwind of your target.',
              style: TextStyle(color: Colors.orangeAccent, fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSolunarCard(AsyncValue solunarAsync) {
    return solunarAsync.when(
      data: (solunar) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SOLUNAR ACTIVITY', style: GoogleFonts.oswald(color: Colors.white70)),
                Row(
                  children: List.generate(5, (index) => Icon(
                    Icons.star,
                    color: index < solunar.overallRating ? Colors.orangeAccent : Colors.white10,
                    size: 16,
                  )),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(Icons.brightness_5, 'SUNRISE', DateFormat.jm().format(solunar.sunrise)),
            const Divider(color: Colors.white10),
            _buildInfoRow(Icons.brightness_4, 'SUNSET', DateFormat.jm().format(solunar.sunset)),
            const Divider(color: Colors.white10),
            const SizedBox(height: 12),
            Text('PEAK ACTIVITY PERIODS', style: GoogleFonts.oswald(fontSize: 14)),
            const SizedBox(height: 8),
            ...solunar.majorPeriods.map((p) => _buildPeriodTile(p, Colors.greenAccent)),
            ...solunar.minorPeriods.map((p) => _buildPeriodTile(p, Colors.blueAccent)),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPeriodTile(dynamic period, Color color) {
    final startTime = DateFormat.jm().format(period.start);
    final endTime = DateFormat.jm().format(period.end);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 30,
            color: color,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(period.type.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
              Text('$startTime - $endTime', style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
