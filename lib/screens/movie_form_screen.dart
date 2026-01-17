import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/movie.dart';
import '../utils/hive_helper.dart';

/// Экран формы для добавления/редактирования фильма
class MovieFormScreen extends StatefulWidget {
  /// Редактируемый фильм (null для создания нового)
  final Movie? movie;

  const MovieFormScreen({super.key, this.movie});

  @override
  State<MovieFormScreen> createState() => _MovieFormScreenState();
}

class _MovieFormScreenState extends State<MovieFormScreen> {
  /// Контроллеры полей ввода
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();

  /// Выбранное изображение
  File? _selectedImage;

  /// Флаг загрузки
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    debugPrint('MovieFormScreen инициализирован');

    // Если редактируем существующий фильм, заполняем поля
    if (widget.movie != null) {
      _titleController.text = widget.movie!.title;
      _yearController.text = widget.movie!.year.toString();
      _genreController.text = widget.movie!.genre;
      if (widget.movie!.imagePath != null) {
        _selectedImage = File(widget.movie!.imagePath!);
      }
    }
  }

  /// Выбор изображения из галереи
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора изображения: $e')),
        );
      }
    }
  }

  /// Удаление выбранного изображения
  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  /// Сохранение фильма
  Future<void> _saveMovie() async {
    // Валидация полей
    if (_titleController.text.trim().isEmpty) {
      _showError('Введите название фильма');
      return;
    }

    if (_yearController.text.trim().isEmpty) {
      _showError('Введите год выпуска');
      return;
    }

    if (_genreController.text.trim().isEmpty) {
      _showError('Введите жанр');
      return;
    }

    // Проверка корректности года
    final year = int.tryParse(_yearController.text.trim());
    if (year == null || year < 1888 || year > DateTime.now().year + 5) {
      _showError(
        'Введите корректный год выпуска (1888-${DateTime.now().year + 5})',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final movie = Movie(
        id: widget.movie?.id ?? HiveHelper.generateId(),
        title: _titleController.text.trim(),
        year: year,
        genre: _genreController.text.trim(),
        imagePath: _selectedImage?.path,
      );

      // Возвращаем результат
      Navigator.pop(context, movie);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Показ сообщения об ошибке
  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.movie == null ? 'Добавить фильм' : 'Редактировать фильм',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveMovie,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Выбор изображения
            _buildImagePicker(),
            const SizedBox(height: 24),

            // Название фильма
            _buildTextField(
              controller: _titleController,
              label: 'Название фильма',
              hint: 'Введите название',
              icon: Icons.movie,
            ),
            const SizedBox(height: 16),

            // Год выпуска
            _buildTextField(
              controller: _yearController,
              label: 'Год выпуска',
              hint: 'Введите год',
              icon: Icons.calendar_today,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Жанр
            _buildTextField(
              controller: _genreController,
              label: 'Жанр',
              hint: 'Введите жанр',
              icon: Icons.local_movies,
            ),
            const SizedBox(height: 32),

            // Кнопка сохранения
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveMovie,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        widget.movie == null
                            ? 'Добавить фильм'
                            : 'Сохранить изменения',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Компонент выбора изображения
  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Обложка фильма',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).cardColor,
            ),
            child: _selectedImage != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.red,
                          radius: 16,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                            onPressed: _removeImage,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: Theme.of(context).disabledColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Нажмите для выбора изображения',
                        style: TextStyle(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// Компонент текстового поля
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    _genreController.dispose();
    super.dispose();
  }
}
