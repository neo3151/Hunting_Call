import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/core/services/simple_storage.dart';

/// Service for showing in-app review prompts at the right moment.
///
/// Triggers after positive moments: high scores, achievement unlocks, etc.
/// Uses counters and cooldowns to avoid annoying users.
class AppRatingService {
  static const _keyLastPrompt = 'app_rating_last_prompt';
  static const _keySessionCount = 'app_rating_session_count';
  static const _keyHasRated = 'app_rating_has_rated';
  static const _minSessionsBeforePrompt = 5;
  static const _cooldownDays = 30;

  final ISimpleStorage _storage;

  AppRatingService(this._storage);

  /// Call this after a positive moment (high score, achievement).
  /// Returns true if a review prompt should be shown.
  Future<bool> shouldPromptReview() async {
    // Never prompt again if user already rated
    final hasRated = await _storage.getBool(_keyHasRated) ?? false;
    if (hasRated) return false;

    // Check session count threshold
    final sessionCount = (await _storage.getInt(_keySessionCount) ?? 0) + 1;
    await _storage.setInt(_keySessionCount, sessionCount);
    if (sessionCount < _minSessionsBeforePrompt) return false;

    // Check cooldown
    final lastPromptStr = await _storage.getString(_keyLastPrompt);
    if (lastPromptStr != null) {
      final lastPrompt = DateTime.tryParse(lastPromptStr);
      if (lastPrompt != null &&
          DateTime.now().difference(lastPrompt).inDays < _cooldownDays) {
        return false;
      }
    }

    // All conditions met — show prompt
    await _storage.setString(_keyLastPrompt, DateTime.now().toIso8601String());
    AppLogger.d('AppRatingService: Prompting user for review');
    return true;
  }

  /// Call when the user has submitted a review.
  Future<void> markAsRated() async {
    await _storage.setBool(_keyHasRated, true);
  }
}
