import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/core/services/bayesian_fusion_service.dart';

void main() {
  group('BayesianFusionService.applyPriors', () {
    test('empty rawResults returns empty', () {
      final result = BayesianFusionService.applyPriors(
        rawResults: {},
        scientificName: 'Meleagris gallopavo',
        commonName: 'Wild Turkey',
      );
      expect(result, isEmpty);
    });

    test('null context returns rawResults unchanged', () {
      final raw = {'Wild Turkey': 80.0, 'Red Junglefowl': 20.0};
      final result = BayesianFusionService.applyPriors(
        rawResults: raw,
        scientificName: null,
        commonName: null,
      );
      expect(result, equals(raw));
    });

    test('empty string context returns rawResults unchanged', () {
      final raw = {'Wild Turkey': 80.0, 'Red Junglefowl': 20.0};
      final result = BayesianFusionService.applyPriors(
        rawResults: raw,
        scientificName: '',
        commonName: '',
      );
      expect(result, equals(raw));
    });

    test('matching species gets boosted', () {
      final raw = {'Wild Turkey': 50.0, 'Crow': 50.0};
      final result = BayesianFusionService.applyPriors(
        rawResults: raw,
        commonName: 'Wild Turkey',
      );
      // Wild Turkey should be higher after boost
      expect(result['Wild Turkey']!, greaterThan(result['Crow']!));
    });

    test('non-matching species gets suppressed relatively', () {
      final raw = {'Wild Turkey': 60.0, 'Mallard': 40.0};
      final result = BayesianFusionService.applyPriors(
        rawResults: raw,
        commonName: 'Wild Turkey',
      );
      // Mallard's relative share should decrease
      const originalRatio = 40.0 / 60.0;
      final newRatio = result['Mallard']! / result['Wild Turkey']!;
      expect(newRatio, lessThan(originalRatio));
    });

    test('results are capped at 99%', () {
      final raw = {'Wild Turkey': 95.0, 'Other': 5.0};
      final result = BayesianFusionService.applyPriors(
        rawResults: raw,
        commonName: 'Wild Turkey',
      );
      expect(result['Wild Turkey']!, lessThanOrEqualTo(99.0));
    });

    test('results below confidence floor (5%) are dropped', () {
      final raw = {'Wild Turkey': 95.0, 'Rare Bird': 2.0, 'Ultra Rare': 1.0};
      final result = BayesianFusionService.applyPriors(
        rawResults: raw,
        commonName: 'Wild Turkey',
      );
      // The tiny values should get further suppressed and dropped
      // Wild Turkey gets the boost, so tiny values shrink even more
      for (final v in result.values) {
        expect(v, greaterThanOrEqualTo(5.0));
      }
    });

    test('scientific name matching works', () {
      final raw = {'Meleagris gallopavo_Wild Turkey': 50.0, 'Unknown': 50.0};
      final result = BayesianFusionService.applyPriors(
        rawResults: raw,
        scientificName: 'Meleagris gallopavo',
        commonName: 'Wild Turkey',
      );
      expect(result.keys.first, contains('Turkey'));
    });

    test('partial token matching works (e.g. "Turkey" in "Wild Turkey")', () {
      final raw = {'Turkey Hen': 40.0, 'Crow': 60.0};
      final result = BayesianFusionService.applyPriors(
        rawResults: raw,
        commonName: 'Wild Turkey',
      );
      // "Turkey" token (>= 4 chars) from "Wild Turkey" should match "Turkey Hen"
      expect(result['Turkey Hen']!, greaterThan(result['Crow']!));
    });

    test('results are sorted descending by confidence', () {
      final raw = {'A': 30.0, 'B': 70.0, 'C': 50.0};
      final result = BayesianFusionService.applyPriors(
        rawResults: raw,
        commonName: 'B',
      );
      final values = result.values.toList();
      for (int i = 1; i < values.length; i++) {
        expect(values[i - 1], greaterThanOrEqualTo(values[i]));
      }
    });

    test('single result returns correct value', () {
      final raw = {'Wild Turkey': 85.0};
      final result = BayesianFusionService.applyPriors(
        rawResults: raw,
        commonName: 'Wild Turkey',
      );
      expect(result.length, 1);
      expect(result['Wild Turkey'], isNotNull);
    });

    test('all zero confidences return rawResults', () {
      final raw = {'A': 0.0, 'B': 0.0};
      final result = BayesianFusionService.applyPriors(
        rawResults: raw,
        commonName: 'A',
      );
      // posteriorSum = 0, so returns rawResults unchanged
      expect(result, equals(raw));
    });
  });
}
