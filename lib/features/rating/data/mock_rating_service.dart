import 'dart:math';
import '../domain/rating_model.dart';
import '../domain/rating_service.dart';

class MockRatingService implements RatingService {
  @override
  Future<RatingResult> rateCall(String userId, String audioPath, String animalType) async {
    // No delay
    final random = Random();
    final score = 60 + random.nextInt(40).toDouble(); // Score 60-100

    String feedback;
    if (score > 90) {
      feedback = "Excellent! Perfect pitch and rhythm.";
    } else if (score > 75) {
      feedback = "Good job. Try to hold the end note a bit longer.";
    } else {
      feedback = "Decent start. Your pitch is a bit high for a $animalType.";
    }

    return RatingResult(
      score: score,
      feedback: feedback,
      pitchHz: 150.0,
      metrics: {
        "Pitch": 70 + random.nextInt(30).toDouble(),
        "Duration": 60 + random.nextInt(40).toDouble(),
        "Realism": score - 5,
      },
    );
  }
}
