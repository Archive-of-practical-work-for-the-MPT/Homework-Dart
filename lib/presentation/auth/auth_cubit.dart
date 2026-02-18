import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class Authenticated extends AuthState {
  final AppUser user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<AppUser?>? _subscription;

  AuthCubit(this._authRepository) : super(const AuthLoading());

  void init() {
    _subscription?.cancel();
    _subscription = _authRepository.authStateChanges().listen(
      (user) {
        if (user == null) {
          emit(const Unauthenticated());
        } else {
          emit(Authenticated(user));
        }
      },
      onError: (error, _) {
        emit(AuthError(error.toString()));
      },
    );
  }

  Future<void> signIn(String email, String password) async {
    emit(const AuthLoading());
    try {
      await _authRepository.signIn(email: email, password: password);
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
      emit(const Unauthenticated());
    }
  }

  Future<void> signUp(String email, String password) async {
    emit(const AuthLoading());
    try {
      await _authRepository.signUp(email: email, password: password);
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
      emit(const Unauthenticated());
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

