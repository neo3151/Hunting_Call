import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';

/// Service that calls Ollama directly from the app to get
/// personalized AI coaching from Gemma 3 4B.
///
/// Point [ollamaBaseUrl] to your local machine's IP on the network.
/// The phone and server must be on the same Wi-Fi network.
class AiCoachService {
  // Cloudflare Tunnel to local Ollama instance
  // Note: this URL changes each time cloudflared restarts
  // Local fallback: http://192.168.1.189:11434
  static const String ollamaBaseUrl = 'https://estate-douglas-subject-eagle.trycloudflare.com';

  /// Request AI coaching feedback based on rating results.
  ///
  /// Returns the coaching text, or a fallback string if
  /// Ollama is unreachable.
  static Future<String> getCoaching({
    required String animalName,
    required String callType,
    required RatingResult result,
    required double idealPitchHz,
    String? proTips,
  }) async {
    try {
      final pitchDiff = (result.pitchHz - idealPitchHz).abs();
      final pitchDirection = result.pitchHz > idealPitchHz ? 'too high' : 'too low';

      final metricsBreakdown = result.metrics.entries
          .map((e) => '  - ${e.key}: ${e.value.toStringAsFixed(1)}')
          .join('\n');

      const systemPrompt = 'You are a master hunting call coach with decades of field experience. '
          'You give warm, encouraging, practical advice to hunters learning to '
          'perfect their animal calls. You speak with authority but never '
          'condescension. Keep your coaching concise — 2-3 short paragraphs max. '
          'Use specific, actionable tips. Never use markdown formatting, emojis, '
          'or bullet points — just clean conversational text.';

      final userPrompt = 'A hunter just practiced their $callType call for $animalName '
          'and scored ${result.score.toStringAsFixed(0)}%.\n\n'
          'Their pitch was ${result.pitchHz.toStringAsFixed(0)} Hz '
          '(target: ${idealPitchHz.toStringAsFixed(0)} Hz — '
          '${pitchDiff < 10 ? "right on target" : "${pitchDiff.toStringAsFixed(0)} Hz $pitchDirection"}).\n\n'
          'Detailed metrics:\n$metricsBreakdown\n\n'
          '${proTips != null && proTips.isNotEmpty ? "Reference tips for this call: $proTips\n\n" : ""}'
          'Give them personalized coaching feedback. What are they doing well? '
          "What's the #1 thing they should focus on improving? "
          'Give one specific, practical drill or technique they can try right now.';

      final response = await http
          .post(
            Uri.parse('$ollamaBaseUrl/api/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': 'gemma3:4b',
              'prompt': userPrompt,
              'system': systemPrompt,
              'stream': false,
              'options': {
                'temperature': 0.7,
                'top_p': 0.9,
                'num_predict': 300,
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
