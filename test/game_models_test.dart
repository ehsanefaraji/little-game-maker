import 'dart:collection';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_game_maker/game_models.dart';

void main() {
  group('GameProject generation', () {
    test('maze has a reachable exit and valid boundaries', () {
      final project = GameProject.create(GameType.maze, 'maze');
      expect(project.cells.length, 121);
      final start = project.cells.indexOf(5);
      final goal = project.cells.indexOf(4);
      expect(start, 12);
      expect(goal, 108);
      final visited = <int>{start};
      final queue = Queue<int>()..add(start);
      while (queue.isNotEmpty) {
        final current = queue.removeFirst();
        final candidates = [current - 11, current + 11, current - 1, current + 1];
        for (final next in candidates) {
          if (next < 0 || next >= project.cells.length) continue;
          if ((next - current).abs() == 1 && next ~/ 11 != current ~/ 11) continue;
          if (project.cells[next] == 1 || !visited.add(next)) continue;
          queue.add(next);
        }
      }
      expect(visited.contains(goal), isTrue);
      for (var i = 0; i < 11; i++) {
        expect(project.cells[i], 1);
        expect(project.cells[110 + i], 1);
      }
    });

    test('memory board contains eight matching pairs', () {
      final project = GameProject.create(GameType.memory, 'memory');
      expect(project.cells.length, 16);
      final counts = <int, int>{};
      for (final card in project.cells) {
        counts[card] = (counts[card] ?? 0) + 1;
      }
      expect(counts.length, 8);
      expect(counts.values.every((count) => count == 2), isTrue);
    });

    test('all templates have correct board dimensions', () {
      for (final type in GameType.values) {
        final project = GameProject.create(type, 'test');
        expect(project.cells.length, type.columns * type.rows);
      }
    });

    test('project settings survive JSON round trip', () {
      final project = GameProject.create(GameType.platformer, 'مرحله آزمایشی')
        ..character = 4
        ..background = 2
        ..soundEnabled = false
        ..musicEnabled = true;
      final restored = GameProject.fromJson(project.toJson());
      expect(restored.name, project.name);
      expect(restored.type, project.type);
      expect(restored.cells, project.cells);
      expect(restored.character, 4);
      expect(restored.background, 2);
      expect(restored.soundEnabled, isFalse);
      expect(restored.musicEnabled, isTrue);
    });
  });
}
