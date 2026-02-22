import 'dart:io';
import 'package:flutter/services.dart';
import 'package:hunting_calls_perfection/core/services/cloud_audio_service.dart';
import 'package:hunting_calls_perfection/features/rating/domain/rating_model.dart';
import 'package:hunting_calls_perfection/features/rating/domain/rating_service.dart';
import 'package:hunting_calls_perfection/features/analysis/domain/audio_analysis_model.dart';
import 'package:hunting_calls_perfection/features/analysis/domain/frequency_analyzer.dart';
import 'package:hunting_calls_perfection/features/analysis/domain/use_cases/analyze_audio_use_case.dart';
import 'package:hunting_calls_perfection/features/analysis/domain/use_cases/calculate_score_use_case.dart';
import 'package:hunting_calls_perfection/features/daily_challenge/domain/usecases/get_daily_challenge_use_case.dart';
import 'package:hunting_calls_perfection/features/library/data/reference_database.dart';

import 'package:hunting_calls_perfection/features/profile/domain/repositories/profile_repository.dart';
import 'package:hunting_calls_perfection/features/leaderboard/domain/repositories/leaderboard_service.dart';
import 'package:hunting_calls_perfection/features/leaderboard/domain/leaderboard_entry.dart';

import 'package:hunting_calls_perfection/features/rating/domain/personality_feedback_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hunting_calls_perfection/core/utils/app_logger.dart';

class RealRatingService implements RatingService {
  final AnalyzeAudioUseCase _analyzeUseCase;
  final CalculateScoreUseCase _calculateUseCase;
  final GetDailyChallengeUseCase _getDailyChallengeUseCase;
  final FrequencyAnalyzer analyzer; // Still needed for reference audio analysis
  final ProfileRepository profileRepository;
  final LeaderboardService? leaderboardService;
  final CloudAudioService? cloudAudioService;
  
  Position? _currentPosition;

  RealRatingService({
    required AnalyzeAudioUseCase analyzeUseCase,
    required CalculateScoreUseCase calculateUseCase,
    required GetDailyChallengeUseCase getDailyChallengeUseCase,
    required this.analyzer, 
    required this.profileRepository,
    this.leaderboardService,
    this.cloudAudioService,
  }) : _analyzeUseCase = analyzeUseCase,
       _calculateUseCase = calculateUseCase,
       _getDailyChallengeUseCase = getDailyChallengeUseCase;

  static final Map<String, AudioAnalysis> _refCache = {};

  @override
  Future<RatingResult> rateCall(String userId, String audioPath, String animalType) async {
    AppLogger.d('RealRatingService: rateCall started for $animalType at $audioPath');
    
    // Try to get location (fire and forget or await briefly?)
    // Await briefly so we have it for the result
    try {
      final hasPermission = await Geolocator.checkPermission();
      if (hasPermission == LocationPermission.always || hasPermission == LocationPermission.whileInUse) {
        // High accuracy might take time, use medium
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

    try {
      // 1. Get the ideal metrics
      final reference = ReferenceDatabase.getById(animalType);

      // 2. Analyze the user's audio (via use case)
      final userAnalysisResult = await _analyzeUseCase.execute(audioPath);
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
      
      // 3. Get or Analyze the reference audio
      AudioAnalysis? refAnalysis = _refCache[animalType];
      
      if (refAnalysis == null) {
        try {
          AppLogger.d('RealRatingService: Analyzing reference for $animalType (not cached)');
          final assetPath = reference.audioAssetPath;
          
          // Use CloudAudioService if available, otherwise fall back to rootBundle
          String refFilePath;
          if (cloudAudioService != null) {
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
          
          try { await File(refFilePath).delete(); } catch (_) {}
        } catch (e) {
          AppLogger.d('Reference Analysis Error: $e');
        }
      } else {
        AppLogger.d('RealRatingService: Using cached reference for $animalType');
      }

      // 3. Calculate score (via use case - extracts all scoring logic to domain layer)
      final scoreResult = await _calculateUseCase.execute(
        CalculateScoreParams(
          userId: userId,
          recordingId: DateTime.now().millisecondsSinceEpoch.toString(),
          animalId: reference.id,
          userAnalysis: userAnalysis,
          referenceAnalysis: refAnalysis,
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
      
      String technicalFeedback = '';
      final bool pitchIsGood = pitchScore >= 85;
      final bool timbreIsGood = timbreScore >= 80;
      final bool rhythmIsGood = rhythmScore >= 80;
      
      if (pitchIsGood && timbreIsGood && rhythmIsGood) {
        technicalFeedback = 'Outstanding! You sound just like a ${reference.animalName}.';
      } else if (!pitchIsGood) {
        technicalFeedback = detectedPitch > reference.idealPitchHz ? 'Too High! Lower your pitch.' : 'Too Low! Raise your pitch.';
      } else if (!timbreIsGood) {
        technicalFeedback = userAnalysis.nasality > (refAnalysis?.nasality ?? 50) + 15 ? 'Too much nasality!' : 'Tone is muffled.';
      } else {
        technicalFeedback = 'Watch your rhythm and stability.';
      }

      final String personalityCritique = PersonalityFeedbackService.getSpecificCritique({
        'pitch': pitchScore,
        'timbre': timbreScore,
        'rhythm': rhythmScore,
        'duration': durationScore,
      });

      final result = RatingResult(
        score: analysisResult.overallScore,
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
          'avg_volume': userAnalysis.averageVolume * 100,
          'peak_volume': userAnalysis.peakVolume * 100,
          'consistency': userAnalysis.volumeConsistency,
          'tone_clarity': userAnalysis.toneClarity,
          'harmonic_richness': userAnalysis.harmonicRichness,
          'call_quality': userAnalysis.callQualityScore,
          'brightness': userAnalysis.brightness,
          'warmth': userAnalysis.warmth,
          'nasality': userAnalysis.nasality,
        },
        userWaveform: userAnalysis.waveform,
        referenceWaveform: reference.waveform ?? refAnalysis?.waveform,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );
      AppLogger.d('RealRatingService: Pro-Grade Analysis complete. Score: ${result.score}');

      // Save to history
      await profileRepository.saveResultForUser(userId, result, animalType);
      
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
          challengeResult.fold(
            (l) => AppLogger.d('Could not fetch daily challenge for completion check: $l'),
            (dailyCall) async {
              if (dailyCall.id == animalType && analysisResult.overallScore >= 70) {
                AppLogger.d('Daily Challenge ($animalType) Completed by $userId with score ${analysisResult.overallScore}');
                await profileRepository.updateDailyChallengeStats(userId);
              }
            }
          );
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
}
