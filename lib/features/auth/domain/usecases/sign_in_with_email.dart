import 'package:outcall/features/auth/domain/repositories/auth_repository.dart';

class SignInWithEmail {
  final AuthRepository _repository;

  SignInWithEmail(this._repository);

  Future<void> call(String email, String password) async {
    return _repository.signInWithEmail(email, password);
  }
}
