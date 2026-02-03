import 'dart:io';
import 'dart:math';

import 'package:fftea/fftea.dart';
import 'package:flutter/foundation.dart';
import '../domain/frequency_analyzer.dart';

class FFTEAFrequencyAnalyzer implements FrequencyAnalyzer {
  @override
  Future<double> getDominantFrequency(String audioPath) async {
    try {
      // 1. Read the file
      final file = File(audioPath);
      if (!await file.exists()) {
        debugPrint("Analysis Error: File $audioPath not found");
        return 0.0;
      }

      // 2. Extract PCM Data (Skip WAV header)
      final bytes = await file.readAsBytes();
      if (bytes.length < 44) return 0.0;

      final numSamples = (bytes.length - 44) ~/ 2;
      const chunkLength = 4096;
      final int processLength = numSamples < chunkLength ? numSamples : chunkLength;

      if (processLength == 0) return 0.0;

      final signal = Float64List(processLength);
      final ByteData view = bytes.buffer.asByteData();
      
      // Analyze middle of recording
      int startOffset = 44 + ((numSamples - processLength) ~/ 2) * 2;
      if (startOffset < 44) startOffset = 44;

      // Apply Hanning window while reading samples
      for (var i = 0; i < processLength; i++) {
        int sample = view.getInt16(startOffset + (i * 2), Endian.little);
        double normalized = sample / 32768.0;
        // Apply Hanning window: 0.5 * (1 - cos(2*pi*n/(N-1)))
        double window = 0.5 * (1 - cos(2 * pi * i / (processLength - 1)));
        signal[i] = normalized * window;
      }

      // 3. Run FFT
      final fft = FFT(processLength);
      final freq = fft.realFft(signal);
      
      // 4. Find Peak
      final magnitudes = freq.magnitudes();
      
      double maxMag = -1.0;
      int peakIndex = -1;
      
      for (int i = 1; i < magnitudes.length ~/ 2; i++) {
        if (magnitudes[i] > maxMag) {
          maxMag = magnitudes[i];
          peakIndex = i;
        }
      }
      
      // 5. Convert Index to Hz
      int sampleRate = 44100;
      if (bytes.length >= 28) {
        sampleRate = view.getUint32(24, Endian.little);
      }

      if (peakIndex != -1) {
        final dominantFreq = fft.frequency(peakIndex, sampleRate.toDouble());
        debugPrint("FFT Analysis: Peak at $dominantFreq Hz (Bin $peakIndex of $processLength)");
        return dominantFreq;
      }

      return 0.0;
    } catch (e, stackTrace) {
      debugPrint("FFT Analysis Error: $e");
      debugPrint("Stack trace: $stackTrace");
      return 0.0;
    }
  }
  
  /* 
   * Real FFT Logic (Reference for when we add file decoding):
   * 
   * final fft = FFT(chunkLength);
   * final freq = fft.realFft(signal);
   * final magnitudes = freq.magnitudes();
   * final peakIndex = magnitudes.indexOf(magnitudes.reduce(max));
   * final peakFreq = fft.frequency(peakIndex, sampleRate);
   * return peakFreq;
   */
}
