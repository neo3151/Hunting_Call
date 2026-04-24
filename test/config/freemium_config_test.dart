import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/config/app_config.dart';
import 'package:outcall/config/freemium_config.dart';
import 'package:outcall/features/library/data/reference_database.dart';

void main() {
  group('FreemiumConfig', () {
    test('has exactly 16 free call IDs', () {
      expect(FreemiumConfig.freeCallIds.length, 16);
    });

    test('all IDs are non-empty strings', () {
      for (final id in FreemiumConfig.freeCallIds) {
        expect(id.isNotEmpty, true, reason: 'Found empty free call ID');
        expect(id.trim(), id, reason: 'ID "$id" has leading/trailing whitespace');
      }
    });

    test('no duplicate IDs (Set guarantees this, but verify)', () {
      final asList = FreemiumConfig.freeCallIds.toList();
      expect(asList.toSet().length, asList.length);
    });

    test('contains essential waterfowl calls', () {
      expect(FreemiumConfig.freeCallIds, contains('duck_mallard_greeting'));
      expect(FreemiumConfig.freeCallIds, contains('goose_canadian_honk'));
      expect(FreemiumConfig.freeCallIds, contains('wood_duck'));
    });

    test('contains essential big game calls', () {
      expect(FreemiumConfig.freeCallIds, contains('deer_buck_grunt'));
      expect(FreemiumConfig.freeCallIds, contains('deer_doe_bleat'));
    });

    test('contains essential predator calls', () {
      expect(FreemiumConfig.freeCallIds, contains('coyote_howl'));
      expect(FreemiumConfig.freeCallIds, contains('rabbit_distress'));
      expect(FreemiumConfig.freeCallIds, contains('red_fox_scream'));
    });

    test('contains essential land bird calls', () {
      expect(FreemiumConfig.freeCallIds, contains('turkey_gobble'));
      expect(FreemiumConfig.freeCallIds, contains('crow'));
      expect(FreemiumConfig.freeCallIds, contains('dove'));
      expect(FreemiumConfig.freeCallIds, contains('owl_barred_hoot'));
    });

    test('IDs follow snake_case naming convention', () {
      final snakeCasePattern = RegExp(r'^[a-z][a-z0-9_]*$');
      for (final id in FreemiumConfig.freeCallIds) {
        expect(snakeCasePattern.hasMatch(id), true,
            reason: 'ID "$id" does not follow snake_case convention');
      }
    });

    test('premium call IDs are NOT in the free set', () {
      // These are known premium-only calls
      expect(FreemiumConfig.freeCallIds.contains('elk_bugle'), false);
      expect(FreemiumConfig.freeCallIds.contains('wolf_howl'), false);
      expect(FreemiumConfig.freeCallIds.contains('bobcat_growl'), false);
    });
  });

  group('ReferenceDatabase.isLocked tests', () {
    test('Premium user has everything unlocked, even in Free app flavor', () {
      AppConfig.create(flavor: AppFlavor.free, appName: 'Test Free');
      
      expect(ReferenceDatabase.isLocked('premium_call_dummy', true), false);
      expect(ReferenceDatabase.isLocked('duck_mallard_greeting', true), false);
    });

    test('Paid App Flavor (Full) has everything unlocked for non-premium user', () {
      AppConfig.create(flavor: AppFlavor.full, appName: 'Test Full');
      
      expect(ReferenceDatabase.isLocked('premium_call_dummy', false), false);
      expect(ReferenceDatabase.isLocked('duck_mallard_greeting', false), false);
    });

    test('Free App Flavor locks premium calls for non-premium users', () {
      AppConfig.create(flavor: AppFlavor.free, appName: 'Test Free');
      
      const premiumCallId = 'premium_call_dummy';
      expect(FreemiumConfig.freeCallIds.contains(premiumCallId), false);
      expect(ReferenceDatabase.isLocked(premiumCallId, false), true);
    });

    test('Free App Flavor unlocks free calls for non-premium users', () {
      AppConfig.create(flavor: AppFlavor.free, appName: 'Test Free');
      
      const freeCallId = 'duck_mallard_greeting';
      expect(FreemiumConfig.freeCallIds.contains(freeCallId), true);
      expect(ReferenceDatabase.isLocked(freeCallId, false), false);
    });
  });
}
