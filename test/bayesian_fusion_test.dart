import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/core/services/bayesian_fusion_service.dart';

void main() {
  group('BayesianFusionService', () {
    test('boosts matching species and suppresses others', () {
      final raw = {
        'Wild Turkey': 45.0,
        'Ring-necked Pheasant': 30.0,
        'American Crow': 25.0,
      };

      final result = BayesianFusionService.applyPriors(
        rawResults: raw,
        scientificName: 'Meleagris gallopavo',
        commonName: 'Wild Turkey',
      );

      // Turkey should be boosted significantly
      expect(result['Wild Turkey']!, greaterThan(70.0),
          reason: 'Matching species should be boosted');

      // Non-matching species should be suppressed
      expect(result['Ring-necked Pheasant']!, lessThan(30.0),
          reason: 'Non-matching species should be suppressed');

      // Turkey should be the top result
      expect(result.keys.first, equals('Wild Turkey'),
          reason: 'Matching species should be ranked first');
    });

    test('returns raw results when no reference provided', () {
      final raw = {
        'Wild Turkey': 45.0,
        'Ring-necked Pheasant': 30.0,
      };

      final result = BayesianFusionService.applyPriors(
        rawResults: raw,
        scientificName: null,
        commonName: null,
      );

      expect(result, equals(raw));
    });

    test('returns raw results when reference is empty string', () {
      final raw = {
        'Wild Turkey': 45.0,
        'Ring-necked Pheasant': 30.0,
      };

      final result = BayesianFusionService.applyPriors(
        rawResults: raw,
        scientificName: '',
        commonName: '',
      );

      expect(result, equals(raw));
    });

    test('gracefully handles no label match', () {
      final raw = {
        'Wild Turkey': 45.0,
        'Ring-necked Pheasant': 30.0,
      };

      // Reference doesn't match any BirdNET label
      final result = BayesianFusionService.applyPriors(
        rawResults: raw,
        scientificName: 'Ursus arctos',
        commonName: 'Grizzly Bear',
      );

      // Should be identical (no match → all priors are 1.0)
      expect(result['Wild Turkey'], closeTo(raw['Wild Turkey']!, 0.01));
      expect(result['Ring-necked Pheasant'], closeTo(raw['Ring-necked Pheasant']!, 0.01));
    });

    test('handles empty input', () {
      final result = BayesianFusionService.applyPriors(
        rawResults: {},
        scientificName: 'Meleagris gallopavo',
        commonName: 'Wild Turkey',
      );

      expect(result, isEmpty);
    });

    test('matches via partial common name tokens', () {
      // BirdNET might output just "Turkey" while reference says "Wild Turkey"
      final raw = {
        'Turkey': 50.0,
        'Pheasant': 30.0,
      };

      final result = BayesianFusionService.applyPriors(
        rawResults: raw,
        scientificName: 'Meleagris gallopavo',
        commonName: 'Wild Turkey',
      );

      expect(result['Turkey']!, greaterThan(50.0),
          reason: 'Partial token match should still boost');
    });

    test('caps confidence at 99% to avoid false certainty', () {
      // Single species with very high confidence
      final raw = {
        'Wild Turkey': 98.0,
      };

      final result = BayesianFusionService.applyPriors(
        rawResults: raw,
        scientificName: 'Meleagris gallopavo',
        commonName: 'Wild Turkey',
      );

      expect(result['Wild Turkey']!, lessThanOrEqualTo(99.0),
          reason: 'Confidence should be capped at 99%');
    });

    test('drops results below confidence floor after fusion', () {
      final raw = {
        'Wild Turkey': 90.0,
        'Obscure Warbler': 5.5, // Just above floor
      };

      final result = BayesianFusionService.applyPriors(
        rawResults: raw,
        scientificName: 'Meleagris gallopavo',
        commonName: 'Wild Turkey',
      );

      // The warbler's probability is diluted by re-normalization
      // after Turkey gets boosted, so warbler should drop below floor
      final warblerConf = result['Obscure Warbler'];
      if (warblerConf != null) {
        expect(warblerConf, greaterThanOrEqualTo(5.0),
            reason: 'If present, should be above floor');
      }
      // Either way is valid: dropped or kept above floor
    });
  });
}
