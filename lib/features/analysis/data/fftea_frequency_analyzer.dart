import 'dart:io';
import 'dart:math';

import 'package:fftea/fftea.dart';
import 'package:flutter/foundation.dart';
import '../domain/frequency_analyzer.dart';

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
      // 1. Read the file
      final file = File(audioPath);
      if (!await file.exists()) {
        debugPrint("Analysis Error: File $audioPath not found");
        return 0.0;
      }

    // 2. Parse WAV header and extract PCM data
    final bytes = await file.readAsBytes();
    if (bytes.length < 44) return 0.0;

    final ByteData view = bytes.buffer.asByteData();
    
    // Parse sample rate from WAV header (bytes 24-27)
    int sampleRate = 44100;
    if (bytes.length >= 28) {
      sampleRate = view.getUint32(24, Endian.little);
    }
    
    // Calculate total samples (16-bit mono PCM = 2 bytes per sample)
    final numSamples = (bytes.length - 44) ~/ 2;
    if (numSamples < _chunkSize) {
      debugPrint("Analysis Warning: Audio too short for reliable analysis ($numSamples samples)");
      return _analyzeSingleChunk(view, 44, numSamples, sampleRate);
    }

    // 3. Analyze multiple chunks distributed through the audio
    // This gives a more representative frequency analysis
    final chunkResults = <_ChunkResult>[];
    final numChunks = (numSamples ~/ _chunkSize).clamp(1, _maxChunks);
    final chunkSpacing = numSamples ~/ numChunks;
    
    for (int chunk = 0; chunk < numChunks; chunk++) {
      final startSample = chunk * chunkSpacing;
      final startOffset = 44 + (startSample * 2);
      
      // Ensure we don't read past the end
      if (startOffset + (_chunkSize * 2) > bytes.length) continue;
      
      final result = _analyzeChunk(view, startOffset, _chunkSize, sampleRate);
      if (result != null) {
        chunkResults.add(result);
      }
    }

    if (chunkResults.isEmpty) return 0.0;

    // 4. Weight results by amplitude (louder = more reliable)
    double weightedSum = 0.0;
    double totalWeight = 0.0;
    
    for (var result in chunkResults) {
      weightedSum += result.frequency * result.amplitude;
      totalWeight += result.amplitude;
    }
    
    final dominantFreq = totalWeight > 0 ? weightedSum / totalWeight : 0.0;
    debugPrint("FFT Analysis: Weighted average = ${dominantFreq.toStringAsFixed(1)}Hz from $numChunks chunks");
    
    return dominantFreq;
  }
  
  /// Analyze a single chunk when audio is too short for multi-chunk analysis
  double _analyzeSingleChunk(ByteData view, int offset, int length, int sampleRate) {
    final result = _analyzeChunk(view, offset, length, sampleRate);
    return result?.frequency ?? 0.0;
  }
  
  /// Analyze a chunk and return frequency + amplitude, or null if analysis fails
  _ChunkResult? _analyzeChunk(ByteData view, int offset, int length, int sampleRate) {
    // Build signal array, normalized to -1.0 to 1.0
    final signal = Float64List(length);
    for (var i = 0; i < length; i++) {
      final sample = view.getInt16(offset + (i * 2), Endian.little);
      signal[i] = sample / 32768.0;
    }
    
    // Apply Hanning window and run FFT
    final fft = FFT(length);
    final windowed = Float64List(length);
    final window = Window.hanning(length);
    for (var i = 0; i < length; i++) {
      windowed[i] = signal[i] * window[i];
    }
    
    final freq = fft.realFft(windowed);
    final magnitudes = freq.magnitudes();
    
    // Find peak within our frequency range of interest
    final minBin = ((_minFrequencyHz * length) / sampleRate).ceil();
    final maxBin = ((_maxFrequencyHz * length) / sampleRate).floor().clamp(0, magnitudes.length ~/ 2);
    
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
}

/// Helper class to store FFT chunk analysis results
class _ChunkResult {
  final double frequency;
  final double amplitude;
  
  _ChunkResult({required this.frequency, required this.amplitude});
}
