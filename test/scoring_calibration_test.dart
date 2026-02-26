import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/library/data/reference_database.dart';
import 'package:outcall/features/library/domain/reference_call_model.dart';
import 'package:outcall/features/analysis/data/comprehensive_audio_analyzer.dart';
import 'package:outcall/features/analysis/domain/use_cases/calculate_score_use_case.dart';
import 'package:outcall/core/utils/app_logger.dart';

/// Manual calibration test — only runs when the audio fixture exists.
/// Place a WAV file at `scripts/perfect_mallard.wav` to use this test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final audioFile = File('scripts/perfect_mallard.wav');

  test('Calculate Score for Perfect Mallard', () async {
    if (!audioFile.existsSync()) {
      AppLogger.d('Skipping: scripts/perfect_mallard.wav not found');
      // Mark test as passing when the fixture is missing
      return;
    }

    // 1. Manually initialize ReferenceDatabase (bypassing rootBundle for test environment)
    final jsonFile = File('assets/data/reference_calls.json');
    final jsonString = await jsonFile.readAsString();
    final data = json.decode(jsonString);
    final List<dynamic> callsJson = data['calls'];
    final calls = callsJson.map((json) => ReferenceCall.fromJson(json)).toList();
    ReferenceDatabase.calls = calls; // @visibleForTesting injection

    // 2. Initialize Analyzer and Use Case
    final analyzer = ComprehensiveAudioAnalyzer();
    final useCase = CalculateScoreUseCase();

    // 3. Analyze the perfect audio file
    final audioPath = audioFile.path;
    AppLogger.d('Analyzing audio at: $audioPath');
    final userAnalysis = await analyzer.analyzeAudio(audioPath);

    AppLogger.d('Pitch: ${userAnalysis.dominantFrequencyHz.toStringAsFixed(2)} Hz');
    AppLogger.d('Duration: ${userAnalysis.totalDurationSec.toStringAsFixed(2)} s');

    // 4. Calculate final score
    final params = CalculateScoreParams(
      recordingId: 'test_recording',
      userId: 'test_user',
      animalId: 'duck_mallard_greeting',
      userAnalysis: userAnalysis,
      referenceAnalysis: null, // Fallback to reference JSON specs
    );

    final result = await useCase.execute(params);

    result.fold(
      (failure) => fail('Score Calculation Failed: $failure'),
      (success) {
        AppLogger.d('Overall Score: ${success.overallScore.toStringAsFixed(2)}%');
        expect(success.overallScore, greaterThan(0));
        expect(success.overallScore, lessThanOrEqualTo(100));
      },
    );
  });
}
