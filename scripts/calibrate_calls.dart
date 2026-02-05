import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:fftea/fftea.dart';

void main() async {
  final jsonFile = File('assets/data/reference_calls.json');
  if (!jsonFile.existsSync()) {
    print("Error: reference_calls.json not found.");
    return;
  }

  final data = json.decode(await jsonFile.readAsString());
  final List<dynamic> calls = data['calls'];
  
  print("--- CALL CALIBRATION TOOL ---");
  print("Analyzing real recordings in assets/audio/...");

  for (var call in calls) {
    final String id = call['id'];
    final String assetPath = call['audioAssetPath'];
    final File audioFile = File(assetPath);

    if (audioFile.existsSync()) {
      // Basic check: is it a real file (usually > 100KB) vs synthetic (usually < 20KB for 1s tone)
      // Actually, better to just analyze it and report.
      final stats = await audioFile.stat();
      if (stats.size < 100) continue; // Skip dummy files

      print("Calibrating $id...");
      final analysis = await analyzeWav(audioFile, id);
      
      if (analysis != null) {
        final double oldPitch = (call['idealPitchHz'] as num).toDouble();
        final double oldDuration = (call['idealDurationSec'] as num).toDouble();
        
        call['idealPitchHz'] = double.parse(analysis.frequency.toStringAsFixed(1));
        call['idealDurationSec'] = double.parse(analysis.duration.toStringAsFixed(2));
        
        print("  -> Updated Hz: $oldPitch -> ${call['idealPitchHz']}");
        print("  -> Updated Sec: $oldDuration -> ${call['idealDurationSec']}");
      }
    }
  }

  // Save updated JSON
  await jsonFile.writeAsString(JsonEncoder.withIndent('    ').convert(data));
  print("\nSuccess: Database calibrated to real-world audio files.");
}

class AnalysisResult {
  final double frequency;
  final double duration;
  AnalysisResult(this.frequency, this.duration);
}

Future<AnalysisResult?> analyzeWav(File file, String id) async {
  try {
    final bytes = await file.readAsBytes();
    if (bytes.length < 44) return null;

    final ByteData view = bytes.buffer.asByteData();
    final int sampleRate = view.getUint32(24, Endian.little);
    final int numChannels = view.getUint16(22, Endian.little);
    final int bitsPerSample = view.getUint16(34, Endian.little);
    final int bytesPerSample = bitsPerSample ~/ 8;
    
    final int numSamplesTotal = (bytes.length - 44) ~/ (numChannels * bytesPerSample);
    final double duration = numSamplesTotal / sampleRate;

    if (numSamplesTotal < 1024) return AnalysisResult(0, duration);

    // Identify the "most active" 8192-sample chunk by RMS energy
    const int chunkSize = 8192;
    int bestOffset = 44;
    double maxEnergy = -1.0;

    // Slide window through the file to find the peak vocalization
    // We step by chunkSize/2 for overlap
    for (int offset = 44; offset + (chunkSize * bytesPerSample * numChannels) <= bytes.length; offset += (chunkSize ~/ 2) * bytesPerSample * numChannels) {
      double currentEnergy = 0;
      for (int i = 0; i < chunkSize; i++) {
        final sample = view.getInt16(offset + (i * bytesPerSample * numChannels), Endian.little);
        final double normalized = sample / 32768.0;
        currentEnergy += normalized * normalized;
      }
      currentEnergy = currentEnergy / chunkSize;

      if (currentEnergy > maxEnergy) {
        maxEnergy = currentEnergy;
        bestOffset = offset;
      }
    }

    // Analyze the best chunk
    final signal = Float64List(chunkSize);
    for (var i = 0; i < chunkSize; i++) {
        final sample = view.getInt16(bestOffset + (i * bytesPerSample * numChannels), Endian.little);
        signal[i] = sample / 32768.0;
    }

    final fft = FFT(chunkSize);
    final windowed = Float64List(chunkSize);
    final window = Window.hanning(chunkSize);
    for (var i = 0; i < chunkSize; i++) {
      windowed[i] = signal[i] * window[i];
    }
    
    final freqData = fft.realFft(windowed);
    final magnitudes = freqData.magnitudes();
    
    // Default range for most calls
    double minFreq = 100.0;
    double maxFreq = 5000.0;

    // Species-specific biological overrides to skip harmonics/noise
    if (id.contains('goose_canadian_honk')) {
      minFreq = 400.0; // Focus on the main honk "scream" segment
      maxFreq = 950.0; 
    } else if (id.contains('goose_cluck')) {
      minFreq = 400.0; // Filter out high harmonics, target fundamental
      maxFreq = 1200.0;
    } else if (id.contains('duck_mallard')) {
      minFreq = 300.0;
      maxFreq = 1200.0;
    } else if (id.contains('pintail')) {
      minFreq = 2000.0; // Target the 2.5k-7k whistle range
      maxFreq = 8000.0;
    } else if (id.contains('deer_snort_wheeze')) {
      minFreq = 2000.0; // Target the high-freq wheeze
      maxFreq = 8000.0;
    } else if (id == 'great_horned_owl' || id == 'gho') {
      minFreq = 250.0; // Target territorial hoots (300-450Hz)
      maxFreq = 550.0;
    } else if (id.contains('quail')) {
      minFreq = 1500.0; // Target the ~2kHz whistle
      maxFreq = 3000.0;
    } else if (id.contains('canvasback')) {
      minFreq = 400.0; // Target the guttural "krrr" Fundamental
      maxFreq = 1500.0;
    } else if (id.contains('wood_duck_sit')) {
      minFreq = 1200.0;
      maxFreq = 2200.0;
    } else if (id.contains('caribou')) {
      minFreq = 30.0; // Target the deep bull grunt (55Hz)
      maxFreq = 150.0;
    } else if (id.contains('fallow')) {
      minFreq = 15.0; // Target the deep groan (20-55Hz)
      maxFreq = 100.0;
    } else if (id.contains('pronghorn')) {
      minFreq = 1200.0; // Focus on the sharp alarm bark peak
      maxFreq = 1800.0;
    } else if (id.contains('turkey_gobble')) {
      minFreq = 400.0; 
    } else if (id.contains('pheasant')) {
      minFreq = 700.0; 
      maxFreq = 1200.0; // Cap to avoid high harmonics
    }

    final minBin = ((minFreq * chunkSize) / sampleRate).ceil();
    final maxBin = ((maxFreq * chunkSize) / sampleRate).floor().clamp(0, magnitudes.length ~/ 2);
    
    double maxMag = -1.0;
    int peakIndex = -1;
    for (int i = minBin; i < maxBin; i++) {
      if (magnitudes[i] > maxMag) {
        maxMag = magnitudes[i];
        peakIndex = i;
      }
    }

    if (peakIndex == -1) return AnalysisResult(0, duration);
    
    final peakFreq = fft.frequency(peakIndex, sampleRate.toDouble());
    return AnalysisResult(peakFreq, duration);
  } catch (e) {
    print("      Error analyzing: $e");
    return null;
  }
}
