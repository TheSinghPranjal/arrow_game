/// Grid primitives shared by the engine, generator and renderer.
library;

enum Direction {
  up(-1, 0),
  down(1, 0),
  left(0, -1),
  right(0, 1);

  const Direction(this.dRow, this.dCol);
  final int dRow;
  final int dCol;

  Direction get opposite => switch (this) {
    Direction.up => Direction.down,
    Direction.down => Direction.up,
    Direction.left => Direction.right,
    Direction.right => Direction.left,
  };

  /// Direction of travel from [from] to the orthogonally adjacent [to].
  static Direction? between(Cell from, Cell to) {
    final dr = to.row - from.row;
    final dc = to.col - from.col;
    for (final d in Direction.values) {
      if (d.dRow == dr && d.dCol == dc) return d;
    }
    return null;
  }
}

/// An immutable logical grid coordinate.
class Cell {
  const Cell(this.row, this.col);
  final int row;
  final int col;

  Cell step(Direction d, [int n = 1]) => Cell(row + d.dRow * n, col + d.dCol * n);

  bool inBounds(int rows, int cols) => row >= 0 && col >= 0 && row < rows && col < cols;

  int index(int cols) => row * cols + col;

  bool isAdjacentTo(Cell o) => (row - o.row).abs() + (col - o.col).abs() == 1;

  @override
  bool operator ==(Object other) => other is Cell && other.row == row && other.col == col;

  @override
  int get hashCode => row * 7919 + col;

  @override
  String toString() => '($row,$col)';
}

/// Cells from the cell after [head] in direction [d] up to (and including) the
/// last cell inside the grid.
List<Cell> rayCells(Cell head, Direction d, int rows, int cols) {
  final out = <Cell>[];
  var c = head.step(d);
  while (c.inBounds(rows, cols)) {
    out.add(c);
    c = c.step(d);
  }
  return out;
}

/// Small deterministic PRNG (mulberry32). Used instead of `dart:math.Random`
/// so that levels are identical on every platform and SDK version.
class SeededRandom {
  SeededRandom(int seed) : _state = seed & 0xFFFFFFFF;
  int _state;

  int _next32() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _state;
    t = _imul(t ^ (t >> 15), t | 1);
    t ^= (t + _imul(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF;
    return (t ^ (t >> 14)) & 0xFFFFFFFF;
  }

  static int _imul(int a, int b) => (a * b) & 0xFFFFFFFF;

  /// Uniform double in [0, 1).
  double nextDouble() => _next32() / 4294967296.0;

  /// Uniform int in [0, max).
  int nextInt(int max) => (nextDouble() * max).floor();

  bool chance(double p) => nextDouble() < p;

  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }
}
