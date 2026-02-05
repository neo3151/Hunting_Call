import 'dart:io';

import 'package:fftea/fftea.dart';
import 'package:flutter/foundation.dart';
import '../domain/frequency_analyzer.dart';
import '../domain/audio_analysis_model.dart';

/// Data class to pass parameters to the isolate
class _AnalysisParams {
  final Uint8List bytes;
  final int sampleRate;

  _AnalysisParams(this.bytes, this.sampleRate);
}

class FFTEAFrequencyAnalyzer implements FrequencyAnalyzer {
  /// FFT chunk size - must be power of 2. Larger = better frequency resolution
  /// 8192 samples @ 44.1kHz = ~186ms per chunk, ~5.4Hz bin resolution
  static const int _chunkSize = 8192;
  
  /// Maximum number of chunks to analyze (evenly distributed through audio)
  /// Analyzing multiple chunks helps find the true dominant frequency
  static const int _maxChunks = 5;
  
  /// Minimum frequency to consider (Hz) - filters out rumble/DC offset
  static const double _minFrequencyHz = 50.0;
  
  /// Maximum frequency to consider (Hz) - most animal calls are below this
  static const double _maxFrequencyHz = 4000.0;

  @override
  Future<double> getDominantFrequency(String audioPath) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        debugPrint("Analysis Error: File $audioPath not found");
        return 0.0;
      }

      final bytes = await file.readAsBytes();
      if (bytes.length < 44) {
        debugPrint("Analysis Error: File $audioPath is too small to be a valid WAV");
        return 0.0;
      }

      // Extract sample rate from WAV header
      final ByteData view = bytes.buffer.asByteData();
      int sampleRate = 44100;
      if (bytes.length >= 28) {
        sampleRate = view.getUint32(24, Endian.little);
      }

      // Use compute to run the heavy FFT in a separate isolate
      return await compute(_performFFTAnalysis, _AnalysisParams(bytes, sampleRate));
    } catch (e, stackTrace) {
      debugPrint("FFT Analysis Error: $e");
      debugPrint(stackTrace.toString());
      return 0.0;
    }
  }

  @override
  Future<AudioAnalysis> analyzeAudio(String audioPath) async {
    debugPrint("--- USING FFTEA ANALYZER ---");
    try {
      final file = File(audioPath);
      final bytes = await file.readAsBytes();
      if (bytes.length < 44) return AudioAnalysis.simple(frequencyHz: 0, durationSec: 0);

      final ByteData view = bytes.buffer.asByteData();
      final int sampleRate = view.getUint32(24, Endian.little);
      final int numChannels = view.getUint16(22, Endian.little);
      final int bitsPerSample = view.getUint16(34, Endian.little);
      
      final freq = await compute(_performFFTAnalysis, _AnalysisParams(bytes, sampleRate));
      
      // Calculate duration using actual file parameters
      final int bytesPerSample = bitsPerSample ~/ 8;
      final double duration = (bytes.length - 44) / (sampleRate * numChannels * bytesPerSample);
      
      return AudioAnalysis.simple(frequencyHz: freq, durationSec: duration);
    } catch (e) {
      debugPrint("Analysis Error: $e");
      return AudioAnalysis.simple(frequencyHz: 0, durationSec: 0);
    }
  }
}

/// Helper class to store FFT chunk analysis results
class _ChunkResult {
  final double frequency;
  final double amplitude;
  
  _ChunkResult({required this.frequency, required this.amplitude});
}

/// Helper function that runs in a separate isolate
double _performFFTAnalysis(_AnalysisParams params) {
  final bytes = params.bytes;
  final sampleRate = params.sampleRate;
  final ByteData view = bytes.buffer.asByteData();

  try {
    // 1. Calculate dimensions from WAV header
    if (bytes.length < 44) return 0.0;
    final int sampleRateHeader = view.getUint32(24, Endian.little);
    final int numChannels = view.getUint16(22, Endian.little);
    final int bitsPerSample = view.getUint16(34, Endian.little);
    final int bytesPerSample = bitsPerSample ~/ 8;
    
    final numSamples = (bytes.length - 44) ~/ (numChannels * bytesPerSample);
    const int chunkSize = 8192;
    const int maxChunks = 5;
    const double minFrequencyHz = 50.0;
    const double maxFrequencyHz = 4000.0;

    if (numSamples < chunkSize) {
      return _analyzeChunk(view, 44, numSamples, sampleRateHeader, minFrequencyHz, maxFrequencyHz)?.frequency ?? 0.0;
    }

    // 2. Identify the peak vocalization chunk
    int bestOffset = 44;
    double maxEnergy = -1.0;
    
    // Slide window to find highest energy 8k chunk
    for (int offset = 44; offset + (chunkSize * 2 * numChannels) <= bytes.length; offset += (chunkSize ~/ 2) * 2 * numChannels) {
      double currentEnergy = 0;
      for (int i = 0; i < chunkSize; i++) {
        final sample = view.getInt16(offset + (i * 2 * numChannels), Endian.little);
        final double normalized = sample / 32768.0;
        currentEnergy += normalized * normalized;
      }
      currentEnergy = currentEnergy / chunkSize;

      if (currentEnergy > maxEnergy) {
        maxEnergy = currentEnergy;
        bestOffset = offset;
      }
    }

    // Analyze the highest energy chunk
    final result = _analyzeChunk(view, bestOffset, chunkSize, sampleRate, minFrequencyHz, maxFrequencyHz);
    return result?.frequency ?? 0.0;
  } catch (e) {
    return 0.0;
  }
}

/// Analyze a chunk and return frequency + amplitude
_ChunkResult? _analyzeChunk(ByteData view, int offset, int length, int sampleRate, double minFreq, double maxFreq) {
  if (sampleRate <= 0 || length <= 0) return null;
  
  final signal = Float64List(length);
  for (var i = 0; i < length; i++) {
    final sample = view.getInt16(offset + (i * 2), Endian.little);
    signal[i] = sample / 32768.0;
  }
  
  final fft = FFT(length);
  final windowed = Float64List(length);
  final window = Window.hanning(length);
  for (var i = 0; i < length; i++) {
    windowed[i] = signal[i] * window[i];
  }
  
  final freq = fft.realFft(windowed);
  final magnitudes = freq.magnitudes();
  
  final minBin = ((minFreq * length) / sampleRate).ceil();
  final maxBin = ((maxFreq * length) / sampleRate).floor().clamp(0, magnitudes.length ~/ 2);
  
  double maxMag = -1.0;
  int peakIndex = -1;
  
  for (int i = minBin; i < maxBin; i++) {
    if (magnitudes[i] > maxMag) {
      maxMag = magnitudes[i];
      peakIndex = i;
    }
  }
  
  if (peakIndex == -1 || maxMag <= 0) return null;
  
  final peakFreq = fft.frequency(peakIndex, sampleRate.toDouble());
  return _ChunkResult(frequency: peakFreq, amplitude: maxMag);
}
