import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outcall/core/utils/app_logger.dart';

/// Tracks coaching sessions in Firestore so the AI coach can
/// reference a user's history and adapt its feedback over time.
///
/// Each session stores: animalId, callType, score, weakest metric,
/// coaching text, and timestamp.
///
/// When generating a new coaching prompt, the service provides
/// a summary of the user's last N sessions so Gemma can reference
/// patterns and progress.
class CoachingSessionHistory {
  static const _collection = 'coaching_sessions';
  static const int _maxHistoryForPrompt = 5;

  /// Save a coaching session after the AI responds.
  static Future<void> saveSession({
    required String userId,
    required String animalId,
    required String animalName,
    required String callType,
    required double score,
    required Map<String, dynamic> metrics,
    required String coachingText,
  }) async {
    try {
      final weakestMetric = _findWeakest(metrics);

      await FirebaseFirestore.instance.collection(_collection).add({
        'userId': userId,
        'animalId': animalId,
        'animalName': animalName,
        'callType': callType,
        'score': score,
        'metrics': metrics,
        'weakestMetric': weakestMetric,
        'coachingText': coachingText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      AppLogger.d('CoachingHistory: Saved session for $animalName ($callType)');
    } catch (e) {
      AppLogger.d('CoachingHistory: Failed to save: $e');
    }
  }

  /// Build a history summary string to inject into the coaching prompt.
  /// Returns empty string if no history is available.
  static Future<String> getHistorySummary(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(_maxHistoryForPrompt)
          .get();

      if (snapshot.docs.isEmpty) {
        return '';
      }

      final sessions = snapshot.docs.map((doc) {
        final d = doc.data();
        return '- ${d['animalName']} ${d['callType']}: '
            '${(d['score'] as num).toStringAsFixed(0)}% '
            '(weakest: ${d['weakestMetric'] ?? 'unknown'})';
      }).join('\n');

      // Compute trends
      final scores = snapshot.docs.map((d) => (d.data()['score'] as num).toDouble()).toList();
      final avgScore = scores.reduce((a, b) => a + b) / scores.length;

      // Find most common weak area
      final weakAreas = snapshot.docs
          .map((d) => d.data()['weakestMetric'] as String?)
          .where((w) => w != null)
          .toList();
      final weakCounts = <String, int>{};
      for (final w in weakAreas) {
        weakCounts[w!] = (weakCounts[w] ?? 0) + 1;
      }
      String? chronicWeak;
      if (weakCounts.isNotEmpty) {
        chronicWeak = weakCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      }

      final buffer = StringBuffer();
      buffer.writeln('This hunter has ${snapshot.docs.length} recent coaching sessions:');
      buffer.writeln(sessions);
      buffer.writeln('Average score: ${avgScore.toStringAsFixed(0)}%');
      if (chronicWeak != null) {
        buffer
            .writeln('Recurring weak area: $chronicWeak — address this pattern in your coaching.');
      }
      if (scores.length >= 2) {
        final trend = scores.first - scores.last;
        if (trend > 5) {
          buffer.writeln('Trend: Improving! Acknowledge their progress.');
        } else if (trend < -5) {
          buffer.writeln('Trend: Scores declining. Encourage them and suggest fundamentals.');
        }
      }

      return buffer.toString();
    } catch (e) {
      AppLogger.d('CoachingHistory: Failed to fetch: $e');
      return '';
    }
  }

  static String? _findWeakest(Map<String, dynamic> metrics) {
    String? weakest;
    double lowest = double.infinity;
    for (final entry in metrics.entries) {
      final val = (entry.value as num?)?.toDouble() ?? 0;
      if (val < lowest) {
        lowest = val;
        weakest = entry.key;
      }
    }
    return weakest;
  }
}
