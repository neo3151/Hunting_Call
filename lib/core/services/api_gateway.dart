import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firedart/firedart.dart' as fd;

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
  Future<List<Map<String, dynamic>>> queryCollection(String collection, String field, dynamic value);

  /// Queries a collection and orders by a field.
  Future<List<Map<String, dynamic>>> getTopDocuments(String collection, String orderByField, {int limit = 50});
}

class FirebaseApiGateway implements ApiGateway {
  final FirebaseFirestore _firestore;

  FirebaseApiGateway(this._firestore);

  @override
  Future<Map<String, dynamic>?> getDocument(String collection, String documentId) async {
    try {
      // Always try server first to get the freshest data (especially isPremium)
      final doc = await _firestore.collection(collection).doc(documentId)
          .get(const GetOptions(source: Source.server));
      return doc.data();
    } catch (_) {
      // Fallback to cache when offline
      final doc = await _firestore.collection(collection).doc(documentId)
          .get(const GetOptions(source: Source.cache));
      return doc.data();
    }
  }

  @override
  Future<void> setDocument(String collection, String documentId, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(documentId).set(data);
  }

  @override
  Future<void> updateDocument(String collection, String documentId, Map<String, dynamic> data) async {
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
    final query = await _firestore.collection(collection).get();
    return query.docs.map((d) => d.data()).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> queryCollection(String collection, String field, dynamic value) async {
    final query = await _firestore.collection(collection).where(field, isEqualTo: value).get();
    return query.docs.map((d) => d.data()).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getTopDocuments(String collection, String orderByField, {int limit = 50}) async {
    final query = await _firestore.collection(collection).orderBy(orderByField, descending: true).limit(limit).get();
    return query.docs.map((d) => d.data()).toList();
  }
}

class FiredartApiGateway implements ApiGateway {
  final fd.Firestore _firestore;

  FiredartApiGateway(this._firestore);

  @override
  Future<Map<String, dynamic>?> getDocument(String collection, String documentId) async {
    try {
      final doc = await _firestore.collection(collection).document(documentId).get();
      // Firedart returns document data in .map
      return doc.map;
    } catch (e) {
      // Firedart throws if doc doesn't exist; return null to match Firebase behavior
      return null;
    }
  }

  @override
  Future<void> setDocument(String collection, String documentId, Map<String, dynamic> data) async {
    // Firedart DocumentReference supports .set() to create or overwrite.
    await _firestore.collection(collection).document(documentId).set(data);
  }

  @override
  Future<void> updateDocument(String collection, String documentId, Map<String, dynamic> data) async {
    await _firestore.collection(collection).document(documentId).update(data);
  }

  @override
  Future<String> addDocument(String collection, Map<String, dynamic> data) async {
    final docRef = await _firestore.collection(collection).add(data);
    return docRef.id;
  }

  @override
  Stream<Map<String, dynamic>?> streamDocument(String collection, String documentId) {
    return _firestore.collection(collection).document(documentId).stream.map((doc) {
      if (doc == null) return null;
      return doc.map;
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    final docs = await _firestore.collection(collection).get();
    return docs.map((d) => d.map).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> queryCollection(String collection, String field, dynamic value) async {
    final query = await _firestore.collection(collection).where(field, isEqualTo: value).get();
    return query.map((d) => d.map).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getTopDocuments(String collection, String orderByField, {int limit = 50}) async {
    final query = await _firestore.collection(collection).orderBy(orderByField, descending: true).limit(limit).get();
    return query.map((d) => d.map).toList();
  }
}
