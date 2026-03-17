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

/// Service that provides audio fingerprint matching.
///
/// Previously this uploaded audio to the Python backend's `/api/fingerprint`
/// endpoint (Railway). Now runs in offline mode — returns empty results.
/// The Expert scoring pipeline gracefully falls back to pitch-based scoring
/// when fingerprint data is unavailable.
class FingerprintService {
  /// Match a user's audio recording against the fingerprint database.
  ///
  /// Currently returns empty (backend offline). The calling code in
  /// [RealRatingService] and [QuickMatchScreen] handles empty results
  /// gracefully by falling back to on-device scoring.
  static Future<FingerprintResult> match(
    String audioPath, {
    String? baseUrl,
  }) async {
    AppLogger.d('Fingerprint: running in offline mode (server-side matching not available)');
    return FingerprintResult.empty();
  }
}
