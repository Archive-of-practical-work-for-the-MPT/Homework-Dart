// Логгер для игры в морской бой
import 'dart:io';
import 'dart:async';
import 'file_handler.dart';

class GameLogger {
  static const String _logFile = 'game.log';

  /// Логирование хода игрока
  static Future<void> logPlayerMove(String playerName, String position, String result) async {
    final message = 'Игрок $playerName сделал ход на $position, результат: $result';
    await FileHandler.writeLog(message);
  }

  /// Логирование ошибки при ходе игрока
  static Future<void> logPlayerMoveError(String playerName, String position, String errorMessage) async {
    final message = 'Игрок $playerName пытался сделать ход на поле $position, он уже ходил на него ранее, вызвана ошибка: $errorMessage';
    await FileHandler.writeLog(message);
  }

  /// Логирование ошибки при размещении корабля
  static Future<void> logShipPlacementError(String playerName, String position, String errorMessage) async {
    final message = 'Игрок $playerName пытался поставить корабль на уже занятое поле $position при расстановке кораблей, вызвана ошибка: $errorMessage';
    await FileHandler.writeLog(message);
  }

  /// Логирование начала игры
  static Future<void> logGameStart(String player1Name, String player2Name, int boardSize) async {
    final message = 'Начало игры между $player1Name и $player2Name на поле размером ${boardSize}x$boardSize';
    await FileHandler.writeLog(message);
  }

  /// Логирование завершения игры
  static Future<void> logGameEnd(String winnerName, String loserName) async {
    final message = 'Игра завершена. Победитель: $winnerName, Проигравший: $loserName';
    await FileHandler.writeLog(message);
  }

  /// Логирование размещения корабля
  static Future<void> logShipPlacement(String playerName, String shipName, String startPosition, String direction) async {
    final message = 'Игрок $playerName разместил корабль "$shipName" начиная с $startPosition в направлении $direction';
    await FileHandler.writeLog(message);
  }
}