import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hunting_calls_perfection/features/analysis/data/real_rating_service.dart';
import 'package:hunting_calls_perfection/features/analysis/domain/frequency_analyzer.dart';
import 'package:hunting_calls_perfection/features/profile/data/profile_repository.dart';
import 'package:hunting_calls_perfection/features/rating/domain/rating_model.dart';

class MockFrequencyAnalyzer extends Mock implements FrequencyAnalyzer {}
class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late RealRatingService ratingService;
  late MockFrequencyAnalyzer mockAnalyzer;
  late MockProfileRepository mockProfileRepository;
  late Directory tempDir;

  setUp(() {
    mockAnalyzer = MockFrequencyAnalyzer();
    mockProfileRepository = MockProfileRepository();
    ratingService = RealRatingService(
      analyzer: mockAnalyzer,
      profileRepository: mockProfileRepository,
    );
    tempDir = Directory.systemTemp.createTempSync();

    // Default mock behavior
    registerFallbackValue(RatingResult(score: 0, feedback: '', pitchHz: 0, metrics: {}));
    when(() => mockProfileRepository.saveResultForUser(any(), any(), any()))
        .thenAnswer((_) async => {});
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  Future<String> createDummyWav(double durationSeconds, {int sampleRate = 44100}) async {
    final file = File('${tempDir.path}/test_${durationSeconds}s.wav');
    final numSamples = (sampleRate * durationSeconds).round();
    final dataSize = numSamples * 2; // 16-bit mono
    final fileSize = 36 + dataSize;

    final bytes = BytesBuilder();
    bytes.add('RIFF'.codeUnits);
    bytes.add(_int32(fileSize));
    bytes.add('WAVE'.codeUnits);
    bytes.add('fmt '.codeUnits);
    bytes.add(_int32(16));
    bytes.add(_int16(1)); // PCM
    bytes.add(_int16(1)); // Mono
    bytes.add(_int32(sampleRate));
    bytes.add(_int32(sampleRate * 2));
    bytes.add(_int16(2));
    bytes.add(_int16(16));
    bytes.add('data'.codeUnits);
    bytes.add(_int32(dataSize));
    bytes.add(Uint8List(dataSize)); // Silent data

    await file.writeAsBytes(bytes.toBytes());
    return file.path;
  }

  group('RealRatingService Tests', () {
    test('Perfect call should score 100', () async {
      const animalId = 'duck_mallard_greeting'; // idealPitch: 479, idealDuration: 1.2
      final audioPath = await createDummyWav(1.2);
      
      when(() => mockAnalyzer.getDominantFrequency(audioPath)).thenAnswer((_) async => 479.0);

      final result = await ratingService.rateCall('user1', audioPath, animalId);

      expect(result.score, 100.0);
      expect(result.feedback, contains('Outstanding'));
      verify(() => mockProfileRepository.saveResultForUser('user1', any(), animalId)).called(1);
    });

    test('High pitch should result in Too High feedback', () async {
      const animalId = 'duck_mallard_greeting'; // idealPitch: 479, tolerance: 50
      final audioPath = await createDummyWav(1.2);
      
      // 580Hz is 101Hz off from 479Hz = 21% deviation
      // tolerance is 50Hz = 10.4% deviation
      // excess deviation = 21% - 10.4% = 10.6%
      // pitchScore = 100 - (10.6 * 3) = 68.2
      // totalScore = 68.2 * 0.6 + 100 * 0.4 = 40.9 + 40 = 80.9
      when(() => mockAnalyzer.getDominantFrequency(audioPath)).thenAnswer((_) async => 580.0);

      final result = await ratingService.rateCall('user1', audioPath, animalId);

      expect(result.score, closeTo(80.9, 1.0));
      expect(result.feedback, contains('Too High'));
    });

    test('Short duration should result in Too Short feedback', () async {
      const animalId = 'duck_mallard_greeting'; // idealDuration: 1.2, tolerance: 0.5
      final audioPath = await createDummyWav(0.5); // 0.7s too short
      
      when(() => mockAnalyzer.getDominantFrequency(audioPath)).thenAnswer((_) async => 479.0);

      final result = await ratingService.rateCall('user1', audioPath, animalId);

      expect(result.feedback, contains('Too Short'));
    });
    
    test('Percentage-based scoring should be fair across frequency ranges', () async {
      // Test that same percentage deviation produces similar scores
      // regardless of whether it's a low or high frequency call
      
      // Low frequency: deer_buck_grunt at 120Hz, tolerance 30Hz (25%)
      final deerPath = await createDummyWav(0.8);
      // 20% deviation = 24Hz off = 144Hz detected
      when(() => mockAnalyzer.getDominantFrequency(deerPath)).thenAnswer((_) async => 144.0);
      final deerResult = await ratingService.rateCall('user1', deerPath, 'deer_buck_grunt');
      
      // High frequency: elk_bull_bugle at 2000Hz, tolerance 200Hz (10%)  
      final elkPath = await createDummyWav(3.0);
      // 20% deviation = 400Hz off = 2400Hz detected
      when(() => mockAnalyzer.getDominantFrequency(elkPath)).thenAnswer((_) async => 2400.0);
      final elkResult = await ratingService.rateCall('user1', elkPath, 'elk_bull_bugle');
      
      // Both have 20% deviation - scores should be in similar range
      // (not exactly equal due to different tolerance percentages)
      expect((deerResult.score - elkResult.score).abs(), lessThan(20), 
          reason: 'Same percentage deviation should produce similar scores');
    });
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
