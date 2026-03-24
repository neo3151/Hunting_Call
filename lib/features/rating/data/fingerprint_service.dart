import 'dart:io';
import 'dart:math';

import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/features/analysis/data/comprehensive_audio_analyzer.dart';
import 'package:outcall/features/library/data/reference_database.dart';

/// Result from on-device audio fingerprint matching.
class FingerprintResult {
  final String? clipId;
  final String animal;
  final String callType;
  final double score;
  final int matchedHashes;
  final double timeOffsetMs;
  final double elapsedMs;
  final int totalUserHashes;

  const FingerprintResult({
    this.clipId,
    this.animal = 'unknown',
    this.callType = 'unknown',
    this.score = 0.0,
    this.matchedHashes = 0,
    this.timeOffsetMs = 0.0,
    this.elapsedMs = 0.0,
    this.totalUserHashes = 0,
  });

  bool get hasMatch => clipId != null && score > 0;

  /// Human-readable label for the matched call.
  String get matchLabel {
    if (!hasMatch) return 'No Match';
    final animalCap = animal.isNotEmpty
        ? animal[0].toUpperCase() + animal.substring(1)
        : 'Unknown';
    final callCap = callType.isNotEmpty
        ? callType[0].toUpperCase() + callType.substring(1)
        : 'Call';
    return '$animalCap $callCap';
  }

  factory FingerprintResult.empty() => const FingerprintResult();

  factory FingerprintResult.fromJson(Map<String, dynamic> json) {
    final bestMatch = json['best_match'] as Map<String, dynamic>? ?? {};
    return FingerprintResult(
      clipId: bestMatch['clip_id'] as String?,
      animal: (bestMatch['animal'] as String?) ?? 'unknown',
      callType: (bestMatch['call_type'] as String?) ?? 'unknown',
      score: (bestMatch['score'] as num?)?.toDouble() ?? 0.0,
      matchedHashes: (bestMatch['matched_hashes'] as num?)?.toInt() ?? 0,
      timeOffsetMs: (bestMatch['time_offset_ms'] as num?)?.toDouble() ?? 0.0,
      elapsedMs: (json['elapsed_ms'] as num?)?.toDouble() ?? 0.0,
      totalUserHashes: (json['total_user_hashes'] as num?)?.toInt() ?? 0,
    );
  }
}

/// On-device audio fingerprint matching service.
///
/// Replaces the server-side librosa fingerprinting with local BirdNET ML
/// species identification + pitch/spectral similarity analysis.
///
/// Uses [ComprehensiveAudioAnalyzer] (which includes BirdNET TFLite) to
/// identify the species and compare the user's audio against the reference.
class FingerprintService {

  /// Match a user's audio recording against the reference database.
  ///
  /// Runs BirdNET species classification + pitch analysis on-device.
  /// Returns a [FingerprintResult] with the matched species and score.
  static Future<FingerprintResult> match(
    String audioPath, {
    String? animalId,
    String? baseUrl, // kept for API compat, ignored
  }) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.d('QuickMatch: starting on-device analysis for $audioPath');

    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        AppLogger.d('QuickMatch: audio file not found at $audioPath');
        return FingerprintResult.empty();
      }

      // Run on-device audio analysis
      final analyzer = ComprehensiveAudioAnalyzer();
      final analysis = await analyzer.analyzeAudio(audioPath);
      final elapsed = stopwatch.elapsedMilliseconds.toDouble();

      // Check if we got any signal at all
      if (analysis.dominantFrequencyHz == 0 && analysis.totalDurationSec == 0) {
        AppLogger.d('QuickMatch: no audio signal detected');
        return FingerprintResult(
          score: 0,
          elapsedMs: elapsed,
          animal: 'unknown',
        );
      }

      // BirdNET species identification
      final speciesMatches = analysis.topSpeciesMatches;
      if (speciesMatches.isEmpty) {
        AppLogger.d('QuickMatch: BirdNET returned no species matches');
        // No species identified — BirdNET=0, pitch=0, only quality/clarity
        // contribute. The sigmoid curve will push this low (~5-15%).
        final noMatchScore = computeScore(
          birdnetConfidence: 0,
          pitchScore: 0,
          callQuality: analysis.callQualityScore.clamp(0, 100),
          toneClarity: analysis.toneClarity.clamp(0, 100),
        );
        return FingerprintResult(
          score: noMatchScore,
          elapsedMs: elapsed,
          animal: 'unknown',
          callType: 'call',
          clipId: 'local_${DateTime.now().millisecondsSinceEpoch}',
          totalUserHashes: 1,
        );
      }

      // Top species from BirdNET
      final topSpecies = speciesMatches.entries.first;
      final birdnetConfidence = topSpecies.value; // 0-100%
      final speciesName = topSpecies.key;

      // Find the closest matching reference call in our database
      final allCalls = ReferenceDatabase.calls;
      String matchedAnimal = speciesName;
      String matchedCallType = 'call';
      String? matchedClipId;
      double pitchScore = 25.0;

      // Try to match BirdNET species name to our reference database
      for (final ref in allCalls) {
        final refName = ref.animalName.toLowerCase();
        final birdName = speciesName.toLowerCase();

        // Fuzzy match: BirdNET label might be "Wild Turkey" while ref is "Wild Turkey"
        // or "Mallard" while ref is "Mallard Duck"
        if (refName.contains(birdName) ||
            birdName.contains(refName) ||
            _fuzzyMatch(refName, birdName)) {
          matchedAnimal = ref.animalName;
          matchedCallType = ref.callType;
          matchedClipId = ref.id;

          // Calculate pitch similarity to this reference
          final idealPitch = ref.idealPitchHz;
          if (idealPitch > 0 && analysis.dominantFrequencyHz > 0) {
            final pitchDiff =
                (analysis.dominantFrequencyHz - idealPitch).abs();
            final maxDiff = idealPitch * 0.5; // 50% tolerance
            pitchScore =
                ((1.0 - (pitchDiff / maxDiff).clamp(0.0, 1.0)) * 100);
          }
          break;
        }
      }

      // If we have an explicit animalId hint, use it for pitch comparison
      if (animalId != null && matchedClipId == null) {
        try {
          final ref = ReferenceDatabase.getById(animalId);
          matchedAnimal = ref.animalName;
          matchedCallType = ref.callType;
          matchedClipId = ref.id;

          final idealPitch = ref.idealPitchHz;
          if (idealPitch > 0 && analysis.dominantFrequencyHz > 0) {
            final pitchDiff =
                (analysis.dominantFrequencyHz - idealPitch).abs();
            final maxDiff = idealPitch * 0.5;
            pitchScore =
                ((1.0 - (pitchDiff / maxDiff).clamp(0.0, 1.0)) * 100);
          }
        } catch (_) {
          // Unknown animalId
        }
      }

      final compositeScore = computeScore(
        birdnetConfidence: birdnetConfidence,
        pitchScore: pitchScore,
        callQuality: analysis.callQualityScore,
        toneClarity: analysis.toneClarity,
      );

      AppLogger.d(
          'QuickMatch: $matchedAnimal ($matchedCallType) — BirdNET=${birdnetConfidence.toStringAsFixed(0)}%, '
          'pitch=${pitchScore.toStringAsFixed(0)}%, quality=${analysis.callQualityScore.toStringAsFixed(0)}%, '
          'score=${compositeScore.toStringAsFixed(0)}% in ${elapsed.toStringAsFixed(0)}ms');

      return FingerprintResult(
        clipId: matchedClipId ?? 'local_${DateTime.now().millisecondsSinceEpoch}',
        animal: matchedAnimal,
        callType: matchedCallType,
        score: compositeScore,
        matchedHashes: speciesMatches.length, // number of species detected
        elapsedMs: elapsed,
        totalUserHashes: 1,
      );
    } catch (e) {
      AppLogger.d('QuickMatch: analysis failed: $e');
      return FingerprintResult(
        score: 0,
        elapsedMs: stopwatch.elapsedMilliseconds.toDouble(),
      );
    }
  }

  /// Compute the Quick Match composite score.
  ///
  /// Combines four sub-scores with weighted averages, then applies a
  /// sigmoid contrast curve to spread results away from 50%.
  /// All inputs should be 0-100.
  ///
  /// Returns the final curved score (0-100).
  static double computeScore({
    required double birdnetConfidence,
    required double pitchScore,
    required double callQuality,
    required double toneClarity,
  }) {
    // Weighted average: BirdNET 35% + pitch 35% + quality 15% + clarity 15%
    final rawScore = (birdnetConfidence.clamp(0, 100) * 0.35 +
            pitchScore.clamp(0, 100) * 0.35 +
            callQuality.clamp(0, 100) * 0.15 +
            toneClarity.clamp(0, 100) * 0.15)
        .clamp(0.0, 100.0);

    // Sigmoid contrast: pushes scores away from 50%
    //   20 raw → ~8, 30 → ~17, 50 → 50, 70 → ~83, 85 → ~94
    return (100.0 / (1.0 + exp(-0.08 * (rawScore - 50.0)))).clamp(0.0, 100.0);
  }

  /// Simple fuzzy matching for BirdNET labels vs reference names.
  static bool _fuzzyMatch(String a, String b) {
    // Normalize
    final aNorm = a.replaceAll(RegExp(r'[^a-z]'), '');
    final bNorm = b.replaceAll(RegExp(r'[^a-z]'), '');

    // Check if either contains 60%+ of the other
    if (aNorm.length < 3 || bNorm.length < 3) return false;

    int matches = 0;
    final shorter = aNorm.length <= bNorm.length ? aNorm : bNorm;
    final longer = aNorm.length > bNorm.length ? aNorm : bNorm;
    for (int i = 0; i <= shorter.length - 3; i++) {
      if (longer.contains(shorter.substring(i, i + 3))) matches++;
    }
    return matches / (shorter.length - 2) > 0.6;
  }
}
