import 'package:outcall/features/auth/domain/repositories/auth_repository.dart';

class SendPasswordResetEmail {
  final AuthRepository _repository;

  SendPasswordResetEmail(this._repository);

  Future<void> call(String email) {
    return _repository.sendPasswordResetEmail(email);
  }
}
