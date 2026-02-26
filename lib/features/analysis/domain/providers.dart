import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/di_providers.dart';
import 'package:outcall/features/analysis/domain/use_cases/analyze_audio_use_case.dart';
import 'package:outcall/features/analysis/domain/use_cases/calculate_score_use_case.dart';

/// Provider for AnalyzeAudioUseCase
final analyzeAudioUseCaseProvider = Provider<AnalyzeAudioUseCase>((ref) {
  final analyzer = ref.watch(frequencyAnalyzerProvider);
  return AnalyzeAudioUseCase(analyzer);
});

/// Provider for CalculateScoreUseCase
final calculateScoreUseCaseProvider = Provider<CalculateScoreUseCase>((ref) {
  return const CalculateScoreUseCase();
});
