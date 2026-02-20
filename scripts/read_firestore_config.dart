import 'package:firedart/firedart.dart';
import 'dart:io';

Future<void> main() async {
  const projectId = 'hunting-call-perfection';
  const apiKey = 'AIzaSyC7zcpxfRV13kHdI6yUzIKzDxWcgWm-EFQ';

  print('Initializing Firedart...');
  FirebaseAuth.initialize(apiKey, VolatileStore());
  Firestore.initialize(projectId);

  final auth = FirebaseAuth.instance;
  if (!auth.isSignedIn) {
    print('Signing in anonymously...');
    await auth.signInAnonymously();
  }

  print('Reading config/app_v1...');
  try {
    final doc = await Firestore.instance.collection('config').document('app_v1').get();
    print('Current config: ${doc.map}');
  } catch (e) {
    print('Error: $e');
  }
}
