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
      debugPrint("ReferenceDatabase: Loaded ${_calls.length} calls from JSON.");
    } catch (e) {
      debugPrint("ReferenceDatabase Error: Failed to load calls from JSON: $e");
      _calls = [];
    }

    // Freemium Logic: Lock calls if Free Flavor
    if (AppConfig.instance.isFree) {
      _applyFreeVersionLocks();
    }
  }

  static void _applyFreeVersionLocks() {
    // Calls to keep UNLOCKED in Free version
    final starterPackIds = FreemiumConfig.freeCallIds;

    for (var call in _calls) {
      if (!starterPackIds.contains(call.id)) {
        // We need to modify the isLocked property. 
        // Since ReferenceCall might be immutable (final), we might need to recreate it.
        // Assuming ReferenceCall has a copyWith or we just replace the object in the list.
        final int index = _calls.indexOf(call);
        _calls[index] = call.copyWith(isLocked: true);
      }
    }
    debugPrint("ReferenceDatabase: Applied Free Version Locks. Unlocked count: ${starterPackIds.length}");
  }

  static ReferenceCall getById(String id) {
    if (_calls.isEmpty) {
      debugPrint("ReferenceDatabase Warning: Attempted to get call before initialization or with empty database.");
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
