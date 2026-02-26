import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/library/data/reference_database.dart';
import 'package:outcall/features/library/domain/reference_call_model.dart';
import 'package:outcall/features/analysis/data/comprehensive_audio_analyzer.dart';
import 'package:outcall/features/analysis/domain/use_cases/calculate_score_use_case.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Calculate Score for Perfect Mallard', () async {
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
    final audioPath = 'scripts/perfect_mallard.wav';
    print('\n==================================================');
    print('Analyzing audio at: $audioPath');
    final userAnalysis = await analyzer.analyzeAudio(audioPath);
    
    // Print raw analysis details
    print('--- Analysis Metrics ---');
    print('Pitch: ${userAnalysis.dominantFrequencyHz.toStringAsFixed(2)} Hz');
    print('Duration: ${userAnalysis.totalDurationSec.toStringAsFixed(2)} s');
    print('Volume (RMS): ${userAnalysis.averageVolume.toStringAsFixed(4)}');
    print('Tone Clarity: ${userAnalysis.toneClarity.toStringAsFixed(2)}%');
    print('Harmonic Richness: ${userAnalysis.harmonicRichness.toStringAsFixed(2)}%');
    print('Rhythm Regularity: ${userAnalysis.rhythmRegularity.toStringAsFixed(2)}%');
    
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
      (failure) => print('Score Calculation Failed: $failure'),
      (success) {
        print('--- Scoring Results ---');
        print('Overall Score:  ${success.overallScore.toStringAsFixed(2)}%');
        print('Pitch Score:    ${success.pitchScore.score.toStringAsFixed(2)}%');
        print('Duration Score: ${success.durationScore.score.toStringAsFixed(2)}%');
        print('Volume Score:   ${success.volumeScore.score.toStringAsFixed(2)}%');
        print('Tone Score:     ${success.toneScore.score.toStringAsFixed(2)}%');
        print('Rhythm Score:   ${success.rhythmScore.score.toStringAsFixed(2)}%');
        print('==================================================\n');
      }
    );
  });
}
