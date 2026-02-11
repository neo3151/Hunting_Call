import 'package:firedart/firedart.dart';
import 'package:flutter/foundation.dart';
import '../domain/profile_model.dart';
import '../../rating/domain/rating_model.dart';
import 'profile_repository.dart';

class FiredartProfileRepository implements ProfileRepository {
  Firestore get _firestore => Firestore.instance;
  final String _collectionPath = 'profiles';

  @override
  Future<UserProfile> getProfile([String? userId]) async {
    if (userId == null || userId == 'guest') {
      return UserProfile.guest();
    }

    return _withRetry(() async {
      debugPrint("FiredartProfileRepository: Fetching profile for $userId...");
      final doc = await _firestore.collection(_collectionPath).document(userId).get().timeout(const Duration(seconds: 10), onTimeout: () {
          throw Exception("Firestore get() timed out after 10 seconds");
      });
      debugPrint("FiredartProfileRepository: Profile fetched for $userId.");
      final data = doc.map;
      _sanitizeProfileData(data, doc.id);
      return UserProfile.fromJson(data);
    }, "getProfile");
  }

  @override
  Future<List<UserProfile>> getAllProfiles() async {
    return _withRetry(() async {
      final docs = await _firestore.collection(_collectionPath).get();
      return docs.map((doc) {
        final data = doc.map;
        _sanitizeProfileData(data, doc.id);
        return UserProfile.fromJson(data);
      }).toList();
    }, "getAllProfiles");
  }

  @override
  Future<List<UserProfile>> getProfilesByEmail(String email) async {
    return _withRetry(() async {
      final query = await _firestore.collection(_collectionPath).where('email', isEqualTo: email).get();
      if (query.isEmpty) return [];
      
      return query.map((doc) {
        final data = doc.map;
        _sanitizeProfileData(data, doc.id);
        return UserProfile.fromJson(data);
      }).toList();
    }, "getProfilesByEmail");
  }

  /// Helper to retry Firestore operations on Linux when hit by transient SignedOutExceptions
  Future<T> _withRetry<T>(Future<T> Function() action, String label) async {
    // Retry up to 3 times to cover the re-auth window (1-3 seconds)
    int retries = 3;
    while (retries > 0) {
      try {
        return await action();
      } catch (e) {
        final errorStr = e.toString();
        if ((errorStr.contains('SignedOutException') || errorStr.contains('User signed out')) && retries > 1) {
          debugPrint("FiredartProfileRepository: $label - Auth not ready, retries left: ${retries - 1}. Waiting 1s...");
          await Future.delayed(const Duration(seconds: 1));
          retries--;
          continue;
        }
        debugPrint("FiredartProfileRepository: $label ERROR: $e");
        rethrow;
      }
    }
    throw Exception("$label: Failed after maximum retries.");
  }

  void _sanitizeProfileData(Map<String, dynamic> data, String docId) {
    data['id'] = data['id'] ?? docId;
    data['name'] = data['name'] ?? 'Hunter';
    
    // Firedart returns DateTime objects for timestamps, but json_serializable expects Strings
    if (data['joinedDate'] is DateTime) {
      data['joinedDate'] = (data['joinedDate'] as DateTime).toIso8601String();
    } else if (data['joinedDate'] == null) {
      data['joinedDate'] = DateTime.now().toIso8601String();
    }

    if (data['lastDailyChallengeDate'] is DateTime) {
      data['lastDailyChallengeDate'] = (data['lastDailyChallengeDate'] as DateTime).toIso8601String();
    }

    // Handle history items
    if (data['history'] != null && data['history'] is List) {
      final historyList = data['history'] as List;
      for (var item in historyList) {
        if (item is Map && item['timestamp'] is DateTime) {
          item['timestamp'] = (item['timestamp'] as DateTime).toIso8601String();
        }
      }
    }
  }

  @override
  Future<UserProfile> createProfile(String name, {String? id, DateTime? birthday, String? email}) async {
    return _withRetry(() async {
      final docId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final docRef = _firestore.collection(_collectionPath).document(docId);
          
      final newProfile = UserProfile(
        id: docId,
        name: name,
        email: email,
        joinedDate: DateTime.now(),
        birthday: birthday,
      );
      await docRef.set(newProfile.toJson());
      return newProfile;
    }, "createProfile");
  }

  @override
  Future<void> saveResultForUser(String userId, RatingResult result, String animalId) async {
    if (userId == 'guest') return;

    await _withRetry(() async {
      final newItem = HistoryItem(
        result: result,
        timestamp: DateTime.now(),
        animalId: animalId,
      );

      final data = newItem.toJson();
      
      final doc = await _firestore.collection(_collectionPath).document(userId).get();
      Map<String, dynamic> existingData = doc.map;
      
      List<dynamic> history = List.from(existingData['history'] ?? []);
      history.add(data);
      
      int totalCalls = (existingData['totalCalls'] as int? ?? 0) + 1;
      
      await _firestore.collection(_collectionPath).document(userId).update({
        'history': history,
        'totalCalls': totalCalls,
        'joinedDate': existingData['joinedDate'] ?? DateTime.now().toIso8601String(),
      });
    }, "saveResultForUser");
  }

  @override
  Future<void> saveAchievements(String userId, List<String> achievementIds) async {
    if (userId == 'guest' || achievementIds.isEmpty) return;

    await _withRetry(() async {
      final doc = await _firestore.collection(_collectionPath).document(userId).get();
      Map<String, dynamic> existingData = doc.map;
      
      Set<String> achievements = Set.from(existingData['achievements'] ?? []);
      achievements.addAll(achievementIds);
      
      await _firestore.collection(_collectionPath).document(userId).update({
        'achievements': achievements.toList(),
      });
    }, "saveAchievements");
  }

  @override
  Future<void> updateDailyChallengeStats(String userId) async {
    if (userId == 'guest') return;

    await _withRetry(() async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final doc = await _firestore.collection(_collectionPath).document(userId).get();
      // doc is non-nullable in firedart
      
      final data = doc.map;
      final lastDateMillis = data['lastDailyChallengeDate'] as int?;
      final lastDate = lastDateMillis != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastDateMillis) 
          : null;
          
      bool shouldIncrement = false;
      if (lastDate == null) {
        shouldIncrement = true;
      } else {
        final lastDateDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
        if (lastDateDay.isBefore(today)) {
          shouldIncrement = true;
        }
      }
      
      if (shouldIncrement) {
        int currentStreak = data['currentStreak'] as int? ?? 0;
        int longestStreak = data['longestStreak'] as int? ?? 0;
        
        bool isConsecutive = false;
        if (lastDate != null) {
          final lastDateDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
          final diff = today.difference(lastDateDay).inDays;
          if (diff == 1) isConsecutive = true;
        } else {
            isConsecutive = true;
        }
        
        int newStreak = isConsecutive ? currentStreak + 1 : 1;
        int newLongest = newStreak > longestStreak ? newStreak : longestStreak;
        int totalCompleted = (data['dailyChallengesCompleted'] as int? ?? 0) + 1;

        await _firestore.collection(_collectionPath).document(userId).update({
          'dailyChallengesCompleted': totalCompleted,
          'lastDailyChallengeDate': now.millisecondsSinceEpoch,
          'currentStreak': newStreak,
          'longestStreak': newLongest,
        });
      }
    }, "updateDailyChallengeStats");
  }

  @override
  Future<void> setPremiumStatus(String userId, bool isPremium) async {
    return _withRetry(() async {
      await _firestore.collection(_collectionPath).document(userId).update({
        'isPremium': isPremium,
      });
      debugPrint("✅ Firedart: Set isPremium=$isPremium for $userId");
    }, "setPremiumStatus");
  }
}
