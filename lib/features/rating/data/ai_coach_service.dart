import 'package:cloud_functions/cloud_functions.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';

/// Service that calls the getCoachingFeedback Cloud Function
/// to get personalized AI coaching from Gemma 3 4B.
class AiCoachService {
  static final _functions = FirebaseFunctions.instance;

  /// Request AI coaching feedback based on rating results.
  ///
  /// Returns the coaching text, or a fallback string if the
  /// Cloud Function or Ollama is unavailable.
  static Future<String> getCoaching({
    required String animalName,
    required String callType,
    required RatingResult result,
    required double idealPitchHz,
    String? proTips,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'getCoachingFeedback',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );

      final response = await callable.call<Map<String, dynamic>>({
        'animalName': animalName,
        'callType': callType,
        'score': result.score,
        'pitchHz': result.pitchHz,
        'idealPitchHz': idealPitchHz,
        'metrics': result.metrics,
        'proTips': proTips ?? '',
      });

      return response.data['coaching'] as String? ?? _fallback(result.score);
    } catch (e) {
      AppLogger.d('AI Coach: Cloud Function error: $e');
      return _fallback(result.score);
    }
  }

  static String _fallback(double score) {
    if (score >= 85) {
      return 'Excellent work! Your call is sounding very natural. Focus on consistency now — try making five calls in a row at this quality level.';
    } else if (score >= 70) {
      return 'Good foundation! Focus on matching the target pitch more precisely — try humming the pitch before making the call.';
    } else if (score >= 50) {
      return 'You\'re making progress! Slow down and focus on pitch accuracy first. Listen to the reference call three times before each attempt.';
    } else {
      return 'Every expert started right where you are. Listen to the reference call, then mimic just the opening note. Build the call piece by piece.';
    }
  }
}
