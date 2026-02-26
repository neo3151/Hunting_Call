import 'package:outcall/features/auth/domain/repositories/auth_repository.dart';

class SignInAnonymously {
  final AuthRepository repository;

  SignInAnonymously(this.repository);

  Future<void> call() {
    return repository.signInAnonymously();
  }
}
