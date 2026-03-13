import 'package:firedart/firedart.dart';
import 'dart:io';

Future<void> main() async {
  const projectId = 'hunting-call-perfection';
  final apiKey = Platform.environment['FIREBASE_API_KEY'];
  if (apiKey == null) {
    print('❌ Set FIREBASE_API_KEY env var first');
    exit(1);
  }

  print('Initializing Firedart...');
  FirebaseAuth.initialize(apiKey, VolatileStore());
  Firestore.initialize(projectId);

  final auth = FirebaseAuth.instance;
  if (!auth.isSignedIn) {
    print('Signing in anonymously...');
    await auth.signInAnonymously();
  }

  print('Updating config/app_v1 to min_version: 1.5.0...');
  try {
    final collection = Firestore.instance.collection('config');
    await collection.document('app_v1').update({
      'min_version': '1.5.0',
      'last_updated': DateTime.now().toIso8601String(),
    });
    print('✅ Firestore updated successfully!');
    
    // Verify update
    final doc = await collection.document('app_v1').get();
    print('New config: ${doc.map}');
  } catch (e) {
    print('❌ Error: $e');
  }
}
