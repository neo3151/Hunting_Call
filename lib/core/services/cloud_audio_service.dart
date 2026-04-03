import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:outcall/config/freemium_config.dart';
import 'package:outcall/core/utils/app_logger.dart';

/// Service for resolving audio file paths.
///
/// Free calls: served from bundled assets (instant, offline).
/// Paid calls: downloaded from Firebase Storage on first play, then cached locally.
class CloudAudioService {
  static const String _storagePath = 'audio/calls';
  static const String _cacheDir = 'audio_cache';

  Directory? _cacheDirectory;

  /// Initialize the cache directory
  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDirectory = Directory('${appDir.path}/$_cacheDir');
    if (!await _cacheDirectory!.exists()) {
      await _cacheDirectory!.create(recursive: true);
    }
    AppLogger.d('CloudAudioService: Cache dir initialized at ${_cacheDirectory!.path}');
  }

  /// Check if a call's audio is bundled (free) or needs cloud download
  bool isBundled(String callId) {
    return FreemiumConfig.freeCallIds.contains(callId);
  }

  /// Check if an asset exists in the bundle (useful for debug overrides)
  Future<bool> _isAssetAvailable(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Bump this version to force all client devices to bypass their local cache
  /// and re-download fresh audio assets from Firebase Storage.
  static const int _audioCacheVersion = 2;

  /// Get the local cache path for a call's audio file
  Future<String> _getCachePath(String callId, String assetPath) async {
    if (_cacheDirectory == null) {
      await init();
    }
    final fileName = assetPath.split('/').last;
    return '${_cacheDirectory!.path}/v${_audioCacheVersion}_$fileName';
  }

  /// Check if audio is already cached locally
  Future<bool> isAudioCached(String callId, String assetPath) async {
    if (isBundled(callId)) return true; // Bundled = always available
    final cachePath = await _getCachePath(callId, assetPath);
    return File(cachePath).exists();
  }

  /// Resolve the audio source for a call.
  /// 
  /// Returns an [AudioSource] which indicates whether to use an asset or a file path.
  Future<AudioSource> resolveAudioSource(String callId, String assetPath) async {
    // Free calls: serve from bundled assets
    if (isBundled(callId)) {
      final strippedPath = assetPath.replaceFirst('assets/', '');
      return AudioSource.asset(strippedPath);
    }

    // DEBUG OVERRIDE: Prioritize local assets over cached/cloud versions during development
    if (kDebugMode && await _isAssetAvailable(assetPath)) {
      final strippedPath = assetPath.replaceFirst('assets/', '');
      AppLogger.d('CloudAudioService: DEBUG OVERRIDE - Serving $callId from local assets');
      return AudioSource.asset(strippedPath);
    }

    // Paid calls: check cache first
    final cachePath = await _getCachePath(callId, assetPath);
    if (await File(cachePath).exists()) {
      AppLogger.d('CloudAudioService: Serving $callId from cache');
      return AudioSource.file(cachePath);
    }

    // Download from Firebase Storage with retry
    AppLogger.d('CloudAudioService: Downloading $callId from cloud...');
    const maxRetries = 3;
    Exception? lastError;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final fileName = assetPath.split('/').last;
        final file = File(cachePath);
        
        if (Platform.isWindows || Platform.isLinux) {
          const bucket = 'hunting-call-perfection.firebasestorage.app';
          final path = Uri.encodeComponent('$_storagePath/$fileName');
          final url = 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$path?alt=media';
          
          final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
          if (response.statusCode == 200) {
            await file.writeAsBytes(response.bodyBytes);
          } else {
            throw Exception('Failed to download audio: Http status ${response.statusCode}');
          }
        } else {
          final ref = FirebaseStorage.instance.ref('$_storagePath/$fileName');
          await ref.writeToFile(file);
        }
        
        AppLogger.d('CloudAudioService: Downloaded $callId (${await file.length()} bytes)');
        return AudioSource.file(cachePath);
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        if (attempt < maxRetries) {
          final delay = Duration(seconds: 1 << (attempt - 1)); // 1s, 2s, 4s
          AppLogger.d('CloudAudioService: Download attempt $attempt failed for $callId, retrying in ${delay.inSeconds}s...');
          await Future.delayed(delay);
        }
      }
    }
    
    // All retries exhausted — try bundled asset fallback
    AppLogger.d('CloudAudioService: All $maxRetries download attempts failed for $callId: $lastError');
    try {
      final strippedPath = assetPath.replaceFirst('assets/', '');
      await rootBundle.load('assets/$strippedPath');
      return AudioSource.asset(strippedPath);
    } catch (e) {
      AppLogger.d('CloudAudioService: Fallback asset load also failed for $callId: $e');
      rethrow;
    }
  }

  /// Resolve a local file path for analysis purposes (rootBundle replacement).
  ///
  /// For bundled assets, extracts to temp. For cloud assets, downloads to cache.
  Future<String> resolveFilePath(String callId, String assetPath) async {
    if (isBundled(callId) || (kDebugMode && await _isAssetAvailable(assetPath))) {
      // Extract bundled asset to a temp file for file-based access
      if (kDebugMode && !isBundled(callId)) {
        AppLogger.d('CloudAudioService: DEBUG OVERRIDE - Extracting $callId from local assets');
      }
      final ByteData data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/ref_$callId.wav');
      await tempFile.writeAsBytes(bytes);
      return tempFile.path;
    }

    // Paid calls: download to cache if needed
    final cachePath = await _getCachePath(callId, assetPath);
    if (await File(cachePath).exists()) {
      return cachePath;
    }

    // Download from cloud
    final fileName = assetPath.split('/').last;
    final file = File(cachePath);
    
    if (Platform.isWindows || Platform.isLinux) {
      const bucket = 'hunting-call-perfection.firebasestorage.app';
      final path = Uri.encodeComponent('$_storagePath/$fileName');
      final url = 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$path?alt=media';
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
      } else {
        throw Exception('Failed to download audio: Http status ${response.statusCode}');
      }
    } else {
      final ref = FirebaseStorage.instance.ref('$_storagePath/$fileName');
      await ref.writeToFile(file);
    }
    
    return cachePath;
  }

  /// Prefetch audio for a specific call (e.g., daily challenge)
  Future<void> prefetchAudio(String callId, String assetPath) async {
    if (isBundled(callId)) return; // Already bundled

    // DEBUG OVERRIDE: If the asset is locally available, skip prefetch
    if (kDebugMode && await _isAssetAvailable(assetPath)) return;

    if (await isAudioCached(callId, assetPath)) return; // Already cached

    try {
      await resolveAudioSource(callId, assetPath);
      AppLogger.d('CloudAudioService: Prefetched $callId');
    } catch (e) {
      AppLogger.d('CloudAudioService: Prefetch failed for $callId: $e');
    }
  }

  /// Get total cache size in bytes
  Future<int> getCacheSize() async {
    if (_cacheDirectory == null || !await _cacheDirectory!.exists()) return 0;
    int total = 0;
    await for (final entity in _cacheDirectory!.list()) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  /// Clear the audio cache
  Future<void> clearCache() async {
    if (_cacheDirectory != null && await _cacheDirectory!.exists()) {
      await _cacheDirectory!.delete(recursive: true);
      await _cacheDirectory!.create(recursive: true);
      AppLogger.d('CloudAudioService: Cache cleared');
    }
  }
}

/// Represents where to load audio from
class AudioSource {
  final String path;
  final bool isAsset;

  const AudioSource._(this.path, this.isAsset);

  /// Bundled asset source
  factory AudioSource.asset(String assetPath) => AudioSource._(assetPath, true);

  /// Local file source (cached download)
  factory AudioSource.file(String filePath) => AudioSource._(filePath, false);
}

/// Riverpod provider for CloudAudioService
final cloudAudioServiceProvider = Provider<CloudAudioService>((ref) {
  return CloudAudioService();
});
