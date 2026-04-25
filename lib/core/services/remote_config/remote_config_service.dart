import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/core/utils/profanity_filter.dart';
import 'package:outcall/features/rating/data/ai_coach_service.dart';

/// Provider for the RemoteConfigService
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    return RemoteConfigService(null);
  }
  return RemoteConfigService(FirebaseRemoteConfig.instance);
});

/// A service that wraps Firebase Remote Config to fetch and provide feature flags
class RemoteConfigService {
  final FirebaseRemoteConfig? _remoteConfig;

  RemoteConfigService(this._remoteConfig);

  /// Initializes the remote config service with default values and settings
  Future<void> initialize() async {
    if (_remoteConfig == null) return;
    try {
      // Set default values before fetching
      await _remoteConfig!.setDefaults(const {
        'is_leaderboard_enabled': true,
        'profanity_blocklist': '', // Comma-separated extra blocked terms
        'ai_coach_url': '',
      });

      // Configure fetch interval (e.g., fetch every 1 hour, or 0 during dev)
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(seconds: 0),
      ));

      // Fetch and activate the latest values from Firebase
      await _remoteConfig!.fetchAndActivate();

      // Load remote profanity terms into the filter
      _loadProfanityTerms();

      // Inject Gemini API key into the AI Coach service
      _loadGeminiApiKey();
    } catch (e) {
      // If fetching fails (e.g., no internet), it will safely use the defaults
      AppLogger.d('Remote Config fetch failed: $e');
    }
  }

  /// The Kill Switch: checks if the leaderboard feature is currently enabled
  bool get isLeaderboardEnabled => _remoteConfig?.getBool('is_leaderboard_enabled') ?? true;

  /// Dynamic AI Coach URL — update in Firebase Console when tunnel changes
  String get aiCoachUrl => _remoteConfig?.getString('ai_coach_url').isNotEmpty == true
      ? _remoteConfig!.getString('ai_coach_url')
      : 'http://10.0.2.2:8000';

  /// Parses the remote profanity blocklist and loads it into ProfanityFilter.
  void _loadProfanityTerms() {
    final raw = _remoteConfig?.getString('profanity_blocklist') ?? '';
    if (raw.isEmpty) return;

    final terms =
        raw.split(',').map((t) => t.trim().toLowerCase()).where((t) => t.isNotEmpty).toList();

    if (terms.isNotEmpty) {
      ProfanityFilter.loadRemoteTerms(terms);
    }
  }

  /// Loads the Gemini API key from Remote Config and injects it into the AI Coach.
  void _loadGeminiApiKey() {
    final key = _remoteConfig?.getString('gemini_api_key') ?? '';
    if (key.isNotEmpty) {
      AiCoachService.setApiKey(key);
      AppLogger.d('Gemini API key loaded from Remote Config');
    }
  }
}
