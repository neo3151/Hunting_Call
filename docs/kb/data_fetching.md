# Data Fetching Strategy: Cache-First Firestore

To ensure a "snappy" luxury experience, a cache-first strategy is implemented for all high-traffic read operations in the `FirebaseApiGateway`.

## 1. Overview
By default, Firestore queries attempt to reach the server to ensure the freshest data. On mobile networks, this can introduce noticeable latency, breaking the premium feel. The **Cache-First** strategy attempts to read from the local persistent cache first, instantly returning results while Firestore background-syncs with the server.

## 2. Implementation (`FirebaseApiGateway`)
The following methods use `Source.cache` in their `get()` calls:
- `getDocument(String path)`
- `getCollection(String path)`
- `queryCollection(Query query)`
- `getTopDocuments(String path, String orderBy, int limit)`

### Example Logic
```dart
Future<Map<String, dynamic>> getDocument(String path) async {
  try {
    // Attempt cache first for instant UI response
    final snapshot = await _firestore.doc(path).get(const GetOptions(source: Source.cache));
    return snapshot.data() ?? {};
  } catch (e) {
    // Fallback to server if cache is empty or fails
    final snapshot = await _firestore.doc(path).get(const GetOptions(source: Source.server));
    return snapshot.data() ?? {};
  }
}
```

## 3. Benefits
1.  **Near-Instant Loading**: Screens like Global Rankings and Animal Libraries load in <100ms when data is already cached.
2.  **Offline Support**: Users can browse the library and review their offline practice attempts without an active connection.
3.  **Reduced Data Usage**: Fewer server read operations occur during frequent navigation between tabs.

## 4. Risks & Considerations
- **Stale Data**: Users might see slightly outdated leaderboards if they haven't synced recently. This is an acceptable trade-off for the performance gain.
- **Cache Size**: Firestore manages cache eviction automatically, but testing should verify that large amounts of audio/profile data do not bloat the local storage excessively.
