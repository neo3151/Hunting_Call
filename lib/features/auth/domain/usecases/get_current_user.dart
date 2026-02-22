import 'package:hunting_calls_perfection/features/auth/domain/entities/auth_user.dart';
import 'package:hunting_calls_perfection/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUser {
  final AuthRepository repository;

  GetCurrentUser(this.repository);

  Future<AuthUser?> call() {
    return repository.currentUser;
  }
}
