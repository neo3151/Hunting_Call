import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  final String ffmpegPath = 'ffmpeg';
  final String assetsDir = 'assets/audio';
  final String dataFile = 'assets/data/reference_calls.json';
  
  print("--- AUDIO OPTIMIZATION SCRIPT ---");
  
  
  // Checking for system ffmpeg is implicit in the Process.run call or could be done with 'where' command if needed, 
  // but for now we assume it's in PATH as verified.

  
  if (!File(dataFile).existsSync()) {
    print("Error: Data file not found at $dataFile");
    return;
  }

  // 1. Load Reference Data
  final jsonString = await File(dataFile).readAsString();
  final Map<String, dynamic> data = jsonDecode(jsonString);
  final List<dynamic> calls = data['calls'];
  
  Map<String, double> durationMap = {};
  
  for (var call in calls) {
    String assetPath = call['audioAssetPath'];
    // Normalize path separators
    assetPath = assetPath.replaceAll('/', p.separator);
    
    // Extract filename
    String filename = p.basename(assetPath);
    
    double duration = (call['idealDurationSec'] as num).toDouble();
    if (duration < 3.0) duration = 5.0; // Minimum reasonable duration
    
    durationMap[filename] = duration;
  }
  
  // 2. Process Files
  final dir = Directory(assetsDir);
  final List<FileSystemEntity> files = dir.listSync();
  
  int successCount = 0;
  int errorCount = 0;
  int skippedCount = 0;
  
  for (var entity in files) {
    if (entity is File && p.extension(entity.path) == '.wav') {
      String filename = p.basename(entity.path);
      
      // Default to 15s if not found in map
      double targetDuration = durationMap[filename] ?? 15.0;
      
      // Add buffer
      targetDuration += 2.0; 
      
      print("Processing $filename (Target: ${targetDuration.toStringAsFixed(1)}s)...");
      
      // Create temp file
      String tempPath = "${entity.path}.temp.wav";
      
      // Run ffmpeg
      // -t duration: trim
      // -ac 1: mono
      // -ar 44100: sample rate
      // -c:a pcm_s16le: codec
      
      final result = await Process.run(ffmpegPath, [
        '-y',
        '-i', entity.path,
        '-t', targetDuration.toString(),
        '-ac', '1',
        '-ar', '44100', 
        '-c:a', 'pcm_s16le',
        tempPath
      ]);
      
      if (result.exitCode == 0) {
        // Replace original
        final tempFile = File(tempPath);
        if (await tempFile.exists()) {
             // Check size difference
            int oldSize = await entity.length();
            int newSize = await tempFile.length();
            
            if (newSize < oldSize) {
                await tempFile.copy(entity.path);
                await tempFile.delete();
                print("  [OK] Reduced: ${(oldSize / 1024).toStringAsFixed(1)}KB -> ${(newSize / 1024).toStringAsFixed(1)}KB");
                successCount++;
            } else {
                print("  [SKIP] New file larger or same size. Keeping original.");
                await tempFile.delete();
                skippedCount++;
            }
        }
      } else {
        print("  [ERROR] FFmpeg failed: ${result.stderr}");
        errorCount++;
      }
    }
  }
  
  print("\n--- SUMMARY ---");
  print("Success: $successCount");
  print("Skipped: $skippedCount");
  print("Errors:  $errorCount");
}
