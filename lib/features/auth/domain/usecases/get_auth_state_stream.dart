import 'package:outcall/features/auth/domain/entities/auth_user.dart';
import 'package:outcall/features/auth/domain/repositories/auth_repository.dart';

class GetAuthStateStream {
  final AuthRepository repository;

  GetAuthStateStream(this.repository);

  Stream<AuthUser?> call() {
    return repository.authStateChanges;
  }
}
