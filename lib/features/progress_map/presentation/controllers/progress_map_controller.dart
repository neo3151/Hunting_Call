import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/di_providers.dart';
import 'package:outcall/features/library/domain/providers.dart';
import 'package:outcall/features/progress_map/domain/world_info.dart';
import 'package:outcall/core/utils/app_logger.dart';

// ──────────────────────────────────────────────────────────
//  STATE
// ──────────────────────────────────────────────────────────

class ProgressMapState {
  final int selectedWorld;
  final List<List<MapNode>> worldNodes;
  final MapNode? selectedNode;
  final bool isLoading;

  const ProgressMapState({
    this.selectedWorld = 0,
    this.worldNodes = const [],
    this.selectedNode,
    this.isLoading = true,
  });

  ProgressMapState copyWith({
    int? selectedWorld,
    List<List<MapNode>>? worldNodes,
    MapNode? selectedNode,
    bool clearSelectedNode = false,
    bool? isLoading,
  }) {
    return ProgressMapState(
      selectedWorld: selectedWorld ?? this.selectedWorld,
      worldNodes: worldNodes ?? this.worldNodes,
      selectedNode: clearSelectedNode ? null : (selectedNode ?? this.selectedNode),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ──────────────────────────────────────────────────────────
//  CONTROLLER
// ──────────────────────────────────────────────────────────

class ProgressMapNotifier extends Notifier<ProgressMapState> {
  @override
  ProgressMapState build() {
    return const ProgressMapState();
  }

  void selectWorld(int index) {
    state = state.copyWith(selectedWorld: index, clearSelectedNode: true);
    // Persist selection
    ref.read(progressMapRepositoryProvider).setCurrentWorldIndex(index);
  }

  void selectNode(MapNode? node) {
    if (node != null && node == state.selectedNode) {
      state = state.copyWith(clearSelectedNode: true);
    } else {
      state = state.copyWith(selectedNode: node);
    }
  }

  void clearSelectedNode() {
    state = state.copyWith(clearSelectedNode: true);
  }

  Future<void> loadData(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      // Restore saved world selection, guarding against cached indices exceeding the new world count
      final repo = ref.read(progressMapRepositoryProvider);
      final savedWorld = await repo.getCurrentWorldIndex();
      
      final validWorldIndex = (savedWorld >= 0 && savedWorld < worlds.length) 
          ? savedWorld 
          : (worlds.isNotEmpty ? worlds.length - 1 : 0);

      if (validWorldIndex != state.selectedWorld) {
        state = state.copyWith(selectedWorld: validWorldIndex);
      }

      final getAllCallsUseCase = ref.read(getAllCallsUseCaseProvider);
      final callsResult = getAllCallsUseCase.execute();

      callsResult.fold(
        (failure) {
          AppLogger.d('ProgressMap Error: ${failure.message}');
          state = state.copyWith(isLoading: false);
        },
        (allCalls) async {
          final profile = await ref
              .read(profileRepositoryProvider)
              .getProfile(userId);

          // Best scores from history
          final Map<String, int> bestScores = {};
          for (final h in profile.history) {
            final score = h.result.score.toInt();
            final prev = bestScores[h.animalId] ?? 0;
            if (score > prev) bestScores[h.animalId] = score;
          }

          final newWorldNodes = <List<MapNode>>[];
          final checkLockUseCase = ref.read(checkCallLockStatusUseCaseProvider);

          for (final world in worlds) {
            final calls = allCalls
                .where((c) => world.containsCall(c))
                .toList();
            final nodes = <MapNode>[];
            for (int i = 0; i < calls.length; i++) {
              final call = calls[i];
              final score = bestScores[call.id];
              NodeState nodeState;
              if (score != null && score >= 70) {
                nodeState = NodeState.mastered;
              } else {
                nodeState = NodeState.available;
              }
              nodes.add(MapNode(
                call: call,
                index: i + 1,
                position: getNodePosition(i, calls.length),
                state: nodeState,
                bestScore: score,
              ));
            }

            // Mark first non-mastered as current
            bool foundCurrent = false;
            for (final n in nodes) {
              if (n.state == NodeState.available && !foundCurrent) {
                n.state = NodeState.current;
                foundCurrent = true;
              }
            }

            // Lock premium calls
            for (final n in nodes) {
              final lockResult = checkLockUseCase.execute(callId: n.call.id, isUserPremium: profile.isPremium);
              lockResult.fold(
                (failure) => AppLogger.d('Lock check error: ${failure.message}'),
                (isLocked) {
                  if (isLocked && n.state != NodeState.mastered) {
                    n.state = NodeState.locked;
                  }
                },
              );
            }

            newWorldNodes.add(nodes);
          }

          state = state.copyWith(worldNodes: newWorldNodes, isLoading: false);
        },
      );
    } catch (e) {
      AppLogger.d('ProgressMap Error: $e');
      state = state.copyWith(isLoading: false);
    }
  }
}

final progressMapNotifierProvider =
    NotifierProvider.autoDispose<ProgressMapNotifier, ProgressMapState>(ProgressMapNotifier.new);

// ──────────────────────────────────────────────────────────
//  HELPER
// ──────────────────────────────────────────────────────────

/// Calculates a grid position for a node, with slight organic jitter.
Offset getNodePosition(int index, int total) {
  const int cols = 3;
  const double padX = 0.15;
  const double padTop = 0.10;
  const double padBot = 0.06;

  final int row = index ~/ cols;
  final int col = index % cols;
  final int totalRows = (total / cols).ceil();
  final bool leftToRight = row.isEven;
  final double colFraction = cols > 1 ? col / (cols - 1) : 0.5;
  final double x =
      padX + (1 - 2 * padX) * (leftToRight ? colFraction : 1 - colFraction);
  final double rowSpacing =
      totalRows > 1 ? (1 - padTop - padBot) / totalRows : 0.4;
  final double y = padTop + rowSpacing * (row + 0.5);

  final rng = Random(index * 7 + total * 13);
  final jitterX = (rng.nextDouble() - 0.5) * 0.04;
  final jitterY = (rng.nextDouble() - 0.5) * 0.02;

  return Offset(
    (x + jitterX).clamp(0.1, 0.9),
    (y + jitterY).clamp(0.05, 0.95),
  );
}
