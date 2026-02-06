import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final dir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(dir.path);
  } catch (_) {
    await Hive.initFlutter();
  }
  await Hive.openBox('gallery');
  await Hive.openBox('music');
  runApp(const MediaApp());
}

class MediaApp extends StatefulWidget {
  const MediaApp({super.key});

  @override
  State<MediaApp> createState() => _MediaAppState();
}

class _MediaAppState extends State<MediaApp> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Галерея + Музыка',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.light,
        ),
        // Добавляем кастомные стили для улучшения визуального восприятия
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
      ),
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: const [GalleryScreen(), MusicScreen()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.photo_library_outlined),
              selectedIcon: Icon(Icons.photo_library),
              label: 'Галерея',
            ),
            NavigationDestination(
              icon: Icon(Icons.music_note_outlined),
              selectedIcon: Icon(Icons.music_note),
              label: 'Музыка',
            ),
          ],
        ),
      ),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late final Box _galleryBox;
  final Location _location = Location();

  @override
  void initState() {
    super.initState();
    _galleryBox = Hive.box('gallery');
  }

  Future<void> _ensureLocationPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
    }
  }

  Future<void> _addMedia({required bool isVideo}) async {
    final controller = TextEditingController();

    final url = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isVideo ? 'Добавить видео по URL' : 'Добавить фото по URL',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'https://...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (url == null || url.isEmpty) return;

    final key = DateTime.now().millisecondsSinceEpoch.toString();
    final createdAt = DateTime.now().toIso8601String();
    // Сохраняем сразу, чтобы интерфейс не зависал
    await _galleryBox.put(key, {
      'type': isVideo ? 'video' : 'photo',
      'url': url,
      'latitude': null,
      'longitude': null,
      'createdAt': createdAt,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Сохранено'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    // Геопозицию подставляем в фоне, не блокируя UI
    _updateLocationInBackground(key, isVideo, url, createdAt);
  }

  Future<void> _updateLocationInBackground(
    String key,
    bool isVideo,
    String url,
    String createdAt,
  ) async {
    try {
      await _ensureLocationPermission();
      final loc = await _location.getLocation().timeout(
        const Duration(seconds: 5),
      );
      if (!mounted) return;
      await _galleryBox.put(key, {
        'type': isVideo ? 'video' : 'photo',
        'url': url,
        'latitude': loc.latitude,
        'longitude': loc.longitude,
        'createdAt': createdAt,
      });
    } catch (_) {
      // Геолокация не обязательна, игнорируем ошибки
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Галерея',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: ValueListenableBuilder(
        valueListenable: _galleryBox.listenable(),
        builder: (context, Box box, _) {
          final keys =
              box.keys.where((k) => box.get(k) != null).cast<dynamic>().toList()
                ..sort((a, b) => _compareKeys(b, a));
          final items = keys
              .map<Map<dynamic, dynamic>>(
                (k) => box.get(k) as Map<dynamic, dynamic>,
              )
              .toList();

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_size_select_actual,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Пока нет медиа',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Добавьте фото или видео',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 9 / 16,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final data = items[index];
              final isVideo = data['type'] == 'video';
              final url = data['url'] as String? ?? '';
              final latitude = (data['latitude'] as num?)?.toDouble();
              final longitude = (data['longitude'] as num?)?.toDouble();
              final createdAt = DateTime.tryParse(
                data['createdAt'] as String? ?? '',
              );

              return Card(
                clipBehavior: Clip.hardEdge,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    isVideo
                        ? VideoFeedItem(key: ValueKey('video_$index'), url: url)
                        : Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isVideo ? 'Видео' : 'Фото',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (createdAt != null)
                              Text(
                                'Сохранено: ${createdAt.toLocal().toString().split('.')[0]}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            if (latitude != null && longitude != null)
                              Text(
                                '📍 ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add_photo',
            onPressed: () => _addMedia(isVideo: false),
            icon: const Icon(Icons.photo),
            label: const Text('Фото'),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'add_video',
            onPressed: () => _addMedia(isVideo: true),
            icon: const Icon(Icons.videocam),
            label: const Text('Видео'),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class VideoFeedItem extends StatefulWidget {
  final String url;

  const VideoFeedItem({super.key, required this.url});

  @override
  State<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<VideoFeedItem> {
  late final VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    // Track the playing state based on the controller state
    if (_controller.value.isPlaying != _isPlaying) {
      _isPlaying = _controller.value.isPlaying;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final duration = _controller.value.duration;
    final position = _controller.value.position;
    final size = _controller.value.size;
    final width = size.width > 0 ? size.width : 16.0;
    final height = size.height > 0 ? size.height : 9.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                      _isPlaying = false;
                    } else {
                      _controller.play();
                      _isPlaying = true;
                    }
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                    if (!_controller.value.isPlaying)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.play_arrow,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    if (_controller.value.isPlaying)
                      Positioned(
                        top: 8, // Moved to the top of the video
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.pause,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Position the slider higher up, well above the text area
        Positioned(
          bottom:
              100, // Moved higher (from 50 to 100) to be well above the text
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: duration.inMilliseconds > 0
                ? Column(
                    children: [
                      Slider(
                        value: position.inMilliseconds
                            .clamp(0, duration.inMilliseconds)
                            .toDouble(),
                        max: duration.inMilliseconds.toDouble(),
                        onChanged: (value) async {
                          final newPosition = Duration(
                            milliseconds: value.toInt(),
                          );
                          await _controller.seekTo(newPosition);
                          // Ensure playback continues if it was playing before seeking
                          if (_isPlaying) {
                            await _controller.play();
                          }
                        },
                        activeColor: Colors.purple,
                        inactiveColor: Colors.grey[300],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(position)),
                            Text(_formatDuration(duration)),
                          ],
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  late final Box _musicBox;
  AudioPlayer? _player;
  int? _currentIndex;
  String? _currentPlayingUrl;

  @override
  void initState() {
    super.initState();
    _musicBox = Hive.box('music');
    _player = AudioPlayer();
    _player!.playerStateStream.listen(_onPlayerState);
  }

  void _onPlayerState(PlayerState state) {
    if (state.processingState == ProcessingState.completed && mounted) {
      setState(() {
        _currentIndex = null;
        _currentPlayingUrl = null;
      });
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    _player = null;
    super.dispose();
  }

  Future<void> _addTrack() async {
    final controller = TextEditingController();

    final url = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Добавить аудио по URL',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'https://...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (url == null || url.isEmpty) return;

    final key = DateTime.now().millisecondsSinceEpoch.toString();
    await _musicBox.put(key, {
      'url': url,
      'createdAt': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Трек добавлен'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _playTrackByKey(dynamic hiveKey) async {
    final data = _musicBox.get(hiveKey) as Map<dynamic, dynamic>?;
    if (data == null) return;
    final url = (data['url'] as String? ?? '').trim();
    if (url.isEmpty) return;
    try {
      final isSameTrack = _currentPlayingUrl == url;
      if (isSameTrack && _player != null && !_player!.playing) {
        setState(() => _currentPlayingUrl = url);
        await _player!.play();
        return;
      }
      // При смене трека — новый плеер, чтобы гарантированно играл выбранный трек
      _player?.dispose();
      _player = AudioPlayer();
      _player!.playerStateStream.listen(_onPlayerState);
      await _player!.setAudioSource(AudioSource.uri(Uri.parse(url)));
      final keysList =
          _musicBox.keys.where((k) => _musicBox.get(k) != null).toList()
            ..sort((a, b) => _compareKeys(b, a));
      final idx = keysList.indexWhere((k) => _keyEquals(k, hiveKey));
      setState(() {
        _currentIndex = idx >= 0 ? idx : null;
        _currentPlayingUrl = url;
      });
      await _player!.play();
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentIndex = null;
          _currentPlayingUrl = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка воспроизведения: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  bool _keyEquals(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a is String && b is String) return a == b;
    if (a is num && b is num) return a == b;
    return a.toString() == b.toString();
  }

  String _format(Duration d) => _formatDuration(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Музыка',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _addTrack,
              icon: const Icon(Icons.add),
              label: const Text('Добавить аудио'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _musicBox.listenable(),
              builder: (context, Box box, _) {
                final keys =
                    box.keys
                        .where((k) => box.get(k) != null)
                        .cast<dynamic>()
                        .toList()
                      ..sort((a, b) => _compareKeys(b, a));
                final items = keys
                    .map<Map<dynamic, dynamic>>(
                      (k) => box.get(k) as Map<dynamic, dynamic>,
                    )
                    .toList();

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_note,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Нет аудиозаписей',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Добавьте URL',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final hiveKey = keys[index];
                    final data = items[index];
                    final trackUrl = (data['url'] as String? ?? '').trim();
                    final createdAt = DateTime.tryParse(
                      data['createdAt'] as String? ?? '',
                    );
                    final isCurrent = _currentPlayingUrl == trackUrl;
                    final truncatedUrl = trackUrl.length > 50
                        ? '${trackUrl.substring(0, 50)}...'
                        : trackUrl;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isCurrent
                              ? Colors.purple
                              : Colors.grey[300],
                          child: Icon(
                            isCurrent && (_player?.playing ?? false)
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: isCurrent ? Colors.white : Colors.grey[600],
                            size: 20,
                          ),
                        ),
                        title: Text(truncatedUrl),
                        subtitle: createdAt != null
                            ? Text(
                                'Добавлено: ${createdAt.toLocal().toString().split('.')[0]}',
                              )
                            : null,
                        trailing: IconButton(
                          icon: Icon(
                            isCurrent && (_player?.playing ?? false)
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.purple,
                          ),
                          onPressed: () {
                            if (isCurrent && (_player?.playing ?? false)) {
                              _player?.pause();
                              setState(() {});
                            } else {
                              _playTrackByKey(hiveKey);
                            }
                          },
                        ),
                        onTap: () {
                          if (isCurrent && (_player?.playing ?? false)) {
                            _player?.pause();
                            setState(() {});
                          } else {
                            _playTrackByKey(hiveKey);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          StreamBuilder<Duration>(
            stream: _player?.positionStream ?? Stream<Duration>.empty(),
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = _player?.duration ?? Duration.zero;
              final maxMs = duration.inMilliseconds > 0
                  ? duration.inMilliseconds
                  : 1;

              if (_currentPlayingUrl == null) {
                return const SizedBox.shrink();
              }

              final value = position.inMilliseconds.clamp(0, maxMs).toDouble();

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(width: 1, color: Colors.grey[300]!),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Slider(
                      value: value,
                      max: maxMs.toDouble(),
                      onChanged: (v) {
                        _player?.seek(Duration(milliseconds: v.toInt()));
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_format(position)),
                          Text(_format(duration)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final minutes = two(d.inMinutes.remainder(60));
  final seconds = two(d.inSeconds.remainder(60));
  return '$minutes:$seconds';
}

int _compareKeys(dynamic a, dynamic b) {
  final na = _keyToNum(a);
  final nb = _keyToNum(b);
  return na.compareTo(nb);
}

double _keyToNum(dynamic k) {
  if (k is num) return k.toDouble();
  if (k is String) return double.tryParse(k) ?? 0.0;
  return 0.0;
}
