import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/features/rating/data/coaching_session_history.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';

/// Service that calls Ollama directly from the app to get
/// personalized AI coaching from the custom outcall-coach model.
///
/// The outcall-coach model is based on Gemma 3 4B with the full
/// hunting call knowledge base baked into its system prompt.
///
/// Session history is injected into each prompt so the coach
/// remembers past sessions and adapts its feedback.
class AiCoachService {
  // Cloudflare Tunnel to local Ollama instance
  // Note: this URL changes each time cloudflared restarts
  // Local fallback: http://192.168.1.189:11434
  static const String ollamaBaseUrl = 'https://estate-douglas-subject-eagle.trycloudflare.com';

  // Custom model with baked-in hunting call knowledge
  static const String _model = 'outcall-coach';

  /// Request AI coaching feedback based on rating results.
  ///
  /// Injects user's session history for personalized, adaptive coaching.
  /// Returns the coaching text, or a fallback string if Ollama is unreachable.
  static Future<String> getCoaching({
    required String animalName,
    required String callType,
    required RatingResult result,
    required double idealPitchHz,
    String? proTips,
    String? userId,
  }) async {
    try {
      // Fetch session history for context (non-blocking fallback)
      String historySummary = '';
      if (userId != null && userId.isNotEmpty) {
        try {
          historySummary = await CoachingSessionHistory.getHistorySummary(userId);
        } catch (_) {
          // History is nice-to-have, don't block coaching on it
        }
      }

      final pitchDiff = (result.pitchHz - idealPitchHz).abs();
      final pitchDirection = result.pitchHz > idealPitchHz ? 'too high' : 'too low';

      final metricsBreakdown = result.metrics.entries
          .map((e) => '  - ${e.key}: ${e.value.toStringAsFixed(1)}')
          .join('\n');

      final prompt = StringBuffer();
      prompt.writeln('A hunter just practiced their $callType call for $animalName '
          'and scored ${result.score.toStringAsFixed(0)}%.');
      prompt.writeln();
      prompt.writeln('Their pitch was ${result.pitchHz.toStringAsFixed(0)} Hz '
          '(target: ${idealPitchHz.toStringAsFixed(0)} Hz — '
          '${pitchDiff < 10 ? "right on target" : "${pitchDiff.toStringAsFixed(0)} Hz $pitchDirection"}).');
      prompt.writeln();
      prompt.writeln('Detailed metrics:');
      prompt.writeln(metricsBreakdown);

      if (proTips != null && proTips.isNotEmpty) {
        prompt.writeln();
        prompt.writeln('Reference tips for this call: $proTips');
      }

      if (historySummary.isNotEmpty) {
        prompt.writeln();
        prompt.writeln('SESSION HISTORY:');
        prompt.writeln(historySummary);
      }

      prompt.writeln();
      prompt.writeln('Give them personalized coaching feedback. What are they doing well? '
          "What's the #1 thing they should focus on improving? "
          'Give one specific, practical drill or technique they can try right now.');

      final response = await http
          .post(
            Uri.parse('$ollamaBaseUrl/api/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': _model,
              'prompt': prompt.toString(),
              'stream': false,
              'options': {
                'temperature': 0.7,
                'top_p': 0.9,
                'num_predict': 350,
              },
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        AppLogger.d('AI Coach: Ollama returned ${response.statusCode}');
        return _fallback(result.score);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final coaching = (data['response'] as String?)?.trim() ?? '';

      if (coaching.length < 20) {
        return _fallback(result.score);
      }

      // Save session for future context (fire and forget)
      if (userId != null && userId.isNotEmpty) {
        CoachingSessionHistory.saveSession(
          userId: userId,
          animalId: animalName,
          animalName: animalName,
          callType: callType,
          score: result.score,
          metrics: result.metrics,
          coachingText: coaching,
        );
      }

      return coaching;
    } catch (e) {
      AppLogger.d('AI Coach: Ollama unreachable: $e');
      return _fallback(result.score);
    }
  }

  static String _fallback(double score) {
    if (score >= 85) {
      return 'Excellent work! Your call is sounding very natural. Focus on '
          'consistency now — try making five calls in a row at this quality level.';
    } else if (score >= 70) {
      return 'Good foundation! Focus on matching the target pitch more '
          'precisely — try humming the pitch before making the call.';
    } else if (score >= 50) {
      return "You're making progress! Slow down and focus on pitch accuracy "
          'first. Listen to the reference call three times before each attempt.';
    } else {
      return 'Every expert started right where you are. Listen to the reference '
          'call, then mimic just the opening note. Build the call piece by piece.';
    }
  }
}
