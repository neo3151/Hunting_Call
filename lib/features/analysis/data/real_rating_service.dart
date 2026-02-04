import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../rating/domain/rating_model.dart';
import '../../rating/domain/rating_service.dart';
import '../domain/frequency_analyzer.dart';
import '../../library/data/mock_reference_database.dart';

import '../../profile/data/profile_repository.dart';

class RealRatingService implements RatingService {
  final FrequencyAnalyzer analyzer;
  final ProfileRepository profileRepository;

  RealRatingService({required this.analyzer, required this.profileRepository});

  @override
  Future<RatingResult> rateCall(String userId, String audioPath, String animalType) async {
    // 1. Get the ideal metrics
    // We now pass the ID directly from the dropdown
    final reference = MockReferenceDatabase.getById(animalType);

    // 2. Analyze the user's audio
    final detectedPitch = await analyzer.getDominantFrequency(audioPath);
    
    // Calculate real duration
    double detectedDuration = 0.0;
    try {
      final file = File(audioPath);
      final bytes = await file.readAsBytes();
      if (bytes.length > 44) {
        final ByteData view = bytes.buffer.asByteData();
        int sampleRate = 44100;
        if (bytes.length >= 28) {
          sampleRate = view.getUint32(24, Endian.little);
        }
        // Duration = (Total Bytes - Header) / (Sample Rate * Channels * BytesPerSample)
        // We assume 1 channel, 2 bytes per sample (16-bit) as per RecorderConfig
        detectedDuration = (bytes.length - 44) / (sampleRate * 1 * 2);
      }
    } catch (e) {
      debugPrint("Duration Analysis Error: $e");
      // Fallback to reference duration to avoid division by zero or errors
      detectedDuration = reference.idealDurationSec;
    }

    // 3. Compare (The Algorithm)
    final pitchDiff = (detectedPitch - reference.idealPitchHz).abs();
    final durationDiff = (detectedDuration - reference.idealDurationSec).abs();

    // 4. Calculate Score
    // Pitch contributes 60% of score, Duration 40%
    // Use PERCENTAGE-BASED deviation for fair scoring across frequency ranges
    // (50Hz off on a 120Hz grunt is much worse than 50Hz off on a 2000Hz bugle)
    
    double pitchScore = 100.0;
    if (reference.idealPitchHz > 0) {
      // Calculate deviation as percentage of ideal frequency
      final pitchDeviationPercent = (pitchDiff / reference.idealPitchHz) * 100;
      // Tolerance also as percentage
      final tolerancePercent = (reference.tolerancePitch / reference.idealPitchHz) * 100;
      
      if (pitchDeviationPercent > tolerancePercent) {
        // Deduct 3 points per 1% deviation beyond tolerance, capped at 0
        pitchScore = max(0, 100 - ((pitchDeviationPercent - tolerancePercent) * 3));
      }
    }

    double durationScore = 100.0;
    if (reference.idealDurationSec > 0) {
      // Duration deviation as percentage of ideal duration
      final durationDeviationPercent = (durationDiff / reference.idealDurationSec) * 100;
      final toleranceDurationPercent = (reference.toleranceDuration / reference.idealDurationSec) * 100;
      
      if (durationDeviationPercent > toleranceDurationPercent) {
        // Deduct 2 points per 1% deviation beyond tolerance, capped at 0
        durationScore = max(0, 100 - ((durationDeviationPercent - toleranceDurationPercent) * 2));
      }
    }

    final totalScore = (pitchScore * 0.6) + (durationScore * 0.4);

    // 5. Generate Feedback
    // Only give "Outstanding" if BOTH pitch and duration are within tolerance
    String feedback = "";
    final bool pitchIsGood = pitchScore >= 85;
    final bool durationIsGood = durationScore >= 85;
    
    if (pitchIsGood && durationIsGood) {
      feedback = "Outstanding! You sound just like a ${reference.animalName}.";
    } else if (!pitchIsGood && !durationIsGood) {
      // Both need work - prioritize the worse one
      if (pitchScore < durationScore) {
        final pitchDeviationPercent = (pitchDiff / reference.idealPitchHz) * 100;
        if (detectedPitch > reference.idealPitchHz) {
          feedback = "Too High! Lower your pitch by ~${pitchDeviationPercent.toStringAsFixed(0)}% (${pitchDiff.toInt()}Hz). Duration also needs work.";
        } else {
          feedback = "Too Low! Raise your pitch by ~${pitchDeviationPercent.toStringAsFixed(0)}% (${pitchDiff.toInt()}Hz). Duration also needs work.";
        }
      } else {
        if (detectedDuration > reference.idealDurationSec) {
          feedback = "Too Long! Shorten by ${(detectedDuration - reference.idealDurationSec).toStringAsFixed(1)}s. Pitch also needs work.";
        } else {
          feedback = "Too Short! Hold for ${(reference.idealDurationSec - detectedDuration).toStringAsFixed(1)}s longer. Pitch also needs work.";
        }
      }
    } else if (!pitchIsGood) {
      final pitchDeviationPercent = (pitchDiff / reference.idealPitchHz) * 100;
      if (detectedPitch > reference.idealPitchHz) {
        feedback = "Too High! Lower your pitch by ~${pitchDeviationPercent.toStringAsFixed(0)}% (${pitchDiff.toInt()}Hz).";
      } else {
        feedback = "Too Low! Raise your pitch by ~${pitchDeviationPercent.toStringAsFixed(0)}% (${pitchDiff.toInt()}Hz).";
      }
    } else {
      // Duration needs work
      if (detectedDuration > reference.idealDurationSec) {
        feedback = "Too Long! Shorten the call by ${(detectedDuration - reference.idealDurationSec).toStringAsFixed(1)}s.";
      } else {
        feedback = "Too Short! Hold the call for ${(reference.idealDurationSec - detectedDuration).toStringAsFixed(1)}s longer.";
      }
    }

    final result = RatingResult(
      score: totalScore,
      feedback: feedback,
      pitchHz: detectedPitch,
      metrics: {
        "Pitch (Hz)": detectedPitch,
        "Target Pitch": reference.idealPitchHz,
        "Duration (s)": detectedDuration,
      },
    );

    // Save to history
    await profileRepository.saveResultForUser(userId, result, animalType);
    
    return result;
  }
}
