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
  // This is just the fallback — the actual URL is fetched from Remote Config
  // so it can be updated server-side when the tunnel changes.
  // Local fallback: http://192.168.1.189:11434
  static const String _fallbackBaseUrl = 'https://farming-idaho-location-taste.trycloudflare.com';

  // Custom model with baked-in hunting call knowledge
  static const String _model = 'outcall-coach';

  /// Request AI coaching feedback based on rating results.
  ///
  /// [baseUrl] should come from RemoteConfigService.aiCoachUrl for dynamic updates.
  /// Injects user's session history for personalized, adaptive coaching.
  /// Returns the coaching text, or a fallback string if Ollama is unreachable.
  static Future<String> getCoaching({
    required String animalName,
    required String callType,
    required RatingResult result,
    required double idealPitchHz,
    String? proTips,
    String? userId,
    String? baseUrl,
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
            Uri.parse('${baseUrl ?? _fallbackBaseUrl}/api/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': _model,
              'prompt': prompt.toString(),
              'stream': false,
              'options': {
                'temperature': 0.7,
                'top_p': 0.9,
                'num_predict': 200,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        AppLogger.d('AI Coach: Ollama returned ${response.statusCode}');
        return _fallback(
            result: result, idealPitchHz: idealPitchHz, animalName: animalName, callType: callType);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final coaching = (data['response'] as String?)?.trim() ?? '';

      if (coaching.length < 20) {
        return _fallback(
            result: result, idealPitchHz: idealPitchHz, animalName: animalName, callType: callType);
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
      return _fallback(
          result: result, idealPitchHz: idealPitchHz, animalName: animalName, callType: callType);
    }
  }

  static String _fallback({
    required RatingResult result,
    required double idealPitchHz,
    required String animalName,
    required String callType,
  }) {
    final score = result.score;
    final buf = StringBuffer();

    // Find weakest and strongest metrics
    String? weakest;
    String? strongest;
    double weakestVal = 101;
    double strongestVal = -1;
    for (final entry in result.metrics.entries) {
      if (entry.value < weakestVal) {
        weakestVal = entry.value;
        weakest = entry.key;
      }
      if (entry.value > strongestVal) {
        strongestVal = entry.value;
        strongest = entry.key;
      }
    }

    // Pitch analysis
    final pitchDiff = (result.pitchHz - idealPitchHz).abs();
    final pitchDir = result.pitchHz > idealPitchHz ? 'high' : 'low';

    // Opening line based on score
    if (score >= 85) {
      buf.writeln('Great $callType for $animalName — ${score.toStringAsFixed(0)}% is solid work!');
    } else if (score >= 70) {
      buf.writeln('Decent attempt on the $animalName $callType at ${score.toStringAsFixed(0)}%.');
    } else if (score >= 50) {
      buf.writeln('Your $animalName $callType scored ${score.toStringAsFixed(0)}% — room to grow.');
    } else {
      buf.writeln('${score.toStringAsFixed(0)}% on the $animalName $callType. Let\'s work on it.');
    }
    buf.writeln();

    // Pitch-specific feedback
    if (pitchDiff < 15) {
      buf.writeln('Your pitch is right on target — nice ear!');
    } else {
      buf.writeln('Your pitch is ${pitchDiff.toStringAsFixed(0)} Hz too $pitchDir '
          '(you hit ${result.pitchHz.toStringAsFixed(0)} Hz, target is '
          '${idealPitchHz.toStringAsFixed(0)} Hz). '
          'Try ${pitchDir == "high" ? "relaxing your lips and using less air pressure" : "tightening your embouchure slightly"}.');
    }
    buf.writeln();

    // Metric-specific drill
    if (weakest != null && weakestVal < 70) {
      buf.write('Focus on your $weakest (${weakestVal.toStringAsFixed(0)}%) — ');
      switch (weakest.toLowerCase()) {
        case 'timing':
          buf.writeln('use a metronome or tap your foot to lock in the rhythm.');
          break;
        case 'rhythm':
          buf.writeln('listen to the reference 3x, then clap the pattern before calling.');
          break;
        case 'pitch':
          buf.writeln('hum the target note before each attempt.');
          break;
        case 'duration':
          buf.writeln('practice holding your breath control — aim for steady, even notes.');
          break;
        default:
          buf.writeln('practice that element in isolation before blending it back in.');
      }
    }

    if (strongest != null && strongestVal >= 80) {
      buf.writeln(
          'Your $strongest is a strength at ${strongestVal.toStringAsFixed(0)}% — keep it up.');
    }

    return buf.toString().trim();
  }
}
