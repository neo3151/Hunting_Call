import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class GetAuthStateStream {
  final AuthRepository repository;

  GetAuthStateStream(this.repository);

  Stream<AuthUser?> call() {
    return repository.authStateChanges;
  }
}
