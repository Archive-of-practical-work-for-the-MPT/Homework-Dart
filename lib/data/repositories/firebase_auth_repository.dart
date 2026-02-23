import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AppUser? _firebaseUserToAppUser(User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? user.email?.split('@').first,
    );
  }

  String _authExceptionToMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Пользователь с такой почтой не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'invalid-email':
        return 'Некорректный адрес почты';
      case 'email-already-in-use':
        return 'Пользователь с такой почтой уже существует';
      case 'weak-password':
        return 'Пароль должен содержать не менее 6 символов';
      case 'invalid-credential':
        return 'Неверная почта или пароль';
      case 'user-disabled':
        return 'Учётная запись отключена';
      default:
        return e.message ?? e.code;
    }
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().map(_firebaseUserToAppUser);
  }

  @override
  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      return _firebaseUserToAppUser(cred.user);
    } on FirebaseAuthException catch (e) {
      throw Exception(_authExceptionToMessage(e));
    }
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final user = _firebaseUserToAppUser(cred.user);
      if (user == null) throw Exception('Ошибка при создании пользователя');
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_authExceptionToMessage(e));
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
