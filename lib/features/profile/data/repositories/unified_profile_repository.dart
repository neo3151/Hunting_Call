import 'package:outcall/core/services/api_gateway.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/core/utils/profanity_filter.dart';
import 'package:outcall/core/utils/spam_filter.dart';
import 'package:outcall/features/profile/data/datasources/local_profile_data_source.dart';
import 'package:outcall/features/profile/domain/entities/user_profile.dart';
import 'package:outcall/features/profile/domain/repositories/profile_repository.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';

class UnifiedProfileRepository implements ProfileRepository {
  final ApiGateway _apiGateway;
  final ProfileDataSource? _localDataSource;

  final String _collectionPath = 'profiles';

  UnifiedProfileRepository(this._apiGateway, {ProfileDataSource? localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<UserProfile> getProfile([String? userId]) async {
    if (userId == null || userId == 'guest') {
      if (_localDataSource != null) {
        final localProf = await _localDataSource!.getProfile('guest');
        return localProf;
      }
      return UserProfile.guest();
    }

    try {
      final data = await _apiGateway
          .getDocument(_collectionPath, userId)
          .timeout(const Duration(seconds: 8));
      UserProfile profile;
      if (data != null) {
        _sanitizeProfileData(data, userId);
        profile = UserProfile.fromJson(data);
      } else {
        profile = UserProfile.guest();
      }

      // Cloud is the source of truth for premium status.
      // Write-through: cache cloud profile locally for offline fallback.
      if (_localDataSource != null && profile.id != 'guest') {
        try {
          await _localDataSource!.saveProfile(profile);
        } catch (_) {
          // Non-critical — don't block return if local save fails
        }
      }

      return profile;
    } catch (e) {
      AppLogger.d('UnifiedProfileRepository: getProfile cloud ERROR: $e');

      // Fallback to local cache if cloud fails
      if (_localDataSource != null) {
        try {
          final localProfile = await _localDataSource!.getProfile(userId);
          // Local data source returns a default 'New Hunter' if no cache exists.
          // Only use it if it looks like a real cached profile.
          if (localProfile.id == userId) {
            AppLogger.d('UnifiedProfileRepository: ✅ Loaded profile from local fallback');
            return localProfile;
          }
        } catch (localErr) {
          AppLogger.d('UnifiedProfileRepository: local fallback also failed: $localErr');
        }
      }

      rethrow;
    }
  }

  @override
  Future<List<UserProfile>> getAllProfiles() async {
    try {
      final docs = await _apiGateway.getCollection(_collectionPath);
      if (docs.isEmpty) return [];

      return docs.map((data) {
        final id = data['id'] as String? ?? 'unknown';
        _sanitizeProfileData(data, id);
        try {
          return UserProfile.fromJson(data);
        } catch (e) {
          return UserProfile(
            id: id,
            name: data['name'] ?? 'Error Profile',
            joinedDate: DateTime.now(),
          );
        }
      }).toList();
    } catch (e) {
      AppLogger.d('❌ UnifiedProfileRepository: getAllProfiles ERROR: $e');
      rethrow;
    }
  }

  @override
  Future<List<UserProfile>> getProfilesByEmail(String email) async {
    try {
      final docs = await _apiGateway.queryCollection(_collectionPath, 'email', email);
      if (docs.isEmpty) return [];

      return docs.map((data) {
        final id = data['id'] as String? ?? 'unknown';
        _sanitizeProfileData(data, id);
        return UserProfile.fromJson(data);
      }).toList();
    } catch (e) {
      AppLogger.d('❌ Error getting profiles by email: $e');
      return [];
    }
  }

  void _sanitizeProfileData(Map<String, dynamic> data, String docId) {
    data['id'] = data['id'] ?? docId;
    data['name'] = data['name'] ?? 'Hunter';

    // Clean offensive names/nicknames on read
    if (data['name'] is String) {
      data['name'] = ProfanityFilter.cleanName(data['name'] as String);
    }
    if (data['nickname'] is String && (data['nickname'] as String).isNotEmpty) {
      data['nickname'] = ProfanityFilter.cleanName(data['nickname'] as String);
    }
    // Handle Timestamp (Firebase) or DateTime (Firedart) to ISO String
    if (data['joinedDate'] != null && data['joinedDate'] is! String) {
      try {
        data['joinedDate'] = data['joinedDate'].toDate().toIso8601String();
      } catch (_) {
        // Firedart uses DateTime directly
        if (data['joinedDate'] is DateTime) {
          data['joinedDate'] = (data['joinedDate'] as DateTime).toIso8601String();
        }
      }
    } else if (data['joinedDate'] == null) {
      data['joinedDate'] = DateTime.now().toIso8601String();
    }

    if (data['lastDailyChallengeDate'] != null &&
        data['lastDailyChallengeDate'] is! String &&
        data['lastDailyChallengeDate'] is! int) {
      try {
        data['lastDailyChallengeDate'] = data['lastDailyChallengeDate'].toDate().toIso8601String();
      } catch (_) {
        if (data['lastDailyChallengeDate'] is DateTime) {
          data['lastDailyChallengeDate'] =
              (data['lastDailyChallengeDate'] as DateTime).toIso8601String();
        }
      }
    }

    if (data['lastActiveAt'] != null &&
        data['lastActiveAt'] is! String &&
        data['lastActiveAt'] is! int) {
      try {
        data['lastActiveAt'] = data['lastActiveAt'].toDate().toIso8601String();
      } catch (_) {
        if (data['lastActiveAt'] is DateTime) {
          data['lastActiveAt'] = (data['lastActiveAt'] as DateTime).toIso8601String();
        }
      }
    }

    if (data['history'] != null && data['history'] is List) {
      final historyList = data['history'] as List;
      for (var item in historyList) {
        if (item is Map && item['timestamp'] != null && item['timestamp'] is! String) {
          try {
            item['timestamp'] = item['timestamp'].toDate().toIso8601String();
          } catch (_) {
            if (item['timestamp'] is DateTime) {
              item['timestamp'] = (item['timestamp'] as DateTime).toIso8601String();
            }
          }
        }
      }
      // Sort history newest-first by timestamp.
      // This fixes existing data that was stored in the wrong order.
      historyList.sort((a, b) {
        final tsA = a is Map ? (a['timestamp'] as String? ?? '') : '';
        final tsB = b is Map ? (b['timestamp'] as String? ?? '') : '';
        return tsB.compareTo(tsA); // Descending: newest first
      });
    }
  }

  @override
  Future<UserProfile> createProfile(String name,
      {String? id, DateTime? birthday, String? email}) async {
    try {
      final docId = id ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Spam detection — flag suspicious accounts but still create them
      final bool isFlagged = SpamFilter.isSuspiciousEmail(email);
      if (isFlagged) {
        final reason = SpamFilter.getSuspiciousReason(email);
        AppLogger.d('⚠️ SpamFilter: Flagging new profile ($docId) — $reason');
      }

      final newProfile = UserProfile(
        id: docId,
        name: name,
        email: email,
        joinedDate: DateTime.now(),
        birthday: birthday,
        isAlphaTester: true,
      );

      final profileData = newProfile.toJson();
      if (isFlagged) {
        profileData['flagged'] = true;
        profileData['flagReason'] = SpamFilter.getSuspiciousReason(email);
      }

      await _apiGateway.setDocument(_collectionPath, docId, profileData);
      return newProfile;
    } catch (e) {
      AppLogger.d('UnifiedProfileRepository: createProfile ERROR: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveResultForUser(String userId, RatingResult result, String animalId) async {
    if (userId == 'guest') return;

    try {
      final newItem = HistoryItem(
        result: result,
        timestamp: DateTime.now(),
        animalId: animalId,
      );

      final data = newItem.toJson();

      Map<String, dynamic> existingData = {};
      final doc = await _apiGateway.getDocument(_collectionPath, userId);

      if (doc == null) {
        // Profile doesn't exist — create with first score as the average
        await _apiGateway.setDocument(_collectionPath, userId, {
          'id': userId,
          'name': 'Hunter',
          'joinedDate': DateTime.now().toIso8601String(),
          'history': [data],
          'totalCalls': 1,
          'averageScore': result.score,
          'isAlphaTester': true,
        });
        return;
      } else {
        existingData = doc;
      }

      final history = List<dynamic>.from(existingData['history'] ?? <dynamic>[]);
      history.insert(0, data);

      final totalCalls = (existingData['totalCalls'] as int? ?? 0) + 1;

      // Recalculate average score from all history entries
      double totalScore = 0;
      int scoredItems = 0;
      for (final item in history) {
        if (item is Map) {
          final r = item['result'];
          if (r is Map && r['score'] != null) {
            totalScore += (r['score'] as num).toDouble();
            scoredItems++;
          }
        }
      }
      final averageScore = scoredItems > 0 ? totalScore / scoredItems : 0.0;

      await _apiGateway.updateDocument(_collectionPath, userId, {
        'history': history,
        'totalCalls': totalCalls,
        'averageScore': averageScore,
        'id': userId, // Ensure core fields are there
        'joinedDate': existingData['joinedDate'] ?? DateTime.now().toIso8601String(),
        'isAlphaTester': true,
      });
    } catch (e) {
      AppLogger.d('UnifiedProfileRepository: saveResultForUser ERROR: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveAchievements(String userId, List<String> achievementIds) async {
    if (userId == 'guest' || achievementIds.isEmpty) return;

    final doc = await _apiGateway.getDocument(_collectionPath, userId);
    if (doc == null) {
      await _apiGateway.setDocument(_collectionPath, userId, {
        'id': userId,
        'name': 'Hunter',
        'joinedDate': DateTime.now().toIso8601String(),
        'achievements': achievementIds,
      });
      return;
    }

    final Set<String> achievements = Set.from(doc['achievements'] ?? []);
    achievements.addAll(achievementIds);

    await _apiGateway.updateDocument(_collectionPath, userId, {
      'achievements': achievements.toList(),
    });
  }

  @override
  Future<void> updateDailyChallengeStats(String userId) async {
    if (userId == 'guest') return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final doc = await _apiGateway.getDocument(_collectionPath, userId);

    if (doc == null) {
      // Profile doesn't exist
      await _apiGateway.setDocument(_collectionPath, userId, {
        'id': userId,
        'name': 'Hunter',
        'joinedDate': DateTime.now().toIso8601String(),
        'dailyChallengesCompleted': 1,
        'lastDailyChallengeDate': now.millisecondsSinceEpoch,
        'currentStreak': 1,
        'longestStreak': 1,
      });
      return;
    }

    final data = doc;

    final dynamic rawLastDate = data['lastDailyChallengeDate'];
    DateTime? lastDate;

    if (rawLastDate is int) {
      lastDate = DateTime.fromMillisecondsSinceEpoch(rawLastDate);
    } else if (rawLastDate is String) {
      lastDate = DateTime.tryParse(rawLastDate);
    }

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
      final int currentStreak = data['currentStreak'] as int? ?? 0;
      final int longestStreak = data['longestStreak'] as int? ?? 0;

      bool isConsecutive = false;
      if (lastDate != null) {
        final lastDateDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
        final diff = today.difference(lastDateDay).inDays;
        if (diff == 1) isConsecutive = true;
      } else {
        isConsecutive = true;
      }

      final int newStreak = isConsecutive ? currentStreak + 1 : 1;
      final int newLongest = newStreak > longestStreak ? newStreak : longestStreak;
      final int totalCompleted = (data['dailyChallengesCompleted'] as int? ?? 0) + 1;

      await _apiGateway.updateDocument(_collectionPath, userId, {
        'dailyChallengesCompleted': totalCompleted,
        'lastDailyChallengeDate': now.millisecondsSinceEpoch,
        'currentStreak': newStreak,
        'longestStreak': newLongest,
      });
    }
  }

  @override
  Future<void> setPremiumStatus(String userId, bool isPremium) async {
    // 1. Always attempt local save (Hybrid Persistence)
    if (_localDataSource != null) {
      try {
        final localProfile = await _localDataSource!.getProfile(userId);
        final updated = localProfile.copyWith(isPremium: isPremium);
        await _localDataSource!.saveProfile(updated);
      } catch (e) {
        AppLogger.d('⚠️ Failed to save local backup of premium status: $e');
      }
    }

    if (userId == 'guest') {
      return;
    }

    // 2. Attempt Cloud Save
    try {
      final doc = await _apiGateway.getDocument(_collectionPath, userId);
      if (doc == null) {
        await _apiGateway.setDocument(_collectionPath, userId, {
          'id': userId,
          'name': 'Hunter',
          'joinedDate': DateTime.now().toIso8601String(),
          'isPremium': isPremium,
        });
      } else {
        await _apiGateway.updateDocument(_collectionPath, userId, {
          'isPremium': isPremium,
        });
      }
    } catch (e) {
      AppLogger.d('❌ ApiGateway: Error setting premium status: $e');
      if (_localDataSource == null) rethrow; // If no local, throw
    }
  }

  @override
  Future<List<UserProfile>> getTopGlobalUsers({int limit = 50}) async {
    try {
      final query = await _apiGateway
          .getTopDocuments(_collectionPath, 'averageScore', limit: limit)
          .timeout(const Duration(seconds: 8));

      AppLogger.d('📊 getTopGlobalUsers: orderBy query returned ${query.length} docs');

      List<UserProfile> profiles = query
          .map((data) {
            final id = data['id'] as String? ?? 'unknown';
            _sanitizeProfileData(data, id);
            try {
              var profile = UserProfile.fromJson(data);
              // Compute averageScore from history if stored value is 0
              if (profile.averageScore == 0 && profile.history.isNotEmpty) {
                final scores = profile.history
                    .where((h) => h.result.score > 0)
                    .map((h) => h.result.score)
                    .toList();
                if (scores.isNotEmpty) {
                  final computed = scores.reduce((a, b) => a + b) / scores.length;
                  profile = profile.copyWith(averageScore: computed);
                }
              }
              return profile;
            } catch (e) {
              AppLogger.d('⚠️ Failed to parse profile $id: $e');
              return UserProfile(
                id: id,
                name: data['name'] ?? 'Error Profile',
                joinedDate: DateTime.now(),
              );
            }
          })
          .where((p) => p.totalCalls > 0)
          .toList();

      // Fallback: if orderBy query returned nothing (profiles may lack the
      // 'averageScore' field), fetch all profiles and sort client-side.
      if (profiles.isEmpty) {
        AppLogger.d('📊 getTopGlobalUsers: orderBy empty, falling back to getAllProfiles');
        final allProfiles = await getAllProfiles();
        profiles = allProfiles
            .where((p) => p.totalCalls > 0)
            .toList()
          ..sort((a, b) => b.averageScore.compareTo(a.averageScore));
        if (profiles.length > limit) {
          profiles = profiles.sublist(0, limit);
        }
      }

      return profiles;
    } catch (e, st) {
      AppLogger.d('❌ Error getting top global users: $e\n$st');
      return [];
    }
  }

  @override
  Future<void> updateProfileDetails(String userId,
      {String? nickname, String? avatarUrl, DateTime? lastActiveAt}) async {
    // 1. Local backup if available
    if (_localDataSource != null) {
      try {
        final localProfile = await _localDataSource!.getProfile(userId);
        final updated = localProfile.copyWith(
            nickname: nickname, avatarUrl: avatarUrl, lastActiveAt: lastActiveAt);
        await _localDataSource!.saveProfile(updated);
      } catch (e) {
        AppLogger.d('⚠️ Failed to save local backup of profile details: $e');
      }
    }

    if (userId == 'guest') return;

    // 2. Cloud Update
    try {
      final updates = <String, dynamic>{};
      if (nickname != null) {
        // Safety net: clean offensive nicknames at the data layer
        updates['nickname'] = ProfanityFilter.cleanName(nickname);
      }
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      if (lastActiveAt != null) updates['lastActiveAt'] = lastActiveAt.toIso8601String();

      if (updates.isNotEmpty) {
        final doc = await _apiGateway.getDocument(_collectionPath, userId);
        if (doc == null) {
          await _apiGateway.setDocument(_collectionPath, userId, {
            'id': userId,
            'name': 'Hunter', // Fallback
            'joinedDate': DateTime.now().toIso8601String(),
            ...updates,
          });
        } else {
          await _apiGateway.updateDocument(_collectionPath, userId, updates);
        }
      }
    } catch (e) {
      AppLogger.d('❌ ApiGateway: Error updating profile details: $e');
      if (_localDataSource == null) rethrow; // If no local, throw
    }
  }

  @override
  Future<void> toggleFavoriteCall(String userId, String callId, bool isFavorite) async {
    // 1. Local backup if available
    if (_localDataSource != null) {
      try {
        final localProfile = await _localDataSource!.getProfile(userId);
        final currentFavorites = List<String>.from(localProfile.favoriteCallIds);

        if (isFavorite && !currentFavorites.contains(callId)) {
          currentFavorites.add(callId);
        } else if (!isFavorite && currentFavorites.contains(callId)) {
          currentFavorites.remove(callId);
        }

        final updated = localProfile.copyWith(favoriteCallIds: currentFavorites);
        await _localDataSource!.saveProfile(updated);
      } catch (e) {
        AppLogger.d('⚠️ Failed to save local backup of favorites: $e');
      }
    }

    if (userId == 'guest') return;

    // 2. Cloud Update
    try {
      final doc = await _apiGateway.getDocument(_collectionPath, userId);
      List<String> currentFavorites = [];

      if (doc != null && doc['favoriteCallIds'] != null) {
        currentFavorites = List<String>.from(doc['favoriteCallIds']);
      }

      if (isFavorite && !currentFavorites.contains(callId)) {
        currentFavorites.add(callId);
      } else if (!isFavorite && currentFavorites.contains(callId)) {
        currentFavorites.remove(callId);
      }

      if (doc == null) {
        await _apiGateway.setDocument(_collectionPath, userId, {
          'id': userId,
          'name': 'Hunter',
          'joinedDate': DateTime.now().toIso8601String(),
          'favoriteCallIds': currentFavorites,
        });
      } else {
        await _apiGateway.updateDocument(_collectionPath, userId, {
          'favoriteCallIds': currentFavorites,
        });
      }
    } catch (e) {
      AppLogger.d('❌ ApiGateway: Error toggling favorite call: $e');
      if (_localDataSource == null) rethrow;
    }
  }

  @override
  Future<void> logProfanityViolation({
    required String userId,
    required String attemptedName,
    required String matchedTerm,
  }) async {
    try {
      await _apiGateway.addDocument('profanity_violations', {
        'userId': userId,
        'attemptedName': attemptedName,
        'matchedTerm': matchedTerm,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.d('⚠️ Failed to log profanity violation to Firestore: $e');
    }
  }

  @override
  Future<int> getViolationCount(String userId) async {
    try {
      final docs = await _apiGateway.queryCollection('profanity_violations', 'userId', userId);
      return docs.length;
    } catch (e) {
      AppLogger.d('⚠️ Failed to get violation count: $e');
      return 0;
    }
  }

  @override
  Future<void> restrictUserName(String userId) async {
    try {
      await _apiGateway.updateDocument(_collectionPath, userId, {
        'nameRestricted': true,
        'nickname': null,
      });
    } catch (e) {
      AppLogger.d('⚠️ Failed to restrict user name: $e');
    }
  }
}
