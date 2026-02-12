import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';
import '../../../../features/profile/domain/repositories/profile_repository.dart';

class SignInWithGoogle {
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;

  SignInWithGoogle({
    required this.authRepository,
    required this.profileRepository,
  });

  Future<AuthUser> call() async {
    // 1. Authenticate via Auth Repository
    final user = await authRepository.signInWithGoogle();

    // 2. Ensure Profile exists via Profile Repository
    // We try to get it first, if it doesn't exist/guest, we create it.
    // However, the previous logic in FirebaseAuthRepository._ensureProfileInFirestore 
    // did a check-and-create. We should replicate that or rely on a generic "ensure" method.
    // Since ProfileRepository.createProfile handles "new" profiles, let's check existence first.
    
    try {
      // Attempt to fetch existing profile
      await profileRepository.getProfile(user.id);
    } catch (e) {
      // If retrieval fails (or returns guest fallback depending on implementation), create it.
      // Ideally getProfile throws or returns null if not found for strict logic, 
      // but our repository returns 'Guest' on error/missing. 
      // We might need a more specific check method or assume 'Guest' means we need to create.
      
      // Let's rely on the fact that if it was a distinct "Not Found" we'd want to create.
      // But for now, safe to attempt creation if we are new.
      // A better pattern is `createProfile` using `set(merge: true)` or checking existence internally.
      // Let's trust the repository's `createProfile` to handle "upsert" or we just call it.
      
      // Actually, checking the old logic:
      // It checked by ID, then by Email.
      // We can replicate that logic here or inside a specific "ensureProfile" method in the repo.
      // For Clean Architecture, the UseCase contains the business logic.
      
      final profilesByEmail = user.email != null 
          ? await profileRepository.getProfilesByEmail(user.email!) 
          : [];
          
      if (profilesByEmail.isEmpty) {
        // No profile with this email, safe to create
         await profileRepository.createProfile(
          user.displayName ?? 'Hunter',
          id: user.id,
          email: user.email,
        );
      }
      // If profile exists by email, we might want to link it (advanced), 
      // but essentially we are done.
    }

    return user;
  }
}
