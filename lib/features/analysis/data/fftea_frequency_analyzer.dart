import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'package:flutter/foundation.dart';
import '../domain/frequency_analyzer.dart';

class FFTEAFrequencyAnalyzer implements FrequencyAnalyzer {
  @override
  Future<double> getDominantFrequency(String audioPath) async {
    // 1. Read the file
    final file = File(audioPath);
    if (!await file.exists()) {
      debugPrint("Analysis Error: File $audioPath not found");
      return 0.0;
    }

    // 2. Extract PCM Data (Skip WAV header)
    // WAV header is typically 44 bytes.
    // We assume 16-bit Mono PCM (2 bytes per sample).
    final bytes = await file.readAsBytes();
    if (bytes.length < 44) return 0.0;

    // Convert bytes to Float64List for FFTEA
    // Little-endian 16-bit integer -> -1.0 to 1.0 double
    final numSamples = (bytes.length - 44) ~/ 2;
    // Limit processing to first ~4 seconds (approx 180k samples at 44.1kHz) to avoid OOM on mobile
    final maxSamples = min(numSamples, 131072); // Power of 2 (2^17) typical
    
    // Find next power of 2 for chunk length usually, 
    // but FFTEA handles arbitrary sizes by padding or we just take a chunk.
    const chunkLength = 4096;
    final int processLength = numSamples < chunkLength ? numSamples : chunkLength;

    if (processLength == 0) return 0.0;

    final signal = Float64List(processLength);
    final ByteData view = bytes.buffer.asByteData();
    
    // We analyze the middle of the recording (often loudest/clearest)
    // or just the beginning after header. Let's take a chunk from the middle.
    int startOffset = 44 + ((numSamples - processLength) ~/ 2) * 2;
    if (startOffset < 44) startOffset = 44;

    for (var i = 0; i < processLength; i++) {
      // Read 16-bit signed integer (little endian)
      int sample = view.getInt16(startOffset + (i * 2), Endian.little);
      // Normalize to -1.0 to 1.0
      signal[i] = sample / 32768.0;
    }

    // 3. Run FFT
    final stft = STFT(chunkLength, Window.hanning(chunkLength));
    final spectrogram = stft.run(signal, (freq) {}); // simple run?

    // FFTEA's API for simple spectral analysis:
    final fft = FFT(processLength);
    final freq = fft.realFft(signal);
    
    // 4. Find Peak
    // magnitudes() returns list of amplitudes for each frequency bin
    final magnitudes = freq.magnitudes();
    
    // Ignore DC component (index 0) and very low frequencies
    double maxMag = -1.0;
    int peakIndex = -1;
    
    for (int i = 1; i < magnitudes.length ~/ 2; i++) {
        if (magnitudes[i] > maxMag) {
            maxMag = magnitudes[i];
            peakIndex = i;
        }
    }
    
    // 5. Convert Index to Hz
    // Frequency = (Index * SampleRate) / FFT_Size
    // Note: We assumed 44100 Hz in RecorderService default
    // Ideally we parse rate from WAV header, but MVP/Standard is usually 44100 or 16000.
    // FlutterSound default is often device dependent, but let's assume 44100 for now.
    // Or we can parse bytes 24-27 of WAV header for sample rate.
    
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
