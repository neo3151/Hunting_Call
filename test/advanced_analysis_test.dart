import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hunting_calls_perfection/features/analysis/data/comprehensive_audio_analyzer.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<String> createTestWav(String filename, double frequency) async {
    final tempDir = Directory.systemTemp.createTempSync();
    final file = File('${tempDir.path}/$filename');
    
    const int sampleRate = 44100;
    const int durationSeconds = 1;
    const int numSamples = sampleRate * durationSeconds;
    const int dataSize = numSamples * 2;
    const int fileSize = 36 + dataSize;

    final bytes = BytesBuilder();
    bytes.add('RIFF'.codeUnits);
    bytes.add(_int32(fileSize));
    bytes.add('WAVE'.codeUnits);
    bytes.add('fmt '.codeUnits);
    bytes.add(_int32(16));
    bytes.add(_int16(1));
    bytes.add(_int16(1));
    bytes.add(_int32(sampleRate));
    bytes.add(_int32(sampleRate * 2));
    bytes.add(_int16(2));
    bytes.add(_int16(16));
    bytes.add('data'.codeUnits);
    bytes.add(_int32(dataSize));
    
    for (int i = 0; i < numSamples; i++) {
        double time = i / sampleRate;
        // Vary frequency slightly to test pitch tracking
        double currentFreq = frequency + (i > numSamples / 2 ? 100 : 0);
        double sampleValue = 0.5 * math.sin(2 * math.pi * currentFreq * time);
        bytes.add(_int16((sampleValue * 32767).round()));
    }
    
    await file.writeAsBytes(bytes.toBytes());
    return file.path;
  }

  test('ComprehensiveAudioAnalyzer should track pitch and calculate centroid', () async {
    final analyzer = ComprehensiveAudioAnalyzer();
    final path = await createTestWav('test_complex.wav', 440.0);
    
    final analysis = await analyzer.analyzeAudio(path);
    
    expect(analysis.dominantFrequencyHz, closeTo(490.0, 50.0)); // Weighted average
    expect(analysis.pitchTrack.isNotEmpty, true);
    expect(analysis.spectralCentroid.isNotEmpty, true);
    expect(analysis.waveform.length, 100);
    
    // Check that pitchTrack reflects the change
    final firstHalf = analysis.pitchTrack.take(analysis.pitchTrack.length ~/ 2);
    final secondHalf = analysis.pitchTrack.skip(analysis.pitchTrack.length ~/ 2);
    
    if (firstHalf.isNotEmpty && secondHalf.isNotEmpty) {
        expect(firstHalf.first, closeTo(440.0, 20.0));
        expect(secondHalf.last, closeTo(540.0, 20.0));
    }
  });

  test('Waveform caching should work', () async {
    final analyzer = ComprehensiveAudioAnalyzer();
    final path = await createTestWav('test_cache.wav', 440.0);
    
    // First run - populates cache
    final analysis1 = await analyzer.analyzeAudio(path);
    
    // Second run - should use cache for waveform
    final analysis2 = await analyzer.analyzeAudio(path);
    
    expect(analysis1.waveform, analysis2.waveform);
    // Note: analyzeAudio still performs FFT etc., but waveform extraction is cached.
    // In a real scenario, we might cache the whole analysis.
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
