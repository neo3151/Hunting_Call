import 'dart:io';
import 'dart:math';
import 'package:fftea/fftea.dart';
import 'package:flutter/foundation.dart';
import '../domain/frequency_analyzer.dart';
import '../domain/audio_analysis_model.dart';
import 'waveform_cache_database.dart';

class ComprehensiveAudioAnalyzer implements FrequencyAnalyzer {
  final _cache = WaveformCacheDatabase();
  
  ComprehensiveAudioAnalyzer() {
    // Auto-cleanup old cache entries on initialization
    _cache.clearOldCache(maxAge: const Duration(days: 7)).then((deleted) {
      if (deleted > 0) {
        debugPrint('WaveformCache: Cleaned up $deleted old entries');
      }
    });
  }

  @override
  Future<double> getDominantFrequency(String audioPath) async {
    final analysis = await analyzeAudio(audioPath);
    return analysis.dominantFrequencyHz;
  }

  /// Performs comprehensive audio analysis
  Future<AudioAnalysis> analyzeAudio(String audioPath) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        debugPrint("Analysis Error: File $audioPath not found");
        return AudioAnalysis.simple(frequencyHz: 0.0, durationSec: 0.0);
      }

      // Read WAV file
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
        int sample = view.getInt16(44 + (i * 2), Endian.little);
        samples[i] = sample / 32768.0;
      }

      // Perform analyses
      final pitchAnalysis = _analyzePitch(samples, sampleRate);
      final volumeAnalysis = _analyzeVolume(samples);
      final toneAnalysis = _analyzeTone(samples, sampleRate);
      final timbreAnalysis = _analyzeTimbre(samples, sampleRate);
      final durationAnalysis = _analyzeDuration(samples, sampleRate, totalDuration);
      final rhythmAnalysis = _analyzeRhythm(samples, sampleRate);
      final quality = _assessQuality(samples, sampleRate);

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
        
        // Visualization
        waveform: await getWaveformFromSamples(samples, 100, audioPath),
        pitchTrack: pitchAnalysis['pitchTrack'] as List<double>,
      );
    } catch (e, stack) {
      debugPrint("Comprehensive Analysis Error: $e\n$stack");
      return AudioAnalysis.simple(frequencyHz: 0.0, durationSec: 0.0);
    }
  }

  /// Analyze pitch characteristics
  Map<String, dynamic> _analyzePitch(Float64List samples, int sampleRate) {
    const chunkSize = 4096;
    final chunks = samples.length ~/ chunkSize;
    
    List<double> dominantFreqs = [];
    List<List<double>> allPeaks = [];
    
    for (int i = 0; i < chunks; i++) {
      final start = i * chunkSize;
      final end = min(start + chunkSize, samples.length);
      final chunk = samples.sublist(start, end);
      
      if (chunk.length < chunkSize) continue;
      
      // Calculate chunk energy - skip if too quiet
      double energy = 0.0;
      for (var s in chunk) energy += s * s;
      energy = sqrt(energy / chunkSize);
      if (energy < 0.01) continue; // Skip near-silent chunks
      
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
      List<MapEntry<int, double>> peaks = [];
      double maxMag = 0.0;
      for (int j = 2; j < magnitudes.length ~/ 2 - 2; j++) {
        if (magnitudes[j] > magnitudes[j - 1] &&
            magnitudes[j] > magnitudes[j + 1]) {
          peaks.add(MapEntry(j, magnitudes[j]));
          if (magnitudes[j] > maxMag) maxMag = magnitudes[j];
        }
      }
      
      if (peaks.isNotEmpty) {
        // Preference for fundamental: 
        // If we find a peak that is at least 30% of maxMag but at a lower frequency, 
        // it might be the fundamental.
        peaks.sort((a, b) => a.key.compareTo(b.key)); // Sort by frequency
        
        int selectedIdx = -1;
        for (var peak in peaks) {
          if (peak.value > maxMag * 0.3) {
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
    double avgFreq = dominantFreqs.isEmpty ? 0.0 : 
      dominantFreqs.reduce((a, b) => a + b) / dominantFreqs.length;
    
    double stability = 100.0;
    if (dominantFreqs.length > 1) {
      double variance = 0.0;
      for (var f in dominantFreqs) {
        variance += pow(f - avgFreq, 2);
      }
      variance /= dominantFreqs.length;
      double stdDev = sqrt(variance);
      stability = max(0, 100 - (stdDev / avgFreq * 100));
    }
    
    // Get most common peaks
    Map<double, int> peakCounts = {};
    for (var peakList in allPeaks) {
      for (var peak in peakList) {
        double rounded = (peak / 10).round() * 10.0;
        peakCounts[rounded] = (peakCounts[rounded] ?? 0) + 1;
      }
    }
    
    var topPeaks = peakCounts.entries.toList()
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
  Map<String, double> _analyzeVolume(Float64List samples) {
    double sum = 0.0;
    double peak = 0.0;
    
    for (var sample in samples) {
      double abs = sample.abs();
      sum += abs * abs; // RMS
      if (abs > peak) peak = abs;
    }
    
    double rms = sqrt(sum / samples.length);
    
    // Calculate volume consistency
    List<double> chunkVolumes = [];
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
    
    double avgChunkVol = chunkVolumes.reduce((a, b) => a + b) / chunkVolumes.length;
    double variance = 0.0;
    for (var v in chunkVolumes) {
      variance += pow(v - avgChunkVol, 2);
    }
    variance /= chunkVolumes.length;
    double consistency = max(0, 100 - (sqrt(variance) * 1000));
    
    return {
      'average': rms,
      'peak': peak,
      'consistency': consistency,
    };
  }

  /// Analyze tone characteristics
  Map<String, dynamic> _analyzeTone(Float64List samples, int sampleRate) {
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
    
    double fundamentalFreq = fft.frequency(fundamentalIdx, sampleRate.toDouble());
    
    // Detect harmonics
    Map<String, double> harmonics = {};
    double harmonicEnergy = 0.0;
    for (int h = 2; h <= 6; h++) {
      int harmonicIdx = (fundamentalIdx * h);
      if (harmonicIdx < magnitudes.length) {
        double harmonicFreq = fft.frequency(harmonicIdx, sampleRate.toDouble());
        harmonics['H$h'] = harmonicFreq;
        harmonicEnergy += magnitudes[harmonicIdx];
      }
    }
    
    double harmonicRichness = min(100, (harmonicEnergy / maxMag) * 100);
    
    // Calculate tone clarity (SNR estimation)
    double signalEnergy = 0.0;
    double noiseEnergy = 0.0;
    for (int i = 1; i < magnitudes.length ~/ 2; i++) {
      double freq = fft.frequency(i, sampleRate.toDouble());
      if ((freq - fundamentalFreq).abs() < 50) {
        signalEnergy += magnitudes[i];
      } else {
        noiseEnergy += magnitudes[i];
      }
    }
    
    double snr = signalEnergy / max(noiseEnergy, 0.001);
    double clarity = min(100, snr * 10);
    
    return {
      'clarity': clarity,
      'harmonicRichness': harmonicRichness,
      'harmonics': harmonics,
    };
  }

  /// Analyze timbre characteristics
  Map<String, dynamic> _analyzeTimbre(Float64List samples, int sampleRate) {
    const chunkSize = 4096;
    final chunks = samples.length ~/ chunkSize;
    
    List<double> centroids = [];
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
        double frequency = fft.frequency(j, sampleRate.toDouble());
        weightedSum += frequency * magnitudes[j];
        magnitudeSum += magnitudes[j];
        
        // Energy by frequency bands
        if (frequency < 500) totalLowEnergy += magnitudes[j];
        else if (frequency < 2000) totalMidEnergy += magnitudes[j];
        else totalHighEnergy += magnitudes[j];
        
        // Nasal frequencies (typically 1000-2500 Hz)
        if (frequency >= 1000 && frequency <= 2500) nasalEnergy += magnitudes[j];
      }
      
      if (magnitudeSum > 0) {
        centroids.add(weightedSum / magnitudeSum);
      }
    }
    
    double totalEnergy = totalLowEnergy + totalMidEnergy + totalHighEnergy;
    double brightness = totalEnergy > 0 ? (totalHighEnergy / totalEnergy) * 100 : 50.0;
    double warmth = totalEnergy > 0 ? (totalLowEnergy / totalEnergy) * 100 : 50.0;
    double nasality = totalEnergy > 0 ? (nasalEnergy / totalEnergy) * 100 : 20.0;
    
    return {
      'brightness': brightness,
      'warmth': warmth,
      'nasality': nasality,
      'spectralCentroid': centroids,
    };
  }

  /// Analyze duration characteristics
  Map<String, double> _analyzeDuration(Float64List samples, int sampleRate, double totalDuration) {
    // Calculate energy threshold for silence detection
    double threshold = 0.0;
    for (var sample in samples) {
      threshold += sample.abs();
    }
    threshold = (threshold / samples.length) * 0.3; // 30% of average
    
    int activeCount = 0;
    for (var sample in samples) {
      if (sample.abs() > threshold) activeCount++;
    }
    
    double activeDuration = activeCount / sampleRate;
    double silenceDuration = totalDuration - activeDuration;
    
    return {
      'active': activeDuration,
      'silence': silenceDuration,
    };
  }

  /// Analyze rhythm characteristics
  Map<String, dynamic> _analyzeRhythm(Float64List samples, int sampleRate) {
    // Simple onset detection using energy spikes
    const windowSize = 2205; // ~0.05 sec
    List<double> energy = [];
    
    for (int i = 0; i < samples.length; i += windowSize) {
      double sum = 0.0;
      for (int j = i; j < min(i + windowSize, samples.length); j++) {
        sum += samples[j] * samples[j];
      }
      energy.add(sqrt(sum / windowSize));
    }
    
    // Find peaks (onsets)
    List<double> pulseTimes = [];
    double avgEnergy = energy.reduce((a, b) => a + b) / energy.length;
    double threshold = avgEnergy * 1.5;
    
    for (int i = 1; i < energy.length - 1; i++) {
      if (energy[i] > threshold &&
          energy[i] > energy[i - 1] &&
          energy[i] > energy[i + 1]) {
        pulseTimes.add((i * windowSize) / sampleRate);
      }
    }
    
    bool isPulsed = pulseTimes.length >= 3;
    double tempo = 0.0;
    double regularity = 0.0;
    
    if (pulseTimes.length >= 2) {
      // Calculate tempo
      List<double> intervals = [];
      for (int i = 1; i < pulseTimes.length; i++) {
        intervals.add(pulseTimes[i] - pulseTimes[i - 1]);
      }
      double avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
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
  Map<String, double> _assessQuality(Float64List samples, int sampleRate) {
    // Simple quality metrics
    double clipCount = 0.0;
    double totalEnergy = 0.0;
    
    for (var sample in samples) {
      if (sample.abs() > 0.95) clipCount++;
      totalEnergy += sample * sample;
    }
    
    double clippingScore = max(0, 100 - (clipCount / samples.length * 1000));
    double energyScore = min(100, sqrt(totalEnergy / samples.length) * 100);
    
    double quality = (clippingScore + energyScore) / 2;
    double noise = 100 - quality; // Simplified
    
    return {
      'score': quality,
      'noise': noise,
    };
  }

  double _hanningWindow(int n, int N) {
    return 0.5 * (1 - cos(2 * pi * n / (N - 1)));
  }

  /// Extract a downsampled waveform for visualization
  List<double> _extractWaveform(Float64List samples, int points) {
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
      double maxVal = 0.0;
      final start = i * chunkSize;
      final end = min(start + chunkSize, samples.length);
      
      for (int j = start; j < end; j++) {
        final abs = samples[j].abs();
        if (abs > maxVal) maxVal = abs;
      }
      result[i] = maxVal;
    }
    
    // Normalize to 0-1 range
    double peak = result.reduce(max);
    if (peak > 0) {
      for (int i = 0; i < points; i++) {
        result[i] /= peak;
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
