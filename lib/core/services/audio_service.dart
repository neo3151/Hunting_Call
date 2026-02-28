import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/core/services/cloud_audio_service.dart';

/// Global audio service for playing reference call audio across the app.
/// Prevents memory leaks by centralizing AudioPlayer lifecycle management.
/// 
/// Supports both bundled assets AND cloud-downloaded cached files via CloudAudioService.
class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final CloudAudioService _cloudAudio;
  String? _currentlyPlayingId;
  
  String? get currentlyPlayingId => _currentlyPlayingId;
  bool get isPlaying => _currentlyPlayingId != null;
  
  AudioService(this._cloudAudio) {
    // Single listener for player completion - prevents listener leaks
    _player.onPlayerComplete.listen((_) {
      _currentlyPlayingId = null;
    });
  }
  
  /// Play a call by resolving its source automatically.
  /// If the call is free, plays from bundled assets.
  /// If paid, downloads from cloud (or serves from cache) and plays.
  Future<void> play(String callId, String assetPath) async {
    try {
      if (_currentlyPlayingId == callId) {
        await stop();
        return;
      }
      
      await _player.stop();
      
      final source = await _cloudAudio.resolveAudioSource(callId, assetPath);
      if (source.isAsset) {
        await _player.play(ap.AssetSource(source.path));
      } else {
        await _player.play(ap.DeviceFileSource(source.path));
      }
      _currentlyPlayingId = callId;
      AppLogger.d('AudioService: Playing $callId (${source.isAsset ? "asset" : "cached"})');
    } catch (e) {
      AppLogger.d('AudioService: Error playing $callId - $e');
      _currentlyPlayingId = null;
      rethrow;
    }
  }

  /// Play an asset directly (legacy method, kept for compatibility).
  Future<void> playAsset(String assetPath, String id) async {
    try {
      if (_currentlyPlayingId == id) {
        await stop();
        return;
      }
      
      await _player.stop();
      await _player.play(ap.AssetSource(assetPath));
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

// Re-export AudioPlayer type for consumers that need it directly
typedef AudioPlayer = ap.AudioPlayer;

/// Riverpod provider for global audio service
final audioServiceProvider = Provider<AudioService>((ref) {
  final cloudAudio = ref.read(cloudAudioServiceProvider);
  final service = AudioService(cloudAudio);
  ref.onDispose(() => service.dispose());
  return service;
});

/// State provider for reactive UI updates when playback changes
class CurrentlyPlayingIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
}

final currentlyPlayingIdProvider = NotifierProvider<CurrentlyPlayingIdNotifier, String?>(CurrentlyPlayingIdNotifier.new);
