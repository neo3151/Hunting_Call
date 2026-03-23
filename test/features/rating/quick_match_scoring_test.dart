import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/rating/data/fingerprint_service.dart';

void main() {
  double score({
    double birdnet = 50,
    double pitch = 50,
    double quality = 50,
    double clarity = 50,
  }) =>
      FingerprintService.computeScore(
        birdnetConfidence: birdnet,
        pitchScore: pitch,
        callQuality: quality,
        toneClarity: clarity,
      );

  group('Quick Match Scoring — Sigmoid Contrast Curve', () {
    test('all-50 inputs → exactly 50%', () {
      final s = score();
      expect(s, closeTo(50.0, 0.1));
    });

    test('all-zero → well below 20%', () {
      final s = score(birdnet: 0, pitch: 0, quality: 0, clarity: 0);
      expect(s, lessThan(20));
    });

    test('all-100 → above 95%', () {
      final s = score(birdnet: 100, pitch: 100, quality: 100, clarity: 100);
      expect(s, greaterThan(95));
    });

    test('scores are monotonically increasing', () {
      // As all components increase uniformly, score should always increase
      double prev = 0;
      for (int v = 0; v <= 100; v += 5) {
        final s = score(
          birdnet: v.toDouble(),
          pitch: v.toDouble(),
          quality: v.toDouble(),
          clarity: v.toDouble(),
        );
        expect(s, greaterThanOrEqualTo(prev),
            reason: 'Score should increase as inputs increase (v=$v)');
        prev = s;
      }
    });

    test('sigmoid pushes low scores lower than linear', () {
      // With all inputs at 30, linear would give 30, sigmoid should give ~17
      final s = score(birdnet: 30, pitch: 30, quality: 30, clarity: 30);
      expect(s, lessThan(25),
          reason: 'Sigmoid should push 30 raw well below 25');
    });

    test('sigmoid pushes high scores higher than linear', () {
      // With all inputs at 70, linear would give 70, sigmoid should give ~83
      final s = score(birdnet: 70, pitch: 70, quality: 70, clarity: 70);
      expect(s, greaterThan(75),
          reason: 'Sigmoid should push 70 raw well above 75');
    });

    test('symmetry around 50%', () {
      // Score at 50+Δ and 50-Δ should be equidistant from 50
      final high = score(birdnet: 70, pitch: 70, quality: 70, clarity: 70);
      final low = score(birdnet: 30, pitch: 30, quality: 30, clarity: 30);
      final distHigh = (high - 50).abs();
      final distLow = (50 - low).abs();
      expect(distHigh, closeTo(distLow, 1.0),
          reason: 'Sigmoid should be roughly symmetric around 50');
    });
  });

  group('Quick Match Scoring — Realistic Scenarios', () {
    test('terrible call: noise only, no species match', () {
      // BirdNET 0%, pitchScore defaults to 25 (no match), low quality, low clarity
      final s = score(birdnet: 0, pitch: 25, quality: 15, clarity: 5);
      expect(s, lessThan(25),
          reason: 'Random noise should score below 25%');
    });

    test('poor call: weak species match, bad pitch', () {
      // BirdNET gives 20%, pitch way off, mediocre quality
      final s = score(birdnet: 20, pitch: 30, quality: 40, clarity: 30);
      expect(s, inInclusiveRange(10, 30),
          reason: 'Poor call should be in 10-30% range');
    });

    test('average call: decent species identification', () {
      // BirdNET 50%, pitch okay, decent quality
      final s = score(birdnet: 50, pitch: 50, quality: 50, clarity: 50);
      expect(s, inInclusiveRange(45, 55),
          reason: 'Average call should be around 50%');
    });

    test('good call: solid species match, good pitch', () {
      // BirdNET 65%, good pitch, good quality
      final s = score(birdnet: 65, pitch: 70, quality: 60, clarity: 70);
      expect(s, inInclusiveRange(65, 85),
          reason: 'Good call should be in 65-85% range');
    });

    test('great call: strong BirdNET, very close pitch', () {
      // BirdNET 80%, near-perfect pitch, good conditions
      final s = score(birdnet: 80, pitch: 85, quality: 70, clarity: 80);
      expect(s, greaterThan(85),
          reason: 'Great call should score above 85%');
    });

    test('expert call: near-perfect everything', () {
      // BirdNET 90%, pitch 95%, clean recording
      final s = score(birdnet: 90, pitch: 95, quality: 85, clarity: 90);
      expect(s, greaterThan(93),
          reason: 'Expert call should score above 93%');
    });
  });

  group('Quick Match Scoring — Weight Sensitivity', () {
    test('BirdNET heavily influences score (35% weight)', () {
      final low = score(birdnet: 20, pitch: 50, quality: 50, clarity: 50);
      final high = score(birdnet: 80, pitch: 50, quality: 50, clarity: 50);
      expect(high - low, greaterThan(20),
          reason: 'BirdNET swing 20→80 should move score 20+ points');
    });

    test('pitch heavily influences score (35% weight)', () {
      final low = score(birdnet: 50, pitch: 20, quality: 50, clarity: 50);
      final high = score(birdnet: 50, pitch: 80, quality: 50, clarity: 50);
      expect(high - low, greaterThan(20),
          reason: 'Pitch swing 20→80 should move score 20+ points');
    });

    test('quality has moderate influence (15% weight)', () {
      final low = score(birdnet: 50, pitch: 50, quality: 0, clarity: 50);
      final high = score(birdnet: 50, pitch: 50, quality: 100, clarity: 50);
      expect(high - low, greaterThan(5),
          reason: 'Quality 0→100 should move score at least 5 points');
      expect(high - low, lessThan(35),
          reason: 'Quality alone should not dominate the score');
    });

    test('clarity has moderate influence (15% weight)', () {
      final low = score(birdnet: 50, pitch: 50, quality: 50, clarity: 0);
      final high = score(birdnet: 50, pitch: 50, quality: 50, clarity: 100);
      expect(high - low, greaterThan(5),
          reason: 'Clarity 0→100 should move score at least 5 points');
      expect(high - low, lessThan(35),
          reason: 'Clarity alone should not dominate the score');
    });
  });

  group('Quick Match Scoring — Edge Cases', () {
    test('negative inputs are clamped to 0', () {
      final s = score(birdnet: -50, pitch: -100, quality: -20, clarity: -30);
      expect(s, greaterThanOrEqualTo(0));
      expect(s, lessThan(20));
    });

    test('inputs above 100 are clamped', () {
      final s = score(birdnet: 200, pitch: 150, quality: 300, clarity: 250);
      final perfect = score(birdnet: 100, pitch: 100, quality: 100, clarity: 100);
      expect(s, closeTo(perfect, 0.01),
          reason: 'Over-100 inputs should clamp to same as all-100');
    });

    test('score never exceeds 100', () {
      final s = score(birdnet: 100, pitch: 100, quality: 100, clarity: 100);
      expect(s, lessThanOrEqualTo(100.0));
    });

    test('score is never negative', () {
      final s = score(birdnet: 0, pitch: 0, quality: 0, clarity: 0);
      expect(s, greaterThanOrEqualTo(0.0));
    });
  });

  group('Quick Match Scoring — Discrimination', () {
    test('poor vs good calls have at least 30pt gap', () {
      final poor = score(birdnet: 15, pitch: 25, quality: 20, clarity: 10);
      final good = score(birdnet: 70, pitch: 75, quality: 65, clarity: 70);
      expect(good - poor, greaterThan(30),
          reason: 'Good calls should be clearly separated from poor ones');
    });

    test('average vs expert calls have at least 25pt gap', () {
      final avg = score(birdnet: 45, pitch: 50, quality: 45, clarity: 50);
      final expert = score(birdnet: 90, pitch: 92, quality: 80, clarity: 85);
      expect(expert - avg, greaterThan(25),
          reason: 'Expert calls should be clearly above average');
    });

    test('no two quality tiers produce the same score', () {
      final terrible = score(birdnet: 5, pitch: 10, quality: 10, clarity: 5);
      final poor = score(birdnet: 25, pitch: 30, quality: 30, clarity: 25);
      final avg = score(birdnet: 50, pitch: 50, quality: 50, clarity: 50);
      final good = score(birdnet: 70, pitch: 70, quality: 65, clarity: 70);
      final great = score(birdnet: 85, pitch: 88, quality: 75, clarity: 80);

      expect(terrible, lessThan(poor));
      expect(poor, lessThan(avg));
      expect(avg, lessThan(good));
      expect(good, lessThan(great));
    });
  });

  group('FingerprintResult', () {
    test('empty result has no match', () {
      final r = FingerprintResult.empty();
      expect(r.hasMatch, false);
      expect(r.matchLabel, 'No Match');
    });

    test('result with clipId and score > 0 has match', () {
      const r = FingerprintResult(
        clipId: 'test_123',
        animal: 'turkey',
        callType: 'yelp',
        score: 72.5,
      );
      expect(r.hasMatch, true);
      expect(r.matchLabel, 'Turkey Yelp');
    });

    test('fromJson parses correctly', () {
      final r = FingerprintResult.fromJson({
        'best_match': {
          'clip_id': 'elk_bugle_01',
          'animal': 'elk',
          'call_type': 'bugle',
          'score': 85.3,
          'matched_hashes': 5,
          'time_offset_ms': 120.0,
        },
        'elapsed_ms': 340.0,
        'total_user_hashes': 1,
      });
      expect(r.clipId, 'elk_bugle_01');
      expect(r.animal, 'elk');
      expect(r.score, 85.3);
      expect(r.matchLabel, 'Elk Bugle');
    });
  });
}
