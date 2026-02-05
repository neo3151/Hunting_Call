import 'dart:io';

void main() async {
  final String ffmpegPath = 'scripts/ffmpeg.exe';
  final String sourceDir = 'temp_audio';
  final String destDir = 'assets/audio';
  
  // Mapping for Full 50-Animal Biological Library
  final Map<String, String> mapping = {
    // Predators
    'dthowl.mp3': 'coyote_howl.wav',
    'jackrabbit.mp3': 'rabbit_distress.wav',
    'hurtpup1.mp3': 'fox_scream.wav',
    'elkpowerhowl.mp3': 'wolf_howl.wav', 
    'gray_fox.mp3': 'gray_fox.wav',
    'bobcat.mp3': 'bobcat.wav',
    'raccoon.mp3': 'raccoon.wav',
    'wolf_bark.mp3': 'wolf_bark.wav',
    'badger.mp3': 'badger.wav',
    'cougar_scream.mp3': 'cougar.wav',
    
    // Big Game
    'elkpowerhowl.mp3': 'elk_bull_bugle.wav',
    'elkchatterhowl.mp3': 'elk_cow_mew.wav',
    'moose_test_2.wav': 'moose_bull_grunt.wav',
    'moose_cow.wav': 'moose_cow_call.wav',
    'bear_bawl.wav': 'black_bear_bawl.wav',
    'hog_grunt.wav': 'hog.wav',
    'deer_test.wav': 'deer_buck_grunt.wav',
    'red_stag_roar.wav': 'red_stag.wav',
    'fallow.mp3': 'fallow.wav',
    'mule_deer.mp3': 'mule_deer.wav',
    'caribou.mp3': 'caribou.wav',
    'pronghorn.mp3': 'pronghorn.wav',

    // Waterfowl
    'goose_canadian_honk.mp3': 'goose_canadian_honk.wav',
    'goose_cluck.mp3': 'goose_cluck.wav',
    'snow_goose_bark.mp3': 'snow_goose.wav',
    'specklebelly_yodel.mp3': 'specklebelly.wav',
    'wood_duck_whistle.mp3': 'wood_duck.wav',
    'wood_duck_sit.mp3': 'wood_duck_sit.wav',
    'pintail_whistle.mp3': 'pintail.wav',
    'teal_blue_winged.mp3': 'teal.wav',
    'canvasback_grunt.mp3': 'canvasback.wav',
    'mallard_hen.mp3': 'mallard_hen.wav',

    // Land Birds
    'turkey_gobble.mp3': 'turkey_gobble.wav',
    'turkey_hen_yelp.mp3': 'turkey_hen_yelp.wav',
    'turkey_cluck_purr.mp3': 'turkey_purr.wav',
    'turkey_tree_yelp.mp3': 'turkey_tree.wav',
    'owl_barred_hoot.mp3': 'owl_barred_hoot.wav',
    'great_horned_owl.mp3': 'gho.wav',
    'crow_caw.mp3': 'crow.wav',
    'crow_fight.mp3': 'crow_fight.wav',
    'quail_bobwhite.mp3': 'quail.wav',
    'pheasant_crow.mp3': 'pheasant.wav',
    'dove_coo.mp3': 'dove.wav',
    'woodcock_peent.mp3': 'woodcock.wav',
    'grouse_drum.mp3': 'grouse.wav',
  };

  print("--- BATCH CONVERSION & NORMALIZATION ---");
  
  if (!File(ffmpegPath).existsSync()) {
    print("Error: ffmpeg not found at $ffmpegPath");
    return;
  }

  for (var entry in mapping.entries) {
    final String src = "$sourceDir/${entry.key}";
    final String dest = "$destDir/${entry.value}";
    
    if (File(src).existsSync()) {
      print("Processing ${entry.key} -> ${entry.value}...");
      
      // FFmpeg command: Mono, 44.1kHz, -3dB Normalize, 10s Trim
      final result = await Process.run(ffmpegPath, [
        '-y',
        '-i', src,
        '-ac', '1',
        '-ar', '44100',
        '-af', 'loudnorm=I=-16:TP=-3:LRA=11',
        '-t', '10',
        dest
      ]);
      
      if (result.exitCode == 0) {
        print("  [OK] Converted and Normalized.");
      } else {
        print("  [ERROR] Failed: ${result.stderr}");
      }
    }
  }

  print("\nDone! Now run 'dart run scripts/calibrate_calls.dart' to update the database.");
}
