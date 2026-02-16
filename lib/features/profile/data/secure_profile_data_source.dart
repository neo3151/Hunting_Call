import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/profile_model.dart';
import 'local_profile_data_source.dart';

/// Secure implementation of [ProfileDataSource] backed by
/// flutter_secure_storage (Android Keystore / iOS Keychain).
///
/// Stores user profile data (premium status, user ID, history)
/// using encrypted storage instead of plain SharedPreferences.
class SecureProfileDataSource implements ProfileDataSource {
  final FlutterSecureStorage _secureStorage;

  SecureProfileDataSource({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<UserProfile> getProfile(String userId) async {
    final jsonString = await _secureStorage.read(key: 'user_profile_$userId');
    debugPrint(
      '🔒 SecureProfileDataSource: Reading user_profile_$userId: '
      '${jsonString != null ? "found" : "null"}',
    );
    if (jsonString != null) {
      final p = UserProfile.fromJson(json.decode(jsonString));
      debugPrint(
        '🔒 SecureProfileDataSource: Parsed isPremium=${p.isPremium}',
      );
      return p;
    } else {
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
    await _secureStorage.write(
      key: 'user_profile_${profile.id}',
      value: json.encode(profile.toJson()),
    );
  }

  @override
  Future<List<String>> getProfileIds() async {
    final raw = await _secureStorage.read(key: 'profile_index');
    if (raw == null) return [];
    return List<String>.from(json.decode(raw));
  }

  @override
  Future<void> addProfileId(String id) async {
    final ids = await getProfileIds();
    if (!ids.contains(id)) {
      ids.add(id);
      await _secureStorage.write(
        key: 'profile_index',
        value: json.encode(ids),
      );
    }
  }

  @override
  Future<void> addHistoryItem(String userId, HistoryItem item) async {
    final profile = await getProfile(userId);
    final updatedHistory = List<HistoryItem>.from(profile.history)
      ..insert(0, item);

    // Recalculate stats
    double totalScore = 0;
    for (final h in updatedHistory) {
      totalScore += h.result.score;
    }
    final newAvg =
        updatedHistory.isEmpty ? 0.0 : totalScore / updatedHistory.length;

    final updatedProfile = profile.copyWith(
      history: updatedHistory,
      totalCalls: updatedHistory.length,
      averageScore: newAvg,
    );

    await saveProfile(updatedProfile);
  }
}
