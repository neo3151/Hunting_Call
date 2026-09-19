import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/features/rating/data/coaching_session_history.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';

import 'package:cloud_functions/cloud_functions.dart';

/// Service that calls the AI backend/cloud function to get personalized
/// coaching, falling back to a rule-based engine when offline or unavailable.
class AiCoachService {
  /// Request AI coaching feedback based on rating results.
  static Future<String> getCoaching({
    required String animalName,
    required String callType,
    required RatingResult result,
    required double idealPitchHz,
    String? proTips,
    String? userId,
    required String audioPath,
  }) async {
    try {
      // Desktop / dev check: fallback for non-mobile platforms
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        AppLogger.d('AI Coach: Desktop platform, using local fallback');
        return _fallback(
            result: result,
            idealPitchHz: idealPitchHz,
            animalName: animalName,
            callType: callType);
      }

      // Connectivity check
      final connectivityResults = await Connectivity().checkConnectivity();
      final isOffline = connectivityResults.isEmpty ||
          connectivityResults.every((r) => r == ConnectivityResult.none);
      if (isOffline) {
        AppLogger.d('AI Coach: Device is offline, using fallback');
        return '${_fallback(result: result, idealPitchHz: idealPitchHz, animalName: animalName, callType: callType)}\n\n(Offline — connect to get AI-powered coaching)';
      }

      // Invoke authenticated Cloud Function backend
      final callable = FirebaseFunctions.instance.httpsCallable('getCoachingFeedback');
      final res = await callable.call<Map<String, dynamic>>({
        'animalName': animalName,
        'callType': callType,
        'score': result.score,
        'pitchHz': result.pitchHz,
        'idealPitchHz': idealPitchHz,
        'metrics': result.metrics,
        'proTips': proTips,
      }).timeout(const Duration(seconds: 15));

      final coaching = res.data['coaching'] as String?;
      if (coaching != null && coaching.trim().isNotEmpty) {
        if (userId != null && userId.isNotEmpty) {
          CoachingSessionHistory.saveSession(
            userId: userId,
            animalId: animalName,
            animalName: animalName,
            callType: callType,
            score: result.score,
            metrics: result.metrics,
            coachingText: coaching.trim(),
          );
        }
        return coaching.trim();
      }

      return _fallback(
          result: result,
          idealPitchHz: idealPitchHz,
          animalName: animalName,
          callType: callType);
    } catch (e) {
      AppLogger.e('AI Coach: Coaching request failed', e);
      return _fallback(
          result: result,
          idealPitchHz: idealPitchHz,
          animalName: animalName,
          callType: callType);
    }
  }

  // ── Rule-based fallback (unchanged) ──────────────────────────────────

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
      buf.writeln(
          'Great $callType for $animalName — ${score.toStringAsFixed(0)}% is solid work!');
    } else if (score >= 70) {
      buf.writeln(
          'Decent attempt on the $animalName $callType at ${score.toStringAsFixed(0)}%.');
    } else if (score >= 50) {
      buf.writeln(
          'Your $animalName $callType scored ${score.toStringAsFixed(0)}% — room to grow.');
    } else {
      buf.writeln(
          '${score.toStringAsFixed(0)}% on the $animalName $callType. Let\'s work on it.');
    }
    buf.writeln();

    // Pitch-specific feedback
    if (pitchDiff < 15) {
      buf.writeln('Your pitch is right on target — nice ear!');
    } else {
      buf.writeln(
          'Your pitch is ${pitchDiff.toStringAsFixed(0)} Hz too $pitchDir '
          '(you hit ${result.pitchHz.toStringAsFixed(0)} Hz, target is '
          '${idealPitchHz.toStringAsFixed(0)} Hz). '
          'Try ${pitchDir == "high" ? "relaxing your lips and using less air pressure" : "tightening your embouchure slightly"}.');
    }
    buf.writeln();

    // Metric-specific drill
    final weakestLabel =
        weakest != null ? scoreLabels[weakest] ?? weakest : null;
    if (weakestLabel != null && weakestVal < 70) {
      buf.write(
          'Focus on your $weakestLabel (${weakestVal.toStringAsFixed(0)}%) — ');
      switch (weakestLabel.toLowerCase()) {
        case 'timing':
        case 'rhythm':
          buf.writeln(
              'listen to the reference 3x, then clap the pattern before calling.');
          break;
        case 'pitch':
          buf.writeln('hum the target note before each attempt.');
          break;
        case 'duration':
          buf.writeln(
              'practice holding your breath control — aim for steady, even notes.');
          break;
        case 'tone':
          buf.writeln(
              'try adjusting how much air you push — less pressure for a smoother sound.');
          break;
        default:
          buf.writeln(
              'practice that element in isolation before blending it back in.');
      }
    }

    final strongestLabel =
        strongest != null ? scoreLabels[strongest] ?? strongest : null;
    if (strongestLabel != null && strongestVal >= 80) {
      buf.writeln(
          'Your $strongestLabel is a strength at ${strongestVal.toStringAsFixed(0)}% — keep it up.');
    }

    return buf.toString().trim();
  }

  // ── Species-specific system prompt (from backend services.py) ────────

  static const String _systemPrompt =
      '''You are Coach Buck — a 40-year veteran hunting guide and world-class calling specialist.
You don't sugarcoat things; you are firm but fair because you know a bad call means a lost hunt.
You know NOTHING about anything else. Do NOT answer off-topic questions.

Your goal is to provide concise, practical, and highly specific feedback to a user practicing their hunting calls.
Instead of relying on hardcoded species data, act dynamically based on the performance metrics provided to you.
The user is providing you their real-time performance on a call:
- The species and the specific call type.
- Their exact pitch (Hz) vs the Ideal Pitch (Hz) for that call.
- The breakdown of their scores across pitch, duration, timbre, and rhythm.

SCORING INTERPRETATION & FEEDBACK RULES:
- 90-100 (Elite): Subtle refinements. Celebrate their skill. Focus on realism and field scenarios.
- 70-89 (Advanced): Good foundation. Identify one specific area to improve based on their lowest metric.
- 50-69 (Intermediate): Identify the PRIMARY weakness. Provide one concrete drill to fix it.
- Below 50 (Beginner): Be extremely encouraging. Focus entirely on the basics like breath support, lip pressure, or hand placement.

PITCH CORRECTION TACTICS (Applies to all calls using reed/mouth instruments or vocal cords):
- If Pitch is TOO LOW: Instruct them to increase air speed/pressure, tighten their embouchure/lips, or squeeze the reed tighter.
- If Pitch is TOO HIGH: Instruct them to relax their lips, drop their jaw slightly, use less aggressive air pressure, or muffle the bell/exhaust of the call more with their hands.

DURATION & RHYTHM CORRECTION:
- Duration: Emphasize diaphragmatic breath support. Don't push from the chest. Think steady, even air columns.
- Rhythm: Tell them to step away from the call and tap/clap the cadence of the reference audio first.

RESPONSE CONSTRAINTS:
- Structure: Start with 1-2 warm, encouraging sentences evaluating their overall score. Follow up with 1-2 sentences containing a practical, actionable tip to address their weakest metric.
- Length: Keep it to a maximum of 3-4 sentences total. Be warm and supportive — like a patient hunting mentor in a blind.
- Tone: Avoid being robotic. Use hunting terminology like "in the field" or "bringing 'em in" where appropriate.
- NEVER discuss politics, non-hunting topics, or general knowledge.
- NEVER say 'I'm an AI' or 'As a language model'.''';
}
