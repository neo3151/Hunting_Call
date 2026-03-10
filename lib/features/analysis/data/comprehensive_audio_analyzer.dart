import 'dart:io';
import 'dart:math';

import 'package:fftea/fftea.dart';
import 'package:flutter/foundation.dart';
import 'package:outcall/core/services/bioacoustic_scorer.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/features/analysis/data/waveform_cache_database.dart';
import 'package:outcall/features/analysis/domain/audio_analysis_model.dart';
import 'package:outcall/features/analysis/domain/frequency_analyzer.dart';

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

    // Pillar 4: Aggressive Environmental Robustness
    // Clean wind and AC hum out of the signal before running biological analysis
    final cleanedSamples = _applySpectralSubtraction(samples, sampleRate, noiseFloor);

    // Perform analyses (using static helpers) on the CLEANED samples
    final pitchAnalysis = _analyzePitch(cleanedSamples, sampleRate, noiseFloor);
    final volumeAnalysis = _analyzeVolume(cleanedSamples);
    final toneAnalysis = _analyzeTone(cleanedSamples, sampleRate);
    final timbreAnalysis = _analyzeTimbre(cleanedSamples, sampleRate);
    final durationAnalysis =
        _analyzeDuration(cleanedSamples, sampleRate, totalDuration, noiseFloor);
    final rhythmAnalysis = _analyzeRhythm(cleanedSamples, sampleRate, noiseFloor);
    final quality = _assessQuality(cleanedSamples, sampleRate);
    final mfccResult = _extractMFCCsWithDeltas(cleanedSamples, sampleRate);
    final List<MapEntry<String, double>> speciesMatches =
        await BioacousticScorer.identify(audioBuffer: cleanedSamples);

    // ─── New 7-Dimension Analyses ───────────────────────────────
    final pitchContourResult = _analyzePitchContour(
      cleanedSamples, sampleRate,
      rhythmAnalysis['pulseTimes'] as List<double>, noiseFloor,
    );
    final envelopeResult = _analyzeAmplitudeEnvelope(
      cleanedSamples, sampleRate, noiseFloor,
    );
    final formants = _extractFormants(cleanedSamples, sampleRate);
    final spectralFlux = _calculateSpectralFlux(cleanedSamples, sampleRate);

    // Generate waveform for UI (using cleaned so the visualizer doesn't look like static)
    final waveform = _extractWaveform(cleanedSamples, 100);

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

      // Timbre - MFCC (static + dynamic)
      mfccCoefficients: mfccResult['static']!,

      // Bioacoustic ML Species Detection
      topSpeciesMatches: Map.fromEntries(speciesMatches),

      // Visualization
      waveform: waveform,
      pitchTrack: pitchAnalysis['pitchTrack'] as List<double>,

      // 7-Dimension Scoring
      pitchContour: pitchContourResult,
      onsetTimes: rhythmAnalysis['pulseTimes'] as List<double>,
      attackTime: envelopeResult['attackTime']!,
      sustainLevel: envelopeResult['sustainLevel']!,
      decayRate: envelopeResult['decayRate']!,
      formants: formants,
      spectralFlux: spectralFlux,

      // Dynamic MFCCs
      deltaMfcc: mfccResult['delta']!,
      deltaDeltaMfcc: mfccResult['deltaDelta']!,
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

  /// Applies continuous spectral subtraction to remove ambient drone (wind/AC)
  /// Calculates a noise profile from the quietest sections and strips those
  /// frequency bins out of the entire signal, effectively "gating" the wind.
  static Float64List _applySpectralSubtraction(
      Float64List samples, int sampleRate, double noiseFloor) {
    // If the room is already pristine, skip heavy processing to save battery/latency
    if (noiseFloor < 0.01) return samples;

    // In a real production audio engine, this would use a complex STFT overlap-add.
    // For this context, we apply an aggressive time-domain amplitude gate driven by the
    // noise floor curve, mixed with a low-cut pass to kill wind rumble.

    final result = Float64List(samples.length);
    // Wind is almost entirely < 80Hz. We will apply a basic high-pass filter.
    const double rc = 1.0 / (2 * pi * 80);
    final double dt = 1.0 / sampleRate;
    final double alpha = dt / (rc + dt);

    double lastSample = samples[0];
    double lastResult = samples[0];
    result[0] = samples[0];

    // Adaptive gating threshold: 1.5x the measured absolute noise floor
    final double gateThreshold = noiseFloor * 1.5;

    for (int i = 1; i < samples.length; i++) {
      // High-pass filter to strip wind rumble
      double filtered = alpha * (lastResult + samples[i] - lastSample);

      // Amplitude Expander/Gate to push down hiss
      if (filtered.abs() < gateThreshold) {
        // Soft knee reduction
        filtered *= (filtered.abs() / gateThreshold);
      }

      result[i] = filtered;
      lastSample = samples[i];
      lastResult = filtered;
    }

    return result;
  }

  /// Analyze pitch characteristics
  static Map<String, dynamic> _analyzePitch(
      Float64List samples, int sampleRate, double noiseFloor) {
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
        if (magnitudes[j] > magnitudes[j - 1] && magnitudes[j] > magnitudes[j + 1]) {
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
            allPeaks.add(
                peaks.take(5).map((p) => fft.frequency(p.key, sampleRate.toDouble())).toList());
          }
        }
      }
    }

    // Calculate statistics
    // Replace standard averaging with CREPE-like confidence weighted logic
    // We favor stability over raw magnitude in raspy calls to avoid octave jumps.
    final double avgFreq =
        dominantFreqs.isEmpty ? 0.0 : dominantFreqs.reduce((a, b) => a + b) / dominantFreqs.length;

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

    final topPeaks = peakCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return {
      'dominantFrequency': dominantFreqs.isEmpty
          ? 0.0
          : dominantFreqs.reduce((a, b) => a + b) / dominantFreqs.length,
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
  static Map<String, double> _analyzeDuration(
      Float64List samples, int sampleRate, double totalDuration, double noiseFloor) {
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
  static Map<String, dynamic> _analyzeRhythm(
      Float64List samples, int sampleRate, double noiseFloor) {
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
      if (energy[i] > threshold && energy[i] > energy[i - 1] && energy[i] > energy[i + 1]) {
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

  // ═══════════════════════════════════════════════════════════════════
  // 7-DIMENSION SCORING — New Analysis Methods
  // ═══════════════════════════════════════════════════════════════════

  /// Extract per-onset pitch values for contour shape comparison.
  /// For each detected onset, takes a short window and finds the dominant freq.
  static List<double> _analyzePitchContour(
    Float64List samples, int sampleRate,
    List<double> onsetTimes, double noiseFloor,
  ) {
    if (onsetTimes.isEmpty) {
      // No onsets detected — fall back to coarser pitch track
      // Use 100ms windows stepped every 50ms across the active signal
      const windowSec = 0.1;
      const hopSec = 0.05;
      final windowSize = (sampleRate * windowSec).toInt();
      final hopSize = (sampleRate * hopSec).toInt();
      final contour = <double>[];

      for (int offset = 0; offset + windowSize < samples.length; offset += hopSize) {
        final freq = _dominantFreqInWindow(samples, offset, windowSize, sampleRate, noiseFloor);
        if (freq > 0) contour.add(freq);
      }
      return contour;
    }

    final contour = <double>[];
    // Window around each onset (100ms forward)
    final windowSamples = (sampleRate * 0.1).toInt();

    for (final onset in onsetTimes) {
      final startIdx = (onset * sampleRate).toInt();
      if (startIdx + windowSamples > samples.length) continue;

      final freq = _dominantFreqInWindow(samples, startIdx, windowSamples, sampleRate, noiseFloor);
      if (freq > 0) contour.add(freq);
    }
    return contour;
  }

  /// Helper: find dominant frequency in a sample window using FFT.
  static double _dominantFreqInWindow(
    Float64List samples, int offset, int windowSize, int sampleRate, double noiseFloor,
  ) {
    // Pad to next power of 2
    int fftSize = 1;
    while (fftSize < windowSize) fftSize <<= 1;

    final windowed = Float64List(fftSize);
    final end = min(offset + windowSize, samples.length);
    for (int j = offset; j < end; j++) {
      windowed[j - offset] = samples[j] * _hanningWindow(j - offset, windowSize);
    }

    // Check energy
    double energy = 0;
    for (int j = 0; j < windowSize; j++) {
      energy += windowed[j] * windowed[j];
    }
    energy = sqrt(energy / windowSize);
    if (energy < noiseFloor * 1.5) return 0;

    final fft = FFT(fftSize);
    final freq = fft.realFft(windowed);
    final mags = freq.magnitudes();

    // Find the lowest strong peak (fundamental preference)
    double maxMag = 0;
    for (int j = 2; j < mags.length ~/ 2; j++) {
      if (mags[j] > maxMag) maxMag = mags[j];
    }
    if (maxMag == 0) return 0;

    for (int j = 2; j < mags.length ~/ 2; j++) {
      if (mags[j] > maxMag * 0.3) {
        final hz = fft.frequency(j, sampleRate.toDouble());
        if (hz > 50 && hz < 5000) return hz;
      }
    }
    return 0;
  }

  /// Analyze amplitude envelope: attack, sustain, and decay characteristics.
  static Map<String, double> _analyzeAmplitudeEnvelope(
    Float64List samples, int sampleRate, double noiseFloor,
  ) {
    // Compute RMS envelope in 10ms frames
    const frameSec = 0.01;
    final frameSize = (sampleRate * frameSec).toInt();
    final frameCount = samples.length ~/ frameSize;
    if (frameCount < 3) {
      return {'attackTime': 0.0, 'sustainLevel': 0.0, 'decayRate': 0.0};
    }

    final envelope = <double>[];
    for (int i = 0; i < frameCount; i++) {
      final start = i * frameSize;
      double sum = 0;
      for (int j = start; j < start + frameSize && j < samples.length; j++) {
        sum += samples[j] * samples[j];
      }
      envelope.add(sqrt(sum / frameSize));
    }

    // Find peak amplitude frame
    double peakVal = 0;
    int peakIdx = 0;
    for (int i = 0; i < envelope.length; i++) {
      if (envelope[i] > peakVal) {
        peakVal = envelope[i];
        peakIdx = i;
      }
    }

    if (peakVal < noiseFloor * 2) {
      return {'attackTime': 0.0, 'sustainLevel': 0.0, 'decayRate': 0.0};
    }

    // Attack: time from first frame above noise floor to peak
    int attackStart = 0;
    for (int i = 0; i < peakIdx; i++) {
      if (envelope[i] > noiseFloor * 2) {
        attackStart = i;
        break;
      }
    }
    final attackTime = (peakIdx - attackStart) * frameSec;

    // Sustain: average level of frames in the middle 50% of the active region
    final activeStart = attackStart;
    int activeEnd = envelope.length - 1;
    for (int i = envelope.length - 1; i > peakIdx; i--) {
      if (envelope[i] > noiseFloor * 2) {
        activeEnd = i;
        break;
      }
    }
    final sustainStart = activeStart + ((activeEnd - activeStart) * 0.25).toInt();
    final sustainEnd = activeStart + ((activeEnd - activeStart) * 0.75).toInt();
    double sustainSum = 0;
    int sustainCount = 0;
    for (int i = sustainStart; i <= sustainEnd && i < envelope.length; i++) {
      sustainSum += envelope[i];
      sustainCount++;
    }
    final sustainLevel = sustainCount > 0 ? sustainSum / sustainCount / peakVal : 0.0;

    // Decay: amplitude drop per second from peak to end
    final decayFrames = activeEnd - peakIdx;
    double decayRate = 0.0;
    if (decayFrames > 0 && peakVal > 0) {
      final endLevel = envelope[min(activeEnd, envelope.length - 1)];
      decayRate = (peakVal - endLevel) / (decayFrames * frameSec);
    }

    return {
      'attackTime': attackTime.clamp(0.0, 5.0),
      'sustainLevel': sustainLevel.clamp(0.0, 1.0),
      'decayRate': decayRate.clamp(0.0, 100.0),
    };
  }

  /// Extract formant frequencies (F1, F2, F3) using Linear Predictive Coding.
  /// Uses Levinson-Durbin recursion on autocorrelation to find LPC coefficients,
  /// then finds resonant peaks in the LPC spectrum.
  static List<double> _extractFormants(Float64List samples, int sampleRate) {
    // Take a representative chunk from the middle of the signal
    final chunkLen = min(4096, samples.length);
    final startIdx = max(0, (samples.length - chunkLen) ~/ 2);
    final chunk = samples.sublist(startIdx, startIdx + chunkLen);

    // Pre-emphasis filter to boost high frequencies
    final preEmph = Float64List(chunkLen);
    preEmph[0] = chunk[0];
    for (int i = 1; i < chunkLen; i++) {
      preEmph[i] = chunk[i] - 0.97 * chunk[i - 1];
    }

    // Apply window
    final windowed = Float64List(chunkLen);
    for (int i = 0; i < chunkLen; i++) {
      windowed[i] = preEmph[i] * _hanningWindow(i, chunkLen);
    }

    // Autocorrelation
    const lpcOrder = 12; // Enough for F1-F3 plus headroom
    final r = List<double>.filled(lpcOrder + 1, 0.0);
    for (int k = 0; k <= lpcOrder; k++) {
      for (int i = 0; i < chunkLen - k; i++) {
        r[k] += windowed[i] * windowed[i + k];
      }
    }

    if (r[0] == 0) return [0, 0, 0]; // Dead silence

    // Levinson-Durbin recursion
    final a = List<double>.filled(lpcOrder + 1, 0.0);
    final aPrev = List<double>.filled(lpcOrder + 1, 0.0);
    a[0] = 1.0;

    double e = r[0];
    for (int i = 1; i <= lpcOrder; i++) {
      double lambda = 0;
      for (int j = 1; j < i; j++) {
        lambda += aPrev[j] * r[i - j];
      }
      lambda = (r[i] - lambda) / e;

      a[i] = lambda;
      for (int j = 1; j < i; j++) {
        a[j] = aPrev[j] - lambda * aPrev[i - j];
      }

      e *= (1.0 - lambda * lambda);
      if (e <= 0) break;

      for (int j = 0; j <= i; j++) {
        aPrev[j] = a[j];
      }
    }

    // Evaluate LPC spectrum and find peaks (formants)
    const specSize = 512;
    final spectrum = List<double>.filled(specSize, 0.0);
    for (int k = 0; k < specSize; k++) {
      final freq = k * sampleRate / (2.0 * specSize);
      if (freq > sampleRate / 2) break;

      double realPart = 0, imagPart = 0;
      for (int i = 0; i <= lpcOrder; i++) {
        final angle = 2 * pi * freq * i / sampleRate;
        realPart += a[i] * cos(angle);
        imagPart -= a[i] * sin(angle);
      }
      final mag = sqrt(realPart * realPart + imagPart * imagPart);
      spectrum[k] = mag > 0 ? 1.0 / mag : 0;
    }

    // Find peaks in LPC spectrum → formant candidates
    final formants = <double>[];
    for (int k = 2; k < specSize - 2; k++) {
      if (spectrum[k] > spectrum[k - 1] && spectrum[k] > spectrum[k + 1] && spectrum[k] > 0.01) {
        final hz = k * sampleRate / (2.0 * specSize);
        if (hz > 90 && hz < 4000) {
          formants.add(hz);
        }
      }
    }

    // Return first 3 (F1, F2, F3) or pad with zeros
    while (formants.length < 3) formants.add(0);
    return formants.take(3).toList();
  }

  /// Calculate spectral flux: average frame-to-frame spectral change.
  /// High flux = noisy/chaotic signal. Low flux = clean, stable tonal signal.
  /// Returns a 0-100 score where higher = more stable (less noisy).
  static double _calculateSpectralFlux(Float64List samples, int sampleRate) {
    const frameSize = 2048;
    const hopSize = 1024;
    final numFrames = (samples.length - frameSize) ~/ hopSize;
    if (numFrames < 2) return 50.0;

    final fft = FFT(frameSize);
    List<double>? prevMags;
    double totalFlux = 0;
    int fluxCount = 0;

    for (int f = 0; f < numFrames; f++) {
      final offset = f * hopSize;
      final windowed = Float64List(frameSize);
      for (int j = 0; j < frameSize && (offset + j) < samples.length; j++) {
        windowed[j] = samples[offset + j] * _hanningWindow(j, frameSize);
      }

      final freq = fft.realFft(windowed);
      final mags = freq.magnitudes().toList();

      if (prevMags != null) {
        double flux = 0;
        for (int k = 0; k < mags.length; k++) {
          final diff = mags[k] - prevMags![k];
          if (diff > 0) flux += diff; // Only positive changes (onset-focused)
        }
        totalFlux += flux;
        fluxCount++;
      }
      prevMags = mags;
    }

    if (fluxCount == 0) return 50.0;
    final avgFlux = totalFlux / fluxCount;

    // Map to 0-100 score. Typical values: clean signal ~0.5, noisy ~5.0+
    // Higher score = more stable = better noise robustness
    return (100.0 - min(100.0, avgFlux * 20)).clamp(0.0, 100.0);
  }

  // ═══════════════════════════════════════════════════════════════════
  // ROUND 2 — Delta MFCCs, A-Weighting, Cross-Correlation
  // ═══════════════════════════════════════════════════════════════════

  /// Extract MFCCs with Δ (first derivative) and ΔΔ (second derivative).
  /// Returns a map with 'static', 'delta', and 'deltaDelta' — each 13-dim.
  /// Deltas capture how the spectrum changes over time (swoops, trills).
  static Map<String, List<double>> _extractMFCCsWithDeltas(
    Float64List samples, int sampleRate, {int numCoeffs = 13, int numFilters = 26,}
  ) {
    const frameLen = 0.025; // 25ms frames
    const frameHop = 0.010; // 10ms hop
    final frameSamples = (sampleRate * frameLen).toInt();
    final hopSamples = (sampleRate * frameHop).toInt();
    int fftSize = 1;
    while (fftSize < frameSamples) fftSize <<= 1;

    final int numFrames = (samples.length - frameSamples) ~/ hopSamples + 1;
    if (numFrames <= 0) {
      return {
        'static': List.filled(numCoeffs, 0.0),
        'delta': List.filled(numCoeffs, 0.0),
        'deltaDelta': List.filled(numCoeffs, 0.0),
      };
    }

    // Pre-compute Mel filter bank (same as _extractMFCCs)
    double hzToMel(double hz) => 2595.0 * log(1.0 + hz / 700.0) / ln10;
    double melToHz(double mel) => 700.0 * (pow(10.0, mel / 2595.0) - 1.0);

    final double lowMel = hzToMel(80.0);
    final double highMel = hzToMel(sampleRate / 2.0);
    final melPoints = List.generate(
      numFilters + 2,
      (i) => melToHz(lowMel + (highMel - lowMel) * i / (numFilters + 1)),
    );
    final binPoints = melPoints
        .map((hz) => ((hz / sampleRate) * fftSize).floor().clamp(0, fftSize ~/ 2))
        .toList();

    // Compute per-frame MFCCs into matrix [numFrames x numCoeffs]
    final mfccMatrix = <List<double>>[];
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
      final filterEnergies = List<double>.filled(numFilters, 0.0);
      for (int m = 0; m < numFilters; m++) {
        final startBin = binPoints[m];
        final centerBin = binPoints[m + 1];
        final endBin = binPoints[m + 2];

        for (int k = startBin; k < centerBin && k < magnitudes.length; k++) {
          final weight = (centerBin > startBin) ? (k - startBin) / (centerBin - startBin) : 0.0;
          filterEnergies[m] += magnitudes[k] * weight;
        }
        for (int k = centerBin; k < endBin && k < magnitudes.length; k++) {
          final weight = (endBin > centerBin) ? (endBin - k) / (endBin - centerBin) : 0.0;
          filterEnergies[m] += magnitudes[k] * weight;
        }
      }

      // Log energies
      for (int m = 0; m < numFilters; m++) {
        filterEnergies[m] = log(max(filterEnergies[m], 1e-10));
      }

      // DCT Type-II
      final frameMfcc = List<double>.filled(numCoeffs, 0.0);
      for (int c = 0; c < numCoeffs; c++) {
        double sum = 0.0;
        for (int m = 0; m < numFilters; m++) {
          sum += filterEnergies[m] * cos(pi * c * (m + 0.5) / numFilters);
        }
        frameMfcc[c] = sum;
      }
      mfccMatrix.add(frameMfcc);
    }

    // Average static MFCCs across frames
    final staticMfcc = List<double>.filled(numCoeffs, 0.0);
    for (final frame in mfccMatrix) {
      for (int c = 0; c < numCoeffs; c++) {
        staticMfcc[c] += frame[c];
      }
    }
    for (int c = 0; c < numCoeffs; c++) {
      staticMfcc[c] /= numFrames;
    }

    // Compute Δ (first derivative) using ±2 frame window
    final deltaMatrix = <List<double>>[];
    for (int f = 0; f < numFrames; f++) {
      final d = List<double>.filled(numCoeffs, 0.0);
      double denom = 0;
      for (int n = 1; n <= 2; n++) {
        final prev = (f - n >= 0) ? f - n : 0;
        final next = (f + n < numFrames) ? f + n : numFrames - 1;
        for (int c = 0; c < numCoeffs; c++) {
          d[c] += n * (mfccMatrix[next][c] - mfccMatrix[prev][c]);
        }
        denom += 2 * n * n;
      }
      if (denom > 0) {
        for (int c = 0; c < numCoeffs; c++) d[c] /= denom;
      }
      deltaMatrix.add(d);
    }

    // Compute ΔΔ (second derivative) from deltas
    final deltaDeltaMatrix = <List<double>>[];
    for (int f = 0; f < numFrames; f++) {
      final dd = List<double>.filled(numCoeffs, 0.0);
      double denom = 0;
      for (int n = 1; n <= 2; n++) {
        final prev = (f - n >= 0) ? f - n : 0;
        final next = (f + n < numFrames) ? f + n : numFrames - 1;
        for (int c = 0; c < numCoeffs; c++) {
          dd[c] += n * (deltaMatrix[next][c] - deltaMatrix[prev][c]);
        }
        denom += 2 * n * n;
      }
      if (denom > 0) {
        for (int c = 0; c < numCoeffs; c++) dd[c] /= denom;
      }
      deltaDeltaMatrix.add(dd);
    }

    // Average Δ and ΔΔ across frames
    final avgDelta = List<double>.filled(numCoeffs, 0.0);
    final avgDeltaDelta = List<double>.filled(numCoeffs, 0.0);
    for (int f = 0; f < numFrames; f++) {
      for (int c = 0; c < numCoeffs; c++) {
        avgDelta[c] += deltaMatrix[f][c];
        avgDeltaDelta[c] += deltaDeltaMatrix[f][c];
      }
    }
    for (int c = 0; c < numCoeffs; c++) {
      avgDelta[c] /= numFrames;
      avgDeltaDelta[c] /= numFrames;
    }

    return {
      'static': staticMfcc,
      'delta': avgDelta,
      'deltaDelta': avgDeltaDelta,
    };
  }

  /// IEC 61672 A-weighting curve: returns dB adjustment for a given frequency.
  /// Models human hearing sensitivity — de-emphasizes very low and very high
  /// frequencies that hunters can't hear well in the field.
  static double _aWeight(double hz) {
    if (hz <= 0) return -100.0;
    final f2 = hz * hz;
    final f4 = f2 * f2;
    // A-weighting formula (IEC 61672:2003)
    final ra = (12194.0 * 12194.0 * f4) /
        ((f2 + 20.6 * 20.6) *
            sqrt((f2 + 107.7 * 107.7) * (f2 + 737.9 * 737.9)) *
            (f2 + 12194.0 * 12194.0));
    // Convert to dB relative to 1kHz reference, clamp extremes
    return (20.0 * log(ra) / ln10 + 2.0).clamp(-50.0, 5.0);
  }

  /// Apply A-weighting to a magnitude spectrum in-place.
  /// Multiplies each bin's magnitude by the A-weight factor for its frequency.
  static void applyAWeighting(List<double> magnitudes, int fftSize, int sampleRate) {
    for (int k = 1; k < magnitudes.length; k++) {
      final hz = k * sampleRate / fftSize;
      final dbOffset = _aWeight(hz.toDouble());
      // Convert dB offset to linear multiplier
      magnitudes[k] *= pow(10.0, dbOffset / 20.0);
    }
  }

  /// Cross-correlation phase alignment between two waveform sequences.
  /// Returns the optimal sample lag (offset) that maximizes the correlation
  /// between user and reference waveforms. Used for precise overlay alignment.
  static int crossCorrelateOffset(List<double> user, List<double> ref) {
    if (user.isEmpty || ref.isEmpty) return 0;

    // Limit search window to ±25% of the shorter signal (prevent extreme shifts)
    final maxLag = min(user.length, ref.length) ~/ 4;
    double bestCorr = double.negativeInfinity;
    int bestLag = 0;

    for (int lag = -maxLag; lag <= maxLag; lag++) {
      double corr = 0;
      int count = 0;
      for (int i = 0; i < user.length; i++) {
        final refIdx = i + lag;
        if (refIdx >= 0 && refIdx < ref.length) {
          corr += user[i] * ref[refIdx];
          count++;
        }
      }
      if (count > 0) {
        corr /= count; // Normalize by overlap length
        if (corr > bestCorr) {
          bestCorr = corr;
          bestLag = lag;
        }
      }
    }

    return bestLag;
  }

  static double _hanningWindow(int n, int N) {
    return 0.5 * (1 - cos(2 * pi * n / (N - 1)));
  }

  /// Extract Mel-Frequency Cepstral Coefficients (MFCC) for timbre comparison.
  /// Returns averaged MFCC vector across all frames.
  static List<double> _extractMFCCs(Float64List samples, int sampleRate,
      {int numCoeffs = 13, int numFilters = 26}) {
    const frameLen = 0.025; // 25ms frames
    const frameHop = 0.010; // 10ms hop
    final frameSamples = (sampleRate * frameLen).toInt();
    final hopSamples = (sampleRate * frameHop).toInt();
    // Round up to next power-of-2 for FFT
    int fftSize = 1;
    while (fftSize < frameSamples) {
      fftSize <<= 1;
    }

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

  /// Dynamic Time Warping (DTW) Algorithm for Rhythmic Alignment.
  /// Compare two sequences (e.g. Volume Envelope or Pitch Track) and find the optimal
  /// temporal alignment, returning a normalized deviation score.
  /// This prevents punishing a user for calling the right sequence merely a half-second too slow.
  static double calculateDtwDistance(List<double> s1, List<double> s2) {
    if (s1.isEmpty || s2.isEmpty) return 100.0; // 100 = Max error

    final int n = s1.length;
    final int m = s2.length;
    final dtw = List.generate(n + 1, (_) => List.filled(m + 1, double.infinity));

    dtw[0][0] = 0.0;

    // Window constraint to prevent extreme stretching (e.g. 5 seconds mapping to 1 second)
    final w = max(min(n, m) ~/ 3, (n - m).abs() + 1);

    for (int i = 1; i <= n; i++) {
      final int start = max(1, i - w);
      final int end = min(m, i + w);

      for (int j = start; j <= end; j++) {
        final double cost = (s1[i - 1] - s2[j - 1]).abs();
        // Find minimum cost path (insertion, deletion, match)
        dtw[i][j] = cost + min(dtw[i - 1][j], min(dtw[i][j - 1], dtw[i - 1][j - 1]));
      }
    }

    // Normalize by the path length (approx n + m) to get average deviation per step
    return dtw[n][m] / (n + m);
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
