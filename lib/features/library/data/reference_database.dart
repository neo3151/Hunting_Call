import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../domain/reference_call_model.dart';
import '../../../config/app_config.dart';
import '../../../config/freemium_config.dart';

class ReferenceDatabase {
  static List<ReferenceCall> _calls = [];
  static bool _isInitialized = false;

  static List<ReferenceCall> get calls => _calls;
  
  @visibleForTesting
  static set calls(List<ReferenceCall> value) {
    _calls = value;
    _isInitialized = true;
  }

  static Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      final jsonString = await rootBundle.loadString('assets/data/reference_calls.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      final List<dynamic> callsJson = data['calls'];
      
      _calls = callsJson.map((json) => ReferenceCall.fromJson(json)).toList();
      _isInitialized = true;
      debugPrint('ReferenceDatabase: Loaded ${_calls.length} calls from JSON.');
    } catch (e) {
      debugPrint('ReferenceDatabase Error: Failed to load calls from JSON: $e');
      _calls = [];
    }

    // Freemium Logic: Locks are now calculated dynamically, not mutated on load.
  }

  /// Checks if a call is locked based on the current App Flavor and User Premium status.
  static bool isLocked(String callId, bool isUserPremium) {
    // 1. If User is Premium, EVERYTHING is unlocked.
    if (isUserPremium) return false;

    // 2. If this is the "Full" version (paid app), EVERYTHING is unlocked.
    if (AppConfig.instance.isFull) return false;

    // 3. We are in the "Free" version and User is NOT Premium.
    // Check if this call is part of the "Starter Pack" (Free entitlement).
    // If it IS in the starter pack, it is NOT locked.
    // If it is NOT in the starter pack, it IS locked.
    return !FreemiumConfig.freeCallIds.contains(callId);
  }

  static ReferenceCall getById(String id) {
    if (_calls.isEmpty) {
      debugPrint('ReferenceDatabase Warning: Attempted to get call before initialization or with empty database.');
      // Return a dummy call to prevent crashes, but this should be avoided by calling init()
      return _calls.isNotEmpty ? _calls.first : const ReferenceCall(
        id: 'unknown',
        animalName: 'Unknown',
        callType: 'Unknown',
        category: 'Unknown',
        difficulty: 'Unknown',
        idealPitchHz: 0,
        idealDurationSec: 0,
        audioAssetPath: '',
        isLocked: true,
      );
    }
    return _calls.firstWhere((c) => c.id == id, orElse: () => _calls.first);
  }
}
