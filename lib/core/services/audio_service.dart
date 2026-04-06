import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/core/services/cloud_audio_service.dart';
import 'package:outcall/core/utils/app_logger.dart';

/// Global audio service for playing reference call audio across the app.
/// Prevents memory leaks by centralizing AudioPlayer lifecycle management.
///
/// Supports both bundled assets AND cloud-downloaded cached files via CloudAudioService.
class AudioService extends Notifier<String?> {
  final AudioPlayer _player = AudioPlayer();
  late final CloudAudioService _cloudAudio;

  @override
  String? build() {
    _cloudAudio = ref.read(cloudAudioServiceProvider);
    
    // Single listener for player completion - prevents listener leaks
    _player.onPlayerComplete.listen((_) {
      state = null;
    });

    ref.onDispose(() {
      _player.dispose();
      AppLogger.d('AudioService: Disposed');
    });

    return null; // Initial currentlyPlayingId
  }

  String? get currentlyPlayingId => state;
  bool get isPlaying => state != null;

  /// Play a call by resolving its source automatically.
  /// If the call is free, plays from bundled assets.
  /// If paid, downloads from cloud (or serves from cache) and plays.
  Future<void> play(String callId, String assetPath, {bool isDiagnostic = false}) async {
    try {
      if (state == callId) {
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
      state = callId;
      AppLogger.d(
          'AudioService: Playing $callId (${source.isAsset ? "asset" : "cached"}) [Diagnostic: $isDiagnostic]');
    } catch (e) {
      AppLogger.d('AudioService: Error playing $callId - $e');
      state = null;
      rethrow;
    }
  }

  /// Play an asset directly (legacy method, kept for compatibility).
  Future<void> playAsset(String assetPath, String id, {bool isDiagnostic = false}) async {
    try {
      if (state == id) {
        await stop();
        return;
      }

      await _player.stop();
      await _player.play(ap.AssetSource(assetPath));
      state = id;
      AppLogger.d('AudioService: Playing $id [Diagnostic: $isDiagnostic]');
    } catch (e) {
      AppLogger.d('AudioService: Error playing $id - $e');
      state = null;
      rethrow;
    }
  }

  /// Stop current playback
  Future<void> stop() async {
    await _player.stop();
    state = null;
    AppLogger.d('AudioService: Stopped');
  }
}

// Re-export AudioPlayer type for consumers that need it directly
typedef AudioPlayer = ap.AudioPlayer;

/// Riverpod 3 provider for global audio service
final audioServiceProvider = NotifierProvider<AudioService, String?>(AudioService.new);
