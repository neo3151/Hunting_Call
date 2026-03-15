import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/features/rating/data/coaching_session_history.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';

/// Service that calls the Railway AI backend to get personalized
/// AI coaching powered by Gemini 2.0 Flash.
///
/// The backend uses Gemini with a hunting-specific system prompt
/// covering species techniques, scoring metrics, and field strategy.
///
/// Session history is injected into each prompt so the coach
/// remembers past sessions and adapts its feedback.
class AiCoachService {

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
    required String audioPath,
  }) async {
    try {
      // #5: Check connectivity before making network request
      final connectivityResults = await Connectivity().checkConnectivity();
      final isOffline = connectivityResults.isEmpty ||
          connectivityResults.every((r) => r == ConnectivityResult.none);
      if (isOffline) {
        AppLogger.d('AI Coach: Device is offline, using fallback');
        return '${_fallback(result: result, idealPitchHz: idealPitchHz, animalName: animalName, callType: callType)}\n\n(Offline — connect to get AI-powered coaching)';
      }
      // Fetch session history for context (non-blocking fallback)
      // ignore: unused_local_variable
      String historySummary = '';
      if (userId != null && userId.isNotEmpty) {
        try {
          historySummary = await CoachingSessionHistory.getHistorySummary(userId);
        } catch (_) {
          // History is nice-to-have, don't block coaching on it
        }
      }

      // Fallback matches the Remote Config default so real devices still work
      final targetUrl = baseUrl ?? 'https://huntingcallaibackend-production.up.railway.app';
      
      final response = await http
          .post(
            Uri.parse('$targetUrl/api/coach'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'animalId': animalName.toLowerCase(),
              'animalName': animalName,
              'pitchScore': result.metrics['score_pitch'] ?? result.score,
              'durationScore': result.metrics['score_duration'] ?? result.score,
              'detectedPitchHz': result.pitchHz,
              'idealPitchHz': idealPitchHz,
              'detectedDurationSec': result.metrics['Duration (s)'] ?? 0.0,
              'idealDurationSec': result.metrics['Duration (s)'] ?? 0.0,
              'metrics': result.metrics,
              'audioFilePath': audioPath,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        AppLogger.d('AI Coach Backend returned ${response.statusCode}');
        return _fallback(
            result: result, idealPitchHz: idealPitchHz, animalName: animalName, callType: callType);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final coaching = (data['feedback'] as String?)?.trim() ?? '';

      if (coaching.length < 10) {
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
      AppLogger.d('AI Coach: Backend unreachable: $e');
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

    // Only consider score-based metrics (0-100 range) for feedback,
    // not raw values like Pitch (Hz) or Duration (s).
    const scoreLabels = {
      'score_pitch': 'Pitch',
      'score_timbre': 'Tone',
      'score_rhythm': 'Rhythm',
      'score_duration': 'Duration',
    };

    String? weakest;
    String? strongest;
    double weakestVal = 101;
    double strongestVal = -1;
    for (final key in scoreLabels.keys) {
      final val = result.metrics[key];
      if (val == null) continue;
      if (val < weakestVal) {
        weakestVal = val;
        weakest = key;
      }
      if (val > strongestVal) {
        strongestVal = val;
        strongest = key;
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
    final weakestLabel = weakest != null ? scoreLabels[weakest] ?? weakest : null;
    if (weakestLabel != null && weakestVal < 70) {
      buf.write('Focus on your $weakestLabel (${weakestVal.toStringAsFixed(0)}%) — ');
      switch (weakestLabel.toLowerCase()) {
        case 'timing':
        case 'rhythm':
          buf.writeln('listen to the reference 3x, then clap the pattern before calling.');
          break;
        case 'pitch':
          buf.writeln('hum the target note before each attempt.');
          break;
        case 'duration':
          buf.writeln('practice holding your breath control — aim for steady, even notes.');
          break;
        case 'tone':
          buf.writeln('try adjusting how much air you push — less pressure for a smoother sound.');
          break;
        default:
          buf.writeln('practice that element in isolation before blending it back in.');
      }
    }

    final strongestLabel = strongest != null ? scoreLabels[strongest] ?? strongest : null;
    if (strongestLabel != null && strongestVal >= 80) {
      buf.writeln(
          'Your $strongestLabel is a strength at ${strongestVal.toStringAsFixed(0)}% — keep it up.');
    }

    return buf.toString().trim();
  }
}
