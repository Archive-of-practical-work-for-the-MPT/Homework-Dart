// Обработчик файлов для игры в морской бой
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'models.dart';

class FileHandler {
  static const String _playersDir = 'players';
  static const String _gameDataFile = 'current_game.json';
  static const String _logFile = 'game.log';

  /// Инициализация директорий для файлов
  static Future<void> initializeDirectories() async {
    final playersDirectory = Directory(_playersDir);
    if (!await playersDirectory.exists()) {
      await playersDirectory.create(recursive: true);
    }
  }

  /// Получить данные игрока по имени
  static Future<PlayerData?> getPlayerData(String playerName) async {
    try {
      final playerFile = File(path.join(_playersDir, '$playerName.json'));
      if (await playerFile.exists()) {
        final content = await playerFile.readAsString();
        final jsonData = jsonDecode(content);
        return PlayerData.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      // Логируем ошибку, но не прерываем выполнение
      await writeLog('Ошибка при получении данных игрока $playerName: $e');
      return null;
    }
  }

  /// Сохранить или обновить данные игрока
  static Future<void> savePlayerData(PlayerData playerData) async {
    try {
      final playerFile = File(path.join(_playersDir, '${playerData.name}.json'));
      final jsonString = jsonEncode(playerData.toJson());
      await playerFile.writeAsString(jsonString);
    } catch (e) {
      await writeLog('Ошибка при сохранении данных игрока ${playerData.name}: $e');
    }
  }

  /// Обновить статистику игрока (победа или поражение)
  static Future<void> updatePlayerStats(String playerName, bool isWinner) async {
    try {
      PlayerData? playerData = await getPlayerData(playerName);
      
      if (playerData == null) {
        // Если игрок новый, создаем данные для него
        playerData = PlayerData(name: playerName);
      }
      
      // Обновляем статистику
      playerData.gamesPlayed++;
      if (isWinner) {
        playerData.wins++;
      } else {
        playerData.losses++;
      }
      
      // Сохраняем обновленные данные
      await savePlayerData(playerData);
    } catch (e) {
      await writeLog('Ошибка при обновлении статистики игрока $playerName: $e');
    }
  }

  /// Сохранить данные текущей игры
  static Future<void> saveCurrentGameData(GameData gameData) async {
    try {
      final gameFile = File(_gameDataFile);
      final jsonString = jsonEncode(gameData.toJson());
      await gameFile.writeAsString(jsonString);
    } catch (e) {
      await writeLog('Ошибка при сохранении данных текущей игры: $e');
    }
  }

  /// Получить данные текущей игры
  static Future<GameData?> getCurrentGameData() async {
    try {
      final gameFile = File(_gameDataFile);
      if (await gameFile.exists()) {
        final content = await gameFile.readAsString();
        final jsonData = jsonDecode(content);
        return GameData.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      await writeLog('Ошибка при получении данных текущей игры: $e');
      return null;
    }
  }

  /// Очистить данные текущей игры
  static Future<void> clearCurrentGameData() async {
    try {
      final gameFile = File(_gameDataFile);
      if (await gameFile.exists()) {
        await gameFile.writeAsString('');
      }
    } catch (e) {
      await writeLog('Ошибка при очистке данных текущей игры: $e');
    }
  }

  /// Удалить файл данных текущей игры
  static Future<void> deleteCurrentGameDataFile() async {
    try {
      final gameFile = File(_gameDataFile);
      if (await gameFile.exists()) {
        await gameFile.delete();
      }
    } catch (e) {
      await writeLog('Ошибка при удалении файла данных текущей игры: $e');
    }
  }

  /// Запись в лог-файл
  static Future<void> writeLog(String message) async {
    try {
      final log = File(_logFile);
      final timestamp = DateTime.now().toString();
      final logEntry = '[$timestamp] $message\n';
      await log.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      // Игнорируем ошибки записи в лог, чтобы не создавать бесконечный цикл
      stderr.writeln('Ошибка при записи в лог: $e');
    }
  }

  /// Получить поток логов в реальном времени
  static Stream<String> getLogStream() async* {
    try {
      final log = File(_logFile);
      if (await log.exists()) {
        yield* log.openRead().transform(utf8.decoder).transform(const LineSplitter());
      }
    } catch (e) {
      yield 'Ошибка при получении потока логов: $e';
    }
  }
}