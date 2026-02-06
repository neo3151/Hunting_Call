import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../features/leaderboard/data/leaderboard_service.dart';
import '../features/leaderboard/domain/leaderboard_entry.dart';

final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  return GetIt.I<LeaderboardService>();
});

final leaderboardScoresProvider = StreamProvider.family<List<LeaderboardEntry>, String>((ref, animalId) {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getTopScores(animalId);
});

class LeaderboardNotifier extends StateNotifier<AsyncValue<void>> {
  final LeaderboardService _service;

  LeaderboardNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> submitScore({
    required String animalId,
    required LeaderboardEntry entry,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.submitScore(animalId: animalId, entry: entry);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final leaderboardNotifierProvider = StateNotifierProvider<LeaderboardNotifier, AsyncValue<void>>((ref) {
  return LeaderboardNotifier(ref.watch(leaderboardServiceProvider));
});
