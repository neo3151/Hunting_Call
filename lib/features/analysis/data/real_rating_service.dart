import 'dart:io';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:outcall/core/services/bayesian_fusion_service.dart';
import 'package:outcall/core/services/cloud_audio_service.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/features/analysis/data/comprehensive_audio_analyzer.dart';
import 'package:outcall/features/analysis/domain/audio_analysis_model.dart';
import 'package:outcall/features/analysis/domain/frequency_analyzer.dart';
import 'package:outcall/features/analysis/domain/use_cases/analyze_audio_use_case.dart';
import 'package:outcall/features/analysis/domain/use_cases/calculate_score_use_case.dart';
import 'package:outcall/features/daily_challenge/domain/usecases/get_daily_challenge_use_case.dart';
import 'package:outcall/features/leaderboard/domain/leaderboard_entry.dart';
import 'package:outcall/features/leaderboard/domain/repositories/leaderboard_service.dart';
import 'package:outcall/features/library/data/reference_database.dart';
import 'package:outcall/features/profile/domain/repositories/profile_repository.dart';
import 'package:outcall/features/rating/data/fingerprint_service.dart';
import 'package:outcall/features/rating/domain/personality_feedback_service.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';
import 'package:outcall/features/rating/domain/rating_service.dart';

class RealRatingService implements RatingService {
  final AnalyzeAudioUseCase _analyzeUseCase;
  final CalculateScoreUseCase _calculateUseCase;
  final GetDailyChallengeUseCase _getDailyChallengeUseCase;
  final FrequencyAnalyzer analyzer; // Still needed for reference audio analysis
  final ProfileRepository profileRepository;
  final LeaderboardService? leaderboardService;
  final CloudAudioService? cloudAudioService;
  final String? backendBaseUrl;

  Position? _currentPosition;

  RealRatingService({
    required AnalyzeAudioUseCase analyzeUseCase,
    required CalculateScoreUseCase calculateUseCase,
    required GetDailyChallengeUseCase getDailyChallengeUseCase,
    required this.analyzer,
    required this.profileRepository,
    this.leaderboardService,
    this.cloudAudioService,
    this.backendBaseUrl,
  })  : _analyzeUseCase = analyzeUseCase,
        _calculateUseCase = calculateUseCase,
        _getDailyChallengeUseCase = getDailyChallengeUseCase;

  static final Map<String, AudioAnalysis> _refCache = {};

  @override
  Future<RatingResult> rateCall(
    String userId,
    String audioPath,
    String animalType, {
    double scoreOffset = 0.0,
    double micSensitivity = 1.0,
    bool skipFingerprint = false,
    bool isBackgroundSync = false,
  }) async {
    AppLogger.d('RealRatingService: rateCall started for $animalType at $audioPath');

    // Global timeout to prevent infinite spinner
    return await _rateCallInternal(userId, audioPath, animalType,
        scoreOffset: scoreOffset, micSensitivity: micSensitivity,
        skipFingerprint: skipFingerprint, isBackgroundSync: isBackgroundSync)
      .timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          AppLogger.d('RealRatingService: TIMEOUT after 45s');
          throw Exception('Analysis timed out. Please try again.');
        },
      );
  }

  Future<RatingResult> _rateCallInternal(
    String userId,
    String audioPath,
    String animalType, {
    double scoreOffset = 0.0,
    double micSensitivity = 1.0,
    bool skipFingerprint = false,
    bool isBackgroundSync = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.d('RealRatingService: _rateCallInternal started');

    // Skip location for Quick Match — saves 2s
    if (!skipFingerprint) {
      try {
        final hasPermission = await Geolocator.checkPermission();
        if (hasPermission == LocationPermission.always ||
            hasPermission == LocationPermission.whileInUse) {
          _currentPosition = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        AppLogger.d('Error getting location: $e');
      }
      AppLogger.d('RealRatingService: Location done in ${stopwatch.elapsedMilliseconds}ms');
    }

    try {
      // 1. Get the ideal metrics
      final reference = ReferenceDatabase.getById(animalType);

      // 2. Analyze the user's audio (via use case)
      final userAnalysisResult = await _analyzeUseCase.execute(audioPath);
      AppLogger.d('RealRatingService: User audio analysis done in ${stopwatch.elapsedMilliseconds}ms');
      final userAnalysis = userAnalysisResult.fold(
        (failure) => throw Exception(failure.message),
        (analysis) => analysis,
      );

      // Double-check signal quality
      if (userAnalysis.dominantFrequencyHz == 0 && userAnalysis.totalDurationSec == 0) {
        return RatingResult(
          score: 0,
          feedback: 'Could not analyze your recording. Please try again in a quiet place.',
          pitchHz: 0,
          metrics: {},
        );
      }

      // Bayesian Fusion: enhance BirdNET's blind classification with
      // contextual priors from the species the user selected.
      final enhancedAnalysis = userAnalysis.topSpeciesMatches.isNotEmpty
          ? userAnalysis.copyWith(
              topSpeciesMatches: BayesianFusionService.applyPriors(
                rawResults: userAnalysis.topSpeciesMatches,
                scientificName: reference.scientificName,
                commonName: reference.animalName,
              ),
            )
          : userAnalysis;

      // 3. Get or Analyze the reference audio
      AudioAnalysis? refAnalysis = _refCache[animalType];

      if (refAnalysis == null) {
        try {
          AppLogger.d('RealRatingService: Analyzing reference for $animalType (not cached)');
          final assetPath = reference.audioAssetPath;

          // Quick Match: always use rootBundle (fast, no network)
          // Expert Mode: try CloudAudioService first (may have higher quality)
          String refFilePath;
          if (cloudAudioService != null && !skipFingerprint) {
            refFilePath = await cloudAudioService!.resolveFilePath(reference.id, assetPath);
          } else {
            final ByteData data = await rootBundle.load(assetPath);
            final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
            final tempDir = Directory.systemTemp;
            final tempFile = File('${tempDir.path}/ref_${reference.id}.wav');
            await tempFile.writeAsBytes(bytes);
            refFilePath = tempFile.path;
          }

          refAnalysis = await analyzer.analyzeAudio(refFilePath);
          _refCache[animalType] = refAnalysis;

          try {
            await File(refFilePath).delete();
          } catch (e) {
            AppLogger.d('Temp ref file cleanup failed: $e');
          }
        } catch (e) {
          AppLogger.d('Reference Analysis Error: $e');
        }
      } else {
        AppLogger.d('RealRatingService: Using cached reference for $animalType');
      }

      // Load user's calibration baseline for this animal
      List<double>? userBaseline;
      String? archetypeLabel;
      double? fingerprintPct;
      try {
        final profile = await profileRepository.getProfile(userId);
        final baselines = profile.calibrationBaselines;
        if (baselines.containsKey(reference.id)) {
          userBaseline = baselines[reference.id];
        }
      } catch (_) { /* first call, no profile yet */ }

      // Fingerprint matching via ngrok-tunneled local backend
      // Quick Match skips this for instant on-device results
      if (!skipFingerprint) {
        AppLogger.d('RealRatingService: Starting fingerprint at ${stopwatch.elapsedMilliseconds}ms');
        try {
          final fpResult = await FingerprintService.match(
            audioPath,
            baseUrl: backendBaseUrl,
          ).timeout(const Duration(seconds: 15));
          AppLogger.d('RealRatingService: Fingerprint done in ${stopwatch.elapsedMilliseconds}ms');
          if (fpResult.hasMatch) {
            fingerprintPct = fpResult.score;
            archetypeLabel = fpResult.matchLabel;
            AppLogger.d('Expert fingerprint: ${fpResult.matchLabel} ${fpResult.score}%');
          }
        } catch (e) {
          AppLogger.d('Expert fingerprint failed, falling back to pitch: $e');
        }
      } else {
        AppLogger.d('RealRatingService: Fingerprint skipped (Quick Match mode)');
      }

      final scoreResult = await _calculateUseCase.execute(
        CalculateScoreParams(
          userId: userId,
          recordingId: DateTime.now().millisecondsSinceEpoch.toString(),
          animalId: reference.id,
          userAnalysis: enhancedAnalysis,
          referenceAnalysis: refAnalysis,
          scoreOffset: scoreOffset,
          micSensitivity: micSensitivity,
          fingerprintMatchPercent: fingerprintPct,
          userBaseline: userBaseline,
        ),
      );

      final analysisResult = scoreResult.fold(
        (failure) => throw Exception(failure.message),
        (result) => result,
      );

      // 4. Generate Feedback (presentation logic)
      final pitchScore = analysisResult.pitchScore.score;
      final timbreScore = analysisResult.toneScore.score;
      final rhythmScore = analysisResult.rhythmScore.score;
      final durationScore = analysisResult.durationScore.score;
      final detectedPitch = analysisResult.pitchScore.actualHz;
      final rawScore = analysisResult.overallScore;

      // Rolling average: blend current score with up to 2 previous attempts for this animal
      double displayScore = rawScore;
      try {
        final profile = await profileRepository.getProfile(userId);
        final recentForAnimal = profile.history
            .where((h) => h.animalId == animalType)
            .take(2) // last 2 prior attempts (current hasn't been saved yet)
            .map((h) => h.result.score)
            .toList();
        if (recentForAnimal.isNotEmpty) {
          final allScores = [rawScore, ...recentForAnimal];
          displayScore = allScores.reduce((a, b) => a + b) / allScores.length;
        }
      } catch (e) {
        AppLogger.d('Rolling average lookup failed, using raw score: $e');
      }

      String technicalFeedback = '';

      // V2 Pro Architecture: Actionable Mechanical Diagnostics
      // We provide specific, anatomical telemetry to the user.

      if (pitchScore >= 85 && timbreScore >= 80 && rhythmScore >= 80) {
        technicalFeedback = 'Outstanding acoustic execution. You are competition-ready.';
      } else {
        // Find the weakest link and deliver a highly specific mechanical critique
        if (pitchScore < timbreScore && pitchScore < rhythmScore) {
          final idealPitch = analysisResult.pitchScore.idealHz;
          final hzDiff = (detectedPitch - idealPitch).abs().toInt();
          if (detectedPitch > idealPitch) {
            technicalFeedback =
                'Pitch ceiling is $hzDiff Hz too high. Drop your jaw and loosen your tongue pressure.';
          } else {
            technicalFeedback =
                'Pitch floor is $hzDiff Hz too low. Increase your diaphragm pressure and tighten your air channel.';
          }
        } else if (timbreScore < pitchScore && timbreScore < rhythmScore) {
          if (enhancedAnalysis.nasality > (refAnalysis?.nasality ?? 50) + 15) {
            technicalFeedback =
                'Critical spectral failure: too nasal. Open your nasal passages and resonate in your chest.';
          } else {
            technicalFeedback =
                'Missing harmonic overtones. The tone is muffled and hollow. Drive more air across the reed.';
          }
        } else {
          technicalFeedback =
              'Temporal failure. Your rhythm envelope drifted significantly from the champion reference sequence. Tighten your cadence.';
        }
      }

      final String personalityCritique = PersonalityFeedbackService.getSpecificCritique({
        'pitch': pitchScore,
        'timbre': timbreScore,
        'rhythm': rhythmScore,
        'duration': durationScore,
      });

      final result = RatingResult(
        score: displayScore,
        feedback: '$technicalFeedback $personalityCritique',
        pitchHz: analysisResult.pitchScore.actualHz,
        metrics: {
          'Pitch (Hz)': analysisResult.pitchScore.actualHz,
          'Target Pitch': analysisResult.pitchScore.idealHz,
          'Duration (s)': analysisResult.durationScore.actualSec,
          'score_pitch': pitchScore,
          'score_timbre': timbreScore,
          'score_rhythm': rhythmScore,
          'score_duration': durationScore,
          'score_pitch_contour': analysisResult.pitchContourScore.score,
          'score_envelope': analysisResult.envelopeScore.score,
          'score_formant': analysisResult.formantScore.score,
          'score_noise': analysisResult.noiseScore.score,
          'score_fingerprint': analysisResult.fingerprintMatchPercent ?? -1,
          'rawScore': rawScore,
          'avg_volume': enhancedAnalysis.averageVolume * 100,
          'peak_volume': enhancedAnalysis.peakVolume * 100,
          'consistency': enhancedAnalysis.volumeConsistency,
          'tone_clarity': enhancedAnalysis.toneClarity,
          'harmonic_richness': enhancedAnalysis.harmonicRichness,
          'call_quality': enhancedAnalysis.callQualityScore,
          'brightness': enhancedAnalysis.brightness,
          'warmth': enhancedAnalysis.warmth,
          'nasality': enhancedAnalysis.nasality,
        },
        userWaveform: enhancedAnalysis.waveform,
        referenceWaveform: _crossCorrelateAlign(
          enhancedAnalysis.waveform,
          reference.waveform ?? refAnalysis?.waveform,
        ),
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        archetypeLabel: archetypeLabel,
        featureVectors: {
          'pitchContour': enhancedAnalysis.pitchContour,
          'formants': enhancedAnalysis.formants,
          'mfcc39': [
            ...enhancedAnalysis.mfccCoefficients,
            ...enhancedAnalysis.deltaMfcc,
            ...enhancedAnalysis.deltaDeltaMfcc,
          ],
          'envelope': [
            enhancedAnalysis.attackTime,
            enhancedAnalysis.sustainLevel,
            enhancedAnalysis.decayRate,
          ],
        },
      );
      AppLogger.d('RealRatingService: Pro-Grade Analysis complete. Score: ${result.score}');

      // Save to history (wrapped in try-catch so network failures don't drop the analysis result)
      try {
        await profileRepository.saveResultForUser(userId, result, animalType);
      } catch (e) {
        AppLogger.d('RealRatingService: Failed to sync result to profile: $e');
      }

      // Submit to Leaderboard if score is decent
      if (analysisResult.overallScore >= 60 && userId != 'guest' && leaderboardService != null) {
        try {
          final profile = await profileRepository.getProfile(userId);
          await leaderboardService!.submitScore(
            animalId: animalType,
            entry: LeaderboardEntry(
              userId: userId,
              userName: profile.name,
              score: analysisResult.overallScore,
              timestamp: DateTime.now(),
              isAlphaTester: profile.isAlphaTester,
            ),
          );
        } catch (e) {
          AppLogger.d('Leaderboard submission failed: $e');
        }
      }

      // Check if this call matches the Daily Challenge
      try {
        if (userId != 'guest') {
          final challengeResult = await _getDailyChallengeUseCase.execute();
          challengeResult
              .fold((l) => AppLogger.d('Could not fetch daily challenge for completion check: $l'),
                  (dailyCall) async {
            if (dailyCall.id == animalType && analysisResult.overallScore >= 70) {
              AppLogger.d(
                  'Daily Challenge ($animalType) Completed by $userId with score ${analysisResult.overallScore}');
              await profileRepository.updateDailyChallengeStats(userId);
            }
          });
        }
      } catch (e) {
        AppLogger.d('Daily Challenge update failed: $e');
      }

      return result;
    } catch (e) {
      AppLogger.d('RealRatingService: Analysis failed: $e');
      rethrow;
    }
  }

  /// Phase-align reference waveform to user waveform using cross-correlation.
  static List<double>? _crossCorrelateAlign(
    List<double> userWaveform,
    List<double>? refWaveform,
  ) {
    if (refWaveform == null || refWaveform.isEmpty || userWaveform.isEmpty) {
      return refWaveform;
    }

    final offset = ComprehensiveAudioAnalyzer.crossCorrelateOffset(
      userWaveform, refWaveform,
    );

    if (offset == 0) return refWaveform;

    // Shift the reference by the optimal lag
    final aligned = List<double>.filled(refWaveform.length, 0.0);
    for (int i = 0; i < refWaveform.length; i++) {
      final srcIdx = i + offset;
      if (srcIdx >= 0 && srcIdx < refWaveform.length) {
        aligned[i] = refWaveform[srcIdx];
      }
    }
    return aligned;
  }
}
