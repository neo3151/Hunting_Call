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

    final doc = await _firestore.collection(_collectionPath).doc(userId).get();
    if (doc.exists) {
      return UserProfile.fromJson(doc.data()!);
    } else {
      // If doc doesn't exist, we might want to return guest or throw
      return UserProfile.guest();
    }
  }

  @override
  Future<List<UserProfile>> getAllProfiles() async {
    final snapshot = await _firestore.collection(_collectionPath).get();
    return snapshot.docs.map((doc) => UserProfile.fromJson(doc.data())).toList();
  }

  @override
  Future<UserProfile> createProfile(String name) async {
    // We use the document ID as the profile ID
    final docRef = _firestore.collection(_collectionPath).doc();
    final newProfile = UserProfile(
      id: docRef.id,
      name: name,
      joinedDate: DateTime.now(),
    );
    
    await docRef.set(newProfile.toJson());
    return newProfile;
  }

  @override
  Future<void> saveResultForUser(String userId, RatingResult result, String animalId) async {
    if (userId == 'guest') return;

    final newItem = HistoryItem(
      result: result,
      timestamp: DateTime.now(),
      animalId: animalId,
    );

    await _firestore.collection(_collectionPath).doc(userId).update({
      'history': FieldValue.arrayUnion([newItem.toJson()]),
      'totalCalls': FieldValue.increment(1),
    });
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
