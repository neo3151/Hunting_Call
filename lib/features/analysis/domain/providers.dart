import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hunting_calls_perfection/di_providers.dart';
import 'use_cases/analyze_audio_use_case.dart';
import 'use_cases/calculate_score_use_case.dart';

/// Provider for AnalyzeAudioUseCase
final analyzeAudioUseCaseProvider = Provider<AnalyzeAudioUseCase>((ref) {
  final analyzer = ref.watch(frequencyAnalyzerProvider);
  return AnalyzeAudioUseCase(analyzer);
});

/// Provider for CalculateScoreUseCase
final calculateScoreUseCaseProvider = Provider<CalculateScoreUseCase>((ref) {
  return const CalculateScoreUseCase();
});
