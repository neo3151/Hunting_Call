import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/weather/data/models/solunar_model.dart';

void main() {
  // Helper to build Open-Meteo-style JSON
  Map<String, dynamic> makeJson({
    String sunrise = '2025-03-01T06:30:00',
    String sunset = '2025-03-01T18:30:00',
    String? moonrise = '2025-03-01T10:00:00',
    String? moonset = '2025-03-01T22:30:00',
    double moonPhase = 0.5,
    double moonIllumination = 100.0,
  }) {
    return {
      'daily': {
        'time': ['2025-03-01'],
        'sunrise': [sunrise],
        'sunset': [sunset],
        'moonrise': [moonrise],
        'moonset': [moonset],
        'moon_phase': [moonPhase],
        'moon_illumination': [moonIllumination],
      },
    };
  }

  final date = DateTime(2025, 3, 1);

  group('SolunarModel.fromOpenMeteo', () {
    test('parses sunrise and sunset', () {
      final model = SolunarModel.fromOpenMeteo(makeJson(), date);
      expect(model.sunrise, DateTime(2025, 3, 1, 6, 30));
      expect(model.sunset, DateTime(2025, 3, 1, 18, 30));
    });

    test('parses moon illumination', () {
      final model = SolunarModel.fromOpenMeteo(makeJson(moonIllumination: 75.5), date);
      expect(model.moonIllumination, 75.5);
    });

    test('moon phase 0 → New Moon', () {
      final model = SolunarModel.fromOpenMeteo(makeJson(moonPhase: 0.0), date);
      expect(model.moonPhaseName, 'New Moon');
    });

    test('moon phase 1 → New Moon', () {
      final model = SolunarModel.fromOpenMeteo(makeJson(moonPhase: 1.0), date);
      expect(model.moonPhaseName, 'New Moon');
    });

    test('moon phase 0.1 → Waxing Crescent', () {
      final model = SolunarModel.fromOpenMeteo(makeJson(moonPhase: 0.1), date);
      expect(model.moonPhaseName, 'Waxing Crescent');
    });

    test('moon phase 0.25 → First Quarter', () {
      final model = SolunarModel.fromOpenMeteo(makeJson(moonPhase: 0.25), date);
      expect(model.moonPhaseName, 'First Quarter');
    });

    test('moon phase 0.4 → Waxing Gibbous', () {
      final model = SolunarModel.fromOpenMeteo(makeJson(moonPhase: 0.4), date);
      expect(model.moonPhaseName, 'Waxing Gibbous');
    });

    test('moon phase 0.5 → Full Moon', () {
      final model = SolunarModel.fromOpenMeteo(makeJson(moonPhase: 0.5), date);
      expect(model.moonPhaseName, 'Full Moon');
    });

    test('moon phase 0.6 → Waning Gibbous', () {
      final model = SolunarModel.fromOpenMeteo(makeJson(moonPhase: 0.6), date);
      expect(model.moonPhaseName, 'Waning Gibbous');
    });

    test('moon phase 0.75 → Last Quarter', () {
      final model = SolunarModel.fromOpenMeteo(makeJson(moonPhase: 0.75), date);
      expect(model.moonPhaseName, 'Last Quarter');
    });

    test('moon phase 0.9 → Waning Crescent', () {
      final model = SolunarModel.fromOpenMeteo(makeJson(moonPhase: 0.9), date);
      expect(model.moonPhaseName, 'Waning Crescent');
    });

    test('rating 5 for high illumination (>90)', () {
      final model =
          SolunarModel.fromOpenMeteo(makeJson(moonIllumination: 95.0, moonPhase: 0.5), date);
      expect(model.overallRating, 5);
    });

    test('rating 5 for low illumination (<10)', () {
      final model =
          SolunarModel.fromOpenMeteo(makeJson(moonIllumination: 5.0, moonPhase: 0.0), date);
      expect(model.overallRating, 5);
    });

    test('rating 4 for illumination 70-90', () {
      final model =
          SolunarModel.fromOpenMeteo(makeJson(moonIllumination: 80.0, moonPhase: 0.4), date);
      expect(model.overallRating, 4);
    });

    test('rating 4 for illumination 10-30', () {
      final model =
          SolunarModel.fromOpenMeteo(makeJson(moonIllumination: 20.0, moonPhase: 0.1), date);
      expect(model.overallRating, 4);
    });

    test('rating 3 for mid illumination', () {
      final model =
          SolunarModel.fromOpenMeteo(makeJson(moonIllumination: 50.0, moonPhase: 0.25), date);
      expect(model.overallRating, 3);
    });

    test('generates major periods when moonrise and moonset present', () {
      final model = SolunarModel.fromOpenMeteo(makeJson(), date);
      expect(model.majorPeriods, isNotEmpty);
      expect(model.majorPeriods.first.type, 'Major');
    });

    test('major period is 2 hours centered on midpoint', () {
      final model = SolunarModel.fromOpenMeteo(
          makeJson(
            moonrise: '2025-03-01T10:00:00',
            moonset: '2025-03-01T22:00:00',
          ),
          date);

      // Midpoint = 16:00, so period should be 15:00 - 17:00
      final major = model.majorPeriods.first;
      expect(major.start, DateTime(2025, 3, 1, 15, 0));
      expect(major.end, DateTime(2025, 3, 1, 17, 0));
    });

    test('generates minor periods at moonrise and moonset', () {
      final model = SolunarModel.fromOpenMeteo(makeJson(), date);
      expect(model.minorPeriods, isNotEmpty);
      for (final minor in model.minorPeriods) {
        expect(minor.type, 'Minor');
      }
    });

    test('minor periods are 1 hour centered on event', () {
      final model = SolunarModel.fromOpenMeteo(
          makeJson(
            moonrise: '2025-03-01T10:00:00',
          ),
          date);

      final moonriseMinor =
          model.minorPeriods.where((p) => p.start == DateTime(2025, 3, 1, 9, 30)).toList();
      expect(moonriseMinor, isNotEmpty);
      expect(moonriseMinor.first.end, DateTime(2025, 3, 1, 10, 30));
    });

    test('no major periods when moonrise is null', () {
      final model = SolunarModel.fromOpenMeteo(makeJson(moonrise: null), date);
      expect(model.majorPeriods, isEmpty);
    });

    test('no major periods when moonset is null', () {
      final model = SolunarModel.fromOpenMeteo(makeJson(moonset: null), date);
      expect(model.majorPeriods, isEmpty);
    });

    test('throws on empty time array', () {
      expect(
        () => SolunarModel.fromOpenMeteo({
          'daily': {
            'time': [],
            'sunrise': [],
            'sunset': [],
            'moonrise': [],
            'moonset': [],
            'moon_phase': [],
            'moon_illumination': [],
          },
        }, date),
        throwsException,
      );
    });
  });
}
