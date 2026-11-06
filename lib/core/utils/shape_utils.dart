import 'dart:math' as math;

import '../../features/gameplay/models/shape_model.dart';

/// Builds grid occupancy masks from analytic silhouettes.
///
/// Each shape is an implicit function over normalised coordinates
/// x ∈ [-1, 1] (left→right) and y ∈ [-1, 1] (top→bottom). A grid cell belongs
/// to the shape when at least half of its 4×4 sub-samples fall inside, which
/// keeps silhouettes recognisable even on small boards. Empty outer rows and
/// columns are trimmed so the board hugs the silhouette.
abstract final class ShapeUtils {
  static List<List<bool>> buildMask(ShapeModel shape) {
    final inside = _insideFn(shape.type, shape.variant);
    const sub = 4;
    final raw = List.generate(shape.rows, (r) {
      return List.generate(shape.cols, (c) {
        var hits = 0;
        for (var i = 0; i < sub; i++) {
          for (var j = 0; j < sub; j++) {
            final x = ((c + (j + 0.5) / sub) / shape.cols) * 2 - 1;
            final y = ((r + (i + 0.5) / sub) / shape.rows) * 2 - 1;
            if (inside(x, y)) hits++;
          }
        }
        return hits * 2 >= sub * sub;
      });
    });
    return trim(raw);
  }

  /// Removes fully empty border rows/columns.
  static List<List<bool>> trim(List<List<bool>> m) {
    if (m.isEmpty) return m;
    var top = 0, bottom = m.length - 1, left = 0, right = m.first.length - 1;
    bool rowEmpty(int r) => !m[r].contains(true);
    bool colEmpty(int c) => !m.any((row) => row[c]);
    while (top <= bottom && rowEmpty(top)) {
      top++;
    }
    while (bottom >= top && rowEmpty(bottom)) {
      bottom--;
    }
    while (left <= right && colEmpty(left)) {
      left++;
    }
    while (right >= left && colEmpty(right)) {
      right--;
    }
    if (top > bottom) return const [];
    return [for (var r = top; r <= bottom; r++) m[r].sublist(left, right + 1)];
  }

  static int countCells(List<List<bool>> m) => m.fold(0, (s, row) => s + row.where((v) => v).length);

  // ---------------------------------------------------------------------------

  static bool Function(double x, double y) _insideFn(ShapeType t, int v) {
    switch (t) {
      case ShapeType.heart:
        return switch (v % 4) {
          0 => (x, y) => _heart(x, y),
          1 => (x, y) => _heart(x * 0.92, y * 1.05 + 0.03),
          2 => (x, y) => _heart(x, y) && !_heart(x * 2.6, y * 2.6 + 0.15),
          _ => (x, y) => _heart(x, y) && !(x.abs() < 0.12 && y > -0.62 && y < 0.1),
        };
      case ShapeType.doubleHeart:
        return switch (v % 2) {
          0 => (x, y) => _heart((x + 0.5) * 2.05, y * 1.15 + 0.12) || _heart((x - 0.5) * 2.05, y * 1.15 - 0.12),
          _ => (x, y) => _heart(x * 1.25, (y + 0.42) * 2.0) || _heart(x * 1.25, (y - 0.5) * 2.0),
        };
      case ShapeType.diamond:
        return switch (v % 4) {
          0 => (x, y) => x.abs() + y.abs() <= 1.0,
          1 => (x, y) => x.abs() + y.abs() <= 1.0 && x.abs() + y.abs() > 0.38,
          2 => (x, y) => math.pow(x.abs(), 0.8) + math.pow(y.abs(), 0.8) <= 1.0,
          _ => (x, y) => x.abs() + y.abs() <= 1.0 && !(x.abs() < 0.12 || y.abs() < 0.12) || (x.abs() + y.abs() < 0.3),
        };
      case ShapeType.doubleDiamond:
        return (x, y) => (x + 0.48).abs() / 0.52 + y.abs() <= 1.0 || (x - 0.48).abs() / 0.52 + y.abs() <= 1.0;
      case ShapeType.square:
      case ShapeType.rectangle:
        return switch (v % 3) {
          0 => (x, y) => true,
          1 => (x, y) => !(x.abs() < 0.36 && y.abs() < 0.36),
          _ => (x, y) => _superellipse(x, y, 5),
        };
      case ShapeType.oval:
        return switch (v % 4) {
          0 => (x, y) => x * x + y * y <= 1.0,
          1 => (x, y) => x * x + y * y <= 1.0 && x * x + y * y > 0.18,
          2 => (x, y) {
            final yy = y * (1.0 + 0.18 * x); // egg
            return x * x + yy * yy <= 1.0;
          },
          _ => (x, y) => _superellipse(x, y, 2.6),
        };
      case ShapeType.circle:
        return switch (v % 3) {
          0 => (x, y) => x * x + y * y <= 1.0,
          1 => (x, y) => x * x + y * y <= 1.0 && x * x + y * y > 0.2,
          _ => (x, y) => x * x + y * y <= 1.0 && !(x.abs() < 0.1 && y.abs() > 0.25),
        };
      case ShapeType.star:
        return switch (v % 4) {
          0 => (x, y) => _starPoly(x, y, 5, 0.46, 0),
          1 => (x, y) => _starPoly(x, y, 5, 0.52, 0),
          2 => (x, y) => _starPoly(x, y, 6, 0.55, 0),
          _ => (x, y) => _starPoly(x, y, 5, 0.5, 0) && !(x * x + (y - 0.08) * (y - 0.08) < 0.03),
        };
      case ShapeType.triangle:
        return switch (v % 2) {
          0 => (x, y) => x.abs() <= (y + 1) / 2,
          _ => (x, y) => x.abs() <= (1 - y) / 2,
        };
      case ShapeType.hexagon:
        return switch (v % 3) {
          0 => (x, y) => _regularPoly(x, y, 6, 0),
          1 => (x, y) => _regularPoly(x, y, 6, math.pi / 6),
          _ => (x, y) => _regularPoly(x, y, 6, 0) && !_regularPoly(x * 2.4, y * 2.4, 6, 0),
        };
      case ShapeType.pentagon:
        return switch (v % 2) {
          0 => (x, y) => _regularPoly(x, y * 1.05 - 0.08, 5, -math.pi / 2),
          _ => (x, y) => _regularPoly(x, y * 1.05 - 0.08, 5, -math.pi / 2) && !(x * x + y * y < 0.08),
        };
      case ShapeType.butterfly:
        return switch (v % 3) {
          0 => (x, y) => _butterfly(x, y, 1.0),
          1 => (x, y) => _butterfly(x, y, 0.85),
          _ => (x, y) => _butterfly(x, y, 1.0) && !(_ellipse(x.abs() - 0.5, y + 0.35, 0.16, 0.18)),
        };
      case ShapeType.shield:
        return switch (v % 3) {
          0 => (x, y) => _shield(x, y),
          1 =>
            (x, y) => _shield(x, y) && !(x.abs() < 0.12 && y > -0.75 && y < 0.65) && !(y.abs() < 0.1 && x.abs() < 0.7),
          _ => (x, y) => _shield(x * 0.95, y) && !(y < -0.82 && x.abs() > 0.3 && x.abs() < 0.55),
        };
      case ShapeType.flower:
        return switch (v % 4) {
          0 => (x, y) => _flower(x, y, 5, 0),
          1 => (x, y) => _flower(x, y, 6, 0.3),
          2 => (x, y) => _flower(x, y, 4, math.pi / 4),
          _ => (x, y) => _flower(x, y, 8, 0),
        };
      case ShapeType.crescent:
        return switch (v % 2) {
          0 => (x, y) => x * x + y * y <= 1.0 && !(_sq(x - 0.45) + _sq(y + 0.15) < 0.62),
          _ => (x, y) => x * x + y * y <= 1.0 && !(_sq(x + 0.42) + _sq(y - 0.1) < 0.6),
        };
      case ShapeType.cloud:
        return switch (v % 3) {
          0 => (x, y) => _cloud(x, y),
          1 => (x, y) => _cloud(-x, y),
          _ => (x, y) => _cloud(x, y) && !(_ellipse(x, y - 0.25, 0.25, 0.14)),
        };
      case ShapeType.leaf:
        return switch (v % 3) {
          0 => (x, y) => _leaf(x, y, true),
          1 => (x, y) => _leaf(-x, y, true),
          _ => (x, y) => _leaf(x, y, false) && !((x - y).abs() < 0.09 && (x + y).abs() < 0.9),
        };
      case ShapeType.cross:
        return switch (v % 3) {
          0 => (x, y) => x.abs() < 0.36 || y.abs() < 0.36,
          1 => (x, y) => x.abs() < 0.3 || (y > -0.52 && y < -0.08),
          _ => (x, y) => (x - y).abs() < 0.5 || (x + y).abs() < 0.5,
        };
      case ShapeType.arrow:
        return switch (v % 3) {
          0 => (x, y) => _arrowUp(x, y),
          1 => (x, y) => _arrowUp(y, -x),
          _ => (x, y) => _arrowUp(x, y) || _arrowUp(x, -y),
        };
      case ShapeType.tiers:
        // Stacked horizontal bands separated by one empty row, widening
        // toward the bottom. Rows should be 3 * tiers so each band is two
        // grid rows tall plus a one-row gap (the last gap is trimmed).
        final n = 3 + v % 3;
        return (x, y) {
          final t = (y + 1) / 2 * n;
          final k = t.floor().clamp(0, n - 1);
          final f = t - t.floorToDouble();
          if (f >= 2 / 3) return false;
          final half = 0.3 + 0.7 * (k + 1) / n;
          return x.abs() <= half;
        };
      case ShapeType.spiral:
        return (x, y) {
          final r = math.sqrt(x * x + y * y);
          if (r > 1.0) return false;
          if (r < 0.16) return true;
          var theta = math.atan2(y, x);
          if (theta < 0) theta += 2 * math.pi;
          const b = 0.36 / (2 * math.pi);
          final t = (r / b - theta) / (2 * math.pi);
          return t - t.floorToDouble() < 0.62;
        };
    }
  }

  static double _sq(double v) => v * v;

  static bool _ellipse(double x, double y, double rx, double ry) => _sq(x / rx) + _sq(y / ry) <= 1.0;

  static bool _superellipse(double x, double y, double n) => math.pow(x.abs(), n) + math.pow(y.abs(), n) <= 1.0;

  /// Classic implicit heart, y pointing down.
  static bool _heart(double x, double y) {
    final hx = x * 1.18;
    final hy = -y * 1.18 + 0.15;
    final a = hx * hx + hy * hy - 1;
    return a * a * a - hx * hx * hy * hy * hy <= 0;
  }

  static bool _pointInPoly(double x, double y, List<(double, double)> pts) {
    var inside = false;
    for (var i = 0, j = pts.length - 1; i < pts.length; j = i++) {
      final (xi, yi) = pts[i];
      final (xj, yj) = pts[j];
      if ((yi > y) != (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi) {
        inside = !inside;
      }
    }
    return inside;
  }

  static bool _starPoly(double x, double y, int points, double inner, double rot) {
    final pts = <(double, double)>[];
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? 1.0 : inner;
      final a = -math.pi / 2 + rot + i * math.pi / points;
      pts.add((r * math.cos(a), r * math.sin(a) + 0.1));
    }
    return _pointInPoly(x, y, pts);
  }

  static bool _regularPoly(double x, double y, int n, double rot) {
    final pts = <(double, double)>[
      for (var i = 0; i < n; i++) (math.cos(rot + i * 2 * math.pi / n), math.sin(rot + i * 2 * math.pi / n)),
    ];
    return _pointInPoly(x, y, pts);
  }

  static bool _butterfly(double x, double y, double wing) {
    final ax = x.abs();
    final upper = _ellipse(ax - 0.5, y + 0.32, 0.5 * wing, 0.6);
    final lower = _ellipse(ax - 0.4, y - 0.5, 0.38 * wing, 0.42);
    final body = ax < 0.1 && y.abs() < 0.85;
    return upper || lower || body;
  }

  static bool _shield(double x, double y) {
    if (y < -0.95) return false;
    if (y <= 0.05) return x.abs() <= 0.92;
    final t = (y - 0.05) / 0.95; // 0..1
    final w = 0.92 * math.pow(1 - t * t, 0.75);
    return x.abs() <= w;
  }

  static bool _flower(double x, double y, int petals, double rot) {
    final r = math.sqrt(x * x + y * y);
    final th = math.atan2(y, x) + rot;
    if (r < 0.35) return true;
    return r <= 0.55 + 0.45 * (0.5 + 0.5 * math.cos(petals * th));
  }

  static bool _cloud(double x, double y) {
    return _ellipse(x + 0.52, y - 0.12, 0.44, 0.42) ||
        _ellipse(x + 0.05, y + 0.18, 0.55, 0.58) ||
        _ellipse(x - 0.52, y - 0.05, 0.45, 0.46) ||
        (x.abs() < 0.8 && y > 0.05 && y < 0.5);
  }

  static bool _leaf(double x, double y, bool stem) {
    final u = (x + y) / math.sqrt2;
    final v = (x - y) / math.sqrt2;
    final lens = _sq(v - 0.55) + u * u <= 1.0 && _sq(v + 0.55) + u * u <= 1.0;
    final stemHit = stem && v.abs() < 0.1 && u > 0.7 && u < 1.1;
    return lens || stemHit;
  }

  static bool _arrowUp(double x, double y) {
    if (y < -0.05) return x.abs() <= (y + 1.0) * 1.05;
    return x.abs() < 0.36;
  }
}
