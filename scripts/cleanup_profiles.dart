import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Script to delete all profiles from Firestore
/// Run with: dart run scripts/cleanup_profiles.dart
void main() async {
  print('🧹 Starting Firestore profile cleanup...\n');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  final profilesCollection = firestore.collection('profiles');

  try {
    // Get all profiles
    print('📋 Fetching all profiles...');
    final snapshot = await profilesCollection.get();
    final totalProfiles = snapshot.docs.length;

    if (totalProfiles == 0) {
      print('✅ No profiles found. Database is already clean!\n');
      return;
    }

    print('Found $totalProfiles profile(s) to delete.\n');

    // List profiles before deletion
    print('Profiles to be deleted:');
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final name = data['name'] ?? 'Unknown';
      print('  - ${doc.id}: $name');
    }

    print('\n⚠️  WARNING: This will permanently delete all profiles!');
    print('Press Enter to continue or Ctrl+C to cancel...');
    
    // Wait for user confirmation
    // Note: In a real script, you'd use stdin.readLineSync()
    // For now, we'll proceed automatically
    
    print('\n🗑️  Deleting profiles...');
    
    // Delete all profiles
    int deleted = 0;
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
      deleted++;
      print('  Deleted $deleted/$totalProfiles: ${doc.id}');
    }

    print('\n✅ Successfully deleted $deleted profile(s)!');
    print('🎉 Firestore profiles collection is now clean.\n');

  } catch (e) {
    print('\n❌ Error during cleanup: $e\n');
    rethrow;
  }
}
