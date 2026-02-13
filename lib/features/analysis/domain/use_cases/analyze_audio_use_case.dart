import 'dart:io';
import 'package:fpdart/fpdart.dart';
import '../failures/analysis_failure.dart';
import '../frequency_analyzer.dart';
import '../audio_analysis_model.dart';

/// Use case for analyzing audio characteristics
/// 
/// Delegates to FrequencyAnalyzer but adds error handling and validation
class AnalyzeAudioUseCase {
  final FrequencyAnalyzer _analyzer;
  
  const AnalyzeAudioUseCase(this._analyzer);
  
  /// Analyze the audio file and return detailed analysis
  Future<Either<AnalysisFailure, AudioAnalysis>> execute(String audioPath) async {
    try {
      // Validate file exists
      final file = File(audioPath);
      if (!await file.exists()) {
        return left(AudioFileNotFound(audioPath));
      }
      
      // Perform analysis via analyzer
      final analysis = await _analyzer.analyzeAudio(audioPath);
      
      // Validate analysis result
      if (analysis.dominantFrequencyHz == 0 && analysis.totalDurationSec == 0) {
        return left(const InsufficientAudioData('No audio signal detected'));
      }
      
      return right(analysis);
    } on FileSystemException catch (e) {
      return left(AudioFileNotFound('${audioPath}: ${e.message}'));
    } on FormatException catch (e) {
      return left(InvalidAudioFormat(e.message));
    } catch (e) {
      return left(AnalysisComputationError(e.toString()));
    }
  }
}
