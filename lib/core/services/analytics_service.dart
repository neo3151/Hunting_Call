import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:outcall/core/utils/app_logger.dart';

/// Lightweight analytics event tracking backed by Firebase Analytics.
///
/// Wraps Firebase Analytics to track key user actions for
/// understanding feature usage and engagement.
class AnalyticsService {
  AnalyticsService._();

  static FirebaseAnalytics? _instance;
  static bool _enabled = true;

  static void initialize() {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        _instance = FirebaseAnalytics.instance;
        AppLogger.d('📊 Analytics: Firebase Analytics initialized');
      } catch (e) {
        AppLogger.d('📊 Analytics: Firebase Analytics unavailable: $e');
      }
    }
  }

  static void setEnabled(bool enabled) => _enabled = enabled;

  // ─── Core events ──────────────────────────────────────────────────────

  static void logRecordingStarted(String animalId) {
    _log('recording_started', {'animal_id': animalId});
  }

  static void logRecordingCompleted(String animalId, double score) {
    _log('recording_completed', {'animal_id': animalId, 'score': score});
  }

  /// Track when the noise gate or backend rejects a call attempt.
  static void logRecordingRejected(String animalId, String reason) {
    _log('recording_rejected', {'animal_id': animalId, 'reason': reason});
  }

  /// Track how long the full scoring pipeline took from the user's perspective.
  static void logScoringLatency(String animalId, int durationMs) {
    _log('scoring_latency', {'animal_id': animalId, 'duration_ms': durationMs});
  }

  static void logDailyChallengeStarted(String animalId) {
    _log('daily_challenge_started', {'animal_id': animalId});
  }

  static void logDailyChallengeCompleted(String animalId, double score) {
    _log('daily_challenge_completed', {'animal_id': animalId, 'score': score});
  }

  static void logAchievementUnlocked(String achievementId) {
    _log('achievement_unlocked', {'achievement_id': achievementId});
  }

  static void logLeaderboardViewed(String animalId) {
    _log('leaderboard_viewed', {'animal_id': animalId});
  }

  static void logShareScore(String animalId, double score) {
    _log('share_score', {'animal_id': animalId, 'score': score});
  }

  // ─── Navigation events ────────────────────────────────────────────────

  static void logScreenView(String screenName) {
    _instance?.logScreenView(screenName: screenName);
    AppLogger.d('📊 Analytics: screen_view {screen_name: $screenName}');
  }

  static void logLibraryBrowse(String category) {
    _log('library_browse', {'category': category});
  }

  // ─── Monetization events ──────────────────────────────────────────────

  static void logPaywallViewed() {
    _log('paywall_viewed', {});
  }

  /// Track if they closed the paywall without buying (and where they were).
  static void logPaywallAbandoned(String lastVisibleSection) {
    _log('paywall_abandoned', {'last_section': lastVisibleSection});
  }

  static void logPurchaseStarted(String productId) {
    _log('purchase_started', {'product_id': productId});
  }

  static void logPurchaseCompleted(String productId) {
    _log('purchase_completed', {'product_id': productId});
  }

  // ─── Calibration events ───────────────────────────────────────────────

  static void logCalibrationPerformed(double scoreOffset, double micSensitivity) {
    _log('calibration_performed', {
      'score_offset': scoreOffset,
      'mic_sensitivity': micSensitivity,
    });
  }

  // ─── User Properties ──────────────────────────────────────────────────

  /// Set persistent traits to filter your entire dashboard by.
  static void setUserProperties({
    required bool isPremium,
    required String appVersion,
    String? lastAnimalUsed,
  }) {
    if (!_enabled) return;
    _instance?.setUserProperty(name: 'user_status', value: isPremium ? 'premium' : 'free');
    _instance?.setUserProperty(name: 'app_version', value: appVersion);
    if (lastAnimalUsed != null) {
      _instance?.setUserProperty(name: 'last_animal', value: lastAnimalUsed);
    }
    AppLogger.d('📊 Analytics: setUserProperties {premium: $isPremium, version: $appVersion}');
  }

  // ─── Internal ─────────────────────────────────────────────────────────

  static void _log(String event, Map<String, Object> params) {
    if (!_enabled) return;
    _instance?.logEvent(name: event, parameters: params);
    AppLogger.d('📊 Analytics: $event $params');
  }
}
