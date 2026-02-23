import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/app_theme.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/deck_repository.dart';
import '../domain/services/notification_service.dart';
import '../data/repositories/firebase_auth_repository.dart';
import '../data/repositories/firestore_deck_repository.dart';
import '../data/services/firebase_notification_service.dart';
import 'auth/auth_cubit.dart' show AuthCubit, AuthLoading, AuthState, Authenticated;
import 'auth/login_page.dart';
import 'home/home_page.dart';
import 'theme/theme_cubit.dart';

class LaLaLanguageApp extends StatelessWidget {
  final NotificationService notificationService;

  const LaLaLanguageApp({
    super.key,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    final authRepository = FirebaseAuthRepository();
    final deckRepository = FirestoreDeckRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<DeckRepository>.value(value: deckRepository),
        RepositoryProvider<NotificationService>.value(value: notificationService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (_) => AuthCubit(authRepository)..init(),
          ),
          BlocProvider<ThemeCubit>(
            create: (_) => ThemeCubit(),
          ),
        ],
        child: BlocListener<AuthCubit, AuthState>(
          listenWhen: (prev, curr) => curr is Authenticated,
          listener: (context, state) {
            notificationService.rescheduleFromFirestore();
          },
          child: BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'LaLaLanguage',
              theme: buildLightTheme(),
              darkTheme: buildDarkTheme(),
              themeMode: themeMode,
              home: const _RootRouter(),
            );
          },
        ),
        ),
      ),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is Authenticated) {
          return const HomePage();
        }
        return const LoginPage();
      },
    );
  }
}

