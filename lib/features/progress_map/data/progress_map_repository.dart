import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/core/services/simple_storage.dart';

/// Persistence layer for the Progress Map feature.
///
/// Tracks which worlds are unlocked, which nodes are completed,
/// and the user's current world/node selection.
class ProgressMapRepository {
  static const _keyCurrentWorld = 'progress_map_current_world';
  static const _keyCompletedNodes = 'progress_map_completed_nodes';
  static const _keyUnlockedWorlds = 'progress_map_unlocked_worlds';

  final ISimpleStorage _storage;

  ProgressMapRepository(this._storage);

  /// Get the currently selected world index.
  Future<int> getCurrentWorldIndex() async {
    return await _storage.getInt(_keyCurrentWorld) ?? 0;
  }

  /// Set the currently selected world index.
  Future<void> setCurrentWorldIndex(int index) async {
    await _storage.setInt(_keyCurrentWorld, index);
  }

  /// Get the set of completed node IDs.
  Future<Set<String>> getCompletedNodes() async {
    final raw = await _storage.getString(_keyCompletedNodes);
    if (raw == null || raw.isEmpty) return {};
    return raw.split(',').toSet();
  }

  /// Mark a node as completed.
  Future<void> completeNode(String nodeId) async {
    final nodes = await getCompletedNodes();
    nodes.add(nodeId);
    await _storage.setString(_keyCompletedNodes, nodes.join(','));
    AppLogger.d('ProgressMap: Completed node $nodeId (${nodes.length} total)');
  }

  /// Get the set of unlocked world IDs.
  Future<Set<String>> getUnlockedWorlds() async {
    final raw = await _storage.getString(_keyUnlockedWorlds);
    if (raw == null || raw.isEmpty) return {'meadow'}; // First world always unlocked
    return raw.split(',').toSet();
  }

  /// Unlock a new world.
  Future<void> unlockWorld(String worldId) async {
    final worlds = await getUnlockedWorlds();
    worlds.add(worldId);
    await _storage.setString(_keyUnlockedWorlds, worlds.join(','));
    AppLogger.d('ProgressMap: Unlocked world $worldId');
  }

  /// Reset all progress.
  Future<void> resetProgress() async {
    await _storage.setInt(_keyCurrentWorld, 0);
    await _storage.setString(_keyCompletedNodes, '');
    await _storage.setString(_keyUnlockedWorlds, 'meadow');
    AppLogger.d('ProgressMap: Progress reset');
  }
}
