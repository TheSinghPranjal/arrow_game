import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/widgets/sketch_widgets.dart';
import '../../home/widgets/home_doodles.dart';

/// Bushes, rolling hills, daisies and a few sun-ray marks behind the
/// gameplay screen. Hills dip in the middle so the restart and hint buttons
/// sit in the valley.
class GameSceneryPainter extends CustomPainter {
  const GameSceneryPainter();

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    Offset p(double u, double fromBottom) => Offset(u * w, h - fromBottom * w);

    // Ray marks along the screen edges.
    Doodle.rays(canvas, Offset(-w * 0.02, h * 0.37), 0, w * 0.035, spread: 0.5);
    Doodle.rays(canvas, Offset(w * 1.02, h * 0.49), math.pi, w * 0.035, spread: 0.5);
    Doodle.rays(canvas, Offset(-w * 0.02, h * 0.8), 0, w * 0.035, spread: 0.5);

    final edge = Doodle.stroke(w * 0.006, const Color(0xFF3F7A2A));

    // Bush clusters at both sides.
    for (final (cx, sign) in [(0.06, 1.0), (0.94, -1.0)]) {
      var bush = Path();
      for (final (du, v, r) in [(-0.04, 0.2, 0.07), (0.04, 0.23, 0.07), (0.1, 0.19, 0.06), (0.16, 0.15, 0.05)]) {
        bush = Path.combine(
          PathOperation.union,
          bush,
          Path()..addOval(Rect.fromCircle(center: p(cx + du * sign, v), radius: r * w)),
        );
      }
      canvas.drawPath(bush, Doodle.fill(Doodle.leaf));
      canvas.drawCircle(p(cx + 0.02 * sign, 0.25), w * 0.022, Doodle.fill(Colors.white.withValues(alpha: 0.18)));
      canvas.drawPath(bush, Doodle.stroke(w * 0.005));
    }

    // Back hills rising at both sides.
    final back = Path()
      ..moveTo(0, h - 0.17 * w)
      ..cubicTo(0.2 * w, h - 0.16 * w, 0.35 * w, h - 0.06 * w, 0.5 * w, h - 0.06 * w)
      ..cubicTo(0.65 * w, h - 0.06 * w, 0.8 * w, h - 0.16 * w, w, h - 0.17 * w)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(back, Doodle.fill(Doodle.grassDark));
    canvas.drawPath(back, edge);

    // Front hill.
    final front = Path()
      ..moveTo(0, h - 0.1 * w)
      ..cubicTo(0.25 * w, h - 0.12 * w, 0.4 * w, h - 0.03 * w, 0.6 * w, h - 0.04 * w)
      ..cubicTo(0.8 * w, h - 0.05 * w, 0.9 * w, h - 0.11 * w, w, h - 0.1 * w)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(front, Doodle.fill(Doodle.grassLight));
    canvas.drawPath(front, edge);

    final blade = Doodle.stroke(w * 0.004, const Color(0xFF3F8F2E));
    for (final (u, v) in [(0.1, 0.05), (0.24, 0.07), (0.42, 0.02), (0.7, 0.03), (0.86, 0.06)]) {
      final o = p(u, v);
      for (final a in [-0.5, 0.0, 0.5]) {
        canvas.drawLine(o, o + Offset(math.sin(a), -math.cos(a)) * w * 0.02, blade);
      }
    }
    for (final (u, v) in [(0.07, 0.05), (0.3, 0.025), (0.68, 0.015), (0.9, 0.04), (0.04, 0.13), (0.96, 0.13)]) {
      final c = p(u, v);
      final r = w * 0.012;
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

/// Level name painted on a wooden plank, flanked by ray marks, with a cloud
/// on the left and the sun on the right.
class LevelNameSign extends StatelessWidget {
  const LevelNameSign({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          const SizedBox(width: 62, height: 34, child: CustomPaint(painter: _CloudPainter())),
          const Spacer(),
          const RayMarks(right: false, size: 18),
          const SizedBox(width: 4),
          Flexible(
            flex: 8,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 180),
              child: CustomPaint(
                painter: const _PlankPainter(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 8, 26, 10),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: SketchText.heading.copyWith(fontSize: 26, color: const Color(0xFF2E1D0E)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          const RayMarks(right: true, size: 18),
          const Spacer(),
          const SizedBox(width: 54, height: 54, child: CustomPaint(painter: _SunPainter())),
        ],
      ),
    );
  }
}

class _PlankPainter extends CustomPainter {
  const _PlankPainter();
  @override
  void paint(Canvas canvas, Size s) => Doodle.plank(canvas, Offset.zero & s);
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _CloudPainter extends CustomPainter {
  const _CloudPainter();
  @override
  void paint(Canvas canvas, Size s) => Doodle.cloud(canvas, s.center(Offset(0, s.height * 0.05)), s.width * 0.92);
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _SunPainter extends CustomPainter {
  const _SunPainter();
  @override
  void paint(Canvas canvas, Size s) => Doodle.sun(canvas, s.center(Offset.zero), s.width * 0.24, face: false);
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
