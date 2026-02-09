import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/domain/auth_repository.dart';

class AuthService {
  final Ref ref;
  AuthService(this.ref);

  Future<void> signOut() async {
    // 1. Sign out from Backend
    await ref.read(authRepositoryProvider).signOut();
    
    // 2. Clear all Riverpod State to prevent stale data
    ref.invalidateSelf(); 
    
    print('Sentinel: AuthService - Global Sign-out and context reset complete.');
  }
}

final authServiceProvider = Provider((ref) => AuthService(ref));
