import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../domain/reference_call_model.dart';

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
      // Fallback to empty list or hardcoded if necessary
      _calls = [];
    }
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
