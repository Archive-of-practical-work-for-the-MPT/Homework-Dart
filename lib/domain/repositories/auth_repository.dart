import '../entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();

  Future<AppUser?> signIn({
    required String email,
    required String password,
  });

  Future<AppUser> signUp({
    required String email,
    required String password,
  });

  Future<void> signOut();
}

