import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/profile_model.dart';
import '../../rating/domain/rating_model.dart';
import 'profile_repository.dart';

class FirestoreProfileRepository implements ProfileRepository {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final String _collectionPath = 'profiles';

  @override
  Future<UserProfile> getProfile([String? userId]) async {
    if (userId == null || userId == 'guest') {
      return UserProfile.guest();
    }

    try {
      final doc = await _firestore.collection(_collectionPath).doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        _sanitizeProfileData(data, doc.id);
        return UserProfile.fromJson(data);
      } else {
        return UserProfile.guest();
      }
    } catch (e) {
      debugPrint("FirestoreProfileRepository: getProfile ERROR: $e");
      return UserProfile.guest();
    }
  }

  @override
  Future<List<UserProfile>> getAllProfiles() async {
    try {
      debugPrint("FirestoreProfileRepository: Fetching all profiles...");
      final snapshot = await _firestore.collection(_collectionPath).get();
      debugPrint("FirestoreProfileRepository: Found ${snapshot.docs.length} profiles.");
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        _sanitizeProfileData(data, doc.id);
        try {
          return UserProfile.fromJson(data);
        } catch (e) {
          debugPrint("Error parsing profile ${doc.id}: $e");
          // Return a fallback profile if parsing fails to avoid breaking the whole list
          return UserProfile(
            id: doc.id,
            name: data['name'] ?? 'Error Profile',
            joinedDate: DateTime.now(),
          );
        }
      }).toList();
    } catch (e) {
      debugPrint("FirestoreProfileRepository: getAllProfiles ERROR: $e");
      rethrow;
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
  Future<UserProfile> createProfile(String name, {String? id}) async {
    try {
      debugPrint("FirestoreProfileRepository: Creating profile for '$name' (id: $id)...");
      final docRef = id != null 
          ? _firestore.collection(_collectionPath).doc(id)
          : _firestore.collection(_collectionPath).doc();
          
      final newProfile = UserProfile(
        id: docRef.id,
        name: name,
        joinedDate: DateTime.now(),
      );
      
      await docRef.set(newProfile.toJson());
      debugPrint("FirestoreProfileRepository: Profile created successfully.");
      return newProfile;
    } catch (e) {
      debugPrint("FirestoreProfileRepository: createProfile ERROR: $e");
      rethrow;
    }
  }

  @override
  Future<void> saveResultForUser(String userId, RatingResult result, String animalId) async {
    if (userId == 'guest') return;

    try {
      debugPrint("FirestoreProfileRepository: Saving result for user $userId (animal: $animalId)...");
      
      final newItem = HistoryItem(
        result: result,
        timestamp: DateTime.now(),
        animalId: animalId,
      );

      // Explicitly convert to JSON to avoid codec issues with nested objects
      final data = newItem.toJson();
      debugPrint("FirestoreProfileRepository: Data serialized successfully.");

      // Use set with merge: true so it creates the document if it doesn't exist
      await _firestore.collection(_collectionPath).doc(userId).set({
        'history': FieldValue.arrayUnion([data]),
        'totalCalls': FieldValue.increment(1),
        // If document is new, we should at least have these basic fields
        'id': userId,
        'joinedDate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint("FirestoreProfileRepository: saveResultForUser TIMEOUT after 10s");
        throw Exception("Firestore write timeout - check your connection.");
      });
      
      debugPrint("FirestoreProfileRepository: Result saved successfully.");
    } catch (e) {
      debugPrint("FirestoreProfileRepository: saveResultForUser ERROR: $e");
      // We rethrow so the UI knows analysis of the save part failed
      rethrow;
    }
  }

  @override
  Future<void> saveAchievements(String userId, List<String> achievementIds) async {
    if (userId == 'guest' || achievementIds.isEmpty) return;

    await _firestore.collection(_collectionPath).doc(userId).update({
      'achievements': FieldValue.arrayUnion(achievementIds),
    });
  }

  @override
  Future<void> updateDailyChallengeStats(String userId) async {
    if (userId == 'guest') return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Using transaction or checking document first would be safer to identify streaks,
    // but for now we just want to log completion if it hasn't been done today.
    // However, since we don't have atomic read-write here easily without transaction logic
    // we will blindly write for now but check date in the logic layer if possible or just update.
    
    // Actually, let's just update the lastDailyChallengeDate and increment if it's a new day.
    // For simplicity in this pivot: Just set the date and increment total. 
    // The UI can determine if it was "today" for display purposes.
    // Ideally we check if `lastDailyChallengeDate` < today.
    
    final docRef = _firestore.collection(_collectionPath).doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return; // Should not happen if user exists
      
      final data = snapshot.data()!;
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
        // Calculate Streak
        int currentStreak = data['currentStreak'] as int? ?? 0;
        int longestStreak = data['longestStreak'] as int? ?? 0;
        
        // Check for consecutive days
        bool isConsecutive = false;
        if (lastDate != null) {
          final lastDateDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
          final diff = today.difference(lastDateDay).inDays;
          if (diff == 1) {
            isConsecutive = true;
          }
        } else {
            // First time ever
            isConsecutive = true; // Technically consecutive start
            currentStreak = 0;
        }
        
        int newStreak = isConsecutive ? currentStreak + 1 : 1;
        int newLongest = newStreak > longestStreak ? newStreak : longestStreak;

        transaction.update(docRef, {
          'dailyChallengesCompleted': FieldValue.increment(1),
          'lastDailyChallengeDate': now.millisecondsSinceEpoch,
          'currentStreak': newStreak,
          'longestStreak': newLongest,
        });
      }
    }); 
  }
}
