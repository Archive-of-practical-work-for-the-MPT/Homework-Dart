import 'dart:async';

import 'package:equatable/equatable.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class _UserRecord extends Equatable {
  final AppUser user;
  final String password;

  const _UserRecord({
    required this.user,
    required this.password,
  });

  @override
  List<Object?> get props => [user, password];
}

class InMemoryAuthRepository implements AuthRepository {
  final _usersByEmail = <String, _UserRecord>{};
  final _authController = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  InMemoryAuthRepository() {
    // Тестовый пользователь по умолчанию
    final demoUser = AppUser(id: 'demo', email: 'demo@lala.app', displayName: 'Demo User');
    _usersByEmail[demoUser.email] = const _UserRecord(
      user: AppUser(id: 'demo', email: 'demo@lala.app', displayName: 'Demo User'),
      password: 'password',
    );
  }

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _authController.stream;
  }

  @override
  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final record = _usersByEmail[email.trim().toLowerCase()];
    if (record == null) {
      throw Exception('Пользователь с такой почтой не найден');
    }
    if (record.password != password) {
      throw Exception('Неверный пароль');
    }
    _currentUser = record.user;
    _authController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final normalizedEmail = email.trim().toLowerCase();
    if (_usersByEmail.containsKey(normalizedEmail)) {
      throw Exception('Пользователь с такой почтой уже существует');
    }
    if (password.length < 6) {
      throw Exception('Пароль должен содержать не менее 6 символов');
    }

    final user = AppUser(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      email: normalizedEmail,
      displayName: normalizedEmail.split('@').first,
    );
    _usersByEmail[normalizedEmail] = _UserRecord(user: user, password: password);
    _currentUser = user;
    _authController.add(_currentUser);
    return user;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _authController.add(null);
  }

  void dispose() {
    _authController.close();
  }
}

