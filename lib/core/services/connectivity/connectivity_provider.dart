import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a stream of connectivity changes
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// A provider that evaluates whether the app currently has an internet connection
final isOfflineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityStreamProvider);
  return connectivity.when(
    data: (results) {
      // If the result list is empty or only contains ConnectivityResult.none, we are offline.
      if (results.isEmpty || results.every((result) => result == ConnectivityResult.none)) {
        return true;
      }
      return false;
    },
    loading: () => false, // Assume online while loading to avoid flashing offline state
    error: (_, __) => true, // If we fail to check, assume offline to be safe
  );
});
