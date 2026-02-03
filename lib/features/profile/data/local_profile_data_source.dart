import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/profile_model.dart';

abstract class ProfileDataSource {
  Future<UserProfile> getProfile(String userId);
  Future<List<String>> getProfileIds();
  Future<void> addProfileId(String id);
  Future<void> saveProfile(UserProfile profile);
  Future<void> addHistoryItem(String userId, HistoryItem item);
}

class LocalProfileDataSource implements ProfileDataSource {
  final SharedPreferences sharedPreferences;

  LocalProfileDataSource({required this.sharedPreferences});

  @override
  Future<UserProfile> getProfile(String userId) async {
    final jsonString = sharedPreferences.getString('user_profile_$userId');
    if (jsonString != null) {
      return UserProfile.fromJson(json.decode(jsonString));
    } else {
      // Return default new profile
      return UserProfile(
        id: userId,
        name: 'New Hunter',
        joinedDate: DateTime.now(),
        totalCalls: 0,
        averageScore: 0,
        history: [],
      );
    }
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await sharedPreferences.setString(
      'user_profile_${profile.id}',
      json.encode(profile.toJson()),
    );
  }

  @override
  Future<List<String>> getProfileIds() async {
    return sharedPreferences.getStringList('profile_index') ?? [];
  }

  @override
  Future<void> addProfileId(String id) async {
    final ids = await getProfileIds();
    if (!ids.contains(id)) {
      ids.add(id);
      await sharedPreferences.setStringList('profile_index', ids);
    }
  }

  @override
  Future<void> addHistoryItem(String userId, HistoryItem item) async {
    final profile = await getProfile(userId);
    final updatedHistory = List<HistoryItem>.from(profile.history)..insert(0, item);
    
    // Recalculate stats
    double totalScore = 0;
    for (var h in updatedHistory) {
      totalScore += h.result.score;
    }
    double newAvg = updatedHistory.isEmpty ? 0 : totalScore / updatedHistory.length;
    
    final updatedProfile = profile.copyWith(
      history: updatedHistory,
      totalCalls: updatedHistory.length,
      averageScore: newAvg,
    );
    
    await saveProfile(updatedProfile);
  }
}
