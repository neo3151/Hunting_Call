abstract class FrequencyAnalyzer {
  /// Analyzes the audio at [audioPath] and returns the dominant frequency in Hz.
  Future<double> getDominantFrequency(String audioPath);
}
