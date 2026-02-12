import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';

class AuthService {
  final Ref ref;
  AuthService(this.ref);

  Future<void> signOut() async {
    // 1. Sign out from Backend
    await ref.read(authRepositoryProvider).signOut();
    
    // 2. Clear all Riverpod State to prevent stale data
    ref.invalidateSelf(); 
    
    debugPrint('AuthService: Global Sign-out and context reset complete.');
  }
}


