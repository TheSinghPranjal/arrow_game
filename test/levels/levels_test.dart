import 'package:arrow_game/core/constants/game_constants.dart';
import 'package:arrow_game/core/utils/grid_utils.dart';
import 'package:arrow_game/core/utils/shape_utils.dart';
import 'package:arrow_game/features/gameplay/engine/arrow_engine.dart';
import 'package:arrow_game/features/gameplay/engine/dependency_graph.dart';
import 'package:arrow_game/features/gameplay/engine/game_controller.dart';
import 'package:arrow_game/features/gameplay/engine/level_generator.dart';
import 'package:arrow_game/features/gameplay/engine/level_validator.dart';
import 'package:arrow_game/features/gameplay/models/level_model.dart';
import 'package:arrow_game/features/gameplay/models/shape_model.dart';
import 'package:arrow_game/features/levels/level_definitions.dart';
import 'package:arrow_game/features/levels/level_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  final repo = LevelRepository();
  const validator = LevelValidator();

  test('levels are numbered contiguously 1..N', () {
    expect(levelDefinitions.length, GameConstants.totalLevels);
    expect([for (final d in levelDefinitions) d.levelNumber], List.generate(GameConstants.totalLevels, (i) => i + 1));
  });

  test('level 20 is the filled Nested board (Medium)', () {
    final l = repo.level(20);
    expect(l.name, 'Nested');
    expect(l.difficulty, Difficulty.medium);
    expect((l.gridRows, l.gridColumns), (15, 12));
    expect(l.coveredCellCount, l.maskCellCount);
  });

  test('levels 21–30 are the new hand-tuned boards and fully covered', () {
    const names = [
      'Gridlock',
      'Pyramid Steps',
      'Hooks',
      'Bastion',
      'Snakes',
      'Crossroads',
      'Long Haul',
      'Bullseye',
      'Hive',
      'Grand Maze',
    ];
    for (var i = 0; i < names.length; i++) {
      final l = repo.level(21 + i);
      expect(l.name, names[i]);
      expect(l.coveredCellCount, l.maskCellCount, reason: names[i]);
      final (lo, hi) = l.params.arrowRange;
      expect(l.arrows.length, inInclusiveRange(lo, hi), reason: names[i]);
    }
    expect(levelDefinitions.length, 150);
  });

  test('level 19 is the twisty filled Circuit board (Easy)', () {
    final l = repo.level(19);
    expect(l.name, 'Circuit');
    expect(l.difficulty, Difficulty.easy);
    expect((l.gridRows, l.gridColumns), (13, 11));
    expect(l.coveredCellCount, l.maskCellCount);
    final bent = l.arrows.where(
      (a) => a.cells.map((c) => c.row).toSet().length > 1 && a.cells.map((c) => c.col).toSet().length > 1,
    );
    expect(bent.length, greaterThanOrEqualTo(l.arrows.length ~/ 2), reason: 'mostly twisting arrows');
  });

  test('level 18 is the tall filled Citadel board (Hard)', () {
    final l = repo.level(18);
    expect(l.name, 'Citadel');
    expect(l.difficulty, Difficulty.hard);
    expect((l.gridRows, l.gridColumns), (16, 12));
    expect(l.coveredCellCount, l.maskCellCount);
    expect(l.arrows.map((a) => a.length).reduce((a, b) => a > b ? a : b), greaterThanOrEqualTo(12));
  });

  test('level 17 is the filled Switchback board (Medium) with long folding arrows', () {
    final l = repo.level(17);
    expect(l.name, 'Switchback');
    expect(l.difficulty, Difficulty.medium);
    expect((l.gridRows, l.gridColumns), (14, 12));
    expect(l.coveredCellCount, l.maskCellCount);
    expect(l.arrows.map((a) => a.length).reduce((a, b) => a > b ? a : b), greaterThanOrEqualTo(10));
  });

  test('level 16 is the tiered Layer Cake board (Easy)', () {
    final l = repo.level(16);
    expect(l.name, 'Layer Cake');
    expect(l.difficulty, Difficulty.easy);
    expect(l.gridRows, 8, reason: '3 tiers of 2 rows + 2 gap rows');
    final widths = [for (final r in l.occupancyMask) r.where((v) => v).length];
    expect(widths[2], 0, reason: 'gap row between tiers');
    expect(widths[5], 0);
    expect(widths.first, lessThan(widths.last), reason: 'widens toward the bottom');
    expect(l.coveredCellCount / l.maskCellCount, greaterThanOrEqualTo(0.95));
  });

  test('level 15 is the Frame board (Hard) with a long wrapping arrow', () {
    final l = repo.level(15);
    expect(l.name, 'Frame');
    expect(l.difficulty, Difficulty.hard);
    expect((l.gridRows, l.gridColumns), (12, 12));
    expect(l.coveredCellCount, l.maskCellCount);
    expect(l.arrows.map((a) => a.length).reduce((a, b) => a > b ? a : b), greaterThanOrEqualTo(14));
  });

  test('level 14 is the dense Tangle board (Medium)', () {
    final l = repo.level(14);
    expect(l.name, 'Tangle');
    expect(l.difficulty, Difficulty.medium);
    expect((l.gridRows, l.gridColumns), (12, 11));
    expect(l.coveredCellCount, l.maskCellCount);
  });

  test('level 13 is the small filled Zigzag board (Easy)', () {
    final l = repo.level(13);
    expect(l.name, 'Zigzag');
    expect(l.difficulty, Difficulty.easy);
    expect((l.gridRows, l.gridColumns), (9, 7));
    expect(l.coveredCellCount, l.maskCellCount);
  });

  test('level 12 is the tall filled Corridors board (Hard)', () {
    final l = repo.level(12);
    expect(l.name, 'Corridors');
    expect(l.difficulty, Difficulty.hard);
    expect((l.gridRows, l.gridColumns), (14, 10));
    expect(l.coveredCellCount, l.maskCellCount);
  });

  test('level 11 is the filled 11x11 Maze board (Medium) and old 11..60 moved up', () {
    final l = repo.level(11);
    expect(l.name, 'Maze');
    expect(l.difficulty, Difficulty.medium);
    expect((l.gridRows, l.gridColumns), (11, 11));
    expect(l.coveredCellCount, l.maskCellCount);
    expect(levelDefinitions[100].name, 'Flower');
    expect(levelDefinitions.map((d) => d.name), contains('Grand Star'));
  });

  test('difficulty cycles Easy → Medium → Hard, 20 of each', () {
    for (var n = 1; n <= GameConstants.totalLevels; n++) {
      expect(Difficulty.forLevel(n), Difficulty.values[(n - 1) % 3]);
      expect(levelDefinitions[n - 1].difficulty, Difficulty.values[(n - 1) % 3]);
    }
    expect(Difficulty.forLevel(4), Difficulty.easy, reason: 'level 4 resets to easy');
  });

  test('every level has a unique seed', () {
    expect(levelDefinitions.map((d) => d.seed).toSet().length, GameConstants.totalLevels);
  });

  test('generation is deterministic', () {
    for (final n in [1, 11, 23, 61]) {
      final a = LevelRepository().level(n), b = LevelRepository().level(n);
      expect(
        a.arrows.map((x) => '${x.cells}${x.direction}').toList(),
        b.arrows.map((x) => '${x.cells}${x.direction}').toList(),
      );
    }
  });

  group('all levels', () {
    for (var n = 1; n <= GameConstants.totalLevels; n++) {
      test('level $n passes LevelValidator and is reasonably sized', () {
        final level = repo.level(n);
        final report = validator.validate(level);
        expect(report.isValid, isTrue, reason: report.toString());
        expect(validator.validateShapeMask(level), isEmpty);
        expect(validator.validateArrowPositions(level), isEmpty);
        expect(validator.validateArrowDirections(level), isEmpty);
        expect(validator.validateNoOverlaps(level), isEmpty);
        expect(validator.validateSolutionOrder(level), isEmpty);
        expect(validator.validateDependencyGraph(level), isEmpty);
        expect(validator.validateAllArrowsCanEscape(level), isEmpty);
        expect(DependencyGraph.build(level.arrows, level.gridRows, level.gridColumns).isAcyclic, isTrue);

        final (lo, hi) = level.params.arrowRange;
        expect(level.arrows.length, inInclusiveRange(lo, hi), reason: 'arrow count for ${level.difficulty.name}');
        expect(level.coveredCellCount / level.maskCellCount, greaterThanOrEqualTo(level.params.minFill));
        expect(level.arrows.every((a) => a.length >= 1), isTrue);
      });
    }
  });

  test('simulation: every level is cleared by playing its solution order through the game controller', () async {
    final container = await makeContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(gameControllerProvider.notifier);
    for (var n = 1; n <= GameConstants.totalLevels; n++) {
      ctrl.startLevel(n);
      final level = container.read(gameControllerProvider)!.level;
      for (final id in level.solutionOrder) {
        expect(ctrl.tapArrow(id), TapOutcome.escaped, reason: 'level $n arrow $id');
      }
      final s = container.read(gameControllerProvider)!;
      expect(s.isLevelCompleted, isTrue, reason: 'level $n');
      expect(s.lives, 3);
      expect(s.remainingArrows, 0);
    }
  });

  test('simulation: hint-guided play also clears every level (alternative orders work)', () async {
    final container = await makeContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(gameControllerProvider.notifier);
    for (var n = 1; n <= GameConstants.totalLevels; n++) {
      ctrl.startLevel(n);
      while (!container.read(gameControllerProvider)!.isLevelCompleted) {
        final s = container.read(gameControllerProvider)!;
        final free = ArrowEngine.removable(s.arrows, s.level.gridRows, s.level.gridColumns);
        expect(free, isNotEmpty, reason: 'level $n stuck');
        // Pick the *last* free arrow to diverge from the stored order.
        expect(ctrl.tapArrow(free.last.id), TapOutcome.escaped);
      }
    }
  });

  test('all levels have different arrangements', () {
    final sigs = <String>{};
    for (var n = 1; n <= GameConstants.totalLevels; n++) {
      final l = repo.level(n);
      sigs.add('${l.gridRows}x${l.gridColumns}|${l.arrows.map((a) => '${a.cells}${a.direction.index}').join(';')}');
    }
    expect(sigs.length, GameConstants.totalLevels);
  });

  test('variations of the same shape use different occupancy masks or arrows', () {
    final byShape = <ShapeType, List<LevelModel>>{};
    for (var n = 1; n <= GameConstants.totalLevels; n++) {
      final l = repo.level(n);
      byShape.putIfAbsent(l.shapeType, () => []).add(l);
    }
    for (final group in byShape.values) {
      for (var i = 0; i < group.length; i++) {
        for (var j = i + 1; j < group.length; j++) {
          final a = group[i], b = group[j];
          final sameMask = a.occupancyMask.toString() == b.occupancyMask.toString();
          final sameArrows =
              a.arrows.map((x) => x.cells.toString()).join() == b.arrows.map((x) => x.cells.toString()).join();
          expect(sameMask && sameArrows, isFalse, reason: 'levels ${a.levelNumber} and ${b.levelNumber}');
        }
      }
    }
  });

  group('shape occupancy', () {
    test('every shape type produces a trimmed, non-empty mask', () {
      for (final t in ShapeType.values) {
        final m = ShapeUtils.buildMask(ShapeModel(t, rows: 10, cols: 10));
        expect(ShapeUtils.countCells(m), greaterThan(10), reason: t.name);
        expect(m.first.contains(true) && m.last.contains(true), isTrue);
      }
    });

    test('heart is symmetric with a pointed bottom and wider top', () {
      final m = ShapeUtils.buildMask(const ShapeModel(ShapeType.heart, rows: 12, cols: 12));
      for (final row in m) {
        expect(row, row.reversed.toList());
      }
      final bottom = m.last.where((v) => v).length;
      final widest = m.map((r) => r.where((v) => v).length).reduce((a, b) => a > b ? a : b);
      expect(bottom, lessThan(widest ~/ 2));
    });

    test('diamond is narrow at top and bottom, widest in the middle', () {
      final m = ShapeUtils.buildMask(const ShapeModel(ShapeType.diamond, rows: 9, cols: 9));
      final widths = m.map((r) => r.where((v) => v).length).toList();
      expect(widths.first, lessThan(widths[widths.length ~/ 2]));
      expect(widths.last, lessThan(widths[widths.length ~/ 2]));
    });

    test('validator rejects arrows outside the mask', () {
      final level = customLevel([
        arrow(0, [(0, 0)], Direction.up),
      ]);
      level.occupancyMask[0][0] = false;
      expect(const LevelValidator().validateArrowPositions(level), isNotEmpty);
    });
  });

  group('overlap & structure validation', () {
    test('overlapping arrows are rejected', () {
      final level = customLevel([
        arrow(0, [(1, 1)], Direction.up),
        arrow(1, [(1, 1)], Direction.down),
      ]);
      expect(const LevelValidator().validateNoOverlaps(level), isNotEmpty);
    });

    test('arrowhead must match the final body segment', () {
      final level = customLevel([
        arrow(0, [(2, 1), (2, 2)], Direction.up),
      ]);
      expect(const LevelValidator().validateArrowDirections(level), isNotEmpty);
    });

    test('deadlocked boards are rejected', () {
      final level = customLevel([
        arrow(0, [(2, 0)], Direction.right),
        arrow(1, [(2, 4)], Direction.left),
      ]);
      final r = const LevelValidator().validate(level);
      expect(r.isValid, isFalse);
      expect(const LevelValidator().validateAllArrowsCanEscape(level), isNotEmpty);
      expect(const LevelValidator().validateDependencyGraph(level), isNotEmpty);
    });

    test('generator never places overlapping arrows (fresh seeds)', () {
      final gen = LevelGenerator();
      for (var i = 0; i < 10; i++) {
        final def = LevelDefinition(
          levelNumber: 1 + i,
          name: 'fuzz',
          shape: ShapeModel(ShapeType.values[i % ShapeType.values.length], variant: i, rows: 10, cols: 10),
          targetArrowCount: 25,
        );
        final l = gen.generate(def);
        final seen = <Cell>{};
        for (final a in l.arrows) {
          for (final c in a.cells) {
            expect(seen.add(c), isTrue);
          }
        }
        expect(const LevelValidator().validate(l).isValid, isTrue);
      }
    });
  });
}
