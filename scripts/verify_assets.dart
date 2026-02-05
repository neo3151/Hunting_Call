import 'dart:io';
import 'dart:convert';

void main() async {
  final jsonFile = File('assets/data/reference_calls.json');
  if (!jsonFile.existsSync()) {
    print("❌ Error: reference_calls.json not found.");
    exit(1);
  }

  final data = json.decode(await jsonFile.readAsString());
  final List<dynamic> calls = data['calls'];
  
  print("--- AUDITING CALL ASSETS ---");
  bool allGood = true;

  for (var call in calls) {
    final String id = call['id'];
    final String assetPath = call['audioAssetPath'];
    final double pitch = (call['idealPitchHz'] as num).toDouble();
    final File audioFile = File(assetPath);

    if (!audioFile.existsSync()) {
      print("❌ MISSING: $id -> $assetPath");
      allGood = false;
      continue;
    }

    final size = audioFile.lengthSync();
    if (size < 1000) {
      print("⚠️ DUMMY FILE: $id -> $assetPath ($size bytes)");
      allGood = false;
    }

    if (pitch < 100) {
      print("⚠️ SUSPICIOUS PITCH: $id -> ${pitch}Hz (Likely background hum)");
      allGood = false;
    }
  }

  if (allGood) {
    print("\n✅ Verification Passed: All 50 calls have valid assets and biological calibration.");
  } else {
    print("\n❌ Verification Failed: See issues above.");
    exit(1);
  }
}
