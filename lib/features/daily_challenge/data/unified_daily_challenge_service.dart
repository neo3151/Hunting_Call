import 'package:outcall/core/services/api_gateway.dart';
import 'package:outcall/core/services/simple_storage.dart';
import 'package:outcall/features/daily_challenge/domain/daily_challenge_repository.dart';
import 'package:outcall/core/utils/app_logger.dart';

class UnifiedDailyChallengeService implements DailyChallengeRepository {
  final ApiGateway? _apiGateway;
  final ISimpleStorage _storage;

  static const String _cacheKey = 'cached_daily_challenge_id';
  static const String _cacheDateKey = 'cached_daily_challenge_date';

  UnifiedDailyChallengeService(this._apiGateway, this._storage);

  @override
  Future<String?> getDailyChallengeId() async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    // 1. Try to fetch from Cloud
    if (_apiGateway != null) {
      try {
        final docData = await _apiGateway!
            .getDocument('config', 'daily_challenge')
            .timeout(const Duration(seconds: 3));
            
        if (docData != null && docData.containsKey('callId')) {
          final String callId = docData['callId'] as String;
          
          // Cache it for offline use
          await _storage.setString(_cacheKey, callId);
          await _storage.setString(_cacheDateKey, todayStr);
          
          AppLogger.d('🌍 Fetched Daily Challenge from Cloud: $callId');
          return callId;
        }
      } catch (e) {
        AppLogger.d('⚠️ Failed to fetch Daily Challenge from Cloud (or timed out): $e');
        // Let it fall through to cache
      }
    }

    // 2. Fallback to offline cache
    AppLogger.d('📱 Falling back to Offline Cache for Daily Challenge');
    final cachedDate = await _storage.getString(_cacheDateKey);
    final cachedId = await _storage.getString(_cacheKey);

    // If we have a cached ID from today, use it.
    // If it's a different day, the cloud fetch failed, so we'll let it return null 
    // and let the UseCase fallback to the mathematical algorithm.
    if (cachedDate == todayStr && cachedId != null) {
      AppLogger.d('💾 Found cached Daily Challenge: $cachedId');
      return cachedId;
    }

    // 3. Complete fallback (return null so UseCase handles mathematical calc)
    AppLogger.d('❌ No active Cloud or Cached Daily Challenge found.');
    return null;
  }
}
