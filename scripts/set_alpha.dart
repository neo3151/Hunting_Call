import 'package:firedart/firedart.dart';
import 'dart:io';

Future<void> main() async {
  const projectId = 'hunting-call-perfection';
  final apiKey = Platform.environment['FIREBASE_API_KEY'];
  final email = Platform.environment['FIREBASE_ADMIN_EMAIL'];
  final password = Platform.environment['FIREBASE_ADMIN_PASSWORD'];
  if (apiKey == null || email == null || password == null) {
    print('❌ Set FIREBASE_API_KEY, FIREBASE_ADMIN_EMAIL, FIREBASE_ADMIN_PASSWORD env vars first');
    exit(1);
  }

  FirebaseAuth.initialize(apiKey, VolatileStore());
  Firestore.initialize(projectId);

  final auth = FirebaseAuth.instance;
  try {
    await auth.signIn(email, password);
    final user = await auth.getUser();
    print('Signed in successfully.');

    final collection = Firestore.instance.collection('profiles');
    await collection.document(user.id).update({'isAlphaTester': true});
    print('Successfully updated isAlphaTester to true!');
  } catch (e) {
    print('Failed to update: $e');
  }
}
