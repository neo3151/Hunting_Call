import 'dart:math';
import '../../rating/domain/rating_model.dart';
import '../../rating/domain/rating_service.dart';
import '../domain/frequency_analyzer.dart';
import '../../library/data/mock_reference_database.dart';
import '../../library/domain/reference_call_model.dart';
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
    // Simulate duration for now (since we don't have real file decoding yet)
    final detectedDuration = reference.idealDurationSec * (0.8 + (Random().nextDouble() * 0.4)); 

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
             if (detectedDuration > reference.idealDurationSec) {
                 feedback = "Too Long! Shorten the call by ${(detectedDuration - reference.idealDurationSec).toStringAsFixed(1)}s.";
             } else {
                 feedback = "Too Short! Hold the call longer.";
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
