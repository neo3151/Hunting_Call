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

class RealRatingService implements RatingService {
  final FrequencyAnalyzer analyzer;
  final ProfileRepository profileRepository;

  RealRatingService({required this.analyzer, required this.profileRepository});

  @override
  Future<RatingResult> rateCall(String userId, String audioPath, String animalType) async {
    debugPrint("RealRatingService: rateCall started for $animalType at $audioPath");
    // 1. Get the ideal metrics
    // We now pass the ID directly from the dropdown
    final reference = ReferenceDatabase.getById(animalType);

    // 2. Analyze the user's audio and the reference audio
    final userAnalysis = await analyzer.analyzeAudio(audioPath);
    
    // For comparison, we also need the reference audio characteristics
    AudioAnalysis? refAnalysis;
    try {
      final assetPath = reference.audioAssetPath;
      
      // Since assetPath is a Flutter asset, we can't use File(assetPath) directly in a running app
      // We need to load it via rootBundle and save to a temp file for the analyzer
      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/ref_${reference.id}.wav');
      await tempFile.writeAsBytes(bytes);
      
      refAnalysis = await analyzer.analyzeAudio(tempFile.path);
      debugPrint("RealRatingService: Reference analysis complete. Waveform: ${refAnalysis.waveform.length} pts");
      
      // Clean up temp file (optional, but good practice)
      // await tempFile.delete(); 
    } catch (e) {
      debugPrint("Reference Analysis Error: $e");
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
    );

    // Save to history
    await profileRepository.saveResultForUser(userId, result, animalType);
    
    return result;
  }
}
