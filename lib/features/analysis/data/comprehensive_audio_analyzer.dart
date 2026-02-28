import 'dart:io';
import 'dart:math';
import 'package:fftea/fftea.dart';
import 'package:flutter/foundation.dart';
import 'package:outcall/features/analysis/domain/frequency_analyzer.dart';
import 'package:outcall/features/analysis/domain/audio_analysis_model.dart';
import 'package:outcall/features/analysis/data/waveform_cache_database.dart';
import 'package:outcall/core/utils/app_logger.dart';

class ComprehensiveAudioAnalyzer implements FrequencyAnalyzer {
  final _cache = WaveformCacheDatabase();
  
  ComprehensiveAudioAnalyzer() {
    // Clear ALL cached waveforms — normalization curve changed from sqrt to
    // pow(1.5), so every cached waveform is stale and must be recomputed.
    _cache.clearCache().then((_) {
      AppLogger.d('WaveformCache: Cleared all entries (normalization update)');
    });
  }

  @override
  Future<double> getDominantFrequency(String audioPath) async {
    final analysis = await analyzeAudio(audioPath);
    return analysis.dominantFrequencyHz;
  }

  /// Performs comprehensive audio analysis
  @override
  Future<AudioAnalysis> analyzeAudio(String audioPath) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        AppLogger.d('Analysis Error: File $audioPath not found');
        return AudioAnalysis.simple(frequencyHz: 0.0, durationSec: 0.0);
      }

      // Check cache first (on main thread)
      // Note: We don't cache the full object yet, just waveform. 
      // If we move to full caching, check here.

      AppLogger.d('ComprehensiveAudioAnalyzer: Spawning isolate for analysis...');
      final analysis = await compute(_runAnalysisInIsolate, audioPath);
      AppLogger.d('ComprehensiveAudioAnalyzer: Analysis complete.');
      
      // Update waveform cache with the result if needed
      if (analysis.waveform.isNotEmpty) {
        await _cache.cacheWaveform(audioPath, analysis.waveform);
      }
      
      return analysis;

    } catch (e, stack) {
      AppLogger.d('Comprehensive Analysis Error: $e\n$stack');
      return AudioAnalysis.simple(frequencyHz: 0.0, durationSec: 0.0);
    }
  }

  /// Static entry point for the isolate
  static Future<AudioAnalysis> _runAnalysisInIsolate(String audioPath) async {
    final file = File(audioPath);
    final bytes = await file.readAsBytes();
      if (bytes.length < 44) {
        return AudioAnalysis.simple(frequencyHz: 0.0, durationSec: 0.0);
      }

      final ByteData view = bytes.buffer.asByteData();
      
      // Parse WAV header
      int sampleRate = 44100;
      if (bytes.length >= 28) {
        sampleRate = view.getUint32(24, Endian.little);
      }

      // Extract PCM data
      final numSamples = (bytes.length - 44) ~/ 2;
      final totalDuration = numSamples / sampleRate;
      
      // Convert to float samples
      final samples = Float64List(numSamples);
      for (var i = 0; i < numSamples; i++) {
        final int sample = view.getInt16(44 + (i * 2), Endian.little);
        samples[i] = sample / 32768.0;
      }

      // Calibrate adaptive noise floor from the recording
      final noiseFloor = _calibrateNoiseFloor(samples, sampleRate);

      // Perform analyses (using static helpers)
      final pitchAnalysis = _analyzePitch(samples, sampleRate, noiseFloor);
      final volumeAnalysis = _analyzeVolume(samples);
      final toneAnalysis = _analyzeTone(samples, sampleRate);
      final timbreAnalysis = _analyzeTimbre(samples, sampleRate);
      final durationAnalysis = _analyzeDuration(samples, sampleRate, totalDuration, noiseFloor);
      final rhythmAnalysis = _analyzeRhythm(samples, sampleRate, noiseFloor);
      final quality = _assessQuality(samples, sampleRate);
      final mfccs = _extractMFCCs(samples, sampleRate);
      
      // Generate waveform (expensive, do in isolate)
      final waveform = _extractWaveform(samples, 100);

      return AudioAnalysis(
        // Pitch
        dominantFrequencyHz: pitchAnalysis['dominantFrequency']!,
        averageFrequencyHz: pitchAnalysis['averageFrequency']!,
        frequencyPeaks: pitchAnalysis['peaks'] as List<double>,
        pitchStability: pitchAnalysis['stability']!,
        
        // Volume
        averageVolume: volumeAnalysis['average']!,
        peakVolume: volumeAnalysis['peak']!,
        volumeConsistency: volumeAnalysis['consistency']!,
        
        // Tone
        toneClarity: toneAnalysis['clarity']!,
        harmonicRichness: toneAnalysis['harmonicRichness']!,
        harmonics: toneAnalysis['harmonics'] as Map<String, double>,
        
        // Timbre
        brightness: timbreAnalysis['brightness']!,
        warmth: timbreAnalysis['warmth']!,
        nasality: timbreAnalysis['nasality']!,
        spectralCentroid: timbreAnalysis['spectralCentroid'] as List<double>,
        
        // Duration
        totalDurationSec: totalDuration,
        activeDurationSec: durationAnalysis['active']!,
        silenceDurationSec: durationAnalysis['silence']!,
        
        // Rhythm
        tempo: rhythmAnalysis['tempo']!,
        pulseTimes: rhythmAnalysis['pulseTimes'] as List<double>,
        rhythmRegularity: rhythmAnalysis['regularity']!,
        isPulsedCall: rhythmAnalysis['isPulsed'] as bool,
        
        // Quality
        callQualityScore: quality['score']!,
        noiseLevel: quality['noise']!,
        
        // Timbre - MFCC
        mfccCoefficients: mfccs,
        
        // Visualization
        waveform: waveform,
        pitchTrack: pitchAnalysis['pitchTrack'] as List<double>,
      );
  }

  /// Calibrate adaptive noise floor from the quietest frames in the recording.
  /// Returns the RMS energy of the bottom 10% of frames.
  static double _calibrateNoiseFloor(Float64List samples, int sampleRate) {
    const frameDuration = 0.05; // 50ms frames
    final frameSize = (sampleRate * frameDuration).toInt();
    final frameCount = samples.length ~/ frameSize;
    if (frameCount == 0) return 0.005;

    final List<double> frameEnergies = [];
    for (int i = 0; i < frameCount; i++) {
      final start = i * frameSize;
      double sum = 0.0;
      for (int j = start; j < start + frameSize && j < samples.length; j++) {
        sum += samples[j] * samples[j];
      }
      frameEnergies.add(sqrt(sum / frameSize));
    }

    frameEnergies.sort();
    final bottomCount = max(1, (frameEnergies.length * 0.10).ceil());
    double floorSum = 0.0;
    for (int i = 0; i < bottomCount; i++) {
      floorSum += frameEnergies[i];
    }
    // Clamp to minimum of 0.005 to avoid zero-floor on dead silence
    return max(0.005, floorSum / bottomCount);
  }

  /// Analyze pitch characteristics
  static Map<String, dynamic> _analyzePitch(Float64List samples, int sampleRate, double noiseFloor) {
    const chunkSize = 4096;
    final chunks = samples.length ~/ chunkSize;
    
    final List<double> dominantFreqs = [];
    final List<List<double>> allPeaks = [];
    
    for (int i = 0; i < chunks; i++) {
      final start = i * chunkSize;
      final end = min(start + chunkSize, samples.length);
      final chunk = samples.sublist(start, end);
      
      if (chunk.length < chunkSize) continue;
      
      // Calculate chunk energy - skip if below adaptive noise floor
      double energy = 0.0;
      for (var s in chunk) {
        energy += s * s;
      }
      energy = sqrt(energy / chunkSize);
      if (energy < noiseFloor * 1.5) continue; // Adaptive threshold
      
      // Apply window
      final windowed = Float64List(chunkSize);
      for (int j = 0; j < chunkSize; j++) {
        windowed[j] = chunk[j] * _hanningWindow(j, chunkSize);
      }
      
      // FFT
      final fft = FFT(chunkSize);
      final freq = fft.realFft(windowed);
      final magnitudes = freq.magnitudes();
      
      // Find peaks
      final List<MapEntry<int, double>> peaks = [];
      double maxMag = 0.0;
      for (int j = 2; j < magnitudes.length ~/ 2 - 2; j++) {
        if (magnitudes[j] > magnitudes[j - 1] &&
            magnitudes[j] > magnitudes[j + 1]) {
          peaks.add(MapEntry(j, magnitudes[j]));
          if (magnitudes[j] > maxMag) maxMag = magnitudes[j];
        }
      }
      
      if (peaks.isNotEmpty) {
        // Boost peaks in the 80-400 Hz fundamental band (deer/turkey range)
        // This makes the system prefer biological fundamentals over harmonics
        final boostedPeaks = peaks.map((p) {
          final freq = fft.frequency(p.key, sampleRate.toDouble());
          final boost = (freq >= 80 && freq <= 400) ? 1.5 : 1.0;
          return MapEntry(p.key, p.value * boost);
        }).toList();
        
        // Recalculate maxMag with boosted values
        double boostedMax = 0.0;
        for (var p in boostedPeaks) {
          if (p.value > boostedMax) boostedMax = p.value;
        }
        
        // Preference for fundamental:
        // Sort by frequency, pick lowest peak above 30% of boosted max
        boostedPeaks.sort((a, b) => a.key.compareTo(b.key));
        
        int selectedIdx = -1;
        for (var peak in boostedPeaks) {
          if (peak.value > boostedMax * 0.3) {
            selectedIdx = peak.key;
            break;
          }
        }
        
        if (selectedIdx != -1) {
          final dominantFreq = fft.frequency(selectedIdx, sampleRate.toDouble());
          // Basic filtering for extreme outliers in animal calls (very few are > 3kHz)
          if (dominantFreq > 50 && dominantFreq < 5000) {
            dominantFreqs.add(dominantFreq);
            allPeaks.add(peaks.take(5).map((p) => 
              fft.frequency(p.key, sampleRate.toDouble())
            ).toList());
          }
        }
      }
    }
    
    // Calculate statistics
    final double avgFreq = dominantFreqs.isEmpty ? 0.0 : 
      dominantFreqs.reduce((a, b) => a + b) / dominantFreqs.length;
    
    double stability = 100.0;
    if (dominantFreqs.length > 1) {
      double variance = 0.0;
      for (var f in dominantFreqs) {
        variance += pow(f - avgFreq, 2);
      }
      variance /= dominantFreqs.length;
      final double stdDev = sqrt(variance);
      stability = max(0, 100 - (stdDev / avgFreq * 100));
    }
    
    // Get most common peaks
    final Map<double, int> peakCounts = {};
    for (var peakList in allPeaks) {
      for (var peak in peakList) {
        final double rounded = (peak / 10).round() * 10.0;
        peakCounts[rounded] = (peakCounts[rounded] ?? 0) + 1;
      }
    }
    
    final topPeaks = peakCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return {
      'dominantFrequency': dominantFreqs.isEmpty ? 0.0 : 
        dominantFreqs.reduce((a, b) => a + b) / dominantFreqs.length,
      'averageFrequency': avgFreq,
      'peaks': topPeaks.take(5).map((e) => e.key).toList(),
      'stability': stability,
      'pitchTrack': dominantFreqs,
    };
  }

  /// Analyze volume characteristics
  static Map<String, double> _analyzeVolume(Float64List samples) {
    double sum = 0.0;
    double peak = 0.0;
    
    for (var sample in samples) {
      final double abs = sample.abs();
      sum += abs * abs; // RMS
      if (abs > peak) peak = abs;
    }
    
    final double rms = sqrt(sum / samples.length);
    
    // Calculate volume consistency
    final List<double> chunkVolumes = [];
    const chunkSize = 4410; // ~0.1 sec at 44.1kHz
    for (int i = 0; i < samples.length; i += chunkSize) {
      double chunkSum = 0.0;
      int count = 0;
      for (int j = i; j < min(i + chunkSize, samples.length); j++) {
        chunkSum += samples[j].abs();
        count++;
      }
      chunkVolumes.add(chunkSum / count);
    }
    
    final double avgChunkVol = chunkVolumes.reduce((a, b) => a + b) / chunkVolumes.length;
    double variance = 0.0;
    for (var v in chunkVolumes) {
      variance += pow(v - avgChunkVol, 2);
    }
    variance /= chunkVolumes.length;
    final double consistency = max(0, 100 - (sqrt(variance) * 1000));
    
    return {
      'average': rms,
      'peak': peak,
      'consistency': consistency,
    };
  }

  /// Analyze tone characteristics
  static Map<String, dynamic> _analyzeTone(Float64List samples, int sampleRate) {
    const chunkSize = 4096;
    final chunk = samples.sublist(0, min(chunkSize, samples.length));
    
    // Apply window and FFT
    final windowed = Float64List(chunkSize);
    for (int i = 0; i < chunk.length; i++) {
      windowed[i] = chunk[i] * _hanningWindow(i, chunkSize);
    }
    
    final fft = FFT(chunkSize);
    final freq = fft.realFft(windowed);
    final magnitudes = freq.magnitudes();
    
    // Find fundamental and harmonics
    int fundamentalIdx = 0;
    double maxMag = 0.0;
    for (int i = 1; i < magnitudes.length ~/ 2; i++) {
      if (magnitudes[i] > maxMag) {
        maxMag = magnitudes[i];
        fundamentalIdx = i;
      }
    }
    
    final double fundamentalFreq = fft.frequency(fundamentalIdx, sampleRate.toDouble());
    
    // Detect harmonics
    final Map<String, double> harmonics = {};
    double harmonicEnergy = 0.0;
    for (int h = 2; h <= 6; h++) {
      final int harmonicIdx = (fundamentalIdx * h);
      if (harmonicIdx < magnitudes.length) {
        final double harmonicFreq = fft.frequency(harmonicIdx, sampleRate.toDouble());
        harmonics['H$h'] = harmonicFreq;
        harmonicEnergy += magnitudes[harmonicIdx];
      }
    }
    
    final double harmonicRichness = min(100, (harmonicEnergy / maxMag) * 100);
    
    // Calculate tone clarity (SNR estimation)
    double signalEnergy = 0.0;
    double noiseEnergy = 0.0;
    for (int i = 1; i < magnitudes.length ~/ 2; i++) {
      final double freq = fft.frequency(i, sampleRate.toDouble());
      if ((freq - fundamentalFreq).abs() < 50) {
        signalEnergy += magnitudes[i];
      } else {
        noiseEnergy += magnitudes[i];
      }
    }
    
    final double snr = signalEnergy / max(noiseEnergy, 0.001);
    final double clarity = min(100, snr * 10);
    
    return {
      'clarity': clarity,
      'harmonicRichness': harmonicRichness,
      'harmonics': harmonics,
    };
  }

  /// Analyze timbre characteristics
  static Map<String, dynamic> _analyzeTimbre(Float64List samples, int sampleRate) {
    const chunkSize = 4096;
    final chunks = samples.length ~/ chunkSize;
    
    final List<double> centroids = [];
    double totalLowEnergy = 0.0;
    double totalMidEnergy = 0.0;
    double totalHighEnergy = 0.0;
    double nasalEnergy = 0.0;
    
    for (int i = 0; i < chunks; i++) {
      final start = i * chunkSize;
      final chunk = samples.sublist(start, min(start + chunkSize, samples.length));
      
      if (chunk.length < chunkSize) continue;
      
      final windowed = Float64List(chunkSize);
      for (int j = 0; j < chunkSize; j++) {
        windowed[j] = chunk[j] * _hanningWindow(j, chunkSize);
      }
      
      final fft = FFT(chunkSize);
      final freq = fft.realFft(windowed);
      final magnitudes = freq.magnitudes();
      
      // Spectral centroid
      double weightedSum = 0.0;
      double magnitudeSum = 0.0;
      for (int j = 0; j < magnitudes.length ~/ 2; j++) {
        final double frequency = fft.frequency(j, sampleRate.toDouble());
        weightedSum += frequency * magnitudes[j];
        magnitudeSum += magnitudes[j];
        
        // Energy by frequency bands
        if (frequency < 500) {
          totalLowEnergy += magnitudes[j];
        } else if (frequency < 2000) {
          totalMidEnergy += magnitudes[j];
        } else {
          totalHighEnergy += magnitudes[j];
        }
        
        // Nasal frequencies (typically 1000-2500 Hz)
        if (frequency >= 1000 && frequency <= 2500) nasalEnergy += magnitudes[j];
      }
      
      if (magnitudeSum > 0) {
        centroids.add(weightedSum / magnitudeSum);
      }
    }
    
    final double totalEnergy = totalLowEnergy + totalMidEnergy + totalHighEnergy;
    final double brightness = totalEnergy > 0 ? (totalHighEnergy / totalEnergy) * 100 : 50.0;
    final double warmth = totalEnergy > 0 ? (totalLowEnergy / totalEnergy) * 100 : 50.0;
    final double nasality = totalEnergy > 0 ? (nasalEnergy / totalEnergy) * 100 : 20.0;
    
    return {
      'brightness': brightness,
      'warmth': warmth,
      'nasality': nasality,
      'spectralCentroid': centroids,
    };
  }

  /// Analyze duration characteristics
  static Map<String, double> _analyzeDuration(Float64List samples, int sampleRate, double totalDuration, double noiseFloor) {
    // Use adaptive noise floor for silence detection (2× floor for margin)
    final threshold = noiseFloor * 2.0;
    
    int activeCount = 0;
    for (var sample in samples) {
      if (sample.abs() > threshold) activeCount++;
    }
    
    final double activeDuration = activeCount / sampleRate;
    final double silenceDuration = totalDuration - activeDuration;
    
    return {
      'active': activeDuration,
      'silence': silenceDuration,
    };
  }

  /// Analyze rhythm characteristics
  static Map<String, dynamic> _analyzeRhythm(Float64List samples, int sampleRate, double noiseFloor) {
    // Simple onset detection using energy spikes
    const windowSize = 2205; // ~0.05 sec
    final List<double> energy = [];
    
    for (int i = 0; i < samples.length; i += windowSize) {
      double sum = 0.0;
      for (int j = i; j < min(i + windowSize, samples.length); j++) {
        sum += samples[j] * samples[j];
      }
      energy.add(sqrt(sum / windowSize));
    }
    
    // Find peaks (onsets) — ensure threshold stays above adaptive noise floor
    final List<double> pulseTimes = [];
    final double avgEnergy = energy.reduce((a, b) => a + b) / energy.length;
    final double threshold = max(avgEnergy * 1.5, noiseFloor * 3.0);
    
    for (int i = 1; i < energy.length - 1; i++) {
      if (energy[i] > threshold &&
          energy[i] > energy[i - 1] &&
          energy[i] > energy[i + 1]) {
        pulseTimes.add((i * windowSize) / sampleRate);
      }
    }
    
    final bool isPulsed = pulseTimes.length >= 3;
    double tempo = 0.0;
    double regularity = 0.0;
    
    if (pulseTimes.length >= 2) {
      // Calculate tempo
      final List<double> intervals = [];
      for (int i = 1; i < pulseTimes.length; i++) {
        intervals.add(pulseTimes[i] - pulseTimes[i - 1]);
      }
      final double avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      tempo = 60.0 / avgInterval; // BPM
      
      // Calculate regularity
      double variance = 0.0;
      for (var interval in intervals) {
        variance += pow(interval - avgInterval, 2);
      }
      variance /= intervals.length;
      regularity = max(0, 100 - (sqrt(variance) * 100));
    }
    
    return {
      'tempo': tempo,
      'pulseTimes': pulseTimes,
      'regularity': regularity,
      'isPulsed': isPulsed,
    };
  }

  /// Assess overall call quality
  static Map<String, double> _assessQuality(Float64List samples, int sampleRate) {
    // Simple quality metrics
    double clipCount = 0.0;
    double totalEnergy = 0.0;
    
    for (var sample in samples) {
      if (sample.abs() > 0.95) clipCount++;
      totalEnergy += sample * sample;
    }
    
    final double clippingScore = max(0, 100 - (clipCount / samples.length * 1000));
    final double energyScore = min(100, sqrt(totalEnergy / samples.length) * 100);
    
    final double quality = (clippingScore + energyScore) / 2;
    final double noise = 100 - quality; // Simplified
    
    return {
      'score': quality,
      'noise': noise,
    };
  }

  static double _hanningWindow(int n, int N) {
    return 0.5 * (1 - cos(2 * pi * n / (N - 1)));
  }

  /// Extract Mel-Frequency Cepstral Coefficients (MFCC) for timbre comparison.
  /// Returns averaged MFCC vector across all frames.
  static List<double> _extractMFCCs(Float64List samples, int sampleRate, {int numCoeffs = 13, int numFilters = 26}) {
    const frameLen = 0.025; // 25ms frames
    const frameHop = 0.010; // 10ms hop
    final frameSamples = (sampleRate * frameLen).toInt();
    final hopSamples = (sampleRate * frameHop).toInt();
    // Round up to next power-of-2 for FFT
    int fftSize = 1;
    while (fftSize < frameSamples) { fftSize <<= 1; }

    final int numFrames = (samples.length - frameSamples) ~/ hopSamples + 1;
    if (numFrames <= 0) return List.filled(numCoeffs, 0.0);

    // Pre-compute Mel filter bank
    double hzToMel(double hz) => 2595.0 * log(1.0 + hz / 700.0) / ln10;
    double melToHz(double mel) => 700.0 * (pow(10.0, mel / 2595.0) - 1.0);

    final double lowMel = hzToMel(80.0);
    final double highMel = hzToMel(sampleRate / 2.0);
    final List<double> melPoints = List.generate(
      numFilters + 2,
      (i) => melToHz(lowMel + (highMel - lowMel) * i / (numFilters + 1)),
    );
    final List<int> binPoints = melPoints
      .map((hz) => ((hz / sampleRate) * fftSize).floor().clamp(0, fftSize ~/ 2))
      .toList();

    // Accumulate MFCCs across frames
    final List<double> mfccSum = List.filled(numCoeffs, 0.0);
    final fft = FFT(fftSize);

    for (int f = 0; f < numFrames; f++) {
      final offset = f * hopSamples;
      final windowed = Float64List(fftSize);
      for (int j = 0; j < frameSamples && (offset + j) < samples.length; j++) {
        windowed[j] = samples[offset + j] * _hanningWindow(j, frameSamples);
      }

      final freq = fft.realFft(windowed);
      final magnitudes = freq.magnitudes();

      // Apply Mel filter banks
      final List<double> filterEnergies = List.filled(numFilters, 0.0);
      for (int m = 0; m < numFilters; m++) {
        final int startBin = binPoints[m];
        final int centerBin = binPoints[m + 1];
        final int endBin = binPoints[m + 2];

        for (int k = startBin; k < centerBin && k < magnitudes.length; k++) {
          final weight = (centerBin > startBin) ? (k - startBin) / (centerBin - startBin) : 0.0;
          filterEnergies[m] += magnitudes[k] * weight;
        }
        for (int k = centerBin; k < endBin && k < magnitudes.length; k++) {
          final weight = (endBin > centerBin) ? (endBin - k) / (endBin - centerBin) : 0.0;
          filterEnergies[m] += magnitudes[k] * weight;
        }
      }

      // Log energies (with floor to avoid log(0))
      for (int m = 0; m < numFilters; m++) {
        filterEnergies[m] = log(max(filterEnergies[m], 1e-10));
      }

      // DCT Type-II to get cepstral coefficients
      for (int c = 0; c < numCoeffs; c++) {
        double sum = 0.0;
        for (int m = 0; m < numFilters; m++) {
          sum += filterEnergies[m] * cos(pi * c * (m + 0.5) / numFilters);
        }
        mfccSum[c] += sum;
      }
    }

    // Average across frames
    for (int c = 0; c < numCoeffs; c++) {
      mfccSum[c] /= numFrames;
    }
    return mfccSum;
  }

  /// Extract a downsampled waveform for visualization
  /// Uses RMS amplitude (not peak) for better dynamic range representation,
  /// then applies a sqrt curve so quiet sections are more visible.
  static List<double> _extractWaveform(Float64List samples, int points) {
    if (samples.isEmpty) return List.filled(points, 0.0);
    
    final result = List<double>.filled(points, 0.0);
    final chunkSize = samples.length ~/ points;
    
    if (chunkSize < 1) {
      for (int i = 0; i < samples.length; i++) {
        result[i] = samples[i].abs();
      }
      return result;
    }
    
    for (int i = 0; i < points; i++) {
      double sumSquares = 0.0;
      final start = i * chunkSize;
      final end = min(start + chunkSize, samples.length);
      int count = 0;
      
      for (int j = start; j < end; j++) {
        sumSquares += samples[j] * samples[j];
        count++;
      }
      result[i] = count > 0 ? sqrt(sumSquares / count) : 0.0;
    }
    
    // Contrast-stretch to 0-1: maps the actual min-max RMS range to the full
    // visual range. This is critical for mastered reference audio where RMS
    // values cluster in a narrow band (e.g. 0.85-1.0) — without stretching,
    // all bars look the same height regardless of the call's rhythmic pattern.
    final double maxVal = result.reduce(max);
    final double minVal = result.reduce(min);
    final double range = maxVal - minVal;
    
    if (range > 0) {
      for (int i = 0; i < points; i++) {
        // Stretch to 0-1
        result[i] = (result[i] - minVal) / range;
        // Gentle power curve for visual polish (quieter parts slightly smaller)
        result[i] = pow(result[i], 1.3).toDouble();
      }
    } else if (maxVal > 0) {
      // All chunks identical — flat signal, just normalize
      for (int i = 0; i < points; i++) {
        result[i] = result[i] / maxVal;
      }
    }
    
    return result;
  }

  /// Get waveform with caching
  Future<List<double>> getWaveformFromSamples(Float64List samples, int points, String path) async {
    // Try to get from cache first
    final cached = await _cache.getCachedWaveform(path);
    if (cached != null && cached.length == points) {
      return cached;
    }

    // Extract and cache
    final waveform = _extractWaveform(samples, points);
    await _cache.cacheWaveform(path, waveform);
    return waveform;
  }
}
