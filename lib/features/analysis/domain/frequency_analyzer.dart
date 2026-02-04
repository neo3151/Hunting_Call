import 'audio_analysis_model.dart';

abstract class FrequencyAnalyzer {
  /// Analyzes the audio at [audioPath] and returns the dominant frequency in Hz.
  Future<double> getDominantFrequency(String audioPath);
  
  /// Performs comprehensive audio analysis
  Future<AudioAnalysis> analyzeAudio(String audioPath);
}
