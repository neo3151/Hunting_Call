import 'package:firedart/firedart.dart';

Future<void> main() async {
  const projectId = 'hunting-call-perfection';
  const apiKey = 'AIzaSyC7zcpxfRV13kHdI6yUzIKzDxWcgWm-EFQ';

  FirebaseAuth.initialize(apiKey, VolatileStore());
  Firestore.initialize(projectId);

  final auth = FirebaseAuth.instance;
  try {
    await auth.signIn('pongownsyou@gmail.com', 'alpha_password_123');
    final user = await auth.getUser();
    print('Signed in successfully.');

    final collection = Firestore.instance.collection('profiles');
    await collection.document(user.id).update({'isAlphaTester': true});
    print('Successfully updated isAlphaTester to true!');
  } catch (e) {
    print('Failed to update: $e');
  }
}
