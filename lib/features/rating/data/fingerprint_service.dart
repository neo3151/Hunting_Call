import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:outcall/core/utils/app_logger.dart';

/// Result from a fingerprint match against the backend.
class FingerprintResult {
  final String? clipId;
  final String animal;
  final String callType;
  final double score;
  final int matchedHashes;
  final double timeOffsetMs;
  final double elapsedMs;
  final int totalUserHashes;

  const FingerprintResult({
    this.clipId,
    this.animal = 'unknown',
    this.callType = 'unknown',
    this.score = 0.0,
    this.matchedHashes = 0,
    this.timeOffsetMs = 0.0,
    this.elapsedMs = 0.0,
    this.totalUserHashes = 0,
  });

  bool get hasMatch => clipId != null && score > 0;

  /// Human-readable label for the matched call.
  String get matchLabel {
    if (!hasMatch) return 'No Match';
    final animalCap = animal[0].toUpperCase() + animal.substring(1);
    final callCap = callType[0].toUpperCase() + callType.substring(1);
    return '$animalCap $callCap';
  }

  factory FingerprintResult.empty() => const FingerprintResult();

  factory FingerprintResult.fromJson(Map<String, dynamic> json) {
    final bestMatch = json['best_match'] as Map<String, dynamic>? ?? {};
    return FingerprintResult(
      clipId: bestMatch['clip_id'] as String?,
      animal: (bestMatch['animal'] as String?) ?? 'unknown',
      callType: (bestMatch['call_type'] as String?) ?? 'unknown',
      score: (bestMatch['score'] as num?)?.toDouble() ?? 0.0,
      matchedHashes: (bestMatch['matched_hashes'] as num?)?.toInt() ?? 0,
      timeOffsetMs: (bestMatch['time_offset_ms'] as num?)?.toDouble() ?? 0.0,
      elapsedMs: (json['elapsed_ms'] as num?)?.toDouble() ?? 0.0,
      totalUserHashes: (json['total_user_hashes'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Service that calls the Python backend's fingerprint matching endpoint.
class FingerprintService {
  static const String _fallbackBaseUrl = 'http://127.0.0.1:8000';

  /// Match a user's audio recording against the fingerprint database.
  ///
  /// [audioPath] is the path to the WAV file on disk.
  /// [baseUrl] can override the backend URL (from Remote Config).
  static Future<FingerprintResult> match(
    String audioPath, {
    String? baseUrl,
  }) async {
    final targetUrl = baseUrl ?? _fallbackBaseUrl;

    try {
      final response = await http
          .post(
            Uri.parse('$targetUrl/api/fingerprint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'audioFilePath': audioPath}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        AppLogger.d('Fingerprint API returned ${response.statusCode}');
        return FingerprintResult.empty();
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return FingerprintResult.fromJson(data);
    } catch (e) {
      AppLogger.d('Fingerprint match error: $e');
      return FingerprintResult.empty();
    }
  }
}
