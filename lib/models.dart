// Модели данных для игры в морской бой

/// Модель игрока для хранения статистики
class PlayerData {
  final String name;
  int gamesPlayed;
  int wins;
  int losses;

  PlayerData({
    required this.name,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
  });

  /// Создание объекта из JSON
  factory PlayerData.fromJson(Map<String, dynamic> json) {
    return PlayerData(
      name: json['name'],
      gamesPlayed: json['gamesPlayed'],
      wins: json['wins'],
      losses: json['losses'],
    );
  }

  /// Преобразование объекта в JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gamesPlayed': gamesPlayed,
      'wins': wins,
      'losses': losses,
    };
  }

  @override
  String toString() {
    return 'PlayerData(name: $name, gamesPlayed: $gamesPlayed, wins: $wins, losses: $losses)';
  }
}

/// Модель данных текущей игры
class GameData {
  final String player1Name;
  final String player2Name;
  int player1Hits;
  int player1Misses;
  int player2Hits;
  int player2Misses;
  List<ShipStatus> player1Ships;
  List<ShipStatus> player2Ships;

  GameData({
    required this.player1Name,
    required this.player2Name,
    this.player1Hits = 0,
    this.player1Misses = 0,
    this.player2Hits = 0,
    this.player2Misses = 0,
    List<ShipStatus>? player1Ships,
    List<ShipStatus>? player2Ships,
  })  : player1Ships = player1Ships ?? [],
        player2Ships = player2Ships ?? [];

  /// Создание объекта из JSON
  factory GameData.fromJson(Map<String, dynamic> json) {
    return GameData(
      player1Name: json['player1Name'],
      player2Name: json['player2Name'],
      player1Hits: json['player1Hits'],
      player1Misses: json['player1Misses'],
      player2Hits: json['player2Hits'],
      player2Misses: json['player2Misses'],
      player1Ships: (json['player1Ships'] as List)
          .map((e) => ShipStatus.fromJson(e))
          .toList(),
      player2Ships: (json['player2Ships'] as List)
          .map((e) => ShipStatus.fromJson(e))
          .toList(),
    );
  }

  /// Преобразование объекта в JSON
  Map<String, dynamic> toJson() {
    return {
      'player1Name': player1Name,
      'player2Name': player2Name,
      'player1Hits': player1Hits,
      'player1Misses': player1Misses,
      'player2Hits': player2Hits,
      'player2Misses': player2Misses,
      'player1Ships': player1Ships.map((e) => e.toJson()).toList(),
      'player2Ships': player2Ships.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'GameData(player1Name: $player1Name, player2Name: $player2Name, '
        'player1Hits: $player1Hits, player1Misses: $player1Misses, '
        'player2Hits: $player2Hits, player2Misses: $player2Misses)';
  }
}

/// Статус корабля в игре
class ShipStatus {
  final String name;
  final int size;
  int hits;
  bool isSunk;

  ShipStatus({
    required this.name,
    required this.size,
    this.hits = 0,
    this.isSunk = false,
  });

  /// Создание объекта из JSON
  factory ShipStatus.fromJson(Map<String, dynamic> json) {
    return ShipStatus(
      name: json['name'],
      size: json['size'],
      hits: json['hits'],
      isSunk: json['isSunk'],
    );
  }

  /// Преобразование объекта в JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'size': size,
      'hits': hits,
      'isSunk': isSunk,
    };
  }

  @override
  String toString() {
    return 'ShipStatus(name: $name, size: $size, hits: $hits, isSunk: $isSunk)';
  }
}