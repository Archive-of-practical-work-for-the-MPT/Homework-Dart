import 'dart:io';
import 'dart:math';
import 'package:ansicolor/ansicolor.dart';

// Глобальные цвета для сообщений
final titleColor = AnsiPen()..magenta(bold: true);
final promptColor = AnsiPen()..cyan(bold: true);
final successColor = AnsiPen()..green(bold: true);
final errorColor = AnsiPen()..red(bold: true);
final infoColor = AnsiPen()..yellow(bold: true);

class Ship {
  final String name;
  final int size;
  List<Point<int>> positions;
  List<bool> hits;

  Ship(this.name, this.size) : positions = [], hits = List.filled(size, false);

  bool isSunk() => hits.every((hit) => hit);

  void place(List<Point<int>> shipPositions) {
    positions = List.from(shipPositions);
  }

  bool takeHit(Point<int> position) {
    for (int i = 0; i < positions.length; i++) {
      if (positions[i] == position) {
        hits[i] = true;
        return true;
      }
    }
    return false;
  }
}

class Board {
  final int size;
  List<List<String>> grid;
  List<Ship> ships = [];

  // Цвета для отображения
  static final waterColor = AnsiPen()..blue(bold: true);
  static final shipColor = AnsiPen()..white(bold: true);
  static final hitColor = AnsiPen()..red(bold: true);
  static final missColor = AnsiPen()..yellow(bold: true);
  static final headerColor = AnsiPen()..green(bold: true);

  Board(this.size) : grid = List.generate(size, (_) => List.filled(size, '~'));

  void display([bool hideShips = false]) {
    // Заголовок с номерами столбцов
    stdout.write(headerColor('   '));
    for (int i = 0; i < size; i++) {
      stdout.write(headerColor('${i + 1}'.padLeft(3)));
    }
    print('');

    for (int row = 0; row < size; row++) {
      // Буквы строк
      stdout.write(
        headerColor(
          '${String.fromCharCode('A'.codeUnitAt(0) + row)} '.padLeft(3),
        ),
      );
      for (int col = 0; col < size; col++) {
        String cell = grid[row][col];
        if (hideShips && cell == 'S') {
          stdout.write(waterColor('~'.padLeft(3)));
        } else {
          switch (cell) {
            case '~':
              stdout.write(waterColor(cell.padLeft(3)));
              break;
            case 'S':
              stdout.write(shipColor(cell.padLeft(3)));
              break;
            case 'X':
              stdout.write(hitColor(cell.padLeft(3)));
              break;
            case 'O':
              stdout.write(missColor(cell.padLeft(3)));
              break;
            default:
              stdout.write(cell.padLeft(3));
          }
        }
      }
      print('');
    }
  }

  // Проверка, можно ли разместить корабль с учетом расстояния в 1 клетку
  bool canPlaceShip(List<Point<int>> positions) {
    for (var pos in positions) {
      // Проверка границ поля
      if (pos.x < 0 || pos.x >= size || pos.y < 0 || pos.y >= size) {
        return false;
      }
      // Проверка, что клетка свободна
      if (grid[pos.x][pos.y] != '~') {
        return false;
      }

      // Проверка соседних клеток (включая диагональные) на наличие других кораблей
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          int checkX = pos.x + dx;
          int checkY = pos.y + dy;

          // Проверка, что координаты в пределах поля
          if (checkX >= 0 && checkX < size && checkY >= 0 && checkY < size) {
            // Если соседняя клетка занята кораблем
            if (grid[checkX][checkY] == 'S') {
              // Проверим, принадлежит ли эта клетка текущему размещаемому кораблю
              bool isPartOfCurrentShip = false;
              for (var shipPos in positions) {
                if (shipPos.x == checkX && shipPos.y == checkY) {
                  isPartOfCurrentShip = true;
                  break;
                }
              }
              // Если соседняя клетка с кораблем не принадлежит текущему кораблю, размещение невозможно
              if (!isPartOfCurrentShip) {
                return false;
              }
            }
          }
        }
      }
    }
    return true;
  }

  bool placeShip(Ship ship, List<Point<int>> positions) {
    if (!canPlaceShip(positions)) {
      return false;
    }

    ship.place(positions);
    ships.add(ship);
    for (var pos in positions) {
      grid[pos.x][pos.y] = 'S';
    }
    return true;
  }

  bool attack(Point<int> position) {
    if (position.x < 0 ||
        position.x >= size ||
        position.y < 0 ||
        position.y >= size) {
      return false;
    }

    if (grid[position.x][position.y] == 'X' ||
        grid[position.x][position.y] == 'O') {
      return false;
    }

    bool hit = false;
    for (var ship in ships) {
      if (ship.takeHit(position)) {
        hit = true;
        grid[position.x][position.y] = 'X';
        break;
      }
    }

    if (!hit) {
      grid[position.x][position.y] = 'O';
    }

    return true;
  }

  bool allShipsSunk() => ships.every((ship) => ship.isSunk());
}

class Player {
  final String name;
  final Board board;
  bool isBot;

  Player(this.name, int boardSize, {this.isBot = false})
    : board = Board(boardSize);

  Point<int>? parsePosition(String input) {
    if (input.length < 2) return null;

    int row = input.codeUnitAt(0) - 'A'.codeUnitAt(0);
    if (row < 0 || row >= board.size) return null;

    String colStr = input.substring(1);
    int col;
    try {
      col = int.parse(colStr) - 1;
    } catch (e) {
      return null;
    }

    if (col < 0 || col >= board.size) return null;

    return Point(row, col);
  }

  void placeShips() {
    if (isBot) {
      _placeShipsAutomatically();
      return;
    }

    List<List<dynamic>> shipTypes = [
      ['Авианосец', 5],
      ['Линкор', 4],
      ['Крейсер', 3],
      ['Подводная лодка', 3],
      ['Эсминец', 2],
      ['Катер', 1],
      ['Лодка', 1],
    ];

    print('\n$name, разместите свои корабли на поле:');
    board.display();

    for (var shipData in shipTypes) {
      String shipName = shipData[0];
      int shipSize = shipData[1];
      Ship ship = Ship(shipName, shipSize);

      bool placed = false;
      while (!placed) {
        print('\nРазмещение $shipName (размер: $shipSize)');

        // Выбор способа размещения
        print('Выберите способ размещения:');
        print('1. Вручную');
        print('2. Автоматически');

        int placementOption = 0;
        while (placementOption != 1 && placementOption != 2) {
          String? optionInput = stdin.readLineSync();
          if (optionInput == null) continue;

          try {
            placementOption = int.parse(optionInput);
            if (placementOption != 1 && placementOption != 2) {
              print(errorColor('Неверный выбор. Введите 1 или 2:'));
            }
          } catch (e) {
            print(errorColor('Неверный выбор. Введите 1 или 2:'));
          }
        }

        if (placementOption == 2) {
          // Автоматическое размещение
          if (_placeSingleShipAutomatically(ship, shipSize)) {
            placed = true;
            print(successColor('$shipName успешно размещен автоматически!'));
            board.display();
          } else {
            print(
              errorColor(
                'Ошибка при автоматическом размещении. Попробуйте вручную.',
              ),
            );
            continue;
          }
        } else {
          // Ручное размещение
          print(promptColor('Введите начальную позицию (например, A1):'));
          String? startPosInput = stdin.readLineSync();
          if (startPosInput == null) continue;

          Point<int>? startPos = parsePosition(startPosInput.toUpperCase());
          if (startPos == null) {
            print(errorColor('Неверная позиция. Попробуйте снова.'));
            continue;
          }

          print(
            promptColor(
              'Введите направление (H для горизонтального, V для вертикального):',
            ),
          );
          String? directionInput = stdin.readLineSync();
          if (directionInput == null) continue;

          List<Point<int>> positions = [];

          if (directionInput.toUpperCase() == 'H') {
            for (int i = 0; i < shipSize; i++) {
              Point<int> pos = Point(startPos.x, startPos.y + i);
              positions.add(pos);
            }
          } else if (directionInput.toUpperCase() == 'V') {
            for (int i = 0; i < shipSize; i++) {
              Point<int> pos = Point(startPos.x + i, startPos.y);
              positions.add(pos);
            }
          } else {
            print(errorColor('Неверное направление. Используйте H или V.'));
            continue;
          }

          if (board.placeShip(ship, positions)) {
            placed = true;
            print(successColor('$shipName успешно размещен!'));
            board.display();
          } else {
            print(
              errorColor(
                'Неверное размещение (корабли не могут касаться друг друга). Попробуйте снова.',
              ),
            );
          }
        }
      }
    }
  }

  bool _placeSingleShipAutomatically(Ship ship, int shipSize) {
    Random random = Random();
    bool placed = false;
    int attempts = 0;

    while (!placed && attempts < 1000) {
      // Увеличил количество попыток
      attempts++;

      int row = random.nextInt(board.size);
      int col = random.nextInt(board.size);

      bool horizontal = random.nextBool();

      List<Point<int>> positions = [];
      bool valid = true;

      if (horizontal) {
        if (col + shipSize > board.size) {
          valid = false;
        } else {
          for (int i = 0; i < shipSize; i++) {
            positions.add(Point(row, col + i));
          }
        }
      } else {
        if (row + shipSize > board.size) {
          valid = false;
        } else {
          for (int i = 0; i < shipSize; i++) {
            positions.add(Point(row + i, col));
          }
        }
      }

      if (valid && board.placeShip(ship, positions)) {
        placed = true;
      }
    }

    return placed;
  }

  void _placeShipsAutomatically() {
    List<List<dynamic>> shipTypes = [
      ['Авианосец', 5],
      ['Линкор', 4],
      ['Крейсер', 3],
      ['Подводная лодка', 3],
      ['Эсминец', 2],
      ['Катер', 1],
      ['Лодка', 1],
    ];

    // Попробуем разместить все корабли, если не получается, то попробуем снова
    bool allPlaced = false;
    int attempts = 0;

    while (!allPlaced && attempts < 100) {
      attempts++;
      // Создаем временную доску для попытки размещения
      Board tempBoard = Board(board.size);
      List<Ship> tempShips = [];
      bool currentAttemptSuccess = true;

      for (var shipData in shipTypes) {
        String shipName = shipData[0];
        int shipSize = shipData[1];
        Ship ship = Ship(shipName, shipSize);

        if (!_placeSingleShipOnBoard(tempBoard, ship, shipSize)) {
          currentAttemptSuccess = false;
          break;
        }
        tempShips.add(ship);
      }

      if (currentAttemptSuccess) {
        // Если все корабли размещены успешно, копируем их на основную доску
        board.ships = tempShips;
        for (int i = 0; i < board.size; i++) {
          for (int j = 0; j < board.size; j++) {
            board.grid[i][j] = tempBoard.grid[i][j];
          }
        }
        allPlaced = true;
      }
    }
  }

  bool _placeSingleShipOnBoard(Board targetBoard, Ship ship, int shipSize) {
    Random random = Random();
    bool placed = false;
    int attempts = 0;

    while (!placed && attempts < 1000) {
      attempts++;

      int row = random.nextInt(targetBoard.size);
      int col = random.nextInt(targetBoard.size);

      bool horizontal = random.nextBool();

      List<Point<int>> positions = [];

      if (horizontal) {
        if (col + shipSize <= targetBoard.size) {
          for (int i = 0; i < shipSize; i++) {
            positions.add(Point(row, col + i));
          }
        }
      } else {
        if (row + shipSize <= targetBoard.size) {
          for (int i = 0; i < shipSize; i++) {
            positions.add(Point(row + i, col));
          }
        }
      }

      if (positions.length == shipSize &&
          targetBoard.placeShip(ship, positions)) {
        placed = true;
      }
    }

    return placed;
  }

  Point<int> getAttackPosition() {
    if (isBot) {
      return _getBotAttackPosition();
    }

    while (true) {
      print(promptColor('$name, введите позицию для атаки (например, A1):'));
      String? input = stdin.readLineSync();
      if (input == null) continue;

      Point<int>? position = parsePosition(input.toUpperCase());
      if (position != null) {
        return position;
      }
      print(errorColor('Неверная позиция. Попробуйте снова.'));
    }
  }

  Point<int> _getBotAttackPosition() {
    Random random = Random();
    int row, col;

    do {
      row = random.nextInt(board.size);
      col = random.nextInt(board.size);
    } while (board.grid[row][col] == 'X' || board.grid[row][col] == 'O');

    return Point(row, col);
  }
}

class BattleshipGame {
  late Player player1;
  late Player player2;
  late Player currentPlayer;
  late Player opponent;
  int boardSize;
  bool isPlayerVsPlayer = false; // Флаг для определения режима игры

  // Цвета для сообщений игры
  static final titleColor = AnsiPen()..magenta(bold: true);
  static final promptColor = AnsiPen()..cyan(bold: true);
  static final successColor = AnsiPen()..green(bold: true);
  static final errorColor = AnsiPen()..red(bold: true);
  static final infoColor = AnsiPen()..yellow(bold: true);

  BattleshipGame(this.boardSize);

  void start() {
    print(titleColor('=== МОРСКОЙ БОЙ ==='));

    print(promptColor('Выберите режим игры:'));
    print('1. Игрок против игрока');
    print('2. Игрок против компьютера');
    int gameMode = 1;

    while (true) {
      String? input = stdin.readLineSync();
      if (input == '1' || input == '2') {
        gameMode = int.parse(input!);
        isPlayerVsPlayer = (gameMode == 1); // Устанавливаем флаг режима
        break;
      }
      print(errorColor('Неверный выбор. Введите 1 или 2:'));
    }

    print(promptColor('Введите имя первого игрока:'));
    String? player1Name = stdin.readLineSync();
    if (player1Name == null || player1Name.isEmpty) {
      player1Name = 'Игрок 1';
    }

    if (gameMode == 1) {
      print(promptColor('Введите имя второго игрока:'));
      String? player2Name = stdin.readLineSync();
      if (player2Name == null || player2Name.isEmpty) {
        player2Name = 'Игрок 2';
      }
      player1 = Player(player1Name, boardSize);
      player2 = Player(player2Name, boardSize);
    } else {
      player1 = Player(player1Name, boardSize);
      player2 = Player('Компьютер', boardSize, isBot: true);
    }

    print(titleColor('\n=== РАЗМЕЩЕНИЕ КОРАБЛЕЙ ==='));
    player1.placeShips();

    // Очищаем консоль только в режиме игрок против игрока
    if (isPlayerVsPlayer) {
      _clearConsole();
    }

    if (gameMode == 1) {
      _promptNextPlayer(player2.name);
      player2.placeShips();
    } else {
      print(infoColor('\nКомпьютер размещает корабли...'));
      player2.placeShips();
      print(successColor('Компьютер разместил все корабли!'));
    }

    // Очищаем консоль только в режиме игрок против игрока
    if (isPlayerVsPlayer) {
      _clearConsole();
    }

    print(titleColor('\n=== НАЧАЛО ИГРЫ ==='));
    currentPlayer = player1;
    opponent = player2;

    // Игровой цикл с возможностью последовательных хитов
    while (!currentPlayer.board.allShipsSunk() &&
        !opponent.board.allShipsSunk()) {
      // Основной игровой цикл для текущего игрока
      bool playerTurn = true;

      while (playerTurn &&
          !currentPlayer.board.allShipsSunk() &&
          !opponent.board.allShipsSunk()) {
        if (!currentPlayer.isBot) {
          print(infoColor('\nХод игрока: ${currentPlayer.name}'));
          print(titleColor('\nВаше поле:'));
          currentPlayer.board.display();
          print(titleColor('\nПоле противника:'));
          opponent.board.display(true);
        }

        Point<int> attackPos = currentPlayer.getAttackPosition();

        bool validAttack = opponent.board.attack(attackPos);
        if (!validAttack) {
          if (!currentPlayer.isBot) {
            print(errorColor('Неверная позиция для атаки. Попробуйте снова.'));
          }
          continue;
        }

        // Очищаем консоль только в режиме игрок против игрока
        if (isPlayerVsPlayer) {
          _clearConsole();
        }

        bool hit = false; // Флаг для проверки попадания
        String result = '';
        if (opponent.board.grid[attackPos.x][attackPos.y] == 'X') {
          hit = true; // Попадание
          result = successColor('ПОПАДАНИЕ!');

          // Проверяем, потоплен ли корабль
          Ship? sunkShip;
          for (var ship in opponent.board.ships) {
            if (ship.positions.contains(attackPos) && ship.isSunk()) {
              sunkShip = ship;
              break;
            }
          }

          if (sunkShip != null) {
            result = successColor('ПОПАДАНИЕ! ${sunkShip.name} потоплен!');
          }
        } else {
          result = infoColor('МИМО!');
        }

        if (!currentPlayer.isBot) {
          print(result);
        }

        // Проверяем победу
        if (opponent.board.allShipsSunk()) {
          print(successColor('\n${currentPlayer.name} победил!'));
          return; // Завершаем игру
        }

        // Если было попадание, игрок продолжает ход, иначе передаем ход следующему игроку
        if (hit) {
          // Игрок продолжает ход
          if (!currentPlayer.isBot) {
            print(infoColor('Вы попали! Стреляйте еще раз.'));
          }
          // Для компьютера также продолжаем ход (но компьютер всегда делает один выстрел за раз)
          playerTurn = true;
        } else {
          // При промахе завершаем ход игрока
          playerTurn = false;
        }
      }

      // Меняем игрока только если ход завершен (был промах)
      if (!playerTurn) {
        if (isPlayerVsPlayer && !currentPlayer.isBot && !opponent.isBot) {
          _promptNextPlayer(opponent.name);
        }

        var temp = currentPlayer;
        currentPlayer = opponent;
        opponent = temp;
      }
    }
  }

  void _promptNextPlayer(String nextPlayerName) {
    print(titleColor('\n=== СМЕНА ИГРОКА ==='));
    print(infoColor('Теперь ходит игрок: $nextPlayerName'));
    print(promptColor('Нажмите Enter, чтобы продолжить...'));
    stdin.readLineSync();
    _clearConsole();
  }

  void _clearConsole() {
    try {
      if (Platform.isWindows) {
        print('\x1B[2J\x1B[3J');
      } else {
        print('\x1B[2J\x1B[3J');
      }
    } catch (e) {
      print('\n' * 100);
    }
  }
}

void main(List<String> arguments) {
  print(titleColor('Добро пожаловать в Морской бой!'));

  print(promptColor('Выберите размер поля:'));
  print('1. Маленькое (8x8)');
  print('2. Среднее (10x10)');
  print('3. Большое (12x12)');

  int boardSize = 10;

  while (true) {
    String? input = stdin.readLineSync();
    if (input == '1') {
      boardSize = 8;
      break;
    } else if (input == '2') {
      boardSize = 10;
      break;
    } else if (input == '3') {
      boardSize = 12;
      break;
    }
    print(errorColor('Неверный выбор. Введите 1, 2 или 3:'));
  }

  BattleshipGame game = BattleshipGame(boardSize);
  game.start();
}
