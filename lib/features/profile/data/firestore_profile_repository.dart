import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/profile_model.dart';
import '../../rating/domain/rating_model.dart';
import '../domain/repositories/profile_repository.dart';
import '../domain/use_cases/update_daily_challenge_stats_use_case.dart';
import '../domain/entities/daily_challenge_stats.dart';
import 'local_profile_data_source.dart';

class FirestoreProfileRepository implements ProfileRepository {
  final FirebaseFirestore? _firestoreInstance;
  final ProfileDataSource? _localDataSource; // To handle 'guest' persistence locally
  
  FirebaseFirestore get _firestore => _firestoreInstance ?? FirebaseFirestore.instance;
  final String _collectionPath = 'profiles';
  
  FirestoreProfileRepository({FirebaseFirestore? firestore, ProfileDataSource? localDataSource}) 
      : _firestoreInstance = firestore, _localDataSource = localDataSource;

  @override
  Future<UserProfile> getProfile([String? userId]) async {
    // debugPrint("🔍 FirestoreProfileRepository.getProfile($userId)");
    if (userId == null || userId == 'guest') {
      if (_localDataSource != null) {
        // debugPrint("🔍 Delegating 'guest' getProfile to local source.");
        final localProf = await _localDataSource!.getProfile('guest');
        // debugPrint("🔍 Local 'guest' profile premium status: ${localProf.isPremium}");
        return localProf;
      }
      return UserProfile.guest();
    }

    try {
      final doc = await _firestore.collection(_collectionPath).doc(userId).get()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Firestore read timeout — check your connection.');
      });
      UserProfile? profile;
      if (doc.exists) {
        final data = doc.data()!;
        _sanitizeProfileData(data, doc.id);
        profile = UserProfile.fromJson(data);
      } else {
        profile = UserProfile.guest(); // Or return null/error if strictly strict
      }

      // Hybrid Check: If not premium in Cloud, check Local Storage override
      // This ensures that if we bought it on this device, we respect it even if cloud sync failed.
      if (!profile.isPremium && _localDataSource != null) {
        try {
           final localProfile = await _localDataSource!.getProfile(userId);
           if (localProfile.isPremium) {
              // debugPrint("✅ FirestoreProfileRepository: Local override applied! User is Premium locally.");
             profile = profile.copyWith(isPremium: true);
           }
        } catch (e) {
          // Ignore local read errors, trust cloud
        }
      }
      
      return profile!;
    } catch (e) {
      debugPrint('FirestoreProfileRepository: getProfile ERROR: $e');
      return UserProfile.guest();
    }
  }

  @override
  Future<List<UserProfile>> getAllProfiles() async {
    try {
      // debugPrint("🔍 FirestoreProfileRepository: Starting getAllProfiles()...");
      // debugPrint("🔍 Collection path: $_collectionPath");
      
      final snapshot = await _firestore.collection(_collectionPath).get()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Firestore read timeout — check your connection.');
      });
      
      // debugPrint("🔍 Firestore query completed");
      // debugPrint("🔍 Number of documents found: ${snapshot.docs.length}");
      
      if (snapshot.docs.isEmpty) {
        // debugPrint("⚠️ NO PROFILES FOUND IN FIRESTORE!");
        return [];
      }
      
      // debugPrint("🔍 Processing ${snapshot.docs.length} profile documents...");
      
      final profiles = snapshot.docs.map((doc) {
        // Reduced debug logging for performance
        final data = doc.data();
        _sanitizeProfileData(data, doc.id);
        try {
          return UserProfile.fromJson(data);
        } catch (e) {
          debugPrint('❌ Error parsing profile ${doc.id}: $e');
          // Return a fallback profile if parsing fails to avoid breaking the whole list
          return UserProfile(
            id: doc.id,
            name: data['name'] ?? 'Error Profile',
            joinedDate: DateTime.now(),
          );
        }
      }).toList();
      
      // debugPrint("✅ getAllProfiles() returning ${profiles.length} profiles");
      return profiles;
    } catch (e) {
      debugPrint('❌ FirestoreProfileRepository: getAllProfiles ERROR: $e');
      rethrow;
    }
  }

  @override
  Future<List<UserProfile>> getProfilesByEmail(String email) async {
    try {
      // debugPrint("🔍 Looking for profiles with email: $email");
      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('email', isEqualTo: email)
          .get()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Firestore read timeout — check your connection.');
      });
          
      if (snapshot.docs.isEmpty) {
        // debugPrint("❌ No profiles found with that email.");
        return [];
      }
      
      final profiles = snapshot.docs.map((doc) {
        final data = doc.data();
        _sanitizeProfileData(data, doc.id);
        return UserProfile.fromJson(data);
      }).toList();
  
      // debugPrint("✅ Found ${profiles.length} profiles for email.");
      return profiles;
      
    } catch(e) {
       debugPrint('❌ Error getting profiles by email: $e');
       return [];
    }
  }

  /// Ensures profile data matches what the model expects (handles Timestamps and missing fields)
  void _sanitizeProfileData(Map<String, dynamic> data, String docId) {
    data['id'] = data['id'] ?? docId;
    data['name'] = data['name'] ?? 'Hunter';
    
    // Handle joinedDate (Timestamp vs String)
    if (data['joinedDate'] is Timestamp) {
      data['joinedDate'] = (data['joinedDate'] as Timestamp).toDate().toIso8601String();
    } else if (data['joinedDate'] == null) {
      data['joinedDate'] = DateTime.now().toIso8601String();
    }

    // Ensure lastDailyChallengeDate is also safe if it becomes a Timestamp
    if (data['lastDailyChallengeDate'] is Timestamp) {
      data['lastDailyChallengeDate'] = (data['lastDailyChallengeDate'] as Timestamp).toDate().toIso8601String();
    }
  }

  @override
  Future<UserProfile> createProfile(String name, {String? id, DateTime? birthday, String? email}) async {
    try {
      // debugPrint("FirestoreProfileRepository: Creating profile for '$name' (id: $id, email: $email)...");
      final docRef = id != null 
          ? _firestore.collection(_collectionPath).doc(id)
          : _firestore.collection(_collectionPath).doc();
          
      final newProfile = UserProfile(
        id: docRef.id,
        name: name,
        email: email,
        joinedDate: DateTime.now(),
        birthday: birthday,
      );
      
      await docRef.set(newProfile.toJson()).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Firestore write timeout — check your connection.'),
      );
      // debugPrint("FirestoreProfileRepository: Profile created successfully.");
      return newProfile;
    } catch (e) {
      debugPrint('FirestoreProfileRepository: createProfile ERROR: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveResultForUser(String userId, RatingResult result, String animalId) async {
    if (userId == 'guest') return;

    try {
      // debugPrint("FirestoreProfileRepository: Saving result for user $userId (animal: $animalId)...");
      
      final newItem = HistoryItem(
        result: result,
        timestamp: DateTime.now(),
        animalId: animalId,
      );

      // Explicitly convert to JSON to avoid codec issues with nested objects
      final data = newItem.toJson();
      // debugPrint("FirestoreProfileRepository: Data serialized successfully.");

      // Use set with merge: true so it creates the document if it doesn't exist
      await _firestore.collection(_collectionPath).doc(userId).set({
        'history': FieldValue.arrayUnion([data]),
        'totalCalls': FieldValue.increment(1),
        // If document is new, we should at least have these basic fields
        'id': userId,
        'joinedDate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint('FirestoreProfileRepository: saveResultForUser TIMEOUT after 10s');
        throw Exception('Firestore write timeout - check your connection.');
      });
      
      // debugPrint("FirestoreProfileRepository: Result saved successfully.");
    } catch (e) {
      debugPrint('FirestoreProfileRepository: saveResultForUser ERROR: $e');
      // We rethrow so the UI knows analysis of the save part failed
      rethrow;
    }
  }

  @override
  Future<void> saveAchievements(String userId, List<String> achievementIds) async {
    if (userId == 'guest' || achievementIds.isEmpty) return;

    await _firestore.collection(_collectionPath).doc(userId).update({
      'achievements': FieldValue.arrayUnion(achievementIds),
    }).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Firestore write timeout — check your connection.'),
    );
  }

  @override
  Future<void> updateDailyChallengeStats(String userId) async {
    if (userId == 'guest') return;

    final now = DateTime.now();
    final docRef = _firestore.collection(_collectionPath).doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      final data = snapshot.data()!;
      
      // Extract current stats from Firestore
      final lastDateMillis = data['lastDailyChallengeDate'] as int?;
      final currentStats = DailyChallengeStats(
        challengesCompleted: data['dailyChallengesCompleted'] as int? ?? 0,
        lastChallengeDate: lastDateMillis != null 
            ? DateTime.fromMillisecondsSinceEpoch(lastDateMillis)
            : null,
        currentStreak: data['currentStreak'] as int? ?? 0,
        longestStreak: data['longestStreak'] as int? ?? 0,
      );
      
      // Use domain use case for streak calculation (pure business logic)
      final useCase = UpdateDailyChallengeStatsUseCase();
      final result = useCase.execute(currentStats, now);
      
      result.fold(
        (failure) {
          debugPrint('Failed to calculate daily challenge stats: ${failure.message}');
        },
        (newStats) {
          // Only update if stats changed
          if (newStats != currentStats) {
            transaction.update(docRef, {
              'dailyChallengesCompleted': newStats.challengesCompleted,
              'lastDailyChallengeDate': newStats.lastChallengeDate?.millisecondsSinceEpoch,
              'currentStreak': newStats.currentStreak,
              'longestStreak': newStats.longestStreak,
            });
          }
        },
      );
    });
  }

  @override
  Future<void> setPremiumStatus(String userId, bool isPremium) async {
    // 1. Always attempt local save (Hybrid Persistence)
    if (_localDataSource != null) {
      try {
        // debugPrint("✅ FirestoreProfileRepository: Saving Premium status locally as backup/override.");
        final localProfile = await _localDataSource!.getProfile(userId);
        final updated = localProfile.copyWith(isPremium: isPremium);
        await _localDataSource!.saveProfile(updated);
      } catch (e) {
        debugPrint('⚠️ Failed to save local backup of premium status: $e');
      }
    }

    if (userId == 'guest') {
       // already handled by local save above, just return
       return;
    }

    // 2. Attempt Cloud Save
    try {
      await _firestore.collection(_collectionPath).doc(userId).update({
        'isPremium': isPremium,
      });
      // debugPrint("✅ Firestore: Set isPremium=$isPremium for $userId");
    } catch (e) {
      debugPrint('❌ Firestore: Error setting premium status: $e');
      // If we saved locally, we might NOT want to rethrow, because the user technically "has" the product on this device.
      // But for now, let's allow the UI to know cloud failed, OR just suppress if local worked.
      // Given the user experience "Success" is better if it works locally.
      
      // If localDataSource is null or failed, run rethrow.
      if (_localDataSource == null) rethrow;
    }
  }
}
