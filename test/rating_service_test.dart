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
      
      // Pitch diff = 580 - 479 = 101. tolerance = 50. 
      // pitchScore = 100 - (101 - 50) = 49.
      // totalScore = 49 * 0.6 + 100 * 0.4 = 29.4 + 40 = 69.4.
      when(() => mockAnalyzer.getDominantFrequency(audioPath)).thenAnswer((_) async => 580.0);

      final result = await ratingService.rateCall('user1', audioPath, animalId);

      expect(result.score, closeTo(69.4, 0.1));
      expect(result.feedback, contains('Too High'));
    });

    test('Short duration should result in Too Short feedback', () async {
      const animalId = 'duck_mallard_greeting'; // idealDuration: 1.2, tolerance: 0.1? No, toleranceDuration is not in ReferenceCall yet?
      // Wait, let's check ReferenceCall model.
      final audioPath = await createDummyWav(0.5); // Diff = 0.7
      
      when(() => mockAnalyzer.getDominantFrequency(audioPath)).thenAnswer((_) async => 479.0);

      final result = await ratingService.rateCall('user1', audioPath, animalId);

      // We need to check RealRatingService's tolerance for duration.
      // In real_rating_service.dart, it uses reference.toleranceDuration.
      // Let's check ReferenceCall domain model.
      expect(result.feedback, contains('Too Short'));
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
