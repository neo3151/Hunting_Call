import '../domain/reference_call_model.dart';

class MockReferenceDatabase {
  static const List<ReferenceCall> calls = [
    ReferenceCall(
      id: 'duck_mallard_greeting',
      animalName: 'Mallard Duck (Greeting)',
      idealPitchHz: 479.0, // Scientifically verified: ~479Hz fundamental
      idealDurationSec: 1.2,
      audioAssetPath: 'assets/audio/duck_mallard_greeting.ogg',
      tolerancePitch: 50.0,
    ),
    ReferenceCall(
      id: 'elk_bull_bugle',
      animalName: 'Elk (Bull Bugle)',
      idealPitchHz: 2000.0, // High whistle fundamental is ~2kHz
      idealDurationSec: 3.0,
      audioAssetPath: 'assets/audio/elk_bull_bugle.ogg',
      tolerancePitch: 200.0, // Wider tolerance for high pitch calls
    ),
    ReferenceCall(
      id: 'deer_buck_grunt',
      animalName: 'Whitetail Buck (Grunt)',
      idealPitchHz: 120.0, 
      idealDurationSec: 0.8,
      audioAssetPath: 'assets/audio/deer_buck_grunt.wav',
      tolerancePitch: 30.0,
    ),
    ReferenceCall(
      id: 'turkey_hen_yelp',
      animalName: 'Turkey Hen (Yelp)',
      idealPitchHz: 1000.0, // Peak frequency ~1kHz
      idealDurationSec: 0.5,
      audioAssetPath: 'assets/audio/turkey_hen_yelp.wav',
      tolerancePitch: 100.0,
    ),
    ReferenceCall(
      id: 'coyote_howl',
      animalName: 'Coyote (Howl)',
      idealPitchHz: 1000.0, // Variable, but 1kHz is a strong center point
      idealDurationSec: 2.5,
      audioAssetPath: 'assets/audio/coyote_howl.ogg',
      tolerancePitch: 200.0,
    ),
    ReferenceCall(
      id: 'goose_canadian_honk',
      animalName: 'Canadian Goose (Honk)',
      idealPitchHz: 400.0,
      idealDurationSec: 0.4,
      audioAssetPath: 'assets/audio/goose_canadian_honk.ogg',
      tolerancePitch: 50.0,
    ),
    ReferenceCall(
      id: 'owl_barred_hoot',
      animalName: 'Barred Owl',
      idealPitchHz: 550.0, // Research says ~548Hz-613Hz
      idealDurationSec: 1.5,
      audioAssetPath: 'assets/audio/owl_barred_hoot.ogg',
      tolerancePitch: 50.0,
    ),
  ];

  static ReferenceCall getById(String id) {
    return calls.firstWhere((c) => c.id == id, orElse: () => calls.first);
  }
}
