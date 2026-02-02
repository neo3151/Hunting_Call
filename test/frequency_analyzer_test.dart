import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:hunting_calls_perfection/features/analysis/data/fftea_frequency_analyzer.dart';

void main() {
  test('FFTEAFrequencyAnalyzer should detect ~440Hz in a generated WAV file', () async {
    // 1. Generate a synthetic WAV file with a 440Hz sine wave
    final tempDir = Directory.systemTemp.createTempSync();
    final file = File('${tempDir.path}/test_440hz.wav');
    
    // WAV Header parameters
    const int sampleRate = 44100;
    const int durationSeconds = 1;
    const int numSamples = sampleRate * durationSeconds;
    const int byteRate = sampleRate * 2; // 16-bit mono
    const int dataSize = numSamples * 2;
    const int fileSize = 36 + dataSize;

    final bytes = BytesBuilder();
    
    // RIFF header
    bytes.add('RIFF'.codeUnits);
    bytes.add(_int32(fileSize));
    bytes.add('WAVE'.codeUnits);
    
    // fmt chunk
    bytes.add('fmt '.codeUnits);
    bytes.add(_int32(16)); // Subchunk1Size
    bytes.add(_int16(1)); // AudioFormat (PCM)
    bytes.add(_int16(1)); // NumChannels (Mono)
    bytes.add(_int32(sampleRate));
    bytes.add(_int32(byteRate));
    bytes.add(_int16(2)); // BlockAlign
    bytes.add(_int16(16)); // BitsPerSample
    
    // data chunk
    bytes.add('data'.codeUnits);
    bytes.add(_int32(dataSize));
    
    // Generate Sine Wave
    const double frequency = 440.0;
    for (int i = 0; i < numSamples; i++) {
      double time = i / sampleRate;
      double amplitude = 0.5; // Max 0.5 to avoid clipping
      double sampleValue = amplitude * math.sin(2 * math.pi * frequency * time);
      
      // Convert to 16-bit signed integer
      int intSample = (sampleValue * 32767).round();
      bytes.add(_int16(intSample));
    }
    
    await file.writeAsBytes(bytes.toBytes());
    
    // 2. Run Analyzer
    final analyzer = FFTEAFrequencyAnalyzer();
    final detectedHz = await analyzer.getDominantFrequency(file.path);
    
    print('Detected: $detectedHz Hz (Expected: 440 Hz)');
    
    // 3. Assert (Allow small margin of error due to FFT bin width)
    // Bin resolution = 44100 / 4096 ≈ 10.7 Hz
    expect(detectedHz, closeTo(440.0, 11.0));
    
    // Cleanup
    if (file.existsSync()) file.deleteSync();
  });
}

List<int> _int32(int value) {
  var b = Uint8List(4);
  b.buffer.asByteData().setInt32(0, value, Endian.little);
  return b;
}

List<int> _int16(int value) {
  var b = Uint8List(2);
  b.buffer.asByteData().setInt16(0, value, Endian.little);
  return b;
}
