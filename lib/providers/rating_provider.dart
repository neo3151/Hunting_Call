import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/analysis/domain/frequency_analyzer.dart';
import '../features/analysis/data/fftea_frequency_analyzer.dart';
import '../features/rating/domain/rating_service.dart';
import '../features/analysis/data/real_rating_service.dart';
import '../features/rating/domain/rating_model.dart';
import 'profile_provider.dart';

/// Provides the FrequencyAnalyzer instance
final frequencyAnalyzerProvider = Provider<FrequencyAnalyzer>((ref) {
  return FFTEAFrequencyAnalyzer();
});

/// Provides the RatingService instance
final ratingServiceProvider = Provider<RatingService>((ref) {
  final analyzer = ref.watch(frequencyAnalyzerProvider);
  final profileRepo = ref.watch(profileRepositoryProvider);
  return RealRatingService(analyzer: analyzer, profileRepository: profileRepo);
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
  @override
  RatingState build() {
    return const RatingState();
  }

  RatingService get _ratingService => ref.read(ratingServiceProvider);

  /// Analyze a recorded call
  Future<RatingResult?> analyzeCall(String userId, String audioPath, String animalId) async {
    state = state.copyWith(isAnalyzing: true, error: null);
    try {
      final result = await _ratingService.rateCall(userId, audioPath, animalId);
      state = state.copyWith(isAnalyzing: false, result: result);
      return result;
    } catch (e) {
      state = state.copyWith(isAnalyzing: false, error: e.toString());
      return null;
    }
  }

  /// Reset state
  void reset() {
    state = const RatingState();
  }
}

final ratingNotifierProvider = NotifierProvider<RatingNotifier, RatingState>(() {
  return RatingNotifier();
});
