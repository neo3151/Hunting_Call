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
        // Resolve category from the animalId hint if available — mammals are
        // expected to get no BirdNET matches, so use pitch-dominant scoring.
        String noMatchCategory = 'Waterfowl';
        double noMatchPitch = 0.0;
        if (animalId != null) {
          try {
            final ref = ReferenceDatabase.getById(animalId);
            noMatchCategory = ref.category;
            final idealPitch = ref.idealPitchHz;
            if (idealPitch > 0 && analysis.dominantFrequencyHz > 0) {
              final pitchDiff = (analysis.dominantFrequencyHz - idealPitch).abs();
              final maxDiff = idealPitch * 0.75;
              noMatchPitch = (1.0 - (pitchDiff / maxDiff).clamp(0.0, 1.0)) * 100;
            }
          } catch (_) {}
        }
        final noMatchScore = computeScore(
          birdnetConfidence: 0,
          pitchScore: noMatchPitch,
          callQuality: analysis.callQualityScore.clamp(0, 100),
          toneClarity: analysis.toneClarity.clamp(0, 100),
          isBird: _isBirdCategory(noMatchCategory),
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

      // Find the closest matching reference call in our database.
      // We iterate through ALL species BirdNET predicted, in order of highest confidence first.
      // This prevents accuracy drops if BirdNET's #1 guess is a random unsupported bird, 
      // but its #2 or #3 guess is the turkey we actually support.
      final allCalls = ReferenceDatabase.calls;
      String matchedAnimal = speciesMatches.entries.first.key;
      String matchedCallType = 'call';
      String? matchedClipId;
      String matchedCategory = 'Waterfowl';
      double pitchScore = 25.0;
      double finalBirdnetConfidence = speciesMatches.entries.first.value;

      bool foundMatch = false;
      for (final species in speciesMatches.entries) {
        if (foundMatch) break;
        final birdName = species.key.toLowerCase();

        for (final ref in allCalls) {
          final refName = ref.animalName.toLowerCase();

          // Fuzzy match: BirdNET label might be "Wild Turkey" while ref is "Wild Turkey"
          if (refName.contains(birdName) || birdName.contains(refName) || _fuzzyMatch(refName, birdName)) {
            matchedAnimal = ref.animalName;
            matchedCallType = ref.callType;
            matchedClipId = ref.id;
            matchedCategory = ref.category;
            finalBirdnetConfidence = species.value;

            // Calculate pitch similarity to this reference (now 75% tolerance instead of 50% for more forgiving gradings)
            final idealPitch = ref.idealPitchHz;
            if (idealPitch > 0 && analysis.dominantFrequencyHz > 0) {
              final pitchDiff = (analysis.dominantFrequencyHz - idealPitch).abs();
              final maxDiff = idealPitch * 0.75; // More forgiving tolerance
              pitchScore = ((1.0 - (pitchDiff / maxDiff).clamp(0.0, 1.0)) * 100);
            }
            foundMatch = true;
            break;
          }
        }
      }

      // If we have an explicit animalId hint, use it for pitch comparison
      if (animalId != null && matchedClipId == null) {
        try {
          final ref = ReferenceDatabase.getById(animalId);
          matchedAnimal = ref.animalName;
          matchedCallType = ref.callType;
          matchedClipId = ref.id;
          matchedCategory = ref.category;

          final idealPitch = ref.idealPitchHz;
          if (idealPitch > 0 && analysis.dominantFrequencyHz > 0) {
            final pitchDiff =
                (analysis.dominantFrequencyHz - idealPitch).abs();
            final maxDiff = idealPitch * 0.75;
            pitchScore =
                ((1.0 - (pitchDiff / maxDiff).clamp(0.0, 1.0)) * 100);
          }
        } catch (_) {
          // Unknown animalId
        }
      }

      final isBird = _isBirdCategory(matchedCategory);
      final compositeScore = computeScore(
        birdnetConfidence: finalBirdnetConfidence,
        pitchScore: pitchScore,
        callQuality: analysis.callQualityScore,
        toneClarity: analysis.toneClarity,
        isBird: isBird,
      );

      AppLogger.d(
          'QuickMatch: $matchedAnimal ($matchedCallType) [${isBird ? "bird" : "mammal"}] — '
          'BirdNET=${isBird ? finalBirdnetConfidence.toStringAsFixed(0) : "skipped"}%, '
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

  /// Returns true for categories where BirdNET species ID is meaningful.
  static bool _isBirdCategory(String category) {
    final c = category.toLowerCase();
    return c == 'waterfowl' || c == 'land birds' || c == 'birds';
  }

  /// Compute the Quick Match composite score.
  ///
  /// For bird categories (Waterfowl, Birds): BirdNET 40%, pitch 30%, quality 15%, clarity 15%.
  /// For mammal categories (Big Game, Predators, Big Cats): BirdNET is meaningless,
  /// so its 40% weight is redistributed to pitch: pitch 60%, quality 20%, clarity 20%.
  ///
  /// All inputs should be 0-100. Returns the final sigmoid-curved score (0-100).
  static double computeScore({
    required double birdnetConfidence,
    required double pitchScore,
    required double callQuality,
    required double toneClarity,
    bool isBird = true,
  }) {
    final double rawScore;
    if (isBird) {
      rawScore = (birdnetConfidence.clamp(0, 100) * 0.40 +
              pitchScore.clamp(0, 100) * 0.30 +
              callQuality.clamp(0, 100) * 0.15 +
              toneClarity.clamp(0, 100) * 0.15)
          .clamp(0.0, 100.0);
    } else {
      // BirdNET skipped — pitch carries the species signal for mammals
      rawScore = (pitchScore.clamp(0, 100) * 0.60 +
              callQuality.clamp(0, 100) * 0.20 +
              toneClarity.clamp(0, 100) * 0.20)
          .clamp(0.0, 100.0);
    }

    // Sigmoid contrast: tuned to be much more forgiving for beginners.
    // By shifting the midpoint to 40, a raw score of 50 jumps up to ~65%
    // instead of staying at a failing 50%.
    return (100.0 / (1.0 + exp(-0.06 * (rawScore - 40.0)))).clamp(0.0, 100.0);
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
