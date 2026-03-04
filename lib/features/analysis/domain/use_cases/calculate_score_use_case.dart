import 'dart:math';
import 'package:fpdart/fpdart.dart';
import 'package:outcall/features/analysis/domain/entities/analysis_result.dart';
import 'package:outcall/features/analysis/domain/failures/analysis_failure.dart';
import 'package:outcall/features/analysis/domain/audio_analysis_model.dart';
import 'package:outcall/features/library/data/reference_database.dart';

/// Parameters for score calculation
class CalculateScoreParams {
  final String userId;
  final String recordingId;
  final String animalId;
  final AudioAnalysis userAnalysis;
  final AudioAnalysis? referenceAnalysis;

  /// Optional calibration offsets from on-device calibration.
  final double scoreOffset;
  final double micSensitivity;
  
  const CalculateScoreParams({
    required this.userId,
    required this.recordingId,
    required this.animalId,
    required this.userAnalysis,
    this.referenceAnalysis,
    this.scoreOffset = 0.0,
    this.micSensitivity = 1.0,
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
    
    // Check if user analysis is valid
    if (params.userAnalysis.dominantFrequencyHz == 0 && 
        params.userAnalysis.totalDurationSec == 0) {
      return left(const InsufficientAudioData('No detectable audio signal'));
    }
    
    // Calculate individual scores
    // Apply mic sensitivity calibration to volume readings
    final calibratedVolume = params.userAnalysis.averageVolume * params.micSensitivity;
    final volumeScore = _calculateVolumeScore(
      calibratedVolume,
      params.userAnalysis.volumeConsistency,
    );

    // GUARD: If it's effectively silence, fail the score or give a zero before complex trait comparison
    if (calibratedVolume < 0.005) {
      return right(AnalysisResult(
        recordingId: params.recordingId,
        userId: params.userId,
        animalId: params.animalId,
        overallScore: 0.0,
        pitchScore: PitchScore(score: 0, actualHz: 0, idealHz: reference.idealPitchHz, deviation: 0),
        volumeScore: volumeScore,
        durationScore: DurationScore(score: 0, actualSec: params.userAnalysis.totalDurationSec, idealSec: reference.idealDurationSec, deviation: 0),
        toneScore: const ToneScore(score: 0, brightness: 0, warmth: 0, nasality: 0),
        rhythmScore: const RhythmScore(score: 0, stability: 0, regularity: 0, tempo: 0),
        analyzedAt: DateTime.now(),
      ));
    }

    final pitchScore = _calculatePitchScore(
      params.userAnalysis.dominantFrequencyHz,
      reference.idealPitchHz,
      reference.tolerancePitch,
    );
    
    final durationScore = _calculateDurationScore(
      params.userAnalysis.activeDurationSec, // Use active (trimmed) duration, not file length
      reference.idealDurationSec,
      reference.toleranceDuration,
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
    double overallScore = (
      pitchScore.score * 0.40 +
      toneScore.score * 0.30 +
      rhythmScore.score * 0.20 +
      (durationScore.score * 0.7 + volumeScore.score * 0.3) * 0.10
    ).clamp(0.0, 100.0);
    
    // NEW: Apply Harmonic/Clarity Noise Penalty
    // Punish broad-spectrum noise (wind/breathing) that lacks biological harmonics.
    // We require BOTH to be low to trigger the penalty, preventing false positives 
    // on extremely pure (synthesized) signals that might confuse the SNR calculation.
    double noisePenalty = 0.0;
    if (params.userAnalysis.toneClarity < 25.0 && params.userAnalysis.harmonicRichness < 25.0) {
      final lowestMetric = min(params.userAnalysis.toneClarity, params.userAnalysis.harmonicRichness);
      noisePenalty = (25.0 - lowestMetric) * 2.0; // Aggressive scale
    }
    
    overallScore = max(0.0, overallScore - noisePenalty);

  // Apply calibration score offset
  if (params.scoreOffset != 0.0) {
    overallScore = (overallScore + params.scoreOffset).clamp(0.0, 100.0);
  }

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
    final double score = min(100.0, averageVolume * 500);
    
    return VolumeScore(
      score: score,
      volumeDb: averageVolume * 100, // Convert to percentage
      consistency: consistency,
    );
  }
  
  /// Calculate tone quality score
  /// Compares brightness, warmth, and nasality against reference
  /// When MFCC data is available, blends MFCC cosine similarity (60%) with tonal metrics (40%)
  ToneScore _calculateToneScore(
    AudioAnalysis userAnalysis,
    AudioAnalysis? referenceAnalysis,
  ) {
    double toneMetricScore = 100.0;
    
    if (referenceAnalysis != null) {
      final brightnessDiff = (userAnalysis.brightness - referenceAnalysis.brightness).abs();
      final warmthDiff = (userAnalysis.warmth - referenceAnalysis.warmth).abs();
      final nasalityDiff = (userAnalysis.nasality - referenceAnalysis.nasality).abs();
      
      // Penalties for large deviations
      final brightnessPenalty = brightnessDiff > 10 ? (brightnessDiff - 10) * 1.5 : 0.0;
      final warmthPenalty = warmthDiff > 10 ? (warmthDiff - 10) * 1.5 : 0.0;
      final nasalityPenalty = nasalityDiff > 10 ? (nasalityDiff - 10) * 2.5 : 0.0;
      
      toneMetricScore = max(0, 100 - (brightnessPenalty + warmthPenalty + nasalityPenalty));
    } else {
      // Fallback: use the highest of clarity or harmonics. 
      // Mathematical pure signals lack SNR 'clarity' but have perfect harmonics.
      // Because FFT energy distribution naturally caps pure harmonics around 80%,
      // we apply a 1.25x buffer so a perfectly executed call can hit 100%.
      toneMetricScore = min(100.0, max(userAnalysis.toneClarity, userAnalysis.harmonicRichness) * 1.25);
    }
    
    // MFCC-based timbre comparison (cosine similarity)
    double finalScore = toneMetricScore;
    if (referenceAnalysis != null &&
        userAnalysis.mfccCoefficients.isNotEmpty &&
        referenceAnalysis.mfccCoefficients.isNotEmpty &&
        userAnalysis.mfccCoefficients.length == referenceAnalysis.mfccCoefficients.length) {
      final mfccScore = _calculateMFCCScore(
        userAnalysis.mfccCoefficients,
        referenceAnalysis.mfccCoefficients,
      );
      // Blend: MFCC 60%, existing tonal metrics 40%
      finalScore = mfccScore * 0.6 + toneMetricScore * 0.4;
    }
    
    return ToneScore(
      score: finalScore,
      brightness: userAnalysis.brightness,
      warmth: userAnalysis.warmth,
      nasality: userAnalysis.nasality,
    );
  }
  
  /// Calculate MFCC cosine similarity score (0-100)
  double _calculateMFCCScore(List<double> userMFCC, List<double> refMFCC) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < userMFCC.length; i++) {
      dotProduct += userMFCC[i] * refMFCC[i];
      normA += userMFCC[i] * userMFCC[i];
      normB += refMFCC[i] * refMFCC[i];
    }
    if (normA == 0 || normB == 0) return 50.0;
    final cosineSim = dotProduct / (sqrt(normA) * sqrt(normB));
    // cosineSim ranges from -1 to 1; map to 0-100
    return ((cosineSim + 1.0) / 2.0 * 100.0).clamp(0.0, 100.0);
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
