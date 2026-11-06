import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/utils/grid_utils.dart';
import '../models/arrow_model.dart';

/// Maps logical grid coordinates to canvas pixels.
class BoardGeometry {
  const BoardGeometry({required this.cellSize, required this.origin});
  final double cellSize;
  final Offset origin;

  Offset center(Cell c) => origin + Offset((c.col + 0.5) * cellSize, (c.row + 0.5) * cellSize);

  Cell cellAt(Offset p) {
    final local = p - origin;
    return Cell((local.dy / cellSize).floor(), (local.dx / cellSize).floor());
  }
}

/// Visual state applied when drawing a single arrow.
class ArrowStyle {
  const ArrowStyle({this.opacity = 1, this.tint, this.glow = 0, this.outlineColor});
  final double opacity;
  final Color? tint;

  /// 0..1 strength of the hint glow.
  final double glow;
  final Color? outlineColor;
}

/// Hand-drawn arrow renderer: thick dark outline, colourful interior,
/// rounded joins, a clear arrowhead and a tiny per-arrow wobble.
abstract final class ArrowPainter {
  static double outerWidth(double cs) => cs * 0.40;
  static double innerWidth(double cs) => cs * 0.22;

  /// Draws a static arrow at its board position.
  static void paintArrow(Canvas canvas, BoardGeometry g, ArrowModel a, {ArrowStyle style = const ArrowStyle()}) {
    final pts = [for (final c in a.cells) g.center(c)];
    _paint(canvas, g.cellSize, pts, a.direction, a.colorIndex, a.id, style);
  }

  /// Draws an arrow that has slid [t] cells along [path] (body + exit ray).
  static void paintSliding(
    Canvas canvas,
    BoardGeometry g,
    ArrowModel a,
    List<Cell> path,
    double t, {
    ArrowStyle style = const ArrowStyle(),
  }) {
    final len = a.length;
    Offset at(double s) {
      final i = s.floor().clamp(0, path.length - 2);
      final f = s - i;
      return Offset.lerp(g.center(path[i]), g.center(path[i + 1]), f.clamp(0.0, 1.0))!;
    }

    final start = t;
    final end = t + len - 1;
    final pts = <Offset>[at(start)];
    for (var k = start.floor() + 1; k < end; k++) {
      pts.add(g.center(path[k]));
    }
    if (len > 1) pts.add(at(end));
    _paint(canvas, g.cellSize, pts, a.direction, a.colorIndex, a.id, style, wobble: t == 0);
  }

  static void _paint(
    Canvas canvas,
    double cs,
    List<Offset> rawPts,
    Direction dir,
    int colorIndex,
    int seed,
    ArrowStyle style, {
    bool wobble = true,
  }) {
    final dv = Offset(dir.dCol.toDouble(), dir.dRow.toDouble());
    final rng = SeededRandom(seed * 7349 + 11);
    final j = cs * 0.035;
    var pts = [
      for (final p in rawPts) wobble ? p + Offset((rng.nextDouble() - 0.5) * j, (rng.nextDouble() - 0.5) * j) : p,
    ];
    if (pts.length == 1) {
      // Single-cell arrow: short shaft behind the head.
      pts = [pts.first - dv * (cs * 0.36), pts.first];
    }
    final head = pts.last;
    // Shaft stops a touch before the arrowhead tip.
    final tip = head + dv * (cs * 0.44);
    final baseCenter = head + dv * (cs * 0.02);
    final perp = Offset(-dv.dy, dv.dx);
    final halfW = cs * 0.30;

    final shaft = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      shaft.lineTo(p.dx, p.dy);
    }
    shaft.lineTo(baseCenter.dx, baseCenter.dy);

    final headPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo((baseCenter + perp * halfW).dx, (baseCenter + perp * halfW).dy)
      ..quadraticBezierTo(
        baseCenter.dx - dv.dx * cs * 0.06,
        baseCenter.dy - dv.dy * cs * 0.06,
        (baseCenter - perp * halfW).dx,
        (baseCenter - perp * halfW).dy,
      )
      ..close();

    final base = style.tint ?? SketchColors.arrowPalette[colorIndex % SketchColors.arrowPalette.length];
    final fillColor = base.withValues(alpha: style.opacity);
    final outline = (style.outlineColor ?? SketchColors.outline).withValues(alpha: style.opacity);

    if (style.glow > 0) {
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = outerWidth(cs) + cs * 0.38 * style.glow
        ..color = const Color(0xFFFFF27A).withValues(alpha: 0.85 * style.glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawPath(shaft, glow);
      canvas.drawPath(headPath, glow..style = PaintingStyle.fill);
      canvas.drawPath(headPath, glow..style = PaintingStyle.stroke);
    }

    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = outerWidth(cs)
      ..color = outline;
    canvas.drawPath(shaft, outer);
    canvas.drawPath(
      headPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = cs * 0.16
        ..color = outline,
    );
    canvas.drawPath(headPath, Paint()..color = outline);

    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = innerWidth(cs)
      ..color = fillColor;
    canvas.drawPath(shaft, inner);
    // Inner head, slightly smaller than the outline.
    final innerHead = Path()
      ..moveTo((tip - dv * cs * 0.09).dx, (tip - dv * cs * 0.09).dy)
      ..lineTo(
        (baseCenter + perp * (halfW - cs * 0.08) + dv * cs * 0.03).dx,
        (baseCenter + perp * (halfW - cs * 0.08) + dv * cs * 0.03).dy,
      )
      ..lineTo(
        (baseCenter - perp * (halfW - cs * 0.08) + dv * cs * 0.03).dx,
        (baseCenter - perp * (halfW - cs * 0.08) + dv * cs * 0.03).dy,
      )
      ..close();
    canvas.drawPath(innerHead, Paint()..color = fillColor);

    // Pencil highlight for a doodled feel.
    if (pts.length >= 2) {
      final hl = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1.0, cs * 0.045)
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.45 * style.opacity);
      final o = Offset(-cs * 0.035, -cs * 0.035);
      final a = pts.first + o, b = pts[1] + o;
      final mid = Offset.lerp(a, b, 0.55)!;
      canvas.drawLine(Offset.lerp(a, b, 0.15)!, mid, hl);
    }
  }
}
