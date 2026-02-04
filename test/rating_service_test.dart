import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hunting_calls_perfection/features/library/data/reference_database.dart';
import 'package:hunting_calls_perfection/features/analysis/data/real_rating_service.dart';
import 'package:hunting_calls_perfection/features/analysis/domain/frequency_analyzer.dart';
import 'package:hunting_calls_perfection/features/analysis/domain/audio_analysis_model.dart';
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
    TestWidgetsFlutterBinding.ensureInitialized();
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
      const animalId = 'duck_mallard_greeting'; 
      final reference = ReferenceDatabase.getById(animalId);
      final audioPath = await createDummyWav(reference.idealDurationSec);
      
      when(() => mockAnalyzer.analyzeAudio(any())).thenAnswer((_) async => AudioAnalysis.simple(
        frequencyHz: reference.idealPitchHz,
        durationSec: reference.idealDurationSec,
      ));

      final result = await ratingService.rateCall('user1', audioPath, animalId);

      expect(result.score, 100.0);
      expect(result.feedback, contains('Outstanding'));
      verify(() => mockProfileRepository.saveResultForUser('user1', any(), animalId)).called(1);
    });

    test('High pitch should result in Too High feedback', () async {
      const animalId = 'duck_mallard_greeting'; 
      final reference = ReferenceDatabase.getById(animalId);
      final audioPath = await createDummyWav(reference.idealDurationSec);
      
      // Detected is ideal + tolerance + 100Hz
      final detectedPitch = reference.idealPitchHz + reference.tolerancePitch + 100.0;
      when(() => mockAnalyzer.analyzeAudio(any())).thenAnswer((_) async => AudioAnalysis.simple(
        frequencyHz: detectedPitch,
        durationSec: reference.idealDurationSec,
      ));

      final result = await ratingService.rateCall('user1', audioPath, animalId);

      expect(result.score, lessThan(100.0));
      expect(result.feedback, contains('Too High'));
    });

    test('Short duration should result in Too Short feedback', () async {
      const animalId = 'duck_mallard_greeting'; 
      final reference = ReferenceDatabase.getById(animalId);
      final audioPath = await createDummyWav(reference.idealDurationSec * 0.5); 
      
      when(() => mockAnalyzer.analyzeAudio(any())).thenAnswer((_) async => AudioAnalysis.simple(
        frequencyHz: reference.idealPitchHz,
        durationSec: reference.idealDurationSec * 0.5,
      ));

      final result = await ratingService.rateCall('user1', audioPath, animalId);

      expect(result.feedback, contains('Too Short'));
    });
    
    test('Percentage-based scoring should be fair across frequency ranges', () async {
      // Test that same percentage deviation produces similar scores
      // regardless of whether it's a low or high frequency call
      
      // Low frequency: turkey_hen_yelp (now 174Hz)
      final lowAnimal = ReferenceDatabase.getById('turkey_hen_yelp');
      final lowPath = await createDummyWav(lowAnimal.idealDurationSec);
      // 20% deviation
      when(() => mockAnalyzer.analyzeAudio(any())).thenAnswer((_) async => AudioAnalysis.simple(
        frequencyHz: lowAnimal.idealPitchHz * 1.2,
        durationSec: lowAnimal.idealDurationSec,
      ));
      final lowResult = await ratingService.rateCall('user1', lowPath, lowAnimal.id);
      
      // High frequency: elk_bull_bugle (now 1156Hz) 
      final highAnimal = ReferenceDatabase.getById('elk_bull_bugle');
      final highPath = await createDummyWav(highAnimal.idealDurationSec);
      // 20% deviation
      when(() => mockAnalyzer.analyzeAudio(any())).thenAnswer((_) async => AudioAnalysis.simple(
        frequencyHz: highAnimal.idealPitchHz * 1.2,
        durationSec: highAnimal.idealDurationSec,
      ));
      final highResult = await ratingService.rateCall('user1', highPath, highAnimal.id);
      
      // Both have 20% deviation - scores should be in similar range
      expect((lowResult.score - highResult.score).abs(), lessThan(20), 
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
