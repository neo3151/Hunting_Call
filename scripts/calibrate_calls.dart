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
      final analysis = await analyzeWav(audioFile);
      
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

Future<AnalysisResult?> analyzeWav(File file) async {
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

    // Use a robust chunk analysis
    const int chunkSize = 8192;
    if (numSamplesTotal < chunkSize) return AnalysisResult(0, duration);

    // Analyze first clear chunk
    final int offset = 44;
    final signal = Float64List(chunkSize);
    for (var i = 0; i < chunkSize; i++) {
        // Just take first channel
        final sample = view.getInt16(offset + (i * bytesPerSample * numChannels), Endian.little);
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
    
    // Find peak in human-audible/animal range (50Hz - 4000Hz)
    final minBin = ((50.0 * chunkSize) / sampleRate).ceil();
    final maxBin = ((4000.0 * chunkSize) / sampleRate).floor().clamp(0, magnitudes.length ~/ 2);
    
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
