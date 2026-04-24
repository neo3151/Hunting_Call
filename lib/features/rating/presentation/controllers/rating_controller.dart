import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/features/rating/domain/rating_service.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';
import 'package:outcall/features/settings/presentation/controllers/settings_controller.dart';
import 'package:outcall/di_providers.dart';
import 'package:outcall/core/utils/app_logger.dart';

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
      AppLogger.d('RatingNotifier: Analysis already in progress, ignoring request.');
      return null;
    }
    
    AppLogger.d('RatingNotifier: Starting analysis for $animalId at $audioPath');
    state = state.copyWith(isAnalyzing: true, error: null);
    try {
      // Read calibration from settings
      final settingsAsync = ref.read(settingsNotifierProvider);
      final settings = settingsAsync.when(data: (s) => s, loading: () => null, error: (_, __) => null);
      final cal = settings?.calibration;

      final result = await _ratingService.rateCall(
        userId, audioPath, animalId,
        scoreOffset: cal?.scoreOffset ?? 0.0,
        micSensitivity: cal?.micSensitivity ?? 1.0,
      );
      if (!_mounted) return null; // Prevent setting state if disposed
      
      AppLogger.d('RatingNotifier: Analysis complete. Success: ${result.score > 0}');
      state = state.copyWith(isAnalyzing: false, result: result);
      return result;
    } catch (e, stack) {
      AppLogger.d('RatingNotifier: Analysis error: $e\n$stack');
      if (_mounted) {
        state = state.copyWith(isAnalyzing: false, error: e.toString());
      }
      return null;
    }
  }

  /// Reset state
  void reset() {
    AppLogger.d('RatingNotifier: Resetting state');
    state = const RatingState();
  }


}

final ratingNotifierProvider = NotifierProvider<RatingNotifier, RatingState>(() {
  return RatingNotifier();
});
