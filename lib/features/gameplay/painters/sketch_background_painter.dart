import 'package:flutter/material.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/utils/grid_utils.dart';

/// Light-blue notebook paper: soft gradient, faint ruled lines and tiny
/// irregular dots. Deterministic, so it never flickers between frames.
class SketchBackgroundPainter extends CustomPainter {
  const SketchBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SketchColors.backgroundSecondary, SketchColors.background],
        ).createShader(rect),
    );

    final rng = SeededRandom(42);
    final line = Paint()
      ..color = SketchColors.notebookLine.withValues(alpha: 0.55)
      ..strokeWidth = 1.1;
    const spacing = 30.0;
    for (var y = spacing * 1.5; y < size.height; y += spacing) {
      // Slightly wavy pencil line.
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 40) {
        path.lineTo(x, y + (rng.nextDouble() - 0.5) * 0.9);
      }
      canvas.drawPath(path, line..style = PaintingStyle.stroke);
    }

    final dot = Paint()..color = SketchColors.dot.withValues(alpha: 0.7);
    final count = (size.width * size.height / 2600).round();
    for (var i = 0; i < count; i++) {
      final o = Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height);
      canvas.drawCircle(o, 0.6 + rng.nextDouble() * 1.3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant SketchBackgroundPainter oldDelegate) => false;
}

/// Wobbly rounded-rectangle outline used by every panel and button.
Path sketchRRectPath(Rect r, double radius, int seed, {double wobble = 1.2}) {
  final rng = SeededRandom(seed);
  final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
  final base = Path()..addRRect(rr);
  final metric = base.computeMetrics().first;
  final out = Path();
  const step = 9.0;
  final n = (metric.length / step).ceil();
  for (var i = 0; i <= n; i++) {
    final t = metric.getTangentForOffset((i * step) % metric.length)!;
    final normal = Offset(-t.vector.dy, t.vector.dx);
    final p = t.position + normal * ((rng.nextDouble() - 0.5) * wobble * 2);
    if (i == 0) {
      out.moveTo(p.dx, p.dy);
    } else {
      out.lineTo(p.dx, p.dy);
    }
  }
  out.close();
  return out;
}

class SketchPanelPainter extends CustomPainter {
  SketchPanelPainter({required this.fill, this.radius = 16, this.seed = 1, this.shadow = true, this.strokeWidth = 2.6});

  final Color fill;
  final double radius;
  final int seed;
  final bool shadow;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (Offset.zero & size).deflate(strokeWidth);
    final path = sketchRRectPath(r, radius, seed);
    if (shadow) {
      canvas.drawPath(
        path.shift(const Offset(2.5, 3.5)),
        Paint()..color = SketchColors.outline.withValues(alpha: 0.85),
      );
    }
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..color = SketchColors.outline,
    );
  }

  @override
  bool shouldRepaint(covariant SketchPanelPainter old) =>
      old.fill != fill || old.radius != radius || old.seed != seed || old.shadow != shadow;
}
