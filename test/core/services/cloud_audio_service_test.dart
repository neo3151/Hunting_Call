import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/core/services/cloud_audio_service.dart';
import 'package:outcall/config/freemium_config.dart';

void main() {
  group('AudioSource', () {
    test('asset source has isAsset = true', () {
      final source = AudioSource.asset('audio/calls/elk_bugle.mp3');
      expect(source.isAsset, true);
      expect(source.path, 'audio/calls/elk_bugle.mp3');
    });

    test('file source has isAsset = false', () {
      final source = AudioSource.file('/data/cache/elk_bugle.mp3');
      expect(source.isAsset, false);
      expect(source.path, '/data/cache/elk_bugle.mp3');
    });

    test('asset and file sources are distinct types', () {
      final asset = AudioSource.asset('audio/test.mp3');
      final file = AudioSource.file('/tmp/test.mp3');
      expect(asset.isAsset, isNot(equals(file.isAsset)));
    });

    test('preserves path exactly as given', () {
      final source = AudioSource.asset('assets/audio/calls/with spaces/file.mp3');
      expect(source.path, 'assets/audio/calls/with spaces/file.mp3');
    });
  });

  group('CloudAudioService.isBundled', () {
    late CloudAudioService service;

    setUp(() {
      service = CloudAudioService();
    });

    test('returns true for free call IDs', () {
      // Test a few known free calls
      expect(service.isBundled('duck_mallard_greeting'), true);
      expect(service.isBundled('turkey_gobble'), true);
      expect(service.isBundled('deer_buck_grunt'), true);
      expect(service.isBundled('coyote_howl'), true);
    });

    test('returns false for premium call IDs', () {
      expect(service.isBundled('elk_bugle'), false);
      expect(service.isBundled('wolf_howl'), false);
      expect(service.isBundled('bobcat_growl'), false);
      expect(service.isBundled('some_nonexistent_call'), false);
    });

    test('returns true for all configured free call IDs', () {
      for (final id in FreemiumConfig.freeCallIds) {
        expect(service.isBundled(id), true,
            reason: 'Expected $id to be bundled');
      }
    });

    test('returns false for empty string', () {
      expect(service.isBundled(''), false);
    });

    test('is case-sensitive', () {
      // IDs are lowercase; wrong case should fail
      expect(service.isBundled('TURKEY_GOBBLE'), false);
      expect(service.isBundled('Turkey_Gobble'), false);
    });
  });
}
