import 'package:hunting_calls_perfection/features/auth/domain/entities/auth_user.dart';
import 'package:hunting_calls_perfection/features/auth/domain/repositories/auth_repository.dart';

class GetAuthStateStream {
  final AuthRepository repository;

  GetAuthStateStream(this.repository);

  Stream<AuthUser?> call() {
    return repository.authStateChanges;
  }
}
