import "package:hive/hive.dart";

/// Модель фильма для хранения в Hive
@HiveType(typeId: 0)
class Movie extends HiveObject {
  /// Уникальный идентификатор фильма
  @HiveField(0)
  late int id;

  /// Название фильма
  @HiveField(1)
  late String title;

  /// Год выпуска фильма
  @HiveField(2)
  late int year;

  /// Жанр фильма
  @HiveField(3)
  late String genre;

  /// Путь к изображению фильма
  @HiveField(4)
  String? imagePath;

  /// Конструктор фильма
  Movie({
    required this.id,
    required this.title,
    required this.year,
    required this.genre,
    this.imagePath,
  });

  /// Создание копии фильма с возможностью изменения полей
  Movie copyWith({
    int? id,
    String? title,
    int? year,
    String? genre,
    String? imagePath,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  String toString() {
    return 'Movie(id: $id, title: $title, year: $year, genre: $genre, imagePath: $imagePath)';
  }
}
