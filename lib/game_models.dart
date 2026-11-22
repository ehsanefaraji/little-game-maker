import 'dart:math';

enum GameType { maze, platformer, memory, driving }

extension GameTypeText on GameType {
  String get title => switch (this) {
        GameType.maze => 'هزارتو',
        GameType.platformer => 'سکوبازی',
        GameType.memory => 'بازی حافظه',
        GameType.driving => 'رانندگی',
      };
  String get description => switch (this) {
        GameType.maze => 'از مسیرهای پیچ‌درپیچ عبور کن و گنج را پیدا کن.',
        GameType.platformer => 'بپر، از دشمن‌ها دوری کن و سکه جمع کن.',
        GameType.memory => 'کارت‌ها را برگردان و جفت‌های یکسان را پیدا کن.',
        GameType.driving => 'در سه مسیر رانندگی کن و از موانع جاخالی بده.',
      };
  String get emoji => switch (this) {
        GameType.maze => '🧭',
        GameType.platformer => '🦸',
        GameType.memory => '🧠',
        GameType.driving => '🏎️',
      };
  int get columns => switch (this) {
        GameType.maze => 11,
        GameType.platformer => 12,
        GameType.memory => 4,
        GameType.driving => 3,
      };
  int get rows => switch (this) {
        GameType.maze => 11,
        GameType.platformer => 8,
        GameType.memory => 4,
        GameType.driving => 8,
      };
}

const characterOptions = ['🧒', '👧', '🐱', '🐸', '🦊', '🐼', '🦄', '🤖'];
const backgroundNames = ['جنگل جادویی', 'جزیره آفتابی', 'فضای کهکشانی', 'سرزمین آب‌نباتی'];
const backgroundTop = [0xFFB8E6C1, 0xFF9EDCF5, 0xFF202A64, 0xFFFFC6D8];
const backgroundBottom = [0xFFECF8C9, 0xFFFFE7A8, 0xFF7357A6, 0xFFFFE5A8];

class GameProject {
  GameProject({
    required this.id,
    required this.name,
    required this.type,
    required this.cells,
    this.character = 0,
    this.background = 0,
    this.soundEnabled = true,
    this.musicEnabled = false,
  });

  final String id;
  String name;
  GameType type;
  List<int> cells;
  int character;
  int background;
  bool soundEnabled;
  bool musicEnabled;

  int get columns => type.columns;
  int get rows => type.rows;

  GameProject copy() => GameProject(
        id: id,
        name: name,
        type: type,
        cells: List<int>.from(cells),
        character: character,
        background: background,
        soundEnabled: soundEnabled,
        musicEnabled: musicEnabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'cells': cells,
        'character': character,
        'background': background,
        'soundEnabled': soundEnabled,
        'musicEnabled': musicEnabled,
      };

  factory GameProject.fromJson(Map<String, dynamic> json) {
    final type = GameType.values.firstWhere(
      (e) => e.name == json['type'] ?? json['kind'],
      orElse: () => GameType.maze,
    );
    final expected = type.columns * type.rows;
    final raw = (json['cells'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [];
    final cells = List<int>.generate(
      expected,
      (i) => i < raw.length ? raw[i] : 0,
    );
    return GameProject(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? 'بازی من',
      type: type,
      cells: cells,
      character: ((json['character'] as num?)?.toInt() ?? 0).clamp(0, characterOptions.length - 1).toInt(),
      background: ((json['background'] as num?)?.toInt() ?? 0).clamp(0, backgroundNames.length - 1).toInt(),
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      musicEnabled: json['musicEnabled'] as bool? ?? false,
    );
  }

  static GameProject create(GameType type, String name) {
    final count = type.columns * type.rows;
    final cells = List<int>.filled(count, 0);
    final random = Random();
    if (type == GameType.maze) {
      for (var r = 0; r < 11; r++) {
        for (var c = 0; c < 11; c++) {
          cells[r * 11 + c] = 1;
        }
      }
      for (var r = 1; r < 10; r += 2) {
        for (var c = 1; c < 10; c += 2) {
          cells[r * 11 + c] = 0;
        }
      }
      final visited = <int>{12};
      final stack = <int>[12];
      cells[12] = 5;
      while (stack.isNotEmpty) {
        final current = stack.last;
        final candidates = <int>[];
        for (final delta in [-22, 22, -2, 2]) {
          final next = current + delta;
          final nr = next ~/ 11;
          final nc = next % 11;
          if (nr >= 1 && nr <= 9 && nc >= 1 && nc <= 9 && !visited.contains(next)) {
            candidates.add(next);
          }
        }
        if (candidates.isEmpty) {
          stack.removeLast();
        } else {
          final next = candidates[random.nextInt(candidates.length)];
          final between = (current + next) ~/ 2;
          cells[between] = 0;
          cells[next] = 0;
          visited.add(next);
          stack.add(next);
        }
      }
      cells[108] = 4;
      final open = <int>[];
      for (var i = 0; i < cells.length; i++) {
        if (cells[i] == 0 && i != 12 && i != 108) open.add(i);
      }
      open.shuffle(random);
      for (final i in open.take(8)) cells[i] = 2;
    } else if (type == GameType.platformer) {
      for (var c = 0; c < 12; c++) cells[7 * 12 + c] = 1;
      for (final i in [17, 20, 26, 30, 39, 43, 51, 56, 66, 70]) {
        if (i < cells.length) cells[i] = 2;
      }
      for (final i in [22, 34, 47, 61]) cells[i] = 3;
      for (final i in [27, 41, 53]) cells[i] = 1;
      cells[6 * 12 + 11] = 4;
      cells[6 * 12] = 5;
    } else if (type == GameType.driving) {
      for (final i in [8, 17, 29, 38, 51, 62, 70]) {
        if (i < cells.length) cells[i] = 3;
      }
      for (final i in [12, 25, 44, 57, 73]) {
        if (i < cells.length) cells[i] = 2;
      }
    } else {
      final symbols = List<int>.generate(8, (i) => i + 1)..addAll(List<int>.generate(8, (i) => i + 1));
      symbols.shuffle(random);
      for (var i = 0; i < 16; i++) cells[i] = symbols[i];
    }
    return GameProject(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      type: type,
      cells: cells,
    );
  }
}
