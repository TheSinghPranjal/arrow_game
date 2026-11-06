import '../../core/utils/shape_utils.dart';
import '../gameplay/models/level_model.dart';
import '../gameplay/models/shape_model.dart';

/// A level *design*: which silhouette to use and how it is proportioned.
/// Its level number (and therefore its difficulty) comes from its position
/// in [_designs], so designs can be inserted or reordered freely and the
/// Easy → Medium → Hard cycle always stays intact.
class _Design {
  const _Design(
    this.name,
    this.type, {
    this.variant = 0,
    this.rowFrac = 1,
    this.colFrac = 1,
    this.fixedSize,
    this.params,
    this.easyOnly = false,
    this.seedSalt = 0,
    this.avgLen,
  });

  final String name;
  final ShapeType type;
  final int variant;

  /// Proportions relative to the tier's base grid size.
  final double rowFrac;
  final double colFrac;

  /// Exact (rows, cols), overriding tier sizing.
  final (int, int)? fixedSize;
  final DifficultyParams? params;

  /// Thin silhouettes with too few cells for Medium/Hard arrow counts.
  final bool easyOnly;

  /// Chooses an alternative deterministic layout.
  final int seedSalt;

  /// When set, the arrow target and accepted range are derived from the
  /// silhouette's cell count at this average arrow length (series levels).
  final double? avgLen;

  /// Hand-placed designs keep their exact level number.
  bool get pinned => fixedSize != null;
}

/// Base grid edge per tier (spec: Easy 4–8, Medium 7–10, Hard 9–12).
const _baseSize = {Difficulty.easy: 8, Difficulty.medium: 10, Difficulty.hard: 12};

/// Average arrow length aimed for per tier.
const _avgLength = {Difficulty.easy: 2.6, Difficulty.medium: 2.8, Difficulty.hard: 2.9};

/// Level 11 "Maze": a completely filled square packed with long hooked and
/// zig-zag arrows that wrap around one another.
const _mazeParams = DifficultyParams(
  minLength: 2,
  maxLength: 9,
  straightBias: 0.3,
  orderNoise: 0.45,
  outwardBias: 0.45,
  minFill: 0.97,
  arrowRange: (24, 36),
);

/// Level 12 "Corridors": a tall filled board mixing long straight runs
/// across rows/columns, long edge-hugging L shapes and short hooks.
const _corridorParams = DifficultyParams(
  minLength: 2,
  maxLength: 12,
  straightBias: 0.72,
  orderNoise: 0.7,
  outwardBias: 0.35,
  minFill: 0.97,
  arrowRange: (32, 50),
  longArrowChance: 0.22,
);

/// Level 13 "Zigzag": a small portrait board of stepping S- and E-shaped
/// arrows. Easy tier: arrows mostly point toward the nearest edge.
const _zigzagParams = DifficultyParams(
  minLength: 3,
  maxLength: 7,
  straightBias: 0.18,
  orderNoise: 0.2,
  outwardBias: 0.75,
  minFill: 0.97,
  arrowRange: (10, 18),
);

/// Level 14 "Tangle": a large dense board of short, twisty arrows
/// (U-turns, S-steps and hooks) with only a few long runs.
const _tangleParams = DifficultyParams(
  minLength: 2,
  maxLength: 6,
  straightBias: 0.22,
  orderNoise: 0.5,
  outwardBias: 0.45,
  minFill: 0.97,
  arrowRange: (34, 50),
  longArrowChance: 0.04,
);

/// Level 15 "Frame": a large square with one or two very long wrapping
/// arrows plus medium L-, U- and Z-shapes and long horizontal runs.
const _frameParams = DifficultyParams(
  minLength: 2,
  maxLength: 20,
  straightBias: 0.55,
  orderNoise: 0.7,
  outwardBias: 0.3,
  minFill: 0.97,
  arrowRange: (30, 40),
  longArrowChance: 0.08,
);

/// Level 16 "Layer Cake": stacked two-row tiers that widen toward the
/// bottom, separated by empty rows, filled with mostly sideways arrows.
const _layerCakeParams = DifficultyParams(
  minLength: 2,
  maxLength: 8,
  straightBias: 0.85,
  orderNoise: 0.15,
  outwardBias: 0.8,
  minFill: 0.95,
  arrowRange: (10, 16),
);

/// Level 17 "Switchback": a tall filled board of long U-turns and
/// L-hooks that fold around one another, framed by long edge rails.
const _switchbackParams = DifficultyParams(
  minLength: 2,
  maxLength: 14,
  straightBias: 0.5,
  orderNoise: 0.55,
  outwardBias: 0.4,
  minFill: 0.97,
  arrowRange: (34, 50),
  longArrowChance: 0.1,
);

/// Level 18 "Citadel": a tall, densely filled board of long vertical
/// rails, notched battlement-like hooks and stacked horizontal runs.
const _citadelParams = DifficultyParams(
  minLength: 2,
  maxLength: 16,
  straightBias: 0.62,
  orderNoise: 0.75,
  outwardBias: 0.3,
  minFill: 0.97,
  arrowRange: (34, 48),
  longArrowChance: 0.12,
);

/// Level 19 "Circuit": a filled board of tightly twisting arrows —
/// zig-zags, E-shapes and little crenellations, like circuit traces.
/// Easy tier: chains stay short and most arrows face the nearest edge.
const _circuitParams = DifficultyParams(
  minLength: 3,
  maxLength: 8,
  straightBias: 0.12,
  orderNoise: 0.2,
  outwardBias: 0.7,
  minFill: 0.97,
  arrowRange: (18, 30),
);

/// Level 20 "Nested": a filled board of long U-wraps folded inside one
/// another, stacked horizontal runs and small notched hooks.
const _nestedParams = DifficultyParams(
  minLength: 2,
  maxLength: 18,
  straightBias: 0.6,
  orderNoise: 0.55,
  outwardBias: 0.35,
  minFill: 0.97,
  arrowRange: (32, 46),
  longArrowChance: 0.14,
);

/// Levels 21–30: new hand-tuned boards drawing on the styles of 11–20.

/// 21 "Gridlock" (Hard): long straight rails crossing in both directions.
const _gridlockParams = DifficultyParams(
  minLength: 2,
  maxLength: 12,
  straightBias: 0.8,
  orderNoise: 0.75,
  outwardBias: 0.25,
  minFill: 0.97,
  arrowRange: (28, 40),
  longArrowChance: 0.25,
);

/// 22 "Pyramid Steps" (Easy): four widening tiers of sideways arrows.
const _stepsParams = DifficultyParams(
  minLength: 2,
  maxLength: 6,
  straightBias: 0.8,
  orderNoise: 0.15,
  outwardBias: 0.8,
  minFill: 0.95,
  arrowRange: (12, 22),
);

/// 23 "Hooks" (Medium): a portrait board of L- and J-hooks.
const _hooksParams = DifficultyParams(
  minLength: 3,
  maxLength: 7,
  straightBias: 0.45,
  orderNoise: 0.45,
  outwardBias: 0.45,
  minFill: 0.97,
  arrowRange: (24, 38),
);

/// 24 "Bastion" (Hard): a large shield-shaped maze of wrapping arrows.
const _bastionParams = DifficultyParams(
  minLength: 2,
  maxLength: 12,
  straightBias: 0.35,
  orderNoise: 0.5,
  outwardBias: 0.45,
  minFill: 0.95,
  arrowRange: (24, 38),
  longArrowChance: 0.06,
);

/// 25 "Snakes" (Easy): a small board of wriggling S-shaped arrows.
const _snakesParams = DifficultyParams(
  minLength: 3,
  maxLength: 7,
  straightBias: 0.1,
  orderNoise: 0.15,
  outwardBias: 0.75,
  minFill: 0.97,
  arrowRange: (10, 20),
);

/// 26 "Crossroads" (Medium): a plus-shaped board of rails and turns.
const _crossroadsParams = DifficultyParams(
  minLength: 2,
  maxLength: 10,
  straightBias: 0.6,
  orderNoise: 0.5,
  outwardBias: 0.4,
  minFill: 0.95,
  arrowRange: (24, 40),
  longArrowChance: 0.1,
);

/// 27 "Long Haul" (Hard): a tall board ringed by very long wraps.
const _longHaulParams = DifficultyParams(
  minLength: 2,
  maxLength: 22,
  straightBias: 0.55,
  orderNoise: 0.6,
  outwardBias: 0.3,
  minFill: 0.97,
  arrowRange: (26, 38),
  longArrowChance: 0.1,
);

/// 28 "Bullseye" (Easy): a round board of arrows curling outward.
const _bullseyeParams = DifficultyParams(
  minLength: 2,
  maxLength: 6,
  straightBias: 0.4,
  orderNoise: 0.15,
  outwardBias: 0.85,
  minFill: 0.95,
  arrowRange: (12, 24),
);

/// 29 "Hive" (Medium): a hexagon packed with twisty little arrows.
const _hiveParams = DifficultyParams(
  minLength: 2,
  maxLength: 7,
  straightBias: 0.2,
  orderNoise: 0.5,
  outwardBias: 0.45,
  minFill: 0.95,
  arrowRange: (26, 42),
);

/// 30 "Grand Maze" (Hard): the biggest filled maze so far.
const _grandMazeParams = DifficultyParams(
  minLength: 2,
  maxLength: 14,
  straightBias: 0.45,
  orderNoise: 0.75,
  outwardBias: 0.3,
  minFill: 0.97,
  arrowRange: (34, 46),
  longArrowChance: 0.08,
);

const List<_Design> _designs = [
  // 1–10
  _Design('Heart', ShapeType.heart),
  _Design('Diamond', ShapeType.diamond, rowFrac: 0.9, colFrac: 0.9),
  _Design('Square', ShapeType.square, rowFrac: 0.84, colFrac: 0.84),
  _Design('Oval', ShapeType.oval, rowFrac: 0.75),
  _Design('Circle', ShapeType.circle, rowFrac: 0.9, colFrac: 0.9),
  _Design('Star', ShapeType.star),
  _Design('Triangle', ShapeType.triangle, rowFrac: 0.88),
  _Design('Hexagon', ShapeType.hexagon, rowFrac: 0.9),
  _Design('Butterfly', ShapeType.butterfly, rowFrac: 0.92),
  _Design('Shield', ShapeType.shield, rowFrac: 0.88, colFrac: 0.88),
  // 11 — new maze-style board
  _Design('Maze', ShapeType.square, fixedSize: (11, 11), params: _mazeParams),
  // 12 — new tall corridor board
  _Design('Corridors', ShapeType.rectangle, fixedSize: (14, 10), params: _corridorParams),
  // 13 — new zig-zag board
  _Design('Zigzag', ShapeType.rectangle, fixedSize: (9, 7), params: _zigzagParams),
  // 14 — new dense tangle board
  _Design('Tangle', ShapeType.square, fixedSize: (12, 11), params: _tangleParams),
  // 15 — new frame board
  _Design('Frame', ShapeType.square, fixedSize: (12, 12), params: _frameParams, seedSalt: 6),
  // 16 — new tiered board
  _Design('Layer Cake', ShapeType.tiers, fixedSize: (9, 10), params: _layerCakeParams),
  // 17 — new switchback board
  _Design('Switchback', ShapeType.rectangle, fixedSize: (14, 12), params: _switchbackParams, seedSalt: 39),
  // 18 — new tall citadel board
  _Design('Citadel', ShapeType.rectangle, fixedSize: (16, 12), params: _citadelParams, seedSalt: 7),
  // 19 — new twisty circuit board
  _Design('Circuit', ShapeType.rectangle, fixedSize: (13, 11), params: _circuitParams, seedSalt: 19),
  // 20 — new nested-wrap board
  _Design('Nested', ShapeType.rectangle, fixedSize: (15, 12), params: _nestedParams, seedSalt: 22),
  // 21–30 — new boards in the style of 11–20
  _Design('Gridlock', ShapeType.square, fixedSize: (12, 12), params: _gridlockParams, seedSalt: 27),
  _Design('Pyramid Steps', ShapeType.tiers, variant: 1, fixedSize: (12, 10), params: _stepsParams, seedSalt: 19),
  _Design('Hooks', ShapeType.rectangle, fixedSize: (12, 10), params: _hooksParams, seedSalt: 36),
  _Design('Bastion', ShapeType.shield, fixedSize: (14, 13), params: _bastionParams, seedSalt: 28),
  _Design('Snakes', ShapeType.rectangle, fixedSize: (10, 8), params: _snakesParams, seedSalt: 30),
  _Design('Crossroads', ShapeType.cross, fixedSize: (13, 13), params: _crossroadsParams, seedSalt: 13),
  _Design('Long Haul', ShapeType.rectangle, fixedSize: (16, 11), params: _longHaulParams, seedSalt: 28),
  _Design('Bullseye', ShapeType.circle, fixedSize: (10, 10), params: _bullseyeParams, seedSalt: 10),
  _Design('Hive', ShapeType.hexagon, fixedSize: (12, 12), params: _hiveParams, seedSalt: 9),
  _Design('Grand Maze', ShapeType.square, fixedSize: (14, 13), params: _grandMazeParams, seedSalt: 35),
  // 31–100 — series levels built from the 11–30 styles
  _Design('Zigzag II', ShapeType.rectangle, fixedSize: (10, 8), params: _zigzagParams, avgLen: 4.5, seedSalt: 0), // 31
  _Design('Maze II', ShapeType.square, fixedSize: (12, 12), params: _mazeParams, avgLen: 4.0, seedSalt: 2), // 32
  _Design(
    'Corridors II',
    ShapeType.rectangle,
    fixedSize: (15, 11),
    params: _corridorParams,
    avgLen: 4.0,
    seedSalt: 22,
  ), // 33
  _Design(
    'Layer Cake II',
    ShapeType.tiers,
    variant: 1,
    fixedSize: (11, 10),
    params: _layerCakeParams,
    avgLen: 3.5,
    seedSalt: 26,
  ), // 34
  _Design('Tangle II', ShapeType.square, fixedSize: (12, 12), params: _tangleParams, avgLen: 3.2, seedSalt: 4), // 35
  _Design('Frame II', ShapeType.square, fixedSize: (13, 13), params: _frameParams, avgLen: 4.0, seedSalt: 4), // 36
  _Design(
    'Circuit II',
    ShapeType.rectangle,
    fixedSize: (12, 10),
    params: _circuitParams,
    avgLen: 4.9,
    seedSalt: 24,
  ), // 37
  _Design(
    'Switchback II',
    ShapeType.rectangle,
    fixedSize: (14, 11),
    params: _switchbackParams,
    avgLen: 4.5,
    seedSalt: 2,
  ), // 38
  _Design(
    'Citadel II',
    ShapeType.rectangle,
    fixedSize: (16, 13),
    params: _citadelParams,
    avgLen: 4.8,
    seedSalt: 5,
  ), // 39
  _Design('Pyramid II', ShapeType.triangle, fixedSize: (10, 11), params: _stepsParams, avgLen: 2.9, seedSalt: 6), // 40
  _Design('Nested II', ShapeType.rectangle, fixedSize: (14, 12), params: _nestedParams, avgLen: 4.7, seedSalt: 1), // 41
  _Design(
    'Gridlock II',
    ShapeType.square,
    fixedSize: (13, 13),
    params: _gridlockParams,
    avgLen: 3.8,
    seedSalt: 13,
  ), // 42
  _Design('Snakes II', ShapeType.rectangle, fixedSize: (10, 9), params: _snakesParams, avgLen: 4.0, seedSalt: 9), // 43
  _Design('Hooks II', ShapeType.rectangle, fixedSize: (12, 11), params: _hooksParams, avgLen: 3.4, seedSalt: 5), // 44
  _Design(
    'Shield Bastion',
    ShapeType.shield,
    variant: 1,
    fixedSize: (14, 13),
    params: _bastionParams,
    avgLen: 4.1,
    seedSalt: 29,
  ), // 45
  _Design(
    'Round Bullseye',
    ShapeType.circle,
    variant: 1,
    fixedSize: (11, 11),
    params: _bullseyeParams,
    avgLen: 3.3,
    seedSalt: 18,
  ), // 46
  _Design(
    'Crossroads II',
    ShapeType.cross,
    variant: 1,
    fixedSize: (13, 13),
    params: _crossroadsParams,
    avgLen: 3.1,
    seedSalt: 21,
  ), // 47
  _Design(
    'Long Haul II',
    ShapeType.rectangle,
    fixedSize: (16, 12),
    params: _longHaulParams,
    avgLen: 5.0,
    seedSalt: 1,
  ), // 48
  _Design('Zigzag III', ShapeType.square, fixedSize: (10, 9), params: _zigzagParams, avgLen: 4.5, seedSalt: 9), // 49
  _Design(
    'Hex Hive',
    ShapeType.hexagon,
    variant: 1,
    fixedSize: (12, 12),
    params: _hiveParams,
    avgLen: 3.0,
    seedSalt: 14,
  ), // 50
  _Design(
    'Grand Maze II',
    ShapeType.square,
    fixedSize: (14, 13),
    params: _grandMazeParams,
    avgLen: 4.9,
    seedSalt: 28,
  ), // 51
  _Design(
    'Layer Cake III',
    ShapeType.tiers,
    variant: 2,
    fixedSize: (13, 11),
    params: _layerCakeParams,
    avgLen: 3.5,
    seedSalt: 7,
  ), // 52
  _Design('Hex Maze', ShapeType.hexagon, fixedSize: (12, 12), params: _mazeParams, avgLen: 4.0, seedSalt: 15), // 53
  _Design(
    'Corridors III',
    ShapeType.rectangle,
    fixedSize: (16, 11),
    params: _corridorParams,
    avgLen: 4.0,
    seedSalt: 15,
  ), // 54
  _Design(
    'Circuit III',
    ShapeType.square,
    fixedSize: (11, 11),
    params: _circuitParams,
    avgLen: 4.9,
    seedSalt: 20,
  ), // 55
  _Design('Heart Tangle', ShapeType.heart, fixedSize: (13, 13), params: _tangleParams, avgLen: 3.2, seedSalt: 5), // 56
  _Design('Frame III', ShapeType.square, fixedSize: (13, 12), params: _frameParams, avgLen: 4.0, seedSalt: 24), // 57
  _Design(
    'Pyramid III',
    ShapeType.triangle,
    variant: 1,
    fixedSize: (11, 12),
    params: _stepsParams,
    avgLen: 2.9,
    seedSalt: 10,
  ), // 58
  _Design(
    'Switchback III',
    ShapeType.rectangle,
    fixedSize: (15, 12),
    params: _switchbackParams,
    avgLen: 4.5,
    seedSalt: 25,
  ), // 59
  _Design(
    'Citadel III',
    ShapeType.rectangle,
    fixedSize: (15, 13),
    params: _citadelParams,
    avgLen: 4.8,
    seedSalt: 16,
  ), // 60
  _Design(
    'Snakes III',
    ShapeType.rectangle,
    fixedSize: (11, 9),
    params: _snakesParams,
    avgLen: 4.0,
    seedSalt: 18,
  ), // 61
  _Design('Nested III', ShapeType.square, fixedSize: (13, 13), params: _nestedParams, avgLen: 4.7, seedSalt: 13), // 62
  _Design(
    'Gridlock III',
    ShapeType.rectangle,
    fixedSize: (14, 12),
    params: _gridlockParams,
    avgLen: 3.8,
    seedSalt: 28,
  ), // 63
  _Design(
    'Heart Bullseye',
    ShapeType.heart,
    fixedSize: (11, 11),
    params: _bullseyeParams,
    avgLen: 3.3,
    seedSalt: 14,
  ), // 64
  _Design('Shield Hooks', ShapeType.shield, fixedSize: (13, 12), params: _hooksParams, avgLen: 3.4, seedSalt: 16), // 65
  _Design(
    'Pentagon Bastion',
    ShapeType.pentagon,
    fixedSize: (14, 13),
    params: _bastionParams,
    avgLen: 4.1,
    seedSalt: 4,
  ), // 66
  _Design('Zigzag IV', ShapeType.rectangle, fixedSize: (11, 9), params: _zigzagParams, avgLen: 4.5, seedSalt: 7), // 67
  _Design(
    'Crossroads III',
    ShapeType.cross,
    variant: 2,
    fixedSize: (13, 13),
    params: _crossroadsParams,
    avgLen: 3.1,
    seedSalt: 14,
  ), // 68
  _Design(
    'Long Haul III',
    ShapeType.rectangle,
    fixedSize: (15, 12),
    params: _longHaulParams,
    avgLen: 5.0,
    seedSalt: 29,
  ), // 69
  _Design(
    'Layer Cake IV',
    ShapeType.tiers,
    fixedSize: (9, 11),
    params: _layerCakeParams,
    avgLen: 3.5,
    seedSalt: 28,
  ), // 70
  _Design(
    'Hex Hive II',
    ShapeType.hexagon,
    variant: 2,
    fixedSize: (13, 13),
    params: _hiveParams,
    avgLen: 3.0,
    seedSalt: 10,
  ), // 71
  _Design(
    'Grand Maze III',
    ShapeType.rectangle,
    fixedSize: (15, 13),
    params: _grandMazeParams,
    avgLen: 4.9,
    seedSalt: 1,
  ), // 72
  _Design(
    'Circuit IV',
    ShapeType.rectangle,
    fixedSize: (13, 10),
    params: _circuitParams,
    avgLen: 4.9,
    seedSalt: 11,
  ), // 73
  _Design('Round Maze', ShapeType.circle, fixedSize: (12, 12), params: _mazeParams, avgLen: 4.0, seedSalt: 15), // 74
  _Design(
    'Corridors IV',
    ShapeType.rectangle,
    fixedSize: (16, 12),
    params: _corridorParams,
    avgLen: 4.0,
    seedSalt: 16,
  ), // 75
  _Design('Pyramid IV', ShapeType.triangle, fixedSize: (12, 12), params: _stepsParams, avgLen: 2.9, seedSalt: 23), // 76
  _Design(
    'Tangle III',
    ShapeType.rectangle,
    fixedSize: (13, 11),
    params: _tangleParams,
    avgLen: 3.2,
    seedSalt: 28,
  ), // 77
  _Design('Frame IV', ShapeType.rectangle, fixedSize: (14, 13), params: _frameParams, avgLen: 4.0, seedSalt: 12), // 78
  _Design('Snakes IV', ShapeType.square, fixedSize: (11, 10), params: _snakesParams, avgLen: 4.0, seedSalt: 3), // 79
  _Design(
    'Switchback IV',
    ShapeType.square,
    fixedSize: (13, 13),
    params: _switchbackParams,
    avgLen: 4.5,
    seedSalt: 15,
  ), // 80
  _Design(
    'Citadel IV',
    ShapeType.rectangle,
    fixedSize: (16, 12),
    params: _citadelParams,
    avgLen: 4.8,
    seedSalt: 0,
  ), // 81
  _Design(
    'Oval Bullseye',
    ShapeType.oval,
    fixedSize: (10, 12),
    params: _bullseyeParams,
    avgLen: 3.3,
    seedSalt: 27,
  ), // 82
  _Design(
    'Nested IV',
    ShapeType.rectangle,
    fixedSize: (16, 12),
    params: _nestedParams,
    avgLen: 4.7,
    seedSalt: 16,
  ), // 83
  _Design(
    'Gridlock IV',
    ShapeType.rectangle,
    fixedSize: (15, 13),
    params: _gridlockParams,
    avgLen: 3.8,
    seedSalt: 11,
  ), // 84
  _Design('Zigzag V', ShapeType.square, fixedSize: (11, 10), params: _zigzagParams, avgLen: 4.5, seedSalt: 13), // 85
  _Design('Hooks III', ShapeType.rectangle, fixedSize: (14, 11), params: _hooksParams, avgLen: 3.4, seedSalt: 20), // 86
  _Design(
    'Heart Bastion',
    ShapeType.heart,
    variant: 1,
    fixedSize: (14, 13),
    params: _bastionParams,
    avgLen: 4.1,
    seedSalt: 29,
  ), // 87
  _Design(
    'Layer Cake V',
    ShapeType.tiers,
    variant: 2,
    fixedSize: (14, 12),
    params: _layerCakeParams,
    avgLen: 3.5,
    seedSalt: 29,
  ), // 88
  _Design(
    'Crossroads IV',
    ShapeType.cross,
    fixedSize: (12, 12),
    params: _crossroadsParams,
    avgLen: 3.1,
    seedSalt: 19,
  ), // 89
  _Design(
    'Long Haul IV',
    ShapeType.rectangle,
    fixedSize: (16, 13),
    params: _longHaulParams,
    avgLen: 5.0,
    seedSalt: 23,
  ), // 90
  _Design(
    'Hex Circuit',
    ShapeType.hexagon,
    fixedSize: (12, 12),
    params: _circuitParams,
    avgLen: 4.9,
    seedSalt: 22,
  ), // 91
  _Design(
    'Butterfly Hive',
    ShapeType.butterfly,
    fixedSize: (12, 13),
    params: _hiveParams,
    avgLen: 3.0,
    seedSalt: 20,
  ), // 92
  _Design(
    'Round Grand Maze',
    ShapeType.circle,
    fixedSize: (13, 13),
    params: _grandMazeParams,
    avgLen: 4.9,
    seedSalt: 14,
  ), // 93
  _Design(
    'Pyramid V',
    ShapeType.triangle,
    variant: 1,
    fixedSize: (12, 13),
    params: _stepsParams,
    avgLen: 2.9,
    seedSalt: 27,
  ), // 94
  _Design('Maze III', ShapeType.square, fixedSize: (13, 12), params: _mazeParams, avgLen: 4.0, seedSalt: 3), // 95
  _Design('Citadel V', ShapeType.square, fixedSize: (13, 13), params: _citadelParams, avgLen: 4.8, seedSalt: 7), // 96
  _Design('Snakes V', ShapeType.rectangle, fixedSize: (12, 10), params: _snakesParams, avgLen: 4.0, seedSalt: 22), // 97
  _Design('Hooks IV', ShapeType.square, fixedSize: (12, 12), params: _hooksParams, avgLen: 3.4, seedSalt: 29), // 98
  _Design(
    'Grand Maze IV',
    ShapeType.rectangle,
    fixedSize: (16, 13),
    params: _grandMazeParams,
    avgLen: 4.9,
    seedSalt: 24,
  ), // 99
  _Design(
    'Flower Bullseye',
    ShapeType.flower,
    fixedSize: (12, 12),
    params: _bullseyeParams,
    avgLen: 3.3,
    seedSalt: 0,
  ), // 100
  // 101–150 (previously 11–60)
  _Design('Flower', ShapeType.flower),
  _Design('Pentagon', ShapeType.pentagon, rowFrac: 0.92, colFrac: 0.92),
  _Design('Rectangle', ShapeType.rectangle, rowFrac: 0.62),
  _Design('Crescent', ShapeType.crescent),
  _Design('Cloud', ShapeType.cloud, rowFrac: 0.84),
  _Design('Arrow', ShapeType.arrow, colFrac: 0.92),
  _Design('Cross', ShapeType.cross, rowFrac: 0.92, colFrac: 0.92),
  _Design('Leaf', ShapeType.leaf, easyOnly: true),
  _Design('Heart II', ShapeType.heart, variant: 1),
  _Design('Diamond II', ShapeType.diamond, variant: 1),
  _Design('Star II', ShapeType.star, variant: 1),
  _Design('Oval II', ShapeType.oval, variant: 2, rowFrac: 0.75),
  _Design('Spiral', ShapeType.spiral),
  _Design('Butterfly II', ShapeType.butterfly, variant: 1, rowFrac: 0.92),
  _Design('Circle II', ShapeType.circle, variant: 1),
  _Design('Shield II', ShapeType.shield, variant: 1, colFrac: 0.9),
  _Design('Flower II', ShapeType.flower, variant: 1),
  _Design('Triangle II', ShapeType.triangle, variant: 1, rowFrac: 0.88),
  _Design('Hexagon II', ShapeType.hexagon, variant: 1),
  _Design('Double Heart', ShapeType.doubleHeart, rowFrac: 0.75),
  _Design('Pentagon II', ShapeType.pentagon, variant: 1),
  _Design('Cloud II', ShapeType.cloud, variant: 1, rowFrac: 0.92),
  _Design('Leaf II', ShapeType.leaf, variant: 1, easyOnly: true),
  _Design('Square II', ShapeType.square, variant: 1, rowFrac: 0.88, colFrac: 0.88),
  _Design('Crescent II', ShapeType.crescent, variant: 1),
  _Design('Star III', ShapeType.star, variant: 2),
  _Design('Butterfly III', ShapeType.butterfly, variant: 2, rowFrac: 0.9),
  _Design('Diamond III', ShapeType.diamond, variant: 2, rowFrac: 0.88, colFrac: 0.88, easyOnly: true),
  _Design('Cross II', ShapeType.cross, variant: 2, rowFrac: 0.92, colFrac: 0.92),
  _Design('Flower III', ShapeType.flower, variant: 2),
  _Design('Heart III', ShapeType.heart, variant: 2),
  _Design('Shield III', ShapeType.shield, variant: 2, colFrac: 0.92),
  _Design('Oval III', ShapeType.oval, variant: 1, rowFrac: 0.88),
  _Design('Arrow II', ShapeType.arrow, variant: 1, rowFrac: 0.9),
  _Design('Hexagon III', ShapeType.hexagon, variant: 2),
  _Design('Cloud III', ShapeType.cloud, variant: 2, rowFrac: 0.84),
  _Design('Leaf III', ShapeType.leaf, variant: 2, easyOnly: true),
  _Design('Star IV', ShapeType.star, variant: 3),
  _Design('Double Diamond', ShapeType.doubleDiamond, rowFrac: 0.75),
  _Design('Butterfly IV', ShapeType.butterfly, rowFrac: 0.9),
  _Design('Heart IV', ShapeType.heart, variant: 3, rowFrac: 0.92),
  _Design('Circle III', ShapeType.circle, variant: 2),
  _Design('Flower IV', ShapeType.flower, variant: 3),
  _Design('Star V', ShapeType.star, variant: 1, colFrac: 0.92, easyOnly: true),
  _Design('Shield IV', ShapeType.shield, colFrac: 0.88),
  _Design('Diamond IV', ShapeType.diamond, variant: 3),
  _Design('Butterfly V', ShapeType.butterfly, variant: 1),
  _Design('Oval IV', ShapeType.oval, variant: 3, rowFrac: 0.75),
  _Design('Grand Star', ShapeType.star),
  _Design('Double Heart II', ShapeType.doubleHeart, variant: 1, colFrac: 0.9),
];

LevelDefinition _build(int levelNumber, _Design d) {
  final tier = Difficulty.forLevel(levelNumber);
  final base = _baseSize[tier]!;
  final (rows, cols) =
      d.fixedSize ?? ((base * d.rowFrac).round().clamp(4, 12), (base * d.colFrac).round().clamp(4, 12));
  final shape = ShapeModel(d.type, variant: d.variant, rows: rows, cols: cols);
  final cells = ShapeUtils.countCells(ShapeUtils.buildMask(shape));
  var params = d.params ?? DifficultyParams.of(tier);
  final int target;
  if (d.avgLen != null && d.params != null) {
    target = (cells / d.avgLen!).round();
    params = params.withRange(((target * 0.75).floor().clamp(6, 999), (target * 1.3).ceil()));
  } else {
    final (lo, hi) = params.arrowRange;
    target = (cells / _avgLength[tier]!).round().clamp(lo + 2, hi - 2);
  }
  return LevelDefinition(
    levelNumber: levelNumber,
    name: d.name,
    shape: shape,
    targetArrowCount: target,
    paramsOverride: d.params == null ? null : params,
    seedSalt: d.seedSalt,
  );
}

/// Assigns designs to level numbers. Pinned designs keep their position;
/// the others follow in list order, except that an [_Design.easyOnly]
/// design waits for the next Easy slot. The Easy → Medium → Hard cycle is
/// fixed by level number, so inserting a level never breaks it.
List<_Design> _arrange(List<_Design> designs) {
  final slots = List<_Design?>.filled(designs.length, null);
  for (var i = 0; i < designs.length; i++) {
    if (designs[i].pinned) slots[i] = designs[i];
  }
  final pool = [
    for (final d in designs)
      if (!d.pinned) d,
  ];
  for (var i = 0; i < slots.length; i++) {
    if (slots[i] != null) continue;
    final easySlot = Difficulty.forLevel(i + 1) == Difficulty.easy;
    final pick = pool.indexWhere((d) => easySlot || !d.easyOnly);
    slots[i] = pool.removeAt(pick < 0 ? 0 : pick);
  }
  return slots.cast<_Design>();
}

/// All levels in play order. Difficulty is derived from the level number
/// ((n - 1) % 3 → Easy / Medium / Hard).
final List<LevelDefinition> levelDefinitions = () {
  final ordered = _arrange(_designs);
  return List<LevelDefinition>.unmodifiable([for (var i = 0; i < ordered.length; i++) _build(i + 1, ordered[i])]);
}();
