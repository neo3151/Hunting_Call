import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:outcall/core/services/analytics_service.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';
import 'package:outcall/features/rating/domain/rating_service.dart';
import 'package:outcall/features/rating/data/sqlite_outbox_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class BackendRatingService implements RatingService {
  final String baseUrl;
  final SqliteOutboxRepository _outboxRepo = SqliteOutboxRepository();
  
  BackendRatingService({required this.baseUrl});

  @override
  Future<RatingResult> rateCall(String userId, String audioPath, String animalType, {
    double scoreOffset = 0.0,
    double micSensitivity = 1.0,
    bool skipFingerprint = false,
    bool isBackgroundSync = false,
  }) async {
    final startTime = DateTime.now();
    try {
      final uri = Uri.parse('$baseUrl/v1/score_audio');
      var request = http.MultipartRequest('POST', uri);
      
      // Attach audio file
      request.files.add(await http.MultipartFile.fromPath('audio', audioPath));
      request.fields['animal_id'] = animalType;
      request.fields['mode'] = skipFingerprint ? 'quick' : 'expert';
      
      // Get Firebase Auth token
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        if (token != null) {
          request.headers['authorization'] = 'Bearer $token';
        }
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      final latency = DateTime.now().difference(startTime).inMilliseconds;
      AnalyticsService.logScoringLatency(animalType, latency);

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(responseBody);
        final result = RatingResult.fromJson(jsonMap);

        // Track if this was a noise gate rejection
        if (result.metrics['noise_rejected'] == 1.0) {
          AnalyticsService.logRecordingRejected(animalType, 'noise_gate');
        } else {
          AnalyticsService.logRecordingCompleted(animalType, result.score);
        }

        return result;
      } else {
        AnalyticsService.logRecordingRejected(animalType, 'server_error_${response.statusCode}');
        throw Exception('Backend returned status ${response.statusCode}: $responseBody');
      }
    } on SocketException catch (_) {
      // 🌲 HUNTER OFFLINE FALLBACK 🌲
      if (!isBackgroundSync) {
        await _outboxRepo.queueCall(userId, audioPath, animalType);
      }
      
      return RatingResult(
        score: -1.0, // Special flag for pending
        feedback: "Audio safely queued. We will automatically score your call when you reconnect to Wi-Fi or LTE.",
        pitchHz: 0.0,
        metrics: {'offline_pending': 1.0},
        archetypeLabel: "Offline Pending"
      );
    } catch (e, stackTrace) {
      AnalyticsService.logRecordingRejected(animalType, 'exception');
      // Sentry capture specifically for scoring errors
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('feature', 'audio_scoring');
          scope.setContexts('animal', {'animalId': animalType});
        },
      );
      throw Exception('Failed to score audio via backend: $e');
    }
  }
}
