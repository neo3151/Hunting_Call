import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:outcall/features/rating/data/backend_rating_service.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1: Backend Audio Scoring Flow', () {
    late BackendRatingService ratingService;
    late String dummyAudioPath;

    setUpAll(() async {
      // Assuming the backend is running locally on port 8000 for integration tests
      ratingService = BackendRatingService(baseUrl: 'http://10.0.2.2:8000');

      // Create a dummy WAV file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/test_call.wav');
      await file.writeAsBytes([
        // Minimal RIFF/WAV header (44 bytes) for passing simple backend format checks
        0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00, 0x57, 0x41, 0x56, 0x45,
        0x66, 0x6d, 0x74, 0x20, 0x10, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00,
        0x44, 0xac, 0x00, 0x00, 0x88, 0x58, 0x01, 0x00, 0x02, 0x00, 0x10, 0x00,
        0x64, 0x61, 0x74, 0x61, 0x00, 0x00, 0x00, 0x00
      ]);
      dummyAudioPath = file.path;
    });

    testWidgets('Should upload audio to /v1/score_audio and return a RatingResult', (WidgetTester tester) async {
      // Execute scoring
      final result = await ratingService.rateCall(
        'test_user',
        dummyAudioPath,
        'turkey_hen_yelp'
      );

      // Validate core delivery expectations
      expect(result, isA<RatingResult>());
      expect(result.score, greaterThanOrEqualTo(0.0));
      expect(result.feedback, isNotEmpty);
      expect(result.metrics.containsKey('fingerprint_score'), true);
    });
  });
}
