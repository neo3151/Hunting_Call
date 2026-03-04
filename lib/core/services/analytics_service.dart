import 'package:outcall/core/utils/app_logger.dart';

/// Lightweight analytics event tracking.
///
/// Wraps Firebase Analytics (or any other provider) to track
/// key user actions for understanding feature usage and engagement.
class AnalyticsService {
  AnalyticsService._();

  static bool _enabled = true;

  static void setEnabled(bool enabled) => _enabled = enabled;

  // ─── Core events ──────────────────────────────────────────────────────

  static void logRecordingStarted(String animalId) {
    _log('recording_started', {'animal_id': animalId});
  }

  static void logRecordingCompleted(String animalId, double score) {
    _log('recording_completed', {'animal_id': animalId, 'score': score});
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
    _log('screen_view', {'screen_name': screenName});
  }

  static void logLibraryBrowse(String category) {
    _log('library_browse', {'category': category});
  }

  // ─── Monetization events ──────────────────────────────────────────────

  static void logPaywallViewed() {
    _log('paywall_viewed', {});
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

  // ─── Internal ─────────────────────────────────────────────────────────

  static void _log(String event, Map<String, dynamic> params) {
    if (!_enabled) return;
    // TODO: Wire to Firebase Analytics when ready:
    // FirebaseAnalytics.instance.logEvent(name: event, parameters: params);
    AppLogger.d('📊 Analytics: $event $params');
  }
}
