import 'dart:convert';
import 'dart:io';
import 'package:outcall/core/utils/app_logger.dart';

/// Service that integrates with Google's Perspective API to score text
/// for toxicity using advanced ML models.
///
/// The Perspective API provides a toxicity score (0.0–1.0) that indicates
/// how likely a piece of text is to be perceived as toxic.
///
/// Usage:
/// ```dart
/// final score = await PerspectiveApiService.getToxicityScore('some text');
/// if (score != null && score > 0.7) {
///   // Block the text
/// }
/// ```
///
/// To enable, set the API key via [initialize]. Without an API key,
/// all calls gracefully return `null` and the app falls back to the
/// local blocklist filter.
class PerspectiveApiService {
  PerspectiveApiService._();

  static String? _apiKey;
  static bool _enabled = false;

  /// Toxicity threshold — scores above this are considered inappropriate.
  static const double toxicityThreshold = 0.7;

  static const _endpoint = 'commentanalyzer.googleapis.com';
  static const _path = '/v1alpha1/comments:analyze';

  /// Initialize the service with a Google Cloud API key.
  ///
  /// If no key is provided or the key is empty, the service is disabled
  /// and all calls will return `null`.
  static void initialize({String? apiKey}) {
    _apiKey = apiKey;
    _enabled = apiKey != null && apiKey.isNotEmpty;
    if (_enabled) {
      AppLogger.d('🔍 PerspectiveAPI: initialized');
    }
  }

  /// Whether the Perspective API is available.
  static bool get isAvailable => _enabled;

  /// Returns a toxicity score (0.0–1.0) for the given [text].
  ///
  /// Returns `null` if:
  /// - The service is not initialized
  /// - The text is too short to analyse
  /// - The API call fails (network error, quota exceeded, etc.)
  ///
  /// Scores above [toxicityThreshold] (0.7) indicate likely toxic content.
  static Future<double?> getToxicityScore(String text) async {
    if (!_enabled || _apiKey == null) return null;
    if (text.trim().length < 2) return null;

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final uri = Uri.https(_endpoint, _path, {'key': _apiKey});

      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');

      final body = jsonEncode({
        'comment': {'text': text},
        'requestedAttributes': {
          'TOXICITY': {},
          'SEVERE_TOXICITY': {},
          'IDENTITY_ATTACK': {},
          'PROFANITY': {},
        },
        'languages': ['en'],
      });

      request.write(body);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        AppLogger.d('🔍 PerspectiveAPI: HTTP ${response.statusCode}');
        client.close();
        return null;
      }

      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final scores = json['attributeScores'] as Map<String, dynamic>?;

      if (scores == null) {
        client.close();
        return null;
      }

      // Take the maximum score across all requested attributes
      double maxScore = 0.0;
      for (final attr in scores.values) {
        final summaryScore = (attr as Map<String, dynamic>)['summaryScore']
            as Map<String, dynamic>?;
        final value = (summaryScore?['value'] as num?)?.toDouble() ?? 0.0;
        if (value > maxScore) maxScore = value;
      }

      client.close();
      AppLogger.d('🔍 PerspectiveAPI: "$text" → toxicity=$maxScore');
      return maxScore;
    } catch (e) {
      AppLogger.d('🔍 PerspectiveAPI: error — $e');
      return null;
    }
  }

  /// Convenience method: returns `true` if the text is likely toxic.
  static Future<bool> isToxic(String text) async {
    final score = await getToxicityScore(text);
    return score != null && score >= toxicityThreshold;
  }
}
