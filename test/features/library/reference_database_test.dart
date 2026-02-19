import 'package:flutter_test/flutter_test.dart';
import 'package:hunting_calls_perfection/features/library/domain/reference_call_model.dart';
import 'package:hunting_calls_perfection/features/library/data/reference_database.dart';

void main() {
  group('ReferenceCall Model', () {
    test('fromJson parses minimal valid JSON', () {
      final json = {
        'id': 'test_call_1',
        'animalName': 'Mallard Duck',
        'callType': 'Greeting',
        'category': 'Waterfowl',
        'difficulty': 'Easy',
        'idealPitchHz': 1200.0,
        'idealDurationSec': 1.5,
        'audioAssetPath': 'assets/audio/mallard_greeting.mp3',
      };

      final call = ReferenceCall.fromJson(json);

      expect(call.id, 'test_call_1');
      expect(call.animalName, 'Mallard Duck');
      expect(call.callType, 'Greeting');
      expect(call.category, 'Waterfowl');
      expect(call.difficulty, 'Easy');
      expect(call.idealPitchHz, 1200.0);
      expect(call.idealDurationSec, 1.5);
      expect(call.audioAssetPath, 'assets/audio/mallard_greeting.mp3');
    });

    test('fromJson applies defaults for optional fields', () {
      final json = {
        'id': 'test_call_2',
        'animalName': 'Elk',
        'idealPitchHz': 400,
        'idealDurationSec': 3,
        'audioAssetPath': 'assets/audio/elk_bugle.mp3',
      };

      final call = ReferenceCall.fromJson(json);

      expect(call.callType, 'Call');
      expect(call.category, 'General');
      expect(call.difficulty, 'Intermediate');
      expect(call.description, '');
      expect(call.proTips, '');
      expect(call.tolerancePitch, 50.0);
      expect(call.toleranceDuration, 0.5);
      expect(call.isLocked, false);
      expect(call.isPulsedCall, false);
      expect(call.idealTempo, 0.0);
      expect(call.waveform, isNull);
      expect(call.spectrogram, isNull);
    });

    test('fromJson parses waveform data', () {
      final json = {
        'id': 'test_waveform',
        'animalName': 'Test',
        'idealPitchHz': 500,
        'idealDurationSec': 1,
        'audioAssetPath': 'test.mp3',
        'waveform': [0.1, 0.5, 0.9, 0.3, 0.0],
      };

      final call = ReferenceCall.fromJson(json);

      expect(call.waveform, isNotNull);
      expect(call.waveform!.length, 5);
      expect(call.waveform![0], 0.1);
      expect(call.waveform![2], 0.9);
    });

    test('fromJson parses spectrogram data', () {
      final json = {
        'id': 'test_spectrogram',
        'animalName': 'Test',
        'idealPitchHz': 500,
        'idealDurationSec': 1,
        'audioAssetPath': 'test.mp3',
        'spectrogram': [
          [0.1, 0.2, 0.3],
          [0.4, 0.5, 0.6],
        ],
      };

      final call = ReferenceCall.fromJson(json);

      expect(call.spectrogram, isNotNull);
      expect(call.spectrogram!.length, 2);
      expect(call.spectrogram![0].length, 3);
      expect(call.spectrogram![1][2], 0.6);
    });

    test('toJson produces valid JSON', () {
      const call = ReferenceCall(
        id: 'test_json',
        animalName: 'Turkey',
        callType: 'Yelp',
        category: 'Upland',
        difficulty: 'Pro',
        idealPitchHz: 800.0,
        idealDurationSec: 2.0,
        audioAssetPath: 'test.mp3',
      );

      final json = call.toJson();

      expect(json['id'], 'test_json');
      expect(json['animalName'], 'Turkey');
      expect(json['callType'], 'Yelp');
      expect(json['idealPitchHz'], 800.0);
      // Waveform/spectrogram should be absent when null
      expect(json.containsKey('waveform'), isFalse);
      expect(json.containsKey('spectrogram'), isFalse);
    });

    test('toJson includes waveform when present', () {
      const call = ReferenceCall(
        id: 'test',
        animalName: 'Duck',
        callType: 'Call',
        category: 'Waterfowl',
        difficulty: 'Easy',
        idealPitchHz: 1000,
        idealDurationSec: 1,
        audioAssetPath: 'test.mp3',
        waveform: [0.1, 0.2, 0.3],
      );

      final json = call.toJson();
      expect(json.containsKey('waveform'), isTrue);
      expect((json['waveform'] as List).length, 3);
    });

    test('JSON round-trip preserves data', () {
      const original = ReferenceCall(
        id: 'roundtrip',
        animalName: 'Coyote',
        callType: 'Howl',
        category: 'Predator',
        difficulty: 'Intermediate',
        idealPitchHz: 600.0,
        idealDurationSec: 4.0,
        audioAssetPath: 'coyote.mp3',
        isPulsedCall: true,
        idealTempo: 30.0,
        waveform: [0.1, 0.5, 0.9],
      );

      final json = original.toJson();
      final restored = ReferenceCall.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.animalName, original.animalName);
      expect(restored.idealPitchHz, original.idealPitchHz);
      expect(restored.isPulsedCall, original.isPulsedCall);
      expect(restored.idealTempo, original.idealTempo);
      expect(restored.waveform, original.waveform);
    });

    test('copyWith creates modified copy', () {
      const original = ReferenceCall(
        id: 'copy_test',
        animalName: 'Deer',
        callType: 'Grunt',
        category: 'Big Game',
        difficulty: 'Easy',
        idealPitchHz: 200.0,
        idealDurationSec: 1.0,
        audioAssetPath: 'deer.mp3',
      );

      final modified = original.copyWith(
        difficulty: 'Pro',
        isLocked: true,
      );

      expect(modified.id, 'copy_test'); // unchanged
      expect(modified.animalName, 'Deer'); // unchanged
      expect(modified.difficulty, 'Pro'); // changed
      expect(modified.isLocked, true); // changed
    });
  });

  group('ReferenceDatabase', () {
    test('getById returns call with matching ID when populated', () {
      // Use the @visibleForTesting setter
      ReferenceDatabase.calls = [
        const ReferenceCall(
          id: 'duck_mallard_greeting',
          animalName: 'Mallard Duck',
          callType: 'Greeting',
          category: 'Waterfowl',
          difficulty: 'Easy',
          idealPitchHz: 1200.0,
          idealDurationSec: 1.5,
          audioAssetPath: 'assets/audio/duck_mallard_greeting.mp3',
        ),
        const ReferenceCall(
          id: 'elk_bugle',
          animalName: 'Elk',
          callType: 'Bugle',
          category: 'Big Game',
          difficulty: 'Pro',
          idealPitchHz: 400.0,
          idealDurationSec: 5.0,
          audioAssetPath: 'assets/audio/elk_bugle.mp3',
        ),
      ];

      final duck = ReferenceDatabase.getById('duck_mallard_greeting');
      expect(duck.animalName, 'Mallard Duck');
      expect(duck.callType, 'Greeting');

      final elk = ReferenceDatabase.getById('elk_bugle');
      expect(elk.animalName, 'Elk');
      expect(elk.callType, 'Bugle');
    });

    test('getById returns first call for unknown ID', () {
      ReferenceDatabase.calls = [
        const ReferenceCall(
          id: 'first',
          animalName: 'First Call',
          callType: 'Test',
          category: 'Test',
          difficulty: 'Easy',
          idealPitchHz: 100,
          idealDurationSec: 1,
          audioAssetPath: 'test.mp3',
        ),
      ];

      final result = ReferenceDatabase.getById('nonexistent_id');
      expect(result.id, 'first');
    });

    test('isLocked returns false for premium users', () {
      expect(ReferenceDatabase.isLocked('any_call_id', true), isFalse);
    });

    test('calls list is accessible after setting', () {
      ReferenceDatabase.calls = [
        const ReferenceCall(
          id: 'test1',
          animalName: 'Test',
          callType: 'Call',
          category: 'General',
          difficulty: 'Easy',
          idealPitchHz: 100,
          idealDurationSec: 1,
          audioAssetPath: 'test.mp3',
        ),
        const ReferenceCall(
          id: 'test2',
          animalName: 'Test2',
          callType: 'Call',
          category: 'General',
          difficulty: 'Easy',
          idealPitchHz: 200,
          idealDurationSec: 2,
          audioAssetPath: 'test2.mp3',
        ),
      ];

      expect(ReferenceDatabase.calls.length, 2);
    });
  });
}
