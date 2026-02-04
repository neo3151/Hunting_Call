import '../domain/reference_call_model.dart';

class ReferenceDatabase {
  static const List<ReferenceCall> calls = [
    ReferenceCall(
      id: 'duck_mallard_greeting',
      animalName: 'Mallard Duck (Greeting)',
      idealPitchHz: 712.0, // Refined Fundamental
      idealDurationSec: 5.22,
      audioAssetPath: 'assets/audio/duck_mallard_greeting.wav',
      tolerancePitch: 80.0,
      toleranceDuration: 0.8,
    ),
    ReferenceCall(
      id: 'elk_bull_bugle',
      animalName: 'Elk (Bull Bugle)',
      idealPitchHz: 1156.9, // Refined Fundamental
      idealDurationSec: 5.00,
      audioAssetPath: 'assets/audio/elk_bull_bugle.wav',
      tolerancePitch: 200.0,
      toleranceDuration: 1.5,
    ),
    ReferenceCall(
      id: 'deer_buck_grunt',
      animalName: 'Whitetail Buck (Grunt)',
      idealPitchHz: 353.5, // Refined Fundamental
      idealDurationSec: 10.00,
      audioAssetPath: 'assets/audio/deer_buck_grunt.wav',
      tolerancePitch: 60.0,
      toleranceDuration: 2.0,
    ),
    ReferenceCall(
      id: 'turkey_hen_yelp',
      animalName: 'Turkey Hen (Yelp)',
      idealPitchHz: 174.0,
      idealDurationSec: 6.72,
      audioAssetPath: 'assets/audio/turkey_hen_yelp.wav',
      tolerancePitch: 40.0,
      toleranceDuration: 0.8,
    ),
    ReferenceCall(
      id: 'coyote_howl',
      animalName: 'Coyote (Howl)',
      idealPitchHz: 479.6,
      idealDurationSec: 2.36,
      audioAssetPath: 'assets/audio/coyote_howl.wav',
      tolerancePitch: 100.0,
      toleranceDuration: 0.5,
    ),
    ReferenceCall(
      id: 'goose_canadian_honk',
      animalName: 'Canadian Goose (Honk)',
      idealPitchHz: 351.8,
      idealDurationSec: 2.26,
      audioAssetPath: 'assets/audio/goose_canadian_honk.wav',
      tolerancePitch: 60.0,
      toleranceDuration: 0.4,
    ),
    ReferenceCall(
      id: 'owl_barred_hoot',
      animalName: 'Barred Owl',
      idealPitchHz: 249.7,
      idealDurationSec: 5.32,
      audioAssetPath: 'assets/audio/owl_barred_hoot.wav',
      tolerancePitch: 50.0,
      toleranceDuration: 1.0,
    ),
    ReferenceCall(
      id: 'turkey_gobble',
      animalName: 'Turkey (Gobble)',
      idealPitchHz: 296.7,
      idealDurationSec: 2.72,
      audioAssetPath: 'assets/audio/turkey_gobble.wav',
      tolerancePitch: 100.0,
      toleranceDuration: 0.5,
    ),
    ReferenceCall(
      id: 'moose_cow_call',
      animalName: 'Moose (Cow Call)',
      idealPitchHz: 275.0,
      idealDurationSec: 0.39,
      audioAssetPath: 'assets/audio/moose_cow_call.wav',
      tolerancePitch: 50.0,
      toleranceDuration: 0.5,
    ),
    ReferenceCall(
      id: 'deer_doe_bleat',
      animalName: 'Whitetail Doe (Bleat)',
      idealPitchHz: 490.9,
      idealDurationSec: 1.20,
      audioAssetPath: 'assets/audio/deer_doe_bleat.wav',
      tolerancePitch: 70.0,
      toleranceDuration: 0.3,
    ),
    ReferenceCall(
      id: 'coyote_challenge',
      animalName: 'Coyote (Challenge Bark)',
      idealPitchHz: 796.9,
      idealDurationSec: 0.40,
      audioAssetPath: 'assets/audio/coyote_challenge.wav',
      tolerancePitch: 150.0,
      toleranceDuration: 0.2,
    ),
  ];

  static ReferenceCall getById(String id) {
    return calls.firstWhere((c) => c.id == id, orElse: () => calls.first);
  }
}
