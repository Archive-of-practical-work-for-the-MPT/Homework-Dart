import "package:flutter/material.dart";
import "screens/main_screen.dart";
import "utils/theme_service.dart";
import 'dart:async';

void main() {
  runZonedGuarded(
    () {
      runApp(const MyApp());
    },
    (e, st) {
      // Игнорируем необработанные ошибки
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final theme = await ThemeService.getThemeMode();
    setState(() {
      _themeMode = theme;
    });
  }

  Future<void> _toggleTheme() async {
    final newTheme = await ThemeService.toggleTheme(_themeMode);
    setState(() {
      _themeMode = newTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Трекер фильмов',
      theme: ThemeService.getLightTheme(),
      darkTheme: ThemeService.getDarkTheme(),
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      home: MainScreen(themeToggleCallback: _toggleTheme),
    );
  }
}
