import 'package:firedart/firedart.dart';
import 'dart:io';

/// This script replicates the exact logic used in the app's VersionCheckService
/// but pulls from the LIVE Firestore database to prove the system works.

bool isVersionOlder(String current, String minimum) {
  final currentParts = current.split('.').map(int.parse).toList();
  final minParts = minimum.split('.').map(int.parse).toList();

  for (var i = 0; i < 3; i++) {
    final currentPart = i < currentParts.length ? currentParts[i] : 0;
    final minPart = i < minParts.length ? minParts[i] : 0;

    if (currentPart < minPart) return true;
    if (currentPart > minPart) return false;
  }
  return false;
}

Future<void> main() async {
  const projectId = 'hunting-call-perfection';
  final apiKey = Platform.environment['FIREBASE_API_KEY'];
  if (apiKey == null) {
    print('❌ Set FIREBASE_API_KEY env var first');
    exit(1);
  }

  print('--- 🌐 OUTCALL LIVE GATEKEEPER PROOF ---');
  print('Step 1: Connecting to Live Firestore...');
  
  FirebaseAuth.initialize(apiKey, VolatileStore());
  Firestore.initialize(projectId);

  final auth = FirebaseAuth.instance;
  if (!auth.isSignedIn) {
    await auth.signInAnonymously();
  }

  print('Step 2: Fetching live min_version requirement...');
  final doc = await Firestore.instance.collection('config').document('app_v1').get();
  final minVersion = doc.map['min_version'] as String;
  final lastUpdate = doc.map['last_updated'] as String;
  
  print('Result: Live min_version is set to [$minVersion] (Updated: $lastUpdate)');
  print('-----------------------------------------');

  // Scenario A: Testing the OLD version (Pre-rollout)
  const legacyVersion = '1.4.0';
  final isBlockedA = isVersionOlder(legacyVersion, minVersion);
  print('Simulating Version $legacyVersion:');
  print(' > Gatekeeper Status: ${isBlockedA ? "🚨 BLOCKED (User must update)" : "✅ ALLOWED"}');

  // Scenario B: Testing the NEW version (Rollout)
  const currentVersion = '1.5.0';
  final isBlockedB = isVersionOlder(currentVersion, minVersion);
  print('\nSimulating Version $currentVersion (The New Standard):');
  print(' > Gatekeeper Status: ${isBlockedB ? "🚨 BLOCKED" : "✅ ALLOWED (Welcome to OUTCALL)"}');

  print('\nStep 3: Conclusion');
  if (isBlockedA && !isBlockedB) {
    print('✅ LIVE SYSTEM VERIFIED: Users on 1.4.0 are now effectively forced to upgrade to 1.5.0.');
  } else {
    print('❌ VERIFICATION FAILED: Logic or Cloud data mismatch.');
  }
}
