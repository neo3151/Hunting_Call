import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String _projectId = 'hunting-call-perfection';
  const String _baseUrl = 'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  print('Testing getTopDocuments...');
  final uri = Uri.parse('$_baseUrl:runQuery');
  final queryPayload = {
    'structuredQuery': {
      'from': [{'collectionId': 'profiles'}],
      'orderBy': [
        {
          'field': {'fieldPath': 'averageScore'},
          'direction': 'DESCENDING'
        }
      ],
      'limit': 50
    }
  };

  try {
    final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(queryPayload));
    print('runQuery StatusCode: ${res.statusCode}');
    print('runQuery Body: ${res.body}');
  } catch (e) {
    print('runQuery Error: $e');
  }

  print('\nTesting getCollection...');
  try {
    final res2 = await http.get(Uri.parse('$_baseUrl/profiles'));
    print('getCollection StatusCode: ${res2.statusCode}');
    String body = res2.body;
    if (body.length > 500) body = body.substring(0, 500) + '...';
    print('getCollection Body: $body');
  } catch (e) {
    print('getCollection Error: $e');
  }
}
