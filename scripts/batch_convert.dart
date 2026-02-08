import 'dart:io';

void main() async {
  final String ffmpegPath = 'scripts/ffmpeg.exe';
  final String sourceDir = 'temp_audio';
  final String destDir = 'assets/audio';
  
  final Map<String, String> mapping = {
    // Batch 1 Replacements
    'duck_mallard_feed.mp3': 'mallard_hen.wav',
    'goose_canadian_honk.mp3': 'goose_canadian_honk.wav',
    'goose_snow_bark.mp3': 'snow_goose.wav',
    'goose_specklebelly.mp3': 'specklebelly.wav',
    'turkey_hen_yelp.mp3': 'turkey_hen_yelp.wav',
    'owl_barred_hoot.mp3': 'owl_barred_hoot.wav',
    'elk_bull_bugle.mp3': 'elk_bull_bugle.wav',
    'coyote.mp3': 'coyote_howl.wav',
    'wolf_pack_howl.mp3': 'wolf_howl.wav',
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
