import 'dart:math' as math;

import '../../../core/constants/color_constants.dart';
import '../../../core/utils/grid_utils.dart';
import '../../../core/utils/shape_utils.dart';
import '../models/arrow_model.dart';
import '../models/level_model.dart';
import 'level_validator.dart';

extension _Let<T> on T {
  void let(void Function(T) f) => f(this);
}

class LevelGenerationException implements Exception {
  LevelGenerationException(this.message);
  final String message;
  @override
  String toString() => 'LevelGenerationException: $message';
}

/// Mutable arrow under construction.
class _Draft {
  _Draft(this.cells, this.dir, this.ray);
  List<Cell> cells; // tail → head
  final Direction dir;
  final Set<int> ray; // flat indices of the head's escape ray
}

/// Constructive, guaranteed-solvable level generator (reverse construction).
///
/// Arrows are *placed* one at a time. An arrow may only be placed if its
/// escape ray is clear of every arrow placed before it. Arrows placed later
/// may sit on that ray, but they will be removed earlier, so removing arrows
/// in reverse placement order always succeeds. The placement order is
/// therefore a solvability certificate, which the [LevelValidator]
/// re-checks independently before a level is accepted.
class LevelGenerator {
  LevelGenerator({this.maxAttempts = 60});

  final int maxAttempts;
  final LevelValidator _validator = const LevelValidator();

  LevelModel generate(LevelDefinition def) {
    final mask = ShapeUtils.buildMask(def.shape);
    if (mask.isEmpty) throw LevelGenerationException('Level ${def.levelNumber}: empty mask');
    final rows = mask.length;
    final cols = mask.first.length;
    final base = def.params;

    LevelModel? fallback;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      // After a third of the attempts, progressively relax density targets
      // (never solvability).
      final relax = attempt < maxAttempts ~/ 3 ? 0.0 : (attempt / maxAttempts) * 0.25;
      final rng = SeededRandom(def.seed + attempt * 7919);
      final drafts = _build(mask, rows, cols, def, rng);
      if (drafts == null) continue;

      final level = _toLevel(def, mask, drafts, rng);
      final report = _validator.validate(level);
      if (!report.isValid) continue; // reject and retry

      final fill = level.coveredCellCount / level.maskCellCount;
      final n = level.arrows.length;
      final (lo, hi) = base.arrowRange;
      final countOk = n >= (lo * (1 - relax)).floor() && n <= (hi * (1 + relax)).ceil();
      if (fill >= base.minFill - relax && countOk) return level;
      fallback ??= level;
      if (fallback.coveredCellCount < level.coveredCellCount) fallback = level;
    }
    if (fallback != null) return fallback; // lower density, still validated
    throw LevelGenerationException('Level ${def.levelNumber}: no valid board after $maxAttempts attempts');
  }

  // ---------------------------------------------------------------------------

  List<_Draft>? _build(List<List<bool>> mask, int rows, int cols, LevelDefinition def, SeededRandom rng) {
    final p = def.params;
    final occ = List<int>.filled(rows * cols, -1); // draft index
    final drafts = <_Draft>[];
    bool inMask(Cell c) => c.inBounds(rows, cols) && mask[c.row][c.col];
    bool free(Cell c) => inMask(c) && occ[c.index(cols)] == -1;

    final cells = <Cell>[
      for (var r = 0; r < rows; r++)
        for (var c = 0; c < cols; c++)
          if (mask[r][c]) Cell(r, c),
    ];
    final avgLen = (cells.length / def.targetArrowCount).clamp(1.0, p.maxLength.toDouble());

    // Inside-out ordering with difficulty-dependent noise.
    final cr = cells.fold<double>(0, (s, c) => s + c.row) / cells.length;
    final cc = cells.fold<double>(0, (s, c) => s + c.col) / cells.length;
    final maxD = cells.fold<double>(1, (m, c) => math.max(m, _dist(c, cr, cc)));
    final keyed = [for (final c in cells) (c, _dist(c, cr, cc) / maxD + rng.nextDouble() * p.orderNoise * 1.6)];
    keyed.sort((a, b) => a.$2.compareTo(b.$2));

    for (final (tail, _) in keyed) {
      if (!free(tail)) continue;
      final target = rng.chance(p.longArrowChance)
          ? p.maxLength
          : (avgLen + (rng.nextDouble() - 0.5) * avgLen).round().clamp(p.minLength, p.maxLength);
      final draft = _growArrow(tail, target, occ, free, rows, cols, cr, cc, p, rng);
      if (draft == null) continue;
      final idx = drafts.length;
      drafts.add(draft);
      for (final c in draft.cells) {
        occ[c.index(cols)] = idx;
      }
    }

    _fillHoles(drafts, occ, mask, rows, cols, p, rng);
    return drafts.isEmpty ? null : drafts;
  }

  static double _dist(Cell c, double r, double col) => math.sqrt(math.pow(c.row - r, 2) + math.pow(c.col - col, 2));

  /// Grows one arrow forward from [tail] with a bounded randomized DFS that
  /// backtracks out of dead ends. Any prefix whose end can serve as a head —
  /// i.e. the straight ray beyond it is clear of every previously placed arrow
  /// and of the arrow's own body — is a legal placement. Returns the longest
  /// legal prefix up to [target] cells (or null if even a single-cell arrow
  /// cannot be placed here).
  _Draft? _growArrow(
    Cell tail,
    int target,
    List<int> occ,
    bool Function(Cell) free,
    int rows,
    int cols,
    double cr,
    double cc,
    DifficultyParams p,
    SeededRandom rng,
  ) {
    bool rayClear(Cell head, Direction d, Set<Cell> body) {
      for (final c in rayCells(head, d, rows, cols)) {
        if (occ[c.index(cols)] != -1 || body.contains(c)) return false;
      }
      return true;
    }

    List<Direction> outwardFirst(Cell c, List<Direction> dirs) {
      if (!rng.chance(p.outwardBias)) return dirs;
      double away(Direction d) => (c.row - cr) * d.dRow + (c.col - cc) * d.dCol;
      return dirs..sort((a, b) => away(b).compareTo(away(a)));
    }

    List<Cell>? bestPath;
    Direction? bestDir;
    void consider(List<Cell> path, Direction d) {
      if (bestPath == null || path.length > bestPath!.length) {
        bestPath = List.of(path);
        bestDir = d;
      }
    }

    // Single-cell candidate.
    for (final d in outwardFirst(tail, [...Direction.values]..let(rng.shuffle))) {
      if (rayClear(tail, d, {tail})) {
        consider([tail], d);
        break;
      }
    }

    final path = <Cell>[tail];
    final inPath = <Cell>{tail};
    var budget = 80;
    void dfs(Direction? last) {
      if (path.length >= target || budget-- <= 0) return;
      final cur = path.last;
      var options = [...Direction.values]..let(rng.shuffle);
      options = outwardFirst(cur, options);
      if (last != null) {
        options.remove(last.opposite);
        if (rng.chance(p.straightBias) && options.remove(last)) options.insert(0, last);
      }
      for (final d in options) {
        final next = cur.step(d);
        if (!free(next) || inPath.contains(next)) continue;
        path.add(next);
        inPath.add(next);
        if (rayClear(next, d, inPath)) consider(path, d);
        if (bestPath != null && bestPath!.length >= target) return;
        dfs(d);
        if (bestPath != null && bestPath!.length >= target) return;
        path.removeLast();
        inPath.remove(next);
      }
    }

    dfs(null);
    final bp = bestPath;
    if (bp == null) return null;
    final head = bp.last;
    final raySet = {for (final c in rayCells(head, bestDir!, rows, cols)) c.index(cols)};
    return _Draft(bp, bestDir!, raySet);
  }

  /// Covers leftover holes, either by extending an arrow's tail into them or
  /// by inserting a one-cell arrow at a position in the placement order where
  /// the reverse-construction invariant still holds.
  void _fillHoles(
    List<_Draft> drafts,
    List<int> occ,
    List<List<bool>> mask,
    int rows,
    int cols,
    DifficultyParams p,
    SeededRandom rng,
  ) {
    var changed = true;
    var guard = 0;
    while (changed && guard++ < 8) {
      changed = false;
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          if (!mask[r][c] || occ[r * cols + c] != -1) continue;
          final e = Cell(r, c);
          final ei = e.index(cols);
          if (_tryExtendTail(e, ei, drafts, occ, cols, p)) {
            changed = true;
          } else if (_tryInsertSingle(e, ei, drafts, occ, rows, cols, rng)) {
            changed = true;
          }
        }
      }
    }
  }

  bool _tryExtendTail(Cell e, int ei, List<_Draft> drafts, List<int> occ, int cols, DifficultyParams p) {
    for (var x = 0; x < drafts.length; x++) {
      final d = drafts[x];
      if (d.cells.length >= p.maxLength + 2) continue;
      if (!d.cells.first.isAdjacentTo(e)) continue;
      if (d.cells.length == 1 && e != d.cells.first.step(d.dir.opposite)) continue;
      if (d.ray.contains(ei)) continue;
      var ok = true;
      for (var y = x + 1; y < drafts.length && ok; y++) {
        if (drafts[y].ray.contains(ei)) ok = false;
      }
      if (!ok) continue;
      d.cells = [e, ...d.cells];
      occ[ei] = x;
      return true;
    }
    return false;
  }

  /// Inserts a one-cell arrow at placement index k such that
  ///  * its ray is clear of every arrow placed before it (all ray occupants
  ///    have index >= k), and
  ///  * no arrow placed after it has [e] on its ray (all ray holders of [e]
  ///    have index < k).
  bool _tryInsertSingle(Cell e, int ei, List<_Draft> drafts, List<int> occ, int rows, int cols, SeededRandom rng) {
    var lastRayHolder = -1;
    for (var y = 0; y < drafts.length; y++) {
      if (drafts[y].ray.contains(ei)) lastRayHolder = y;
    }
    final dirs = [...Direction.values];
    rng.shuffle(dirs);
    for (final d in dirs) {
      final raySet = {for (final c in rayCells(e, d, rows, cols)) c.index(cols)};
      var minOccupant = drafts.length;
      for (final i in raySet) {
        if (occ[i] != -1) minOccupant = math.min(minOccupant, occ[i]);
      }
      final k = lastRayHolder + 1;
      if (k > minOccupant) continue;
      drafts.insert(k, _Draft([e], d, raySet));
      for (var i = 0; i < occ.length; i++) {
        if (occ[i] >= k) occ[i]++;
      }
      occ[ei] = k;
      return true;
    }
    return false;
  }

  LevelModel _toLevel(LevelDefinition def, List<List<bool>> mask, List<_Draft> drafts, SeededRandom rng) {
    final rows = mask.length;
    final cols = mask.first.length;
    final colors = _assignColors(drafts, rows, cols, rng);
    final arrows = [
      for (var i = 0; i < drafts.length; i++)
        ArrowModel(id: i, cells: drafts[i].cells, direction: drafts[i].dir, colorIndex: colors[i]),
    ];
    return LevelModel(
      levelNumber: def.levelNumber,
      name: def.name,
      shapeType: def.shape.type,
      difficulty: def.difficulty,
      gridRows: rows,
      gridColumns: cols,
      occupancyMask: mask,
      arrows: arrows,
      solutionOrder: [for (var i = arrows.length - 1; i >= 0; i--) i],
      seed: def.seed,
      targetArrowCount: def.targetArrowCount,
      params: def.params,
    );
  }

  /// Greedy colouring so touching arrows get different colours.
  List<int> _assignColors(List<_Draft> drafts, int rows, int cols, SeededRandom rng) {
    final owner = List<int>.filled(rows * cols, -1);
    for (var i = 0; i < drafts.length; i++) {
      for (final c in drafts[i].cells) {
        owner[c.index(cols)] = i;
      }
    }
    final n = SketchColors.arrowPalette.length;
    final colors = List<int>.filled(drafts.length, -1);
    for (var i = 0; i < drafts.length; i++) {
      final used = <int>{};
      for (final c in drafts[i].cells) {
        for (final d in Direction.values) {
          final nb = c.step(d);
          if (!nb.inBounds(rows, cols)) continue;
          final o = owner[nb.index(cols)];
          if (o != -1 && o != i && colors[o] != -1) used.add(colors[o]);
        }
      }
      final start = rng.nextInt(n);
      var chosen = start;
      for (var k = 0; k < n; k++) {
        final cand = (start + k) % n;
        if (!used.contains(cand)) {
          chosen = cand;
          break;
        }
      }
      colors[i] = chosen;
    }
    return colors;
  }
}
