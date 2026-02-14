import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'use_cases/submit_score_use_case.dart';

/// Provider for SubmitScoreUseCase
/// 
/// Pure use case with no dependencies
final submitScoreUseCaseProvider = Provider<SubmitScoreUseCase>((ref) {
  return SubmitScoreUseCase();
});
