import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/features/demo/demo_mode_controller.dart';


class DemoInviteService {
  static const _apiBaseUrl = String.fromEnvironment('OUTCALL_DEMO_API_URL');

  static Future<DemoAccessTier> resolveAccessTier() async {
    if (!kIsWeb || _apiBaseUrl.isEmpty) {
      return DemoAccessTier.publicPreview;
    }

    final token = Uri.base.queryParameters['invite'];
    if (token == null || token.isEmpty) {
      return DemoAccessTier.publicPreview;
    }

    try {
      final uri = Uri.parse('$_apiBaseUrl/v1/demo/invites/validate').replace(
        queryParameters: {'token': token},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return DemoAccessTier.publicPreview;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['valid'] == true && body['tier'] == 'prospectDemo') {
        return DemoAccessTier.prospectDemo;
      }
    } catch (_) {
      return DemoAccessTier.publicPreview;
    }

    return DemoAccessTier.publicPreview;
  }

  static Future<Map<String, dynamic>?> createProspectInvite({
    int ttlHours = 168,
    int maxUses = 1,
    String label = 'Executive Meeting Prospect',
    String? adminKey,
  }) async {
    final baseUrl = _apiBaseUrl.isNotEmpty ? _apiBaseUrl : 'http://localhost:8000';
    try {
      final uri = Uri.parse('$baseUrl/v1/demo/invites');
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (adminKey != null && adminKey.isNotEmpty) {
        headers['X-Demo-Admin-Key'] = adminKey;
      }

      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'ttl_hours': ttlHours,
              'max_uses': maxUses,
              'label': label,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      AppLogger.d('Prospect invite creation fallback to local demo token: $e');
    }

    // Local fallback token generator for offline / local presenter mode
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expiresAt = timestamp + (ttlHours * 3600);
    final mockToken = 'demo_${timestamp}_${label.replaceAll(' ', '_').toLowerCase()}';
    return {
      'token': mockToken,
      'claims': {
        'inviteId': 'inv_$timestamp',
        'tier': 'prospectDemo',
        'expiresAt': expiresAt,
        'maxUses': maxUses,
        'label': label,
      },
    };
  }
}

