import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../features/analysis/domain/frequency_analyzer.dart';
import '../features/rating/domain/rating_service.dart';
import '../features/rating/domain/rating_model.dart';

/// Provides the FrequencyAnalyzer instance
final frequencyAnalyzerProvider = Provider<FrequencyAnalyzer>((ref) {
  return GetIt.I<FrequencyAnalyzer>();
});

/// Provides the RatingService instance
final ratingServiceProvider = Provider<RatingService>((ref) {
  return GetIt.I<RatingService>();
});

/// State for rating/analysis operations
class RatingState {
  final bool isAnalyzing;
  final RatingResult? result;
  final String? error;

  const RatingState({
    this.isAnalyzing = false,
    this.result,
    this.error,
  });

  RatingState copyWith({
    bool? isAnalyzing,
    RatingResult? result,
    String? error,
  }) {
    return RatingState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      result: result ?? this.result,
      error: error,
    );
  }
}

/// Notifier for rating operations
class RatingNotifier extends Notifier<RatingState> {
  bool _mounted = true;

  @override
  RatingState build() {
    ref.onDispose(() => _mounted = false);
    return const RatingState();
  }

  RatingService get _ratingService => ref.read(ratingServiceProvider);

  /// Analyze a recorded call
  Future<RatingResult?> analyzeCall(String userId, String audioPath, String animalId) async {
    if (state.isAnalyzing) {
      debugPrint("RatingNotifier: Analysis already in progress, ignoring request.");
      return null;
    }
    
    debugPrint("RatingNotifier: Starting analysis for $animalId at $audioPath");
    state = state.copyWith(isAnalyzing: true, error: null);
    try {
      final result = await _ratingService.rateCall(userId, audioPath, animalId);
      if (!_mounted) return null; // Prevent setting state if disposed
      
      debugPrint("RatingNotifier: Analysis complete. Success: ${result.score > 0}");
      state = state.copyWith(isAnalyzing: false, result: result);
      return result;
    } catch (e, stack) {
      debugPrint("RatingNotifier: Analysis error: $e\n$stack");
      if (_mounted) {
        state = state.copyWith(isAnalyzing: false, error: e.toString());
      }
      return null;
    }
  }

  /// Reset state
  void reset() {
    debugPrint("RatingNotifier: Resetting state");
    state = const RatingState();
  }

  /// Force a success state for debugging
  void forceSuccess() {
    debugPrint("RatingNotifier: Forcing success state");
    state = RatingState(
      isAnalyzing: false,
      result: RatingResult(
        score: 95.0,
        feedback: "Debug: This is a forced success result.",
        pitchHz: 440.0,
        metrics: {
          "Pitch (Hz)": 440.0,
          "Target Pitch": 440.0,
          "Duration (s)": 1.5,
        },
      ),
    );
  }
}

final ratingNotifierProvider = NotifierProvider<RatingNotifier, RatingState>(() {
  return RatingNotifier();
});
