import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/analysis/domain/animal_archetype.dart';

void main() {
  group('AnimalArchetype', () {
    final sampleJson = {
      'callId': 'elk_bugle',
      'averagePitchHz': 720.0,
      'pitchTolerance': 50.0,
      'averageDurationSec': 3.5,
      'durationTolerance': 1.0,
      'harmonicsProfile': {'H2': 1.5, 'H3': 0.8},
      'mfccProfile': [0.1, 0.2, 0.3, 0.4],
      'isPulsed': true,
      'cadenceBreaks': [0.5, 1.0, 1.5],
      'averageWaveform': [0.0, 0.5, 1.0, 0.5, 0.0],
    };

    test('fromJson creates correct archetype', () {
      final arch = AnimalArchetype.fromJson(sampleJson);
      expect(arch.callId, 'elk_bugle');
      expect(arch.averagePitchHz, 720.0);
      expect(arch.pitchTolerance, 50.0);
      expect(arch.averageDurationSec, 3.5);
      expect(arch.durationTolerance, 1.0);
      expect(arch.isPulsed, true);
      expect(arch.cadenceBreaks.length, 3);
      expect(arch.mfccProfile.length, 4);
    });

    test('toJson round-trips correctly', () {
      final arch = AnimalArchetype.fromJson(sampleJson);
      final json = arch.toJson();
      expect(json['callId'], 'elk_bugle');
      expect(json['averagePitchHz'], 720.0);
      expect(json['isPulsed'], true);
      expect((json['harmonicsProfile'] as Map).length, 2);
    });

    test('fromJson → toJson → fromJson preserves data', () {
      final original = AnimalArchetype.fromJson(sampleJson);
      final roundTripped = AnimalArchetype.fromJson(original.toJson());
      expect(roundTripped, equals(original));
    });

    test('fromJson handles missing optional fields', () {
      final minimal = {
        'callId': 'duck_quack',
        'averagePitchHz': 500.0,
        'pitchTolerance': 30.0,
        'averageDurationSec': 1.0,
        'durationTolerance': 0.5,
      };
      final arch = AnimalArchetype.fromJson(minimal);
      expect(arch.harmonicsProfile, isEmpty);
      expect(arch.mfccProfile, isEmpty);
      expect(arch.isPulsed, false);
      expect(arch.cadenceBreaks, isEmpty);
      expect(arch.averageWaveform, isEmpty);
    });

    test('equality works via Equatable', () {
      final a = AnimalArchetype.fromJson(sampleJson);
      final b = AnimalArchetype.fromJson(sampleJson);
      expect(a, equals(b));
    });

    test('different callId makes them unequal', () {
      final modified = Map<String, dynamic>.from(sampleJson)..['callId'] = 'duck_quack';
      final a = AnimalArchetype.fromJson(sampleJson);
      final b = AnimalArchetype.fromJson(modified);
      expect(a, isNot(equals(b)));
    });

    test('handles integer values in JSON (num → double)', () {
      final intJson = {
        'callId': 'test',
        'averagePitchHz': 500,
        'pitchTolerance': 30,
        'averageDurationSec': 2,
        'durationTolerance': 1,
        'mfccProfile': [1, 2, 3],
      };
      final arch = AnimalArchetype.fromJson(intJson);
      expect(arch.averagePitchHz, 500.0);
      expect(arch.mfccProfile, [1.0, 2.0, 3.0]);
    });
  });
}
