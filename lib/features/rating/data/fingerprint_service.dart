import 'dart:convert';
import 'dart:io';

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
    final animalCap = animal.isNotEmpty
        ? animal[0].toUpperCase() + animal.substring(1)
        : 'Unknown';
    final callCap = callType.isNotEmpty
        ? callType[0].toUpperCase() + callType.substring(1)
        : 'Call';
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
  static const String _fallbackBaseUrl = 'https://mercy-norman-sin-extensions.trycloudflare.com';

  /// Match a user's audio recording against the fingerprint database.
  ///
  /// Uploads the actual audio file as multipart form data since the
  /// backend runs on a different machine and can't access phone paths.
  static Future<FingerprintResult> match(
    String audioPath, {
    String? baseUrl,
  }) async {
    final targetUrl = baseUrl ?? _fallbackBaseUrl;

    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        AppLogger.d('Fingerprint: audio file not found at $audioPath');
        return FingerprintResult.empty();
      }

      final fileSize = await file.length();
      AppLogger.d('Fingerprint: sending $audioPath ($fileSize bytes) to $targetUrl/api/fingerprint');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$targetUrl/api/fingerprint'),
      );
      request.files.add(
        await http.MultipartFile.fromPath('audio', audioPath),
      );

      // Allow more time for first request (DB may be loading)
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      AppLogger.d('Fingerprint: response ${response.statusCode}, body=${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');

      if (response.statusCode != 200) {
        AppLogger.d('Fingerprint API returned ${response.statusCode}: ${response.body}');
        return FingerprintResult.empty();
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = FingerprintResult.fromJson(data);
      AppLogger.d('Fingerprint: score=${result.score}%, animal=${result.animal}, hashes=${result.totalUserHashes}');
      return result;
    } catch (e) {
      AppLogger.d('Fingerprint match error: $e');
      return FingerprintResult.empty();
    }
  }
}
