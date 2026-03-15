import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/config/app_config.dart';
import 'package:outcall/config/freemium_config.dart';
import 'package:outcall/features/library/data/reference_database.dart';
import 'package:outcall/features/library/domain/reference_call_model.dart';

void main() {
  setUp(() {
    // Seed ReferenceDatabase with test data
    ReferenceDatabase.calls = [
      const ReferenceCall(
        id: 'elk_bugle',
        animalName: 'Elk',
        callType: 'Bugle',
        category: 'Big Game',
        difficulty: 'Pro',
        idealPitchHz: 720.0,
        idealDurationSec: 3.5,
        audioAssetPath: 'audio/elk.mp3',
      ),
      const ReferenceCall(
        id: 'duck_quack',
        animalName: 'Duck',
        callType: 'Quack',
        category: 'Waterfowl',
        difficulty: 'Easy',
        idealPitchHz: 500.0,
        idealDurationSec: 1.5,
        audioAssetPath: 'audio/duck.mp3',
      ),
    ];
  });

  group('ReferenceDatabase.isLocked', () {
    test('premium user unlocks everything', () {
      AppConfig.create(flavor: AppFlavor.free, appName: 'Free');
      expect(ReferenceDatabase.isLocked('any_random_call', true), false);
    });

    test('full flavor unlocks everything', () {
      AppConfig.create(flavor: AppFlavor.full, appName: 'Full');
      expect(ReferenceDatabase.isLocked('any_random_call', false), false);
    });

    test('free user, free flavor: free call is unlocked', () {
      AppConfig.create(flavor: AppFlavor.free, appName: 'Free');
      // Pick a call that IS in FreemiumConfig.freeCallIds
      final freeId = FreemiumConfig.freeCallIds.first;
      expect(ReferenceDatabase.isLocked(freeId, false), false);
    });

    test('free user, free flavor: premium call is locked', () {
      AppConfig.create(flavor: AppFlavor.free, appName: 'Free');
      expect(ReferenceDatabase.isLocked('super_premium_call_xyz', false), true);
    });
  });

  group('ReferenceDatabase.getById', () {
    test('returns correct call by id', () {
      final call = ReferenceDatabase.getById('elk_bugle');
      expect(call.id, 'elk_bugle');
      expect(call.animalName, 'Elk');
    });

    test('returns first call as fallback for unknown id', () {
      final call = ReferenceDatabase.getById('nonexistent');
      expect(call, isNotNull);
      expect(call.id, 'elk_bugle'); // falls back to first
    });
  });

  group('ReferenceDatabase.getArchetype', () {
    test('returns null when no archetypes loaded', () {
      final archetype = ReferenceDatabase.getArchetype('elk_bugle');
      expect(archetype, isNull);
    });
  });
}
