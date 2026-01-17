import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/movie.dart';
import '../models/movie_adapter.dart';

/// Сервис для работы с базой данных Hive
class HiveHelper {
  /// Имя бокса для хранения фильмов
  static const String _moviesBoxName = 'movies_box';

  /// Ссылка на бокс с фильмами
  static late Box<Movie> _moviesBox;

  /// Флаг инициализации
  static bool _isInitialized = false;

  /// Инициализация Hive
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Инициализация Hive с указанием директории для хранения данных
      if (!kIsWeb) {
        final documentDir = await getApplicationDocumentsDirectory();
        Hive.init(documentDir.path);
      } else {
        await Hive.initFlutter();
      }

      // Регистрация адаптера для модели Movie
      Hive.registerAdapter(MovieAdapter());

      // Открытие бокса для фильмов
      _moviesBox = await Hive.openBox<Movie>(_moviesBoxName);

      _isInitialized = true;
    } catch (e) {
      debugPrint('Ошибка инициализации Hive: $e');
      rethrow;
    }
  }

  /// Получение всех фильмов
  static List<Movie> getAllMovies() {
    try {
      return _moviesBox.values.toList();
    } catch (e) {
      debugPrint('Ошибка получения фильмов: $e');
      return [];
    }
  }

  /// Получение фильма по ID
  static Movie? getMovie(int id) {
    try {
      return _moviesBox.get(id.toString());
    } catch (e) {
      debugPrint('Ошибка получения фильма: $e');
      return null;
    }
  }

  /// Добавление нового фильма
  static Future<void> addMovie(Movie movie) async {
    try {
      await _moviesBox.put(movie.id.toString(), movie);
    } catch (e) {
      debugPrint('Ошибка добавления фильма: $e');
      rethrow;
    }
  }

  /// Обновление существующего фильма
  static Future<void> updateMovie(Movie movie) async {
    try {
      await _moviesBox.put(movie.id.toString(), movie);
    } catch (e) {
      debugPrint('Ошибка обновления фильма: $e');
      rethrow;
    }
  }

  /// Удаление фильма
  static Future<void> deleteMovie(int id) async {
    try {
      await _moviesBox.delete(id.toString());
    } catch (e) {
      debugPrint('Ошибка удаления фильма: $e');
      rethrow;
    }
  }

  /// Генерация уникального ID для нового фильма
  static int generateId() {
    try {
      if (_moviesBox.isEmpty) return 1;

      final ids = _moviesBox.keys
          .map((key) => int.tryParse(key.toString()) ?? 0)
          .toList();

      return (ids..sort()).last + 1;
    } catch (e) {
      debugPrint('Ошибка генерации ID: $e');
      return DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }
  }

  /// Закрытие соединения с Hive
  static Future<void> close() async {
    try {
      await _moviesBox.close();
      _isInitialized = false;
    } catch (e) {
      debugPrint('Ошибка закрытия Hive: $e');
    }
  }

  /// Очистка всех данных
  static Future<void> clearAll() async {
    try {
      await _moviesBox.clear();
    } catch (e) {
      debugPrint('Ошибка очистки данных: $e');
      rethrow;
    }
  }
}
