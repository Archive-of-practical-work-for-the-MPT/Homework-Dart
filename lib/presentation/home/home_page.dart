import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/deck_repository.dart';
import '../../domain/services/notification_service.dart';
import '../auth/auth_cubit.dart';
import '../decks/decks_cubit.dart';
import '../decks/decks_page.dart';
import '../stats/stats_cubit.dart';
import '../stats/stats_page.dart';
import '../theme/theme_cubit.dart';
import '../training/training_cubit.dart';
import '../training/training_page.dart';
import 'home_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final deckRepository = context.read<DeckRepository>();
    final notificationService = context.read<NotificationService>();

    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeCubit>(
          create: (_) => HomeCubit(),
        ),
        BlocProvider<DecksCubit>(
          create: (_) => DecksCubit(deckRepository)..init(),
        ),
        BlocProvider<TrainingCubit>(
          create: (_) => TrainingCubit(deckRepository),
        ),
        BlocProvider<StatsCubit>(
          create: (_) => StatsCubit(deckRepository)..load(),
        ),
      ],
      child: _HomeScaffold(notificationService: notificationService),
    );
  }
}

class _HomeScaffold extends StatelessWidget {
  final NotificationService notificationService;

  const _HomeScaffold({required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final themeMode = context.watch<ThemeCubit>().state;

        return Scaffold(
          appBar: AppBar(
            title: const Text('LaLaLanguage'),
            actions: [
              IconButton(
                tooltip: themeMode == ThemeMode.light
                    ? 'Включить тёмную тему'
                    : 'Включить светлую тему',
                icon: Icon(
                  themeMode == ThemeMode.light
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                ),
                onPressed: () =>
                    context.read<ThemeCubit>().toggle(),
              ),
              IconButton(
                tooltip: 'Напоминание о повторении',
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 10, minute: 0),
                  );
                  if (time != null) {
                    await notificationService.scheduleDailyReviewReminder(
                      hour: time.hour,
                      minute: time.minute,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Напоминание о повторении запланировано на ${time.format(context)}',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              IconButton(
                tooltip: 'Выйти',
                icon: const Icon(Icons.logout),
                onPressed: () {
                  context.read<AuthCubit>().signOut();
                },
              ),
            ],
          ),
          body: IndexedStack(
            index: state.selectedIndex,
            children: const [
              DecksPage(),
              TrainingPage(),
              StatsPage(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: state.selectedIndex,
            onDestinationSelected: (index) {
              context.read<HomeCubit>().changeTab(index);
              if (index == 2) {
                context.read<StatsCubit>().load();
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder),
                label: 'Наборы',
              ),
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school),
                label: 'Тренировка',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: 'Статистика',
              ),
            ],
          ),
        );
      },
    );
  }
}

