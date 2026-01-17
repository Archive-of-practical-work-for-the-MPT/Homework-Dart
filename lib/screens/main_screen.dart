import 'dart:io';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../utils/hive_helper.dart';
import '../utils/theme_service.dart';
import 'movie_form_screen.dart';

/// Главный экран приложения для управления списком фильмов
class MainScreen extends StatefulWidget {
  /// Callback для переключения темы
  final VoidCallback? themeToggleCallback;

  const MainScreen({super.key, this.themeToggleCallback});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// Список всех фильмов
  List<Movie> _movies = [];

  /// Текущая тема приложения
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  /// Инициализация приложения
  Future<void> _initApp() async {
    debugPrint('Начало инициализации приложения');

    try {
      // Инициализация Hive
      debugPrint('Начинаем жестко инициализировать Hive');
      await HiveHelper.init();
      debugPrint('Hive с кайфом инициализирован');

      // Загрузка темы
      debugPrint('Загружаем тему вам придется подождать');
      _themeMode = await ThemeService.getThemeMode();
      debugPrint('Тема загружена: $_themeMode победа!');

      // Загрузка фильмов
      debugPrint('Загружаем ваши фильмы, держитесь там');
      _loadMovies();
      debugPrint(
        'Фильмы загружены. Количество: ${_movies.length} - можно и больше!',
      );
    } catch (e) {
      debugPrint('Ошибка инициализации (анлак): $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка инициализации (анлак): $e')),
        );
      }
    }
  }

  /// Загрузка фильмов из базы данных
  void _loadMovies() {
    setState(() {
      _movies = HiveHelper.getAllMovies();
    });
  }

  /// Переключение темы
  void _toggleTheme() {
    if (widget.themeToggleCallback != null) {
      widget.themeToggleCallback!();
    } else {
      setState(() {
        _themeMode = _themeMode == ThemeMode.light
            ? ThemeMode.dark
            : ThemeMode.light;
      });
    }
  }

  /// Добавление нового фильма
  Future<void> _addMovie() async {
    debugPrint('Была нажата кнопка +');

    try {
      final result = await Navigator.push<Movie>(
        context,
        MaterialPageRoute(builder: (context) => const MovieFormScreen()),
      );

      if (result != null) {
        await HiveHelper.addMovie(result);
        _loadMovies();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Фильм успешно добавлен')),
          );
        }
      }
    } catch (e) {
      debugPrint('Ошибка при добавлении фильма: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  /// Редактирование фильма
  Future<void> _editMovie(Movie movie) async {
    final result = await Navigator.push<Movie>(
      context,
      MaterialPageRoute(builder: (context) => MovieFormScreen(movie: movie)),
    );

    if (result != null) {
      await HiveHelper.updateMovie(result);
      _loadMovies();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Фильм успешно обновлен')));
      }
    }
  }

  /// Удаление фильма
  Future<void> _deleteMovie(Movie movie) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Вы уверены, что хотите удалить "${movie.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await HiveHelper.deleteMovie(movie.id);
      _loadMovies();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Фильм удален :(')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Трекер фильмов и аниме'),
        actions: [
          IconButton(
            icon: Icon(
              _themeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: _toggleTheme,
            tooltip: 'Переключить тему',
          ),
        ],
      ),
      body: Column(
        children: [
          // Список фильмов
          Expanded(
            child: _movies.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _movies.length,
                    itemBuilder: (context, index) {
                      final movie = _movies[index];
                      return _buildMovieCard(movie);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMovie,
        child: const Icon(Icons.add),
        tooltip: 'Добавить фильм',
      ),
    );
  }

  /// Карточка фильма
  Widget _buildMovieCard(Movie movie) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: movie.imagePath != null && File(movie.imagePath!).existsSync()
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(movie.imagePath!),
                  width: 60,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.movie, size: 30),
              ),
        title: Text(
          movie.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Год: ${movie.year}'),
            Text('Жанр: ${movie.genre}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editMovie(movie),
              tooltip: 'Редактировать',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteMovie(movie),
              tooltip: 'Удалить',
            ),
          ],
        ),
      ),
    );
  }

  /// Состояние пустого списка
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          const Text('Фильмов нет :(', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text(
            'Добавьте через "+" внизу экрана',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
