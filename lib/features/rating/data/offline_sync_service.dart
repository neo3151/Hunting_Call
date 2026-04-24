import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/features/rating/domain/rating_service.dart';
import 'package:outcall/features/rating/data/sqlite_outbox_repository.dart';

class OfflineSyncService {
  final SqliteOutboxRepository _outboxRepo;
  final RatingService _ratingService;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isSyncing = false;

  OfflineSyncService({
    required SqliteOutboxRepository outboxRepo,
    required RatingService ratingService,
  })  : _outboxRepo = outboxRepo,
        _ratingService = ratingService {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
        AppLogger.d('OfflineSyncService: Network restored. Attempting background sync.');
        syncPendingCalls();
      }
    });
  }

  /// Manually trigger a background sync of all pending offline calls.
  Future<void> syncPendingCalls() async {
    if (_isSyncing) return;
    
    final pendingCalls = await _outboxRepo.getPendingCalls();
    if (pendingCalls.isEmpty) return;

    _isSyncing = true;
    AppLogger.d('OfflineSyncService: Found \${pendingCalls.length} queued calls to sync.');

    for (final call in pendingCalls) {
      try {
        final result = await _ratingService.rateCall(
          call.userId,
          call.audioPath,
          call.animalType,
          isBackgroundSync: true, // Prevents duplicate outbox entries if this fails again
        );

        if (result.score >= 0) {
          // Successfully synced!
          await _outboxRepo.removeCall(call.id!);
          AppLogger.d('OfflineSyncService: Successfully synced call \${call.id}');
        } else {
          // It failed again (SocketException)
          await _outboxRepo.incrementAttempt(call.id!);
        }
      } catch (e) {
        AppLogger.e('OfflineSyncService: Failed to sync call \${call.id}', e, StackTrace.current);
        await _outboxRepo.incrementAttempt(call.id!);
      }
    }

    _isSyncing = false;
    AppLogger.d('OfflineSyncService: Sync cycle complete.');
  }

  void dispose() {
    _connectivitySubscription.cancel();
  }
}
