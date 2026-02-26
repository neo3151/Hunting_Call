import 'package:outcall/features/profile/domain/entities/user_profile.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';
import 'package:outcall/features/profile/domain/repositories/profile_repository.dart';
import 'package:outcall/features/profile/data/datasources/local_profile_data_source.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/core/services/api_gateway.dart';

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
      final data = await _apiGateway.getDocument(_collectionPath, userId);
      UserProfile profile;
      if (data != null) {
        _sanitizeProfileData(data, userId);
        profile = UserProfile.fromJson(data);
      } else {
        profile = UserProfile.guest(); 
      }

      // Hybrid Check: If not premium in Cloud, check Local Storage override
      if (!profile.isPremium && _localDataSource != null) {
        try {
           final localProfile = await _localDataSource!.getProfile(userId);
           if (localProfile.isPremium) {
             profile = profile.copyWith(isPremium: true);
           }
        } catch (e) {
          // Ignore local read errors, trust cloud
        }
      }
      
      return profile;
    } catch (e) {
      AppLogger.d('UnifiedProfileRepository: getProfile ERROR: $e');
      return UserProfile.guest();
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
    } catch(e) {
       AppLogger.d('❌ Error getting profiles by email: $e');
       return [];
    }
  }

  void _sanitizeProfileData(Map<String, dynamic> data, String docId) {
    data['id'] = data['id'] ?? docId;
    data['name'] = data['name'] ?? 'Hunter';
    
    // Handle Timestamp (Firebase) or DateTime (Firedart) to ISO String
    if (data['joinedDate'] != null && data['joinedDate'] is! String) {
        try {
            data['joinedDate'] = data['joinedDate'].toDate().toIso8601String();
        } catch (_) { // Firedart uses DateTime directly
             if (data['joinedDate'] is DateTime) {
                 data['joinedDate'] = (data['joinedDate'] as DateTime).toIso8601String();
             }
        }
    } else if (data['joinedDate'] == null) {
      data['joinedDate'] = DateTime.now().toIso8601String();
    }

    if (data['lastDailyChallengeDate'] != null && data['lastDailyChallengeDate'] is! String && data['lastDailyChallengeDate'] is! int) {
       try {
            data['lastDailyChallengeDate'] = data['lastDailyChallengeDate'].toDate().toIso8601String();
       } catch (_) {
           if (data['lastDailyChallengeDate'] is DateTime) {
                data['lastDailyChallengeDate'] = (data['lastDailyChallengeDate'] as DateTime).toIso8601String();
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
    }
  }

  @override
  Future<UserProfile> createProfile(String name, {String? id, DateTime? birthday, String? email}) async {
    try {
      final docId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
          
      final newProfile = UserProfile(
        id: docId,
        name: name,
        email: email,
        joinedDate: DateTime.now(),
        birthday: birthday,
        isAlphaTester: true,
      );
      
      await _apiGateway.setDocument(_collectionPath, docId, newProfile.toJson());
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
          // Profile doesn't exist
          await _apiGateway.setDocument(_collectionPath, userId, {
            'id': userId,
            'name': 'Hunter',
            'joinedDate': DateTime.now().toIso8601String(),
            'history': [data],
            'totalCalls': 1,
            'isAlphaTester': true,
          });
          return;
      } else {
          existingData = doc;
      }

      final history = List<dynamic>.from(existingData['history'] ?? <dynamic>[]);
      history.add(data);
      
      final totalCalls = (existingData['totalCalls'] as int? ?? 0) + 1;
      
      await _apiGateway.updateDocument(_collectionPath, userId, {
        'history': history,
        'totalCalls': totalCalls,
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
      final query = await _apiGateway.getTopDocuments(_collectionPath, 'averageScore', limit: limit);
          
      return query.map((data) {
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
      }).where((p) => p.totalCalls > 0).toList();
    } catch (e) {
      AppLogger.d('❌ Error getting top global users: $e');
      return [];
    }
  }
  @override
  Future<void> updateProfileDetails(String userId, {String? nickname, String? avatarUrl}) async {
    // 1. Local backup if available
    if (_localDataSource != null) {
      try {
        final localProfile = await _localDataSource!.getProfile(userId);
        final updated = localProfile.copyWith(nickname: nickname, avatarUrl: avatarUrl);
        await _localDataSource!.saveProfile(updated);
      } catch (e) {
        AppLogger.d('⚠️ Failed to save local backup of profile details: $e');
      }
    }

    if (userId == 'guest') return;

    // 2. Cloud Update
    try {
      final updates = <String, dynamic>{};
      if (nickname != null) updates['nickname'] = nickname;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      
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
}
