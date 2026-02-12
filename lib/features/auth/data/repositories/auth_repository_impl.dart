import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<AuthUser?> get authStateChanges {
    return remoteDataSource.authStateChanges.map((model) => model);
  }

  @override
  Future<AuthUser?> get currentUser async {
    return remoteDataSource.currentUser;
  }

  @override
  Future<void> signInAnonymously() async {
    return remoteDataSource.signInAnonymously();
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    return remoteDataSource.signInWithGoogle();
  }

  @override
  Future<void> signIn(String userId) async {
    return remoteDataSource.signIn(userId);
  }

  @override
  Future<void> signOut() async {
    return remoteDataSource.signOut();
  }

  @override
  bool get isMock => false;
}
