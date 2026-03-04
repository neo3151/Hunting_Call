import 'package:cloud_functions/cloud_functions.dart';
import 'package:outcall/features/leaderboard/domain/leaderboard_entry.dart';
import 'package:outcall/features/leaderboard/domain/repositories/leaderboard_service.dart';
import 'package:outcall/core/services/api_gateway.dart';
import 'package:outcall/core/utils/app_logger.dart';

/// Cloud Function–backed leaderboard service for mobile platforms.
///
/// Score submissions go through the deployed `submitScore` callable,
/// which runs server-side Firestore transactions with 25 retries —
/// eliminating client-side contention failures.
///
/// Reads still stream directly from Firestore for real-time updates.
class CloudFunctionLeaderboardService implements LeaderboardService {
  final ApiGateway _apiGateway;
  final FirebaseFunctions _functions;

  CloudFunctionLeaderboardService(this._apiGateway, {FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  @override
  Future<bool> submitScore({
    required String animalId,
    required LeaderboardEntry entry,
  }) async {
    try {
      final callable = _functions.httpsCallable('submitScore');
      final result = await callable.call<Map<String, dynamic>>({
        'animalId': animalId,
        'userId': entry.userId,
        'userName': entry.userName,
        'score': entry.score,
        'profileImageUrl': entry.profileImageUrl,
        'isAlphaTester': entry.isAlphaTester,
      });

      final accepted = result.data['accepted'] as bool? ?? false;
      final reason = result.data['reason'] as String?;

      if (!accepted) {
        AppLogger.d('☁️ CF submitScore: Rejected — $reason');
      } else {
        AppLogger.d('☁️ CF submitScore: Accepted for $animalId');
      }

      return accepted;
    } catch (e) {
      AppLogger.d('❌ CF submitScore failed: $e');
      // Don't crash the app over a leaderboard failure
      return false;
    }
  }

  @override
  Stream<List<LeaderboardEntry>> getTopScores(String animalId) {
    // Reads still go direct — real-time streaming from Firestore
    return _apiGateway.streamDocument('leaderboards', animalId).map((data) {
      if (data == null || !data.containsKey('scores')) {
        return [];
      }
      final List<dynamic> rawList = data['scores'];
      return rawList.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
    });
  }
}
