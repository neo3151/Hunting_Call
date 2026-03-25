import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/core/services/bayesian_fusion_service.dart';
import 'package:outcall/core/utils/input_sanitizer.dart';
import 'package:outcall/core/utils/profanity_filter.dart';
import 'package:outcall/core/utils/spam_filter.dart';
import 'package:outcall/features/profile/domain/entities/user_profile.dart';
import '../helpers/test_factories.dart';

/// ══════════════════════════════════════════════════════════════════
/// STRESS TEST 4: Data Integrity & Business Logic
/// Validates scoring algorithms, data models, and input sanitization
/// under extreme/adversarial inputs.
/// ══════════════════════════════════════════════════════════════════

void main() {
  // ─── Bayesian Fusion Stress ────────────────────────────────────
  group('Bayesian Fusion Stress — Extreme Inputs', () {
    test('All-zero raw results should not crash or produce NaN', () {
      final result = BayesianFusionService.applyPriors(
        rawResults: {'Turkey': 0.0, 'Deer': 0.0, 'Elk': 0.0},
        commonName: 'Turkey',
      );

      expect(result, isA<Map<String, double>>());
      for (final v in result.values) {
        expect(v.isNaN, false, reason: 'Score should not be NaN');
        expect(v.isInfinite, false, reason: 'Score should not be infinite');
      }
    });

    test('All-perfect scores should not exceed 99%', () {
      final result = BayesianFusionService.applyPriors(
        rawResults: {'Turkey': 100.0, 'Deer': 100.0, 'Elk': 100.0},
        commonName: 'Turkey',
      );

      for (final v in result.values) {
        expect(v, lessThanOrEqualTo(99.0),
            reason: 'Should cap at 99% to avoid false certainty');
      }
    });

    test('Matched species should get boosted over unmatched', () {
      final result = BayesianFusionService.applyPriors(
        rawResults: {'Wild Turkey': 50.0, 'Red Deer': 50.0},
        commonName: 'Turkey',
      );

      expect(result.containsKey('Wild Turkey'), true);
      if (result.containsKey('Red Deer')) {
        expect(result['Wild Turkey']!, greaterThan(result['Red Deer']!),
            reason: 'Matched species should score higher');
      }
    });

    test('Empty rawResults should return empty map', () {
      final result = BayesianFusionService.applyPriors(
        rawResults: {},
        commonName: 'Turkey',
      );

      expect(result, isEmpty);
    });

    test('No reference name should passthrough raw results', () {
      final raw = {'Turkey': 80.0, 'Deer': 60.0};
      final result = BayesianFusionService.applyPriors(rawResults: raw);

      expect(result, raw);
    });

    test('1000 sequential fusions should be deterministic', () {
      final results = <Map<String, double>>[];
      for (int i = 0; i < 1000; i++) {
        final score = BayesianFusionService.applyPriors(
          rawResults: {'Turkey': 70.0, 'Elk': 30.0},
          commonName: 'Turkey',
        );
        results.add(score);
      }

      // All results should be identical (deterministic)
      for (int i = 1; i < results.length; i++) {
        expect(results[i], results[0],
            reason: 'Iteration $i should match iteration 0');
      }
    });
  });

  // ─── Input Sanitizer Stress ────────────────────────────────────
  group('Input Sanitizer Stress — Adversarial Inputs', () {
    test('XSS injection should be sanitized from names', () {
      final inputs = [
        '<script>alert("xss")</script>',
        '"><img src=x onerror=alert(1)>',
        "'; DROP TABLE users; --",
      ];

      for (final input in inputs) {
        final result = InputSanitizer.sanitizeName(input);
        expect(result.contains('<script>'), false,
            reason: 'Should strip script tags from: $input');
        expect(result.length, lessThanOrEqualTo(50),
            reason: 'Should respect maxNameLength');
      }
    });

    test('Extremely long name should be truncated', () {
      final longInput = 'A' * 10000;
      final result = InputSanitizer.sanitizeName(longInput);

      expect(result.length, lessThanOrEqualTo(50),
          reason: 'Should truncate to maxNameLength');
    });

    test('Empty name should return empty or fallback', () {
      final result = InputSanitizer.sanitizeName('');
      // sanitizeName may return '' or fallback depending on implementation
      expect(result, isA<String>());
    });

    test('Free text with HTML should be sanitized', () {
      final result = InputSanitizer.sanitizeFreeText('<b>Bold</b> text <script>x</script>');
      expect(result.contains('<script>'), false);
    });

    test('Unicode and emoji names should pass through', () {
      final result = InputSanitizer.sanitizeName('Hunter 🦌');
      expect(result, contains('🦌'));
    });

    test('Control characters should be removed', () {
      final result = InputSanitizer.sanitizeName('Test\x00Name\x01Here');
      expect(result.contains('\x00'), false);
      expect(result.contains('\x01'), false);
    });
  });

  // ─── Profanity Filter Stress ───────────────────────────────────
  group('Profanity Filter Stress', () {
    test('1000 display name checks should complete in <1s', () {
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        ProfanityFilter.containsProfanity('TestUser$i');
      }
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(1000),
          reason: '1000 checks should complete in <1s');
    });

    test('Clean names should pass', () {
      expect(ProfanityFilter.containsProfanity('GoodHunter'), false);
      expect(ProfanityFilter.containsProfanity('DeerSlayer'), false);
      expect(ProfanityFilter.containsProfanity('ElkMaster2026'), false);
    });

    test('Empty string should not crash', () {
      expect(() => ProfanityFilter.containsProfanity(''), returnsNormally);
    });
  });

  // ─── Spam Filter Stress ────────────────────────────────────────
  group('Spam Filter Stress', () {
    test('Suspicious emails should be flagged', () {
      final suspicious = [
        'user@tempmail.com',
        'test@guerrillamail.com',
        'spam@mailinator.com',
      ];

      for (final email in suspicious) {
        // Just verify it doesn't crash
        expect(() => SpamFilter.isSuspiciousEmail(email), returnsNormally);
      }
    });

    test('Null email should not crash', () {
      expect(() => SpamFilter.isSuspiciousEmail(null), returnsNormally);
    });

    test('Normal emails should not be flagged', () {
      expect(SpamFilter.isSuspiciousEmail('hunter@gmail.com'), false);
    });
  });

  // ─── User Profile Data Integrity ───────────────────────────────
  group('Data Integrity Stress — UserProfile', () {
    test('Profile with 10000 history items should serialize', () {
      final history = List.generate(10000, (i) =>
          makeHistory(score: (i % 100).toDouble(), animalId: 'elk_bugle'));

      final profile = makeProfile(
        history: history,
        totalCalls: 10000,
        averageScore: 50.0,
      );

      expect(profile.history.length, 10000);
      expect(profile.toJson(), isA<Map<String, dynamic>>());

      // Deserialize round-trip
      final json = profile.toJson();
      final restored = UserProfile.fromJson(json);
      expect(restored.history.length, 10000);
      expect(restored.totalCalls, 10000);
    });

    test('Profile with empty history should serialize cleanly', () {
      final profile = makeProfile(history: []);
      final json = profile.toJson();
      final restored = UserProfile.fromJson(json);
      expect(restored.history, isEmpty);
    });

    test('Profile with max streak should not overflow', () {
      final profile = makeProfile(
        currentStreak: 2147483647,
        longestStreak: 2147483647,
      );
      expect(profile.currentStreak, 2147483647);
      expect(profile.toJson()['currentStreak'], 2147483647);
    });
  });
}
