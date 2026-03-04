import 'package:outcall/core/utils/app_logger.dart';

/// Deep link routing configuration.
///
/// Handles Firebase Dynamic Links and standard app links for:
/// - Profile sharing: outcall.app/profile/{userId}
/// - Challenge invites: outcall.app/challenge/{challengeId}
/// - Score sharing: outcall.app/score/{animalId}/{score}
class DeepLinkService {
  DeepLinkService._();

  /// Initialize deep link handling.
  static Future<void> initialize() async {
    // TODO: Wire to Firebase Dynamic Links when ready:
    // final PendingDynamicLinkData? initialLink =
    //     await FirebaseDynamicLinks.instance.getInitialLink();
    // if (initialLink != null) handleLink(initialLink.link);
    //
    // FirebaseDynamicLinks.instance.onLink.listen((data) {
    //   handleLink(data.link);
    // });
    AppLogger.d('DeepLinkService: Initialized (pending Firebase setup)');
  }

  /// Handle an incoming deep link.
  static void handleLink(Uri link) {
    final segments = link.pathSegments;
    if (segments.isEmpty) return;

    switch (segments[0]) {
      case 'profile':
        if (segments.length > 1) {
          AppLogger.d('DeepLink: Navigate to profile ${segments[1]}');
          // TODO: Navigate to profile screen
        }
        break;
      case 'challenge':
        if (segments.length > 1) {
          AppLogger.d('DeepLink: Navigate to challenge ${segments[1]}');
          // TODO: Navigate to daily challenge
        }
        break;
      case 'score':
        if (segments.length > 2) {
          AppLogger.d('DeepLink: Navigate to score ${segments[1]}/${segments[2]}');
          // TODO: Navigate to leaderboard for the animal
        }
        break;
      default:
        AppLogger.d('DeepLink: Unknown route: ${link.toString()}');
    }
  }

  /// Generate a shareable link for a score.
  static String generateScoreLink(String animalId, double score) {
    return 'https://outcall.app/score/$animalId/${score.toStringAsFixed(0)}';
  }

  /// Generate a shareable profile link.
  static String generateProfileLink(String userId) {
    return 'https://outcall.app/profile/$userId';
  }
}
