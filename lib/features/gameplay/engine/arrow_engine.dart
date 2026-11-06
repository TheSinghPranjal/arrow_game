import '../../../core/utils/grid_utils.dart';
import '../models/arrow_model.dart';

/// Result of probing an arrow's escape ray.
class BlockInfo {
  const BlockInfo(this.blockerId, this.freeSteps);
  final int blockerId;
  final int freeSteps;
}

/// Pure movement rules. No Flutter, no state — every function takes the
/// current board explicitly so it can be reused by the generator, the
/// validator, the game controller and the tests.
abstract final class ArrowEngine {
  /// Occupancy grid: arrow id per cell, -1 for empty.
  static List<int> occupancy(Iterable<ArrowModel> arrows, int rows, int cols) {
    final occ = List<int>.filled(rows * cols, -1);
    for (final a in arrows) {
      if (a.isRemoved) continue;
      for (final c in a.cells) {
        occ[c.index(cols)] = a.id;
      }
    }
    return occ;
  }

  /// Walks the whole ray from the head to the board boundary and returns the
  /// first arrow found on it (checking every remaining arrow in that row or
  /// column, not just the adjacent cell). Returns null when the path is clear.
  static BlockInfo? firstBlocker(ArrowModel arrow, List<int> occ, int rows, int cols) {
    var steps = 0;
    var c = arrow.head.step(arrow.direction);
    while (c.inBounds(rows, cols)) {
      final id = occ[c.index(cols)];
      if (id != -1) return BlockInfo(id, steps);
      steps++;
      c = c.step(arrow.direction);
    }
    return null;
  }

  static bool canEscape(ArrowModel arrow, List<int> occ, int rows, int cols) =>
      firstBlocker(arrow, occ, rows, cols) == null;

  /// All arrows that can currently escape.
  static List<ArrowModel> removable(List<ArrowModel> arrows, int rows, int cols) {
    final occ = occupancy(arrows, rows, cols);
    return [
      for (final a in arrows)
        if (!a.isRemoved && canEscape(a, occ, rows, cols)) a,
    ];
  }

  /// The route the arrow's head follows when it leaves: its own body, the
  /// whole ray to the edge, and enough extra off-board cells for the tail to
  /// fully clear the grid.
  static List<Cell> exitPath(ArrowModel arrow, int rows, int cols) {
    final path = <Cell>[...arrow.cells, ...rayCells(arrow.head, arrow.direction, rows, cols)];
    var c = path.last;
    for (var i = 0; i < arrow.length + 1; i++) {
      c = c.step(arrow.direction);
      path.add(c);
    }
    return path;
  }
}
