import 'dart:math';
import 'package:fpdart/fpdart.dart';
import '../entities/analysis_result.dart';
import '../failures/analysis_failure.dart';
import '../audio_analysis_model.dart';
import '../../../library/data/reference_database.dart';

/// Parameters for score calculation
class CalculateScoreParams {
  final String userId;
  final String recordingId;
  final String animalId;
  final AudioAnalysis userAnalysis;
  final AudioAnalysis? referenceAnalysis;
  
  const CalculateScoreParams({
    required this.userId,
    required this.recordingId,
    required this.animalId,
    required this.userAnalysis,
    this.referenceAnalysis,
  });
}

/// Use case for calculating call quality score
/// 
/// Pure business logic - compares user's recording against reference data
/// Extracted from RealRatingService for testability and separation of concerns
class CalculateScoreUseCase {
  const CalculateScoreUseCase();
  
  Future<Either<AnalysisFailure, AnalysisResult>> execute(
    CalculateScoreParams params,
  ) async {
    // Get reference data
    final reference = ReferenceDatabase.getById(params.animalId);
    if (reference == null) {
      return left(ReferenceDataNotFound(params.animalId));
    }
    
    // Check if user analysis is valid
    if (params.userAnalysis.dominantFrequencyHz == 0 && 
        params.userAnalysis.totalDurationSec == 0) {
      return left(const InsufficientAudioData('No detectable audio signal'));
    }
    
    // Calculate individual scores
    final pitchScore = _calculatePitchScore(
      params.userAnalysis.dominantFrequencyHz,
      reference.idealPitchHz,
      reference.tolerancePitch,
    );
    
    final durationScore = _calculateDurationScore(
      params.userAnalysis.totalDurationSec,
      reference.idealDurationSec,
      reference.toleranceDuration,
    );
    
    final volumeScore = _calculateVolumeScore(
      params.userAnalysis.averageVolume,
      params.userAnalysis.volumeConsistency,
    );
    
    final toneScore = _calculateToneScore(
      params.userAnalysis,
      params.referenceAnalysis,
    );
    
    final rhythmScore = _calculateRhythmScore(
      params.userAnalysis,
      params.referenceAnalysis,
      reference,
    );
    
    // Calculate overall score (weighted average)
    final overallScore = (
      pitchScore.score * 0.40 +
      toneScore.score * 0.30 +
      rhythmScore.score * 0.20 +
      (durationScore.score * 0.7 + volumeScore.score * 0.3) * 0.10
    ).clamp(0.0, 100.0);
    
    return right(AnalysisResult(
      recordingId: params.recordingId,
      userId: params.userId,
      animalId: params.animalId,
      overallScore: overallScore,
      pitchScore: pitchScore,
      volumeScore: volumeScore,
      durationScore: durationScore,
      toneScore: toneScore,
      rhythmScore: rhythmScore,
      analyzedAt: DateTime.now(),
    ));
  }
  
  // ================== PURE CALCULATION FUNCTIONS ==================
  
  /// Calculate pitch accuracy score
  /// Score decreases as deviation from ideal increases
  PitchScore _calculatePitchScore(
    double actualHz,
    double idealHz,
    double tolerance,
  ) {
    double score = 100.0;
    final deviation = (actualHz - idealHz).abs();
    
    if (idealHz > 0) {
      final deviationPercent = (deviation / idealHz) * 100;
      final tolerancePercent = (tolerance / idealHz) * 100;
      
      if (deviationPercent > tolerancePercent) {
        score = max(0, 100 - ((deviationPercent - tolerancePercent) * 3));
      }
    }
    
    return PitchScore(
      score: score,
      actualHz: actualHz,
      idealHz: idealHz,
      deviation: deviation,
    );
  }
  
  /// Calculate duration accuracy score
  DurationScore _calculateDurationScore(
    double actualSec,
    double idealSec,
    double tolerance,
  ) {
    double score = 100.0;
    final deviation = (actualSec - idealSec).abs();
    
    if (idealSec > 0) {
      final deviationPercent = (deviation / idealSec) * 100;
      final tolerancePercent = (tolerance / idealSec) * 100;
      
      if (deviationPercent > tolerancePercent) {
        score = max(0, 100 - ((deviationPercent - tolerancePercent) * 2));
      }
    }
    
    return DurationScore(
      score: score,
      actualSec: actualSec,
      idealSec: idealSec,
      deviation: deviation,
    );
  }
  
  /// Calculate volume quality score
  /// Based on average volume and consistency
  VolumeScore _calculateVolumeScore(
    double averageVolume,
    double consistency,
  ) {
    // 0.2 RMS is considered "ideal" (mapped to 100 score)
    double score = min(100.0, averageVolume * 500);
    
    return VolumeScore(
      score: score,
      volumeDb: averageVolume * 100, // Convert to percentage
      consistency: consistency,
    );
  }
  
  /// Calculate tone quality score
  /// Compares brightness, warmth, and nasality against reference
  ToneScore _calculateToneScore(
    AudioAnalysis userAnalysis,
    AudioAnalysis? referenceAnalysis,
  ) {
    double score = 100.0;
    
    if (referenceAnalysis != null) {
      final brightnessDiff = (userAnalysis.brightness - referenceAnalysis.brightness).abs();
      final warmthDiff = (userAnalysis.warmth - referenceAnalysis.warmth).abs();
      final nasalityDiff = (userAnalysis.nasality - referenceAnalysis.nasality).abs();
      
      // Penalties for large deviations
      final brightnessPenalty = brightnessDiff > 10 ? (brightnessDiff - 10) * 1.5 : 0.0;
      final warmthPenalty = warmthDiff > 10 ? (warmthDiff - 10) * 1.5 : 0.0;
      final nasalityPenalty = nasalityDiff > 10 ? (nasalityDiff - 10) * 2.5 : 0.0;
      
      score = max(0, 100 - (brightnessPenalty + warmthPenalty + nasalityPenalty));
    } else {
      // Fallback: use user's tone clarity and harmonic richness
      score = (userAnalysis.toneClarity * 0.7) + (userAnalysis.harmonicRichness * 0.3);
    }
    
    return ToneScore(
      score: score,
      brightness: userAnalysis.brightness,
      warmth: userAnalysis.warmth,
      nasality: userAnalysis.nasality,
    );
  }
  
  /// Calculate rhythm and stability score
  /// Different weighting for pulsed vs continuous calls
  RhythmScore _calculateRhythmScore(
    AudioAnalysis userAnalysis,
    AudioAnalysis? referenceAnalysis,
    dynamic reference, // ReferenceCall from database
  ) {
    double score = 100.0;
    final pitchStability = userAnalysis.pitchStability;
    
    if (reference.isPulsedCall && referenceAnalysis != null && referenceAnalysis.isPulsedCall) {
      // Pulsed calls: evaluate tempo and regularity
      final tempoDiff = (userAnalysis.tempo - reference.idealTempo).abs();
      final tempoPenalty = tempoDiff > 10 ? (tempoDiff - 10) * 2 : 0.0;
      
      final regularity = userAnalysis.rhythmRegularity;
      score = (pitchStability * 0.4) + (regularity * 0.4) + max(0, 20 - tempoPenalty);
    } else {
      // Non-pulsed calls: value stability more
      score = (pitchStability * 0.8) + (userAnalysis.volumeConsistency * 0.2);
    }
    
    return RhythmScore(
      score: score,
      stability: pitchStability,
      regularity: userAnalysis.rhythmRegularity,
      tempo: userAnalysis.tempo,
    );
  }
}
