import 'package:hunting_calls_perfection/features/auth/domain/repositories/auth_repository.dart';

class SignUpWithEmail {
  final AuthRepository _repository;

  SignUpWithEmail(this._repository);

  Future<void> call(String email, String password) async {
    return _repository.signUpWithEmail(email, password);
  }
}
