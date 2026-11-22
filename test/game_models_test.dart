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

    test('platformer template has one start marker and one finish marker', () {
      final project = GameProject.create(GameType.platformer, 'platformer');
      expect(project.cells.where((cell) => cell == 5).length, 1);
      expect(project.cells.where((cell) => cell == 4).length, 1);
    });

    test('driving template contains editable obstacles and collectible coins', () {
      final project = GameProject.create(GameType.driving, 'driving');
      expect(project.cells.where((cell) => cell == 2).length, greaterThanOrEqualTo(5));
      expect(project.cells.where((cell) => cell == 3).length, greaterThanOrEqualTo(4));
      expect(project.cells.length, 24);
    });

    test('malformed saved project data is normalized safely', () {
      final project = GameProject.fromJson({
        'id': '',
        'name': '   ',
        'type': 'driving',
        'cells': [2, 'bad', 3, 99, -4],
        'character': 999,
        'background': -8,
        'soundEnabled': 'yes',
        'musicEnabled': null,
      });
      expect(project.name, 'بازی من');
      expect(project.id, isNotEmpty);
      expect(project.cells.length, 24);
      expect(project.cells.take(5).toList(), [2, 0, 3, 0, 0]);
      expect(project.character, characterOptions.length - 1);
      expect(project.background, 0);
      expect(project.soundEnabled, isTrue);
      expect(project.musicEnabled, isFalse);
    });

    test('multiple levels survive JSON round trip and switch independently', () {
      final project = GameProject.create(GameType.maze, 'چندمرحله‌ای');
      final firstLevel = List<int>.from(project.cells);
      project.addLevel(copyFrom: firstLevel);
      project.cells[0] = 0;
      project.syncActiveLevel();
      project.setActiveLevel(0);
      expect(project.cells, firstLevel);
      project.setActiveLevel(1);
      expect(project.cells[0], 0);
      final restored = GameProject.fromJson(project.toJson());
      expect(restored.levels.length, 2);
      expect(restored.activeLevel, 1);
      expect(restored.cells[0], 0);
      restored.removeActiveLevel();
      expect(restored.levels.length, 1);
    });

    test('legacy project without level metadata becomes a one-level project', () {
      final legacy = GameProject.fromJson({
        'id': 'legacy',
        'name': 'قدیمی',
        'type': 'memory',
        'cells': List<int>.generate(16, (i) => (i % 8) + 1),
      });
      expect(legacy.levels.length, 1);
      expect(legacy.activeLevel, 0);
      expect(legacy.cells.length, 16);
    });

    test('platformer layers compose in order and survive JSON round trip', () {
      final project = GameProject.create(GameType.platformer, 'لایه‌ها');
      final base = List<int>.from(project.cells);
      project.addLayer();
      project.layers[project.activeLayer][0] = 2;
      project.cells = project.composeLayers();
      expect(project.cells[0], 2);
      project.addLayer();
      project.layers[project.activeLayer][0] = -1;
      project.cells = project.composeLayers();
      expect(project.cells[0], 0);
      final restored = GameProject.fromJson(project.toJson());
      expect(restored.layers.length, 3);
      expect(restored.cells[0], 0);
      expect(restored.layers[1][0], 2);
      expect(restored.layers[2][0], -1);
      restored.layers[2][0] = 0;
      expect(restored.composeLayers()[0], 2);
      restored.layers[1][0] = 0;
      expect(restored.composeLayers(), base);
    });

    test('duplicating a level keeps its independent layer stack', () {
      final project = GameProject.create(GameType.platformer, 'مرحله');
      project.addLayer();
      project.layers[1][0] = 2;
      project.cells = project.composeLayers();
      project.syncActiveLevel();
      project.addLevel(copyFrom: project.cells);
      expect(project.layers.length, 2);
      expect(project.layers[1][0], 2);
      project.layers[1][1] = 3;
      project.cells = project.composeLayers();
      project.syncActiveLevel();
      project.setActiveLevel(0);
      expect(project.composeLayers()[1], 0);
    });

    test('removing the selected layer removes that layer, not always the last one', () {
      final project = GameProject.create(GameType.platformer, 'حذف لایه');
      project.addLayer();
      project.layers[1][0] = 2;
      project.addLayer();
      project.layers[2][1] = 3;
      project.activeLayer = 1;
      project.removeActiveLayer();
      expect(project.layers.length, 2);
      expect(project.layers[1][1], 3);
      expect(project.activeLayer, 1);
    });

    test('moving the active layer changes render order and preserves its contents', () {
      final project = GameProject.create(GameType.platformer, 'ترتیب لایه');
      project.addLayer();
      project.layers[1][0] = 2;
      project.cells = project.composeLayers();
      project.moveActiveLayer(-1);
      expect(project.activeLayer, 0);
      expect(project.layers[0][0], 2);
      expect(project.composeLayers()[0], 2);
    });


    test('layer visibility is preserved without deleting hidden content', () {
      final project = GameProject.create(GameType.platformer, 'نمایش لایه');
      project.addLayer();
      project.layers[1][0] = 2;
      project.cells = project.composeLayers();
      expect(project.cells[0], 2);
      project.toggleLayerVisibility(1);
      expect(project.cells[0], 0);
      final restored = GameProject.fromJson(project.toJson());
      expect(restored.layerVisibility[1], isFalse);
      expect(restored.layers[1][0], 2);
      restored.toggleLayerVisibility(1);
      expect(restored.cells[0], 2);
    });

    test('gameplay rule settings survive JSON round trip and are bounded', () {
      final project = GameProject.create(GameType.maze, 'قانون‌ها')
        ..coinBonusScore = 20
        ..extraLifeOnCoin = true;
      final restored = GameProject.fromJson(project.toJson());
      expect(restored.coinBonusScore, 20);
      expect(restored.extraLifeOnCoin, isTrue);
      final bounded = GameProject.fromJson({...project.toJson(), 'coinBonusScore': 999});
      expect(bounded.coinBonusScore, 50);
    });


    test('moving a layer also moves its visibility state', () {
      final project = GameProject.create(GameType.platformer, 'جابجایی لایه');
      project.addLayer();
      project.toggleLayerVisibility(1);
      project.moveActiveLayer(-1);
      expect(project.activeLayer, 0);
      expect(project.layerVisibility[0], isFalse);
      final restored = GameProject.fromJson(project.toJson());
      expect(restored.layerVisibility[0], isFalse);
    });

    test('non-platformer board edits are not overwritten during synchronization', () {
      final project = GameProject.create(GameType.maze, 'ویرایش هزارتو');
      project.cells[0] = 0;
      project.syncActiveLevel();
      expect(project.cells[0], 0);
      expect(project.levels[0][0], 0);
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
