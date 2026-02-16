import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hunting_calls_perfection/core/utils/app_logger.dart';

/// Global audio service for playing reference call audio across the app.
/// Prevents memory leaks by centralizing AudioPlayer lifecycle management.
class AudioService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentlyPlayingId;
  
  String? get currentlyPlayingId => _currentlyPlayingId;
  bool get isPlaying => _currentlyPlayingId != null;
  
  AudioService() {
    // Single listener for player completion - prevents listener leaks
    _player.onPlayerComplete.listen((_) {
      _currentlyPlayingId = null;
    });
  }
  
  /// Play an asset. If the same ID is playing, stop it (toggle behavior).
  Future<void> playAsset(String assetPath, String id) async {
    try {
      if (_currentlyPlayingId == id) {
        await stop();
        return;
      }
      
      await _player.stop();
      await _player.play(AssetSource(assetPath));
      _currentlyPlayingId = id;
      AppLogger.d('AudioService: Playing $id');
    } catch (e) {
      AppLogger.d('AudioService: Error playing $id - $e');
      _currentlyPlayingId = null;
      rethrow;
    }
  }
  
  /// Stop current playback
  Future<void> stop() async {
    await _player.stop();
    _currentlyPlayingId = null;
    AppLogger.d('AudioService: Stopped');
  }
  
  /// Dispose the audio player
  void dispose() {
    _player.dispose();
    AppLogger.d('AudioService: Disposed');
  }
}

/// Riverpod provider for global audio service
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// State provider for reactive UI updates when playback changes
final currentlyPlayingIdProvider = StateProvider<String?>((ref) {
  // This is a computed provider that watches the service
  // UI screens should watch this to get updates
  return null;
});
