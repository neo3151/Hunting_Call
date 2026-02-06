import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../rating/domain/rating_model.dart';
import '../../rating/domain/rating_service.dart';
import '../domain/audio_analysis_model.dart';
import '../domain/frequency_analyzer.dart';
import '../../library/data/reference_database.dart';

import '../../profile/data/profile_repository.dart';
import '../../leaderboard/data/leaderboard_service.dart';
import '../../leaderboard/domain/leaderboard_entry.dart';
import '../../daily_challenge/data/daily_challenge_service.dart';

import 'package:geolocator/geolocator.dart';

class RealRatingService implements RatingService {
  final FrequencyAnalyzer analyzer;
  final ProfileRepository profileRepository;
  final LeaderboardService? leaderboardService;
  
  Position? _currentPosition;

  RealRatingService({
    required this.analyzer, 
    required this.profileRepository,
    this.leaderboardService,
  });

  static final Map<String, AudioAnalysis> _refCache = {};

  @override
  Future<RatingResult> rateCall(String userId, String audioPath, String animalType) async {
    debugPrint("RealRatingService: rateCall started for $animalType at $audioPath");
    
    // Try to get location (fire and forget or await briefly?)
    // Await briefly so we have it for the result
    try {
      final hasPermission = await Geolocator.checkPermission();
      if (hasPermission == LocationPermission.always || hasPermission == LocationPermission.whileInUse) {
        // High accuracy might take time, use medium
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }

    try {
      // 1. Get the ideal metrics
      final reference = ReferenceDatabase.getById(animalType);

      // 2. Analyze the user's audio
      final userAnalysis = await analyzer.analyzeAudio(audioPath);
      if (userAnalysis.dominantFrequencyHz == 0 && userAnalysis.totalDurationSec == 0) {
        return RatingResult(
          score: 0,
          feedback: "Could not analyze your recording. Please try again in a quiet place.",
          pitchHz: 0,
          metrics: {},
        );
      }
      
      // 3. Get or Analyze the reference audio
      AudioAnalysis? refAnalysis = _refCache[animalType];
      
      if (refAnalysis == null) {
        try {
          debugPrint("RealRatingService: Analyzing reference for $animalType (not cached)");
          final assetPath = reference.audioAssetPath;
          final ByteData data = await rootBundle.load(assetPath);
          final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/ref_${reference.id}.wav');
          await tempFile.writeAsBytes(bytes);
          
          refAnalysis = await analyzer.analyzeAudio(tempFile.path);
          _refCache[animalType] = refAnalysis;
          
          try { await tempFile.delete(); } catch (_) {}
        } catch (e) {
          debugPrint("Reference Analysis Error: $e");
        }
      } else {
        debugPrint("RealRatingService: Using cached reference for $animalType");
      }

      final detectedPitch = userAnalysis.dominantFrequencyHz;
      final detectedDuration = userAnalysis.totalDurationSec;

      // 3. Compare (The Algorithm)
      final pitchDiff = (detectedPitch - reference.idealPitchHz).abs();
      final durationDiff = (detectedDuration - reference.idealDurationSec).abs();

      // 4. Calculate Score
      double pitchScore = 100.0;
      if (reference.idealPitchHz > 0) {
        final pitchDeviationPercent = (pitchDiff / reference.idealPitchHz) * 100;
        final tolerancePercent = (reference.tolerancePitch / reference.idealPitchHz) * 100;
        
        if (pitchDeviationPercent > tolerancePercent) {
          pitchScore = max(0, 100 - ((pitchDeviationPercent - tolerancePercent) * 3));
        }
      }

      double durationScore = 100.0;
      if (reference.idealDurationSec > 0) {
        final durationDeviationPercent = (durationDiff / reference.idealDurationSec) * 100;
        final toleranceDurationPercent = (reference.toleranceDuration / reference.idealDurationSec) * 100;
        
        if (durationDeviationPercent > toleranceDurationPercent) {
          durationScore = max(0, 100 - ((durationDeviationPercent - toleranceDurationPercent) * 2));
        }
      }

      double totalScore = (pitchScore * 0.6) + (durationScore * 0.4);
      totalScore = totalScore.clamp(0, 100);

      // 5. Generate Feedback
      String feedback = "";
      final bool pitchIsGood = pitchScore >= 85;
      final bool durationIsGood = durationScore >= 85;
      
      if (pitchIsGood && durationIsGood) {
        feedback = "Outstanding! You sound just like a ${reference.animalName}.";
      } else if (!pitchIsGood && !durationIsGood) {
        if (pitchScore < durationScore) {
          final pitchDeviationPercent = (pitchDiff / reference.idealPitchHz) * 100;
          feedback = "Pitch is off by ${pitchDeviationPercent.toStringAsFixed(0)}%. Duration also needs work.";
        } else {
          feedback = "Duration is off. Pitch also needs work.";
        }
      } else if (!pitchIsGood) {
        feedback = detectedPitch > reference.idealPitchHz ? "Too High! Lower your pitch." : "Too Low! Raise your pitch.";
      } else {
        feedback = detectedDuration > reference.idealDurationSec ? "Too Long!" : "Too Short!";
      }

      final result = RatingResult(
        score: totalScore,
        feedback: feedback,
        pitchHz: detectedPitch,
        metrics: {
          "Pitch (Hz)": detectedPitch,
          "Target Pitch": reference.idealPitchHz,
          "Duration (s)": detectedDuration,
          "avg_volume": userAnalysis.averageVolume * 100,
          "peak_volume": userAnalysis.peakVolume * 100,
          "consistency": userAnalysis.volumeConsistency,
          "tone_clarity": userAnalysis.toneClarity,
          "harmonic_richness": userAnalysis.harmonicRichness,
          "call_quality": userAnalysis.callQualityScore,
          "brightness": userAnalysis.brightness,
          "warmth": userAnalysis.warmth,
          "nasality": userAnalysis.nasality,
        },
        userWaveform: userAnalysis.waveform,
        referenceWaveform: refAnalysis?.waveform,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );
      debugPrint("RealRatingService: Analysis successful. Score: ${result.score}, Pitch: ${result.pitchHz}Hz");

      // Save to history
      await profileRepository.saveResultForUser(userId, result, animalType);
      
      // Submit to Leaderboard if score is decent
      if (totalScore >= 60 && userId != 'guest' && leaderboardService != null) {
        try {
          final profile = await profileRepository.getProfile(userId);
          await leaderboardService!.submitScore(
            animalId: animalType,
            entry: LeaderboardEntry(
              userId: userId,
              userName: profile.name,
              score: totalScore,
              timestamp: DateTime.now(),
            ),
          );
        } catch (e) {
          debugPrint("Leaderboard submission failed: $e");
        }
      }
      
      // Check if this call matches the Daily Challenge
      try {
        if (userId != 'guest') {
          final dailyCall = DailyChallengeService.getDailyChallenge();
          if (dailyCall.id == animalType && totalScore >= 70) {
            debugPrint("Daily Challenge ($animalType) Completed by $userId with score $totalScore");
            await profileRepository.updateDailyChallengeStats(userId);
          }
        }
      } catch (e) {
        debugPrint("Daily Challenge update failed: $e");
      }
      
      return result;
    } catch (e) {
      debugPrint("RealRatingService: Analysis failed: $e");
      rethrow;
    }
  }
}
