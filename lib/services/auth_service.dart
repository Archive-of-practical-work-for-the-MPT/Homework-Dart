import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Получить текущего пользователя
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Войти с помощью email и пароля
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Ошибка входа: ${e.message}');
      return null;
    }
  }

  // Регистрация с помощью email и пароля
  Future<UserCredential?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Ошибка регистрации: ${e.message}');
      return null;
    }
  }

  // Выйти
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Проверить, вошел ли пользователь
  bool isSignedIn() {
    return _auth.currentUser != null;
  }
}