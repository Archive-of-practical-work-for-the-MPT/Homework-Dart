import 'dart:io';
import 'dart:math';

late List<List<String>> board;
late int size;
String currentPlayer = 'X';
bool gameOver = false;
String botPlayer = 'O';

/// Запуск игры
void startGame() {
  print('Добро пожаловать в игру Крестики-Нолики!');
  
  while (true) {
    String mode = selectGameMode();
    
    initializeBoard();
    randomizeFirstPlayer(mode);
    playGame(mode);
    
    if (!playAgain()) { break; }
  }
  
  print('Спасибо за игру!');
}

String selectGameMode() {
  while (true) {
    print('\nВыберите режим игры:');
    print('1. Друг против друга');
    print('2. Против робота');
    stdout.write('Введите ваш выбор (1 или 2): ');
    
    String? input = stdin.readLineSync();
    if (input == '1') { return 'PVP'; }
    else if (input == '2') { return 'PVB'; }
    else { print('Неверный выбор. Попробуйте снова.'); }
  }
}

void initializeBoard() {
  while (true) {
    stdout.write('Введите размер игрового поля (от 3 до 6): ');
    String? input = stdin.readLineSync();
    
    try {
      int parsedSize = int.parse(input ?? '');
      if (parsedSize >= 3 && parsedSize <= 6) {
        size = parsedSize;
        board = List.generate(size, (i) => List.generate(size, (j) => ' '));
        break;
      } else {
        print('Размер должен быть не менее 3 и не более 6. Попробуйте снова.');
      }
    } catch (e) {
      print('Пожалуйста, введите корректное число.');
    }
  }
}

void randomizeFirstPlayer(String mode) {
  if (mode == 'PVB') {
    // В режиме против бота: 50% шанс, что первым ходит игрок, 50% что бот
    if (Random().nextBool()) {
      currentPlayer = 'X'; // Игрок ходит первым
      botPlayer = 'O'; // Бот играет за O
      print('\nПервым ходит игрок (X)');
    } else {
      currentPlayer = 'X'; // Бот ходит первым
      botPlayer = 'X'; // Бот играет за X
      print('\nПервым ходит бот (X)');
    }
  } else {
    // В режиме игрок против игрока, случайно выбираем между X и O
    currentPlayer = Random().nextBool() ? 'X' : 'O';
    print('\nПервым ходит игрок $currentPlayer');
  }
}

void playGame(String mode) {
  gameOver = false;
  
  while (!gameOver) {
    displayBoard();
    
    if (mode == 'PVB' && currentPlayer == botPlayer) { makeBotMove(); }
    else { makePlayerMove(); }
    
    // Проверка состояния игры
    if (checkWin()) {
      displayBoard();
      
      if (mode == 'PVB' && currentPlayer == botPlayer) { print('Бот победил!'); }
      else { print('Игрок $currentPlayer победил!'); }

      gameOver = true;
    } else if (checkDraw()) {
      displayBoard();
      print('Ничья! Все клетки заполнены.');
      gameOver = true;
    }
    
    // Смена игрока
    if (!gameOver) { currentPlayer = currentPlayer == 'X' ? 'O' : 'X'; }
  }
}

void displayBoard() {
  print('\nТекущее состояние поля:');
  
  // Печать номеров столбцов
  String header = '  ' + List.generate(size, (j) => '  $j ').join();
  print(header);
  
  // Функция для создания строки с разделителями
  String separatorLine() => '  ' + List.filled(size, '+---').join() + '+';
  
  for (int i = 0; i < size; i++) {
    print(separatorLine());
    String row = '$i ' + List.generate(size, (j) => '| ${board[i][j]} ').join() + '|';
    print(row);
  }
  print(separatorLine());
}


void makePlayerMove() {
  while (true) {
    stdout.write('Игрок $currentPlayer, введите координаты хода (строка столбец): ');
    String? input = stdin.readLineSync();
    
    try {
      List<String> coords = input!.split(' ');
      if (coords.length != 2) {
        print('Пожалуйста, введите две координаты через пробел.');
        continue;
      }
      
      var (row, col) = (int.parse(coords[0]), int.parse(coords[1]));
      
      if (row < 0 || row >= size || col < 0 || col >= size) {
        print('Координаты должны быть в диапазоне от 0 до ${size - 1}.');
        continue;
      }
      
      if (board[row][col] != ' ') {
        print('Эта клетка уже занята. Выберите другую.');
        continue;
      }
      
      board[row][col] = currentPlayer;
      break;
    } catch (e) { print('Пожалуйста, введите корректные координаты.'); }
  }
}

void makeBotMove() {
  print('Бот делает ход...');
  
  /// Простая стратегия бота:
  /// 1. Проверить, может ли бот выиграть следующим ходом
  /// 2. Проверить, может ли игрок выиграть следующим ходом и заблокировать его
  /// 3. Выбрать случайную доступную клетку
  
  // Поиск выигрышного хода для бота
  for (int i = 0; i < size; i++) {
    for (int j = 0; j < size; j++) {
      if (board[i][j] == ' ') {
        board[i][j] = currentPlayer;
        if (checkWin()) {
          print('Бот выбрал клетку: $i $j');
          return;
        }
        board[i][j] = ' '; // Отменить ход
      }
    }
  }
  
  // Блокировка выигрышного хода игрока
  String opponent = currentPlayer == 'X' ? 'O' : 'X';
  for (int i = 0; i < size; i++) {
    for (int j = 0; j < size; j++) {
      if (board[i][j] == ' ') {
        board[i][j] = opponent;
        if (checkWin()) {
          board[i][j] = currentPlayer; // Заблокировать
          print('Бот выбрал клетку: $i $j');
          return;
        }
        board[i][j] = ' '; // Отменить ход
      }
    }
  }
  
  // Выбор случайной доступной клетки
  List<List<int>> availableMoves = [];
  for (int i = 0; i < size; i++) {
    for (int j = 0; j < size; j++) {
      if (board[i][j] == ' ') {
        availableMoves.add([i, j]);
      }
    }
  }
  
  if (availableMoves.isNotEmpty) {
    List<int> move = availableMoves[Random().nextInt(availableMoves.length)];
    board[move[0]][move[1]] = currentPlayer;
    print('Бот выбрал клетку: ${move[0]} ${move[1]}');
  }
}

bool checkLine(List<List<int>> line) {
  for (var coord in line) {
    if (board[coord[0]][coord[1]] != currentPlayer) return false;
  }
  return true;
}

bool checkWin() {
  // Проверка строк и столбцов
  for (int i = 0; i < size; i++) {
    if (checkLine(List.generate(size, (j) => [i, j]))) return true; // строка
    if (checkLine(List.generate(size, (j) => [j, i]))) return true; // столбец
  }
  // Проверка диагоналей
  if (checkLine(List.generate(size, (i) => [i, i]))) return true; // главная диагональ
  if (checkLine(List.generate(size, (i) => [i, size - 1 - i]))) return true; // побочная диагональ
  return false;
}

/// Проверка ничьей
bool checkDraw() {
  for (int i = 0; i < size; i++) {
    for (int j = 0; j < size; j++) {
      if (board[i][j] == ' ') { return false; }
    }
  }
  return true; // Все клетки заполнены
}

/// Предложение сыграть еще раз
bool playAgain() {
  while (true) {
    stdout.write('\nХотите сыграть еще раз? (y/n): ');
    String? input = stdin.readLineSync()?.toLowerCase();
    
    if (input == 'y') { return true; }
    else if (input == 'n') { return false; }
    else { print('Пожалуйста, введите y (да) или n (нет).'); }
  }
}