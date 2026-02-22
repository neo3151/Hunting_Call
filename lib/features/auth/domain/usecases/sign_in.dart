import 'package:hunting_calls_perfection/features/auth/domain/repositories/auth_repository.dart';

class SignIn {
  final AuthRepository repository;

  SignIn(this.repository);

  Future<void> call(String userId) {
    return repository.signIn(userId);
  }
}
