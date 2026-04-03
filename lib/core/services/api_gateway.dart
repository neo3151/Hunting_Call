import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// A unified API Gateway that abstracts the differences between
/// FirebaseFirestore (Mobile/Web) and Firedart (Linux/Desktop).
abstract class ApiGateway {
  /// Fetches a document from a specific collection and document ID.
  Future<Map<String, dynamic>?> getDocument(String collection, String documentId);

  /// Sets or overwrites a document.
  Future<void> setDocument(String collection, String documentId, Map<String, dynamic> data);

  /// Updates specific fields in a document.
  Future<void> updateDocument(String collection, String documentId, Map<String, dynamic> data);

  /// Adds a new document to a collection (auto-generates the ID) and returns the ID.
  Future<String> addDocument(String collection, Map<String, dynamic> data);

  /// Streams a document for real-time updates.
  Stream<Map<String, dynamic>?> streamDocument(String collection, String documentId);

  /// Gets all documents in a collection.
  Future<List<Map<String, dynamic>>> getCollection(String collection);

  /// Queries a collection for documents matching a specific field and value.
  Future<List<Map<String, dynamic>>> queryCollection(
      String collection, String field, dynamic value);

  /// Queries a collection and orders by a field.
  Future<List<Map<String, dynamic>>> getTopDocuments(String collection, String orderByField,
      {int limit = 50});
}

class FirebaseApiGateway implements ApiGateway {
  final FirebaseFirestore _firestore;

  FirebaseApiGateway(this._firestore);

  @override
  Future<Map<String, dynamic>?> getDocument(String collection, String documentId) async {
    try {
      // Cache-first for instant loading; server data syncs automatically
      // via Firestore's offline persistence.
      final doc = await _firestore
          .collection(collection)
          .doc(documentId)
          .get(const GetOptions(source: Source.cache));
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
    } catch (e) {
      // Cache miss or empty — fall through to server
      // Intentional: cache misses are expected on first load
    }
    // No cache hit — fetch from server (first-ever load or cleared cache)
    final doc = await _firestore
        .collection(collection)
        .doc(documentId)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 4));
    return doc.data();
  }

  @override
  Future<void> setDocument(String collection, String documentId, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(documentId).set(data);
  }

  @override
  Future<void> updateDocument(
      String collection, String documentId, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(documentId).update(data);
  }

  @override
  Future<String> addDocument(String collection, Map<String, dynamic> data) async {
    final docRef = await _firestore.collection(collection).add(data);
    return docRef.id;
  }

  @override
  Stream<Map<String, dynamic>?> streamDocument(String collection, String documentId) {
    return _firestore.collection(collection).doc(documentId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return snapshot.data();
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    // Server-first for collection queries: the cache may only contain a
    // subset of documents (those previously fetched on this device).
    try {
      final query =
          await _firestore.collection(collection).get(const GetOptions(source: Source.server))
              .timeout(const Duration(seconds: 4));
      return query.docs.map((d) => d.data()).toList();
    } catch (_) {
      // Offline fallback — return whatever is cached
      try {
        final query =
            await _firestore.collection(collection).get(const GetOptions(source: Source.cache));
        return query.docs.map((d) => d.data()).toList();
      } catch (_) {
        return [];
      }
    }
  }

  @override
  Future<List<Map<String, dynamic>>> queryCollection(
      String collection, String field, dynamic value) async {
    try {
      final query = await _firestore
          .collection(collection)
          .where(field, isEqualTo: value)
          .get(const GetOptions(source: Source.cache));
      if (query.docs.isNotEmpty) {
        return query.docs.map((d) => d.data()).toList();
      }
    } catch (e) {
      // Cache miss — fall through to server
    }
    final query = await _firestore
        .collection(collection)
        .where(field, isEqualTo: value)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 4));
    return query.docs.map((d) => d.data()).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getTopDocuments(String collection, String orderByField,
      {int limit = 50}) async {
    // Server-first for ranking queries: the cache typically only contains
    // the current user's profile, making it useless for global rankings.
    try {
      final query = await _firestore
          .collection(collection)
          .orderBy(orderByField, descending: true)
          .limit(limit)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 4));
      return query.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    } catch (_) {
      // Offline fallback — return whatever is cached (partial data is
      // better than nothing when there's no network).
      try {
        final query = await _firestore
            .collection(collection)
            .orderBy(orderByField, descending: true)
            .limit(limit)
            .get(const GetOptions(source: Source.cache));
        return query.docs.map((d) => {...d.data(), 'id': d.id}).toList();
      } catch (_) {
        return [];
      }
    }
  }
}

class RestFirestoreApiGateway implements ApiGateway {
  // Ignored on desktop, but satisfies constructor signature if sharing
  final FirebaseFirestore? _db;
  // Hardcoded for this project based on firebase_options.dart
  static const String _projectId = 'hunting-call-perfection';
  static const String _baseUrl = 'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  RestFirestoreApiGateway(this._db);

  Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      return {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  /// Appends the Firebase Web API Key to the URI if there is no authenticated user.
  /// This is required by Google Cloud to allow public REST reads.
  Future<Uri> _buildUri(String path, {String? queryParams}) async {
    var urlString = '$_baseUrl/$path';
    if (queryParams != null && queryParams.isNotEmpty) {
      urlString += '?$queryParams';
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      try {
        final apiKey = Firebase.app().options.apiKey;
        if (apiKey.isNotEmpty) {
          if (urlString.contains('?')) {
            urlString += '&key=$apiKey';
          } else {
            urlString += '?key=$apiKey';
          }
        }
      } catch (_) {
        // App not fully initialized
      }
    }
    return Uri.parse(urlString);
  }

  /// Converts a Firestore REST document map to a native dart Map.
  /// Note: A full implementation requires unwrapping `stringValue`, `integerValue`, etc.
  /// For this simple wrapper, we'll try to extract fields.
  Map<String, dynamic> _unwrapDocument(Map<String, dynamic> doc) {
    if (!doc.containsKey('fields')) return {};
    final fields = doc['fields'] as Map<String, dynamic>;
    final result = <String, dynamic>{};
    fields.forEach((k, v) {
      final valMap = v as Map<String, dynamic>;
      if (valMap.containsKey('stringValue')) result[k] = valMap['stringValue'];
      else if (valMap.containsKey('integerValue')) result[k] = int.tryParse(valMap['integerValue'].toString()) ?? 0;
      else if (valMap.containsKey('booleanValue')) result[k] = valMap['booleanValue'] == true;
      else if (valMap.containsKey('doubleValue')) result[k] = (valMap['doubleValue'] as num).toDouble();
      else if (valMap.containsKey('arrayValue')) {
        final arr = valMap['arrayValue']['values'] as List<dynamic>? ?? [];
        result[k] = arr.map((e) {
          final eMap = e as Map<String, dynamic>;
          return eMap['stringValue'] ?? eMap['integerValue'] ?? eMap['booleanValue'] ?? eMap['doubleValue'] ?? '';
        }).toList();
      }
      else if (valMap.containsKey('mapValue')) {
         result[k] = _unwrapDocument(valMap['mapValue']);
      }
      // Add more type unwrappings as needed
    });
    return result;
  }

  /// Wraps a Dart map to a Firestore REST document map.
  Map<String, dynamic> _wrapFields(Map<String, dynamic> data) {
    final fields = <String, dynamic>{};
    data.forEach((k, v) {
      if (v is String) fields[k] = {'stringValue': v};
      else if (v is int) fields[k] = {'integerValue': v.toString()};
      else if (v is double) fields[k] = {'doubleValue': v};
      else if (v is bool) fields[k] = {'booleanValue': v};
      else if (v is List) {
        fields[k] = {
          'arrayValue': {
            'values': v.map((e) {
              if (e is String) return {'stringValue': e};
              if (e is int) return {'integerValue': e.toString()};
              if (e is bool) return {'booleanValue': e};
              if (e is double) return {'doubleValue': e};
              return {'stringValue': e.toString()};
            }).toList()
          }
        };
      } else if (v is Map<String, dynamic>) {
        fields[k] = {
           'mapValue': {
               'fields': _wrapFields(v)
           }
        };
      }
    });
    return {'fields': fields};
  }

  @override
  Future<Map<String, dynamic>?> getDocument(String collection, String documentId) async {
    final uri = await _buildUri('$collection/$documentId');
    final res = await http.get(uri, headers: await _headers()).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return _unwrapDocument(jsonDecode(res.body));
    }
    return null;
  }

  @override
  Future<void> setDocument(String collection, String documentId, Map<String, dynamic> data) async {
    // A patching approach using document ID ensures creation if lacking or overwriting.
    // In Firestore REST, we use patch for updates. To set/overwrite we can just use patch as well.
    final uri = await _buildUri('$collection/$documentId');
    final body = jsonEncode(_wrapFields(data));
    await http.patch(uri, headers: await _headers(), body: body).timeout(const Duration(seconds: 10));
  }

  @override
  Future<void> updateDocument(String collection, String documentId, Map<String, dynamic> data) async {
    // Requires appending updateMask for specific fields to simulate update rather than strict overwrite.
    final maskParams = data.keys.map((k) => 'updateMask.fieldPaths=$k').join('&');
    final uri = await _buildUri('$collection/$documentId', queryParams: maskParams);
    final body = jsonEncode(_wrapFields(data));
    await http.patch(uri, headers: await _headers(), body: body).timeout(const Duration(seconds: 10));
  }

  @override
  Future<String> addDocument(String collection, Map<String, dynamic> data) async {
    final uri = await _buildUri(collection);
    final body = jsonEncode(_wrapFields(data));
    final res = await http.post(uri, headers: await _headers(), body: body).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final docName = jsonDecode(res.body)['name'] as String;
      return docName.split('/').last; // The generated document ID
    }
    return '';
  }

  @override
  Stream<Map<String, dynamic>?> streamDocument(String collection, String documentId) async* {
    // Realtime Streams are not fully supported natively on simple REST. 
    // Fallback to retrieving once, as desktop is usually fully offline or polling.
    yield await getDocument(collection, documentId);
  }

  @override
  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    final uri = await _buildUri(collection);
    final res = await http.get(uri, headers: await _headers()).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final docs = jsonDecode(res.body)['documents'] as List<dynamic>? ?? [];
      return docs.map((d) => _unwrapDocument(d)).toList();
    }
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> queryCollection(String collection, String field, dynamic value) async {
    // For specific queries we have to use the runQuery endpoint.
    final uri = await _buildUri(':runQuery');
    
    // Quick and dirty payload for basic queries
    final operator = 'EQUAL';
    final queryPayload = {
      'structuredQuery': {
        'from': [{'collectionId': collection}],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': field},
            'op': operator,
            'value': _wrapFields({'val': value})['fields']['val']
          }
        }
      }
    };

    final res = await http.post(uri, headers: await _headers(), body: jsonEncode(queryPayload)).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final docs = jsonDecode(res.body) as List<dynamic>;
      return docs
          .where((d) => d['document'] != null)
          .map((d) => _unwrapDocument(d['document']))
          .toList();
    }
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getTopDocuments(String collection, String orderByField, {int limit = 50}) async {
    final uri = await _buildUri(':runQuery');

    final queryPayload = {
      'structuredQuery': {
        'from': [{'collectionId': collection}],
        'orderBy': [
          {
            'field': {'fieldPath': orderByField},
            'direction': 'DESCENDING'
          }
        ],
        'limit': limit
      }
    };

    final res = await http.post(uri, headers: await _headers(), body: jsonEncode(queryPayload)).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final docs = jsonDecode(res.body) as List<dynamic>;
      return docs
          .where((d) => d['document'] != null)
          .map((d) {
            final doc = d['document'];
            final id = (doc['name'] as String).split('/').last;
            return {..._unwrapDocument(doc), 'id': id};
          })
          .toList();
    }
    return [];
  }
}
