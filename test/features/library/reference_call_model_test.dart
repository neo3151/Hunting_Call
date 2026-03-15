import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/library/domain/reference_call_model.dart';

void main() {
  group('ReferenceCall', () {
    final sampleJson = {
      'id': 'elk_bugle',
      'animalName': 'Rocky Mountain Elk',
      'callType': 'Bugle',
      'category': 'Big Game',
      'difficulty': 'Pro',
      'description': 'The iconic bugle call.',
      'proTips': 'Use diaphragm pressure.',
      'idealPitchHz': 720.0,
      'idealDurationSec': 3.5,
      'audioAssetPath': 'audio/calls/elk_bugle.mp3',
      'diagnosticAudioAssetPath': 'audio/diag/elk_bugle.wav',
      'tolerancePitch': 60.0,
      'toleranceDuration': 1.0,
      'imageUrl': 'https://example.com/elk.jpg',
      'scientificName': 'Cervus canadensis',
      'isLocked': false,
      'isPulsedCall': false,
      'idealTempo': 0.0,
      'waveform': [0.0, 0.5, 1.0, 0.5, 0.0],
      'releaseVersion': '2.0.0',
    };

    test('fromJson creates correct model', () {
      final call = ReferenceCall.fromJson(sampleJson);
      expect(call.id, 'elk_bugle');
      expect(call.animalName, 'Rocky Mountain Elk');
      expect(call.callType, 'Bugle');
      expect(call.category, 'Big Game');
      expect(call.difficulty, 'Pro');
      expect(call.idealPitchHz, 720.0);
      expect(call.idealDurationSec, 3.5);
      expect(call.scientificName, 'Cervus canadensis');
      expect(call.isLocked, false);
      expect(call.waveform?.length, 5);
      expect(call.releaseVersion, '2.0.0');
    });

    test('fromJson handles minimal JSON with defaults', () {
      final minimal = {
        'id': 'test_call',
        'animalName': 'Test Animal',
        'idealPitchHz': 500,
        'idealDurationSec': 2,
        'audioAssetPath': 'audio/test.mp3',
      };
      final call = ReferenceCall.fromJson(minimal);
      expect(call.callType, 'Call');
      expect(call.category, 'General');
      expect(call.difficulty, 'Intermediate');
      expect(call.description, '');
      expect(call.tolerancePitch, 50.0);
      expect(call.toleranceDuration, 0.5);
      expect(call.isLocked, false);
      expect(call.isPulsedCall, false);
      expect(call.waveform, isNull);
      expect(call.releaseVersion, isNull);
    });

    test('toJson round-trips correctly', () {
      final original = ReferenceCall.fromJson(sampleJson);
      final json = original.toJson();
      expect(json['id'], 'elk_bugle');
      expect(json['animalName'], 'Rocky Mountain Elk');
      expect(json['idealPitchHz'], 720.0);
      expect(json['releaseVersion'], '2.0.0');
    });

    test('toJson excludes null optional fields', () {
      final call = ReferenceCall.fromJson({
        'id': 'test',
        'animalName': 'Test',
        'idealPitchHz': 500,
        'idealDurationSec': 2,
        'audioAssetPath': 'audio/test.mp3',
      });
      final json = call.toJson();
      expect(json.containsKey('diagnosticAudioAssetPath'), false);
      expect(json.containsKey('waveform'), false);
      expect(json.containsKey('spectrogram'), false);
      expect(json.containsKey('releaseVersion'), false);
    });

    test('copyWith preserves unchanged fields', () {
      final call = ReferenceCall.fromJson(sampleJson);
      final copy = call.copyWith(isLocked: true);
      expect(copy.isLocked, true);
      expect(copy.id, 'elk_bugle');
      expect(copy.animalName, 'Rocky Mountain Elk');
      expect(copy.idealPitchHz, 720.0);
    });

    test('copyWith can change id', () {
      final call = ReferenceCall.fromJson(sampleJson);
      final copy = call.copyWith(id: 'new_id');
      expect(copy.id, 'new_id');
    });

    test('handles integer values from JSON (num → double)', () {
      final intJson = {
        'id': 'test',
        'animalName': 'Test',
        'idealPitchHz': 500,
        'idealDurationSec': 2,
        'audioAssetPath': 'audio/test.mp3',
        'tolerancePitch': 30,
      };
      final call = ReferenceCall.fromJson(intJson);
      expect(call.idealPitchHz, 500.0);
      expect(call.tolerancePitch, 30.0);
    });

    test('handles spectrogram data', () {
      final withSpectro = Map<String, dynamic>.from(sampleJson)
        ..['spectrogram'] = [
          [0.1, 0.2, 0.3],
          [0.4, 0.5, 0.6],
        ];
      final call = ReferenceCall.fromJson(withSpectro);
      expect(call.spectrogram?.length, 2);
      expect(call.spectrogram?[0].length, 3);
    });

    test('pulsed call with tempo', () {
      final pulsed = Map<String, dynamic>.from(sampleJson)
        ..['isPulsedCall'] = true
        ..['idealTempo'] = 120.0;
      final call = ReferenceCall.fromJson(pulsed);
      expect(call.isPulsedCall, true);
      expect(call.idealTempo, 120.0);
    });
  });
}
