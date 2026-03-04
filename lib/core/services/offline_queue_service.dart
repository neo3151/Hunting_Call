import 'dart:convert';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/core/services/simple_storage.dart';

/// Queues scoring results and leaderboard submissions for later upload
/// when the device is offline.
///
/// Persisted in SharedPreferences as a JSON array.
class OfflineQueueService {
  static const _queueKey = 'offline_score_queue';

  final ISimpleStorage _storage;

  OfflineQueueService(this._storage);

  /// Add an item to the offline queue.
  Future<void> enqueue(OfflineQueueItem item) async {
    final items = await _getQueue();
    items.add(item);
    await _saveQueue(items);
    AppLogger.d('OfflineQueue: Enqueued ${item.type} (${items.length} pending)');
  }

  /// Process all queued items. Call when connectivity returns.
  Future<void> processQueue(Future<bool> Function(OfflineQueueItem) processor) async {
    final items = await _getQueue();
    if (items.isEmpty) return;

    AppLogger.d('OfflineQueue: Processing ${items.length} queued items');
    final remaining = <OfflineQueueItem>[];

    for (final item in items) {
      try {
        final success = await processor(item);
        if (!success) {
          remaining.add(item);
        }
      } catch (e) {
        AppLogger.d('OfflineQueue: Failed to process ${item.type}: $e');
        remaining.add(item);
      }
    }

    await _saveQueue(remaining);
    AppLogger.d('OfflineQueue: ${items.length - remaining.length} processed, ${remaining.length} remaining');
  }

  /// Get the number of queued items.
  Future<int> get pendingCount async => (await _getQueue()).length;

  /// Clear all queued items.
  Future<void> clear() async {
    await _storage.setString(_queueKey, '[]');
  }

  Future<List<OfflineQueueItem>> _getQueue() async {
    final raw = await _storage.getString(_queueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => OfflineQueueItem.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      AppLogger.d('OfflineQueue: Corrupt queue, resetting: $e');
      return [];
    }
  }

  Future<void> _saveQueue(List<OfflineQueueItem> items) async {
    await _storage.setString(_queueKey, jsonEncode(items.map((e) => e.toMap()).toList()));
  }
}

/// A single queued offline action.
class OfflineQueueItem {
  final String type; // 'score_submit', 'leaderboard_submit', 'history_save'
  final Map<String, dynamic> data;
  final DateTime createdAt;

  OfflineQueueItem({
    required this.type,
    required this.data,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'type': type,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
  };

  factory OfflineQueueItem.fromMap(Map<String, dynamic> map) => OfflineQueueItem(
    type: map['type'] as String,
    data: Map<String, dynamic>.from(map['data'] as Map),
    createdAt: DateTime.parse(map['createdAt'] as String),
  );
}
