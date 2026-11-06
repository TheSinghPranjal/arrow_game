import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/color_constants.dart';
import 'home_doodles.dart';

/// Side clouds plus the rolling green hills, tree, fence and flowers along
/// the bottom of the home screen. Sized from the screen width so the scene
/// keeps its proportions on any phone.
class HomeSceneryPainter extends CustomPainter {
  const HomeSceneryPainter();

  /// Vertical space (as a fraction of width) the hills take at the bottom.
  static const hillsFraction = 0.17;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    Offset p(double u, double fromBottom) => Offset(u * w, h - fromBottom * w);

    Doodle.cloud(canvas, p(0.07, 0.43), w * 0.15);
    Doodle.cloud(canvas, p(0.97, 0.5), w * 0.16);
    Doodle.cloud(canvas, p(0.95, 0.31), w * 0.15);

    final edge = Doodle.stroke(w * 0.006, const Color(0xFF3F7A2A));

    // Back hill.
    final back = Path()
      ..moveTo(0, h - 0.13 * w)
      ..cubicTo(0.22 * w, h - 0.21 * w, 0.62 * w, h - 0.2 * w, w, h - 0.14 * w)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(back, Doodle.fill(Doodle.grassDark));
    canvas.drawPath(back, edge);

    // Tree on the left.
    final trunk = Path()
      ..moveTo(0.055 * w, h - 0.08 * w)
      ..lineTo(0.065 * w, h - 0.22 * w)
      ..lineTo(0.09 * w, h - 0.22 * w)
      ..lineTo(0.1 * w, h - 0.08 * w)
      ..close();
    canvas.drawPath(trunk, Doodle.fill(Doodle.bark));
    canvas.drawPath(trunk, Doodle.stroke(w * 0.005));
    var crown = Path();
    for (final (u, v, r) in [
      (0.03, 0.26, 0.055),
      (0.08, 0.31, 0.065),
      (0.135, 0.265, 0.055),
      (0.08, 0.235, 0.06),
      (0.0, 0.215, 0.04),
      (0.15, 0.215, 0.04),
    ]) {
      crown = Path.combine(
        PathOperation.union,
        crown,
        Path()..addOval(Rect.fromCircle(center: p(u, v), radius: r * w)),
      );
    }
    canvas.drawPath(crown, Doodle.fill(Doodle.leaf));
    canvas.drawCircle(p(0.06, 0.29), w * 0.025, Doodle.fill(Colors.white.withValues(alpha: 0.18)));
    canvas.drawPath(crown, Doodle.stroke(w * 0.005));

    // Fence on the right.
    final wood = Doodle.fill(Doodle.wood);
    final woodLine = Doodle.stroke(w * 0.004);
    for (final v in [0.115, 0.16]) {
      final rail = Rect.fromLTWH(0.8 * w, h - v * w, 0.22 * w, 0.014 * w);
      canvas.drawRect(rail, wood);
      canvas.drawRect(rail, woodLine);
    }
    for (var i = 0; i < 4; i++) {
      final x = (0.82 + i * 0.055) * w;
      final top = h - (0.19 + (i.isEven ? 0.0 : 0.01)) * w;
      final picket = Path()
        ..moveTo(x, h - 0.08 * w)
        ..lineTo(x, top + 0.012 * w)
        ..lineTo(x + 0.016 * w, top)
        ..lineTo(x + 0.032 * w, top + 0.012 * w)
        ..lineTo(x + 0.032 * w, h - 0.08 * w)
        ..close();
      canvas.drawPath(picket, wood);
      canvas.drawPath(picket, woodLine);
    }

    // Bushes.
    for (final (u, v, r) in [(0.17, 0.1, 0.035), (0.21, 0.095, 0.028), (0.77, 0.1, 0.03)]) {
      canvas.drawCircle(p(u, v), r * w, Doodle.fill(Doodle.leaf));
      canvas.drawCircle(p(u, v), r * w, Doodle.stroke(w * 0.004));
    }

    // Front hill.
    final front = Path()
      ..moveTo(0, h - 0.07 * w)
      ..cubicTo(0.3 * w, h - 0.135 * w, 0.55 * w, h - 0.04 * w, w, h - 0.1 * w)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(front, Doodle.fill(Doodle.grassLight));
    canvas.drawPath(front, edge);

    // Grass tufts.
    final blade = Doodle.stroke(w * 0.004, const Color(0xFF3F8F2E));
    for (final (u, v) in [(0.12, 0.045), (0.36, 0.06), (0.47, 0.02), (0.66, 0.05), (0.82, 0.03), (0.95, 0.06)]) {
      final o = p(u, v);
      for (final a in [-0.5, 0.0, 0.5]) {
        canvas.drawLine(o, o + Offset(math.sin(a), -math.cos(a)) * w * 0.022, blade);
      }
    }

    // Daisies.
    for (final (u, v) in [(0.16, 0.025), (0.57, 0.03), (0.9, 0.035)]) {
      final c = p(u, v);
      final r = w * 0.011;
      for (var i = 0; i < 5; i++) {
        final a = i * 2 * math.pi / 5;
        final pc = c + Offset(math.cos(a), math.sin(a)) * r;
        canvas.drawCircle(pc, r * 0.75, Doodle.fill(SketchColors.white));
        canvas.drawCircle(pc, r * 0.75, Doodle.stroke(w * 0.0025));
      }
      canvas.drawCircle(c, r * 0.55, Doodle.fill(const Color(0xFFFFC928)));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
