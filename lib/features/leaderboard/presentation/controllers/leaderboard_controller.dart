import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_service.dart';
import 'package:hunting_calls_perfection/di_providers.dart';

final leaderboardScoresProvider = StreamProvider.family<List<LeaderboardEntry>, String>((ref, animalId) {
  final service = ref.watch(leaderboardServiceProvider);
  if (service == null) return const Stream.empty();
  return service.getTopScores(animalId);
});

class LeaderboardNotifier extends StateNotifier<AsyncValue<void>> {
  final LeaderboardService? _service;

  LeaderboardNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> submitScore({
    required String animalId,
    required LeaderboardEntry entry,
  }) async {
    if (_service == null) return;
    state = const AsyncValue.loading();
    try {
      await _service!.submitScore(animalId: animalId, entry: entry);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final leaderboardNotifierProvider = StateNotifierProvider<LeaderboardNotifier, AsyncValue<void>>((ref) {
  return LeaderboardNotifier(ref.watch(leaderboardServiceProvider));
});
