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
      
      _calls = callsJson.map((json) => ReferenceCall.fromJson(json)).toList();
      _isInitialized = true;
      AppLogger.d('ReferenceDatabase: Loaded ${_calls.length} calls from JSON.');
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
}
