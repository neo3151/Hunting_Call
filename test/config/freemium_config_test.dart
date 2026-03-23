import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/config/freemium_config.dart';

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
      expect(FreemiumConfig.freeCallIds, contains('duck_wood_duck_whistle'));
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
      expect(FreemiumConfig.freeCallIds, contains('crow_caw'));
      expect(FreemiumConfig.freeCallIds, contains('dove_coo'));
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
}
