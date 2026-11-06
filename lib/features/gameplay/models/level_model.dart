import 'arrow_model.dart';
import 'shape_model.dart';

enum Difficulty {
  easy('Easy'),
  medium('Medium'),
  hard('Hard');

  const Difficulty(this.label);
  final String label;

  /// difficulty = (levelNumber - 1) % 3 → 0 easy, 1 medium, 2 hard.
  static Difficulty forLevel(int levelNumber) => Difficulty.values[(levelNumber - 1) % 3];
}

/// Tunables that drive the constructive generator for one difficulty tier.
class DifficultyParams {
  const DifficultyParams({
    required this.minLength,
    required this.maxLength,
    required this.straightBias,
    required this.orderNoise,
    required this.outwardBias,
    required this.minFill,
    required this.arrowRange,
    this.longArrowChance = 0,
  });

  /// Arrow body length bounds (in cells).
  final int minLength;
  final int maxLength;

  /// Probability of continuing straight while growing an arrow body.
  final double straightBias;

  /// 0 = strict inside-out placement (short, obvious dependency chains),
  /// higher = more shuffled placement (longer, interleaved chains).
  final double orderNoise;

  /// Probability of preferring the direction pointing at the nearest edge.
  final double outwardBias;

  /// Minimum fraction of shape cells that must be covered by arrows.
  final double minFill;

  /// Accepted arrow-count range (inclusive) for this tier.
  final (int, int) arrowRange;

  /// Chance that an arrow aims for [maxLength] (long straight rails).
  final double longArrowChance;

  /// Same tuning with a different accepted arrow-count range.
  DifficultyParams withRange((int, int) range) => DifficultyParams(
    minLength: minLength,
    maxLength: maxLength,
    straightBias: straightBias,
    orderNoise: orderNoise,
    outwardBias: outwardBias,
    minFill: minFill,
    arrowRange: range,
    longArrowChance: longArrowChance,
  );

  static DifficultyParams of(Difficulty d) => switch (d) {
    Difficulty.easy => const DifficultyParams(
      minLength: 2,
      maxLength: 5,
      straightBias: 0.75,
      orderNoise: 0.15,
      outwardBias: 0.8,
      minFill: 0.9,
      arrowRange: (8, 22),
    ),
    Difficulty.medium => const DifficultyParams(
      minLength: 2,
      maxLength: 6,
      straightBias: 0.55,
      orderNoise: 0.4,
      outwardBias: 0.5,
      minFill: 0.92,
      arrowRange: (17, 34),
    ),
    Difficulty.hard => const DifficultyParams(
      minLength: 2,
      maxLength: 8,
      straightBias: 0.45,
      orderNoise: 0.7,
      outwardBias: 0.25,
      minFill: 0.94,
      arrowRange: (30, 55),
    ),
  };
}

/// Static description of a level before generation.
class LevelDefinition {
  const LevelDefinition({
    required this.levelNumber,
    required this.shape,
    required this.name,
    required this.targetArrowCount,
    this.paramsOverride,
    this.seedSalt = 0,
  });

  final int levelNumber;
  final ShapeModel shape;
  final String name;
  final int targetArrowCount;

  /// Optional per-level generator tuning (e.g. a maze-style board with
  /// long hooked arrows). Difficulty still follows the level number.
  final DifficultyParams? paramsOverride;

  /// Picks a different (still deterministic) random layout for this level.
  final int seedSalt;

  Difficulty get difficulty => Difficulty.forLevel(levelNumber);
  DifficultyParams get params => paramsOverride ?? DifficultyParams.of(difficulty);

  /// Unique deterministic seed per level.
  int get seed => 0x5EED0000 + levelNumber * 104729 + seedSalt * 7727;
}

/// A fully generated, validated, playable level.
class LevelModel {
  LevelModel({
    required this.levelNumber,
    required this.name,
    required this.shapeType,
    required this.difficulty,
    required this.gridRows,
    required this.gridColumns,
    required this.occupancyMask,
    required this.arrows,
    required this.solutionOrder,
    required this.seed,
    required this.targetArrowCount,
    required this.params,
  });

  final int levelNumber;
  final String name;
  final ShapeType shapeType;
  final Difficulty difficulty;
  final int gridRows;
  final int gridColumns;
  final List<List<bool>> occupancyMask;

  /// Arrows in placement order (index == id).
  final List<ArrowModel> arrows;

  /// Arrow ids in a guaranteed valid removal order (validation certificate,
  /// not a forced sequence).
  final List<int> solutionOrder;
  final int seed;
  final int targetArrowCount;
  final DifficultyParams params;

  int get maskCellCount => occupancyMask.fold(0, (s, r) => s + r.where((v) => v).length);
  int get coveredCellCount => arrows.fold(0, (s, a) => s + a.length);
}
