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
    // If diff is within tolerance, full points. If outside, penalty.
    
    double pitchScore = 100.0;
    if (pitchDiff > reference.tolerancePitch) {
      // Deduct 1 point per Hz off, capped at 0
      pitchScore = max(0, 100 - (pitchDiff - reference.tolerancePitch));
    }

    double durationScore = 100.0;
    if (durationDiff > reference.toleranceDuration) {
      // Deduct 20 points per 0.1s off
      durationScore = max(0, 100 - ((durationDiff - reference.toleranceDuration) * 200));
    }

    final totalScore = (pitchScore * 0.6) + (durationScore * 0.4);

    // 5. Generate Feedback
    String feedback = "";
    if (totalScore > 85) {
      feedback = "Outstanding! You sound just like a ${reference.animalName}.";
    } else {
        if (pitchScore < durationScore) {
             if (detectedPitch > reference.idealPitchHz) {
                 feedback = "Too High! Lower your pitch by approx ${(detectedPitch - reference.idealPitchHz).toInt()}Hz.";
             } else {
                 feedback = "Too Low! Raise your pitch by approx ${(reference.idealPitchHz - detectedPitch).toInt()}Hz.";
             }
        } else {
             if (durationDiff > reference.toleranceDuration) {
               if (detectedDuration > reference.idealDurationSec) {
                   feedback = "Too Long! Shorten the call by ${(detectedDuration - reference.idealDurationSec).toStringAsFixed(1)}s.";
               } else {
                   feedback = "Too Short! Hold the call for ${(reference.idealDurationSec - detectedDuration).toStringAsFixed(1)}s longer.";
               }
             } else {
               feedback = "Pitch is good, but try to be more consistent.";
             }
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
