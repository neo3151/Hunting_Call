import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/features/library/domain/reference_call_model.dart';
import 'package:outcall/config/app_config.dart';
import 'package:outcall/config/freemium_config.dart';
import 'package:outcall/features/analysis/domain/animal_archetype.dart';

class ReferenceDatabase {
  static List<ReferenceCall> _calls = [];
  static Map<String, AnimalArchetype> _archetypes = {};
  static bool _isInitialized = false;

  static List<ReferenceCall> get calls => _calls;
  
  static AnimalArchetype? getArchetype(String callId) => _archetypes[callId];
  
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
      
      final allCalls = callsJson.map((json) => ReferenceCall.fromJson(json)).toList();
      
      // Filter out staged calls whose releaseVersion exceeds the current app version.
      _calls = allCalls.where((call) {
        if (call.releaseVersion == null) return true; // No version gate → always show
        return _isVersionMet(call.releaseVersion!);
      }).toList();
      
      final stagedCount = allCalls.length - _calls.length;
      _isInitialized = true;
      AppLogger.d('ReferenceDatabase: Loaded ${_calls.length} calls ($stagedCount staged for future).');
    } catch (e) {
      AppLogger.d('ReferenceDatabase Error: Failed to load calls from JSON: $e');
      _calls = [];
    }

    // Try to load archetypes
    try {
      final archJsonString = await rootBundle.loadString('assets/data/archetypes.json');
      final Map<String, dynamic> archData = json.decode(archJsonString);
      final List<dynamic> archetypesJson = archData['archetypes'] ?? [];
      
      for (var jsonMap in archetypesJson) {
        final archetype = AnimalArchetype.fromJson(jsonMap);
        _archetypes[archetype.callId] = archetype;
      }
      AppLogger.d('ReferenceDatabase: Loaded ${_archetypes.length} archetypes from JSON.');
    } catch (e) {
      AppLogger.d('ReferenceDatabase Debug: No archetypes.json found or failed to load ($e). Using single-clip matching as fallback.');
      _archetypes = {};
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
      AppLogger.d('ReferenceDatabase Warning: Attempted to get call before initialization or with empty database.');
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

  /// Current app version used for staging filter.
  /// Bump this when releasing a new version to unlock staged calls.
  static const String _appVersion = '2.0.0';

  /// Returns true if the current app version meets or exceeds [requiredVersion].
  /// Compares major.minor.patch numerically (e.g., "2.1.0" >= "2.0.5").
  static bool _isVersionMet(String requiredVersion) {
    try {
      final current = _appVersion.split('.').map(int.parse).toList();
      final required = requiredVersion.split('.').map(int.parse).toList();
      
      // Pad to 3 components
      while (current.length < 3) { current.add(0); }
      while (required.length < 3) { required.add(0); }
      
      for (int i = 0; i < 3; i++) {
        if (current[i] > required[i]) return true;
        if (current[i] < required[i]) return false;
      }
      return true; // Equal versions
    } catch (_) {
      return true; // If parsing fails, show the call
    }
  }
}
