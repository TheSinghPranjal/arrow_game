import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/color_constants.dart';
import 'home_doodles.dart';

/// "Arrow Game – Sketch" title block: rimmed lettering, a paper ribbon,
/// paper plane, sun, clouds and four chunky arrows bobbing around it.
/// All positions are fractions of the block width so it scales cleanly.
class HomeTitle extends StatefulWidget {
  const HomeTitle({super.key});

  /// Height of the block as a fraction of its width.
  static const aspect = 0.70;

  @override
  State<HomeTitle> createState() => _HomeTitleState();
}

class _HomeTitleState extends State<HomeTitle> with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(vsync: this, duration: const Duration(seconds: 3))
    ..repeat();

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Arrow Game - Sketch',
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return SizedBox(
            width: w,
            height: w * HomeTitle.aspect,
            child: CustomPaint(
              painter: _TitleBackdropPainter(),
              isComplex: true,
              child: CustomPaint(painter: _BobbingArrowsPainter(_bob), foregroundPainter: _LetteringPainter()),
            ),
          );
        },
      ),
    );
  }
}

/// Clouds, paper plane, sun, star and ray marks behind the lettering.
class _TitleBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    Offset p(double u, double v) => Offset(u * w, v * w);

    Doodle.cloud(canvas, p(0.1, 0.075), w * 0.17);
    Doodle.cloud(canvas, p(0.9, 0.2), w * 0.16);

    // Dashed flight trail curling down from the plane.
    final trail = Path()
      ..moveTo(p(0.27, 0.095).dx, p(0.27, 0.095).dy)
      ..cubicTo(
        p(0.13, 0.13).dx,
        p(0.13, 0.13).dy,
        p(0.03, 0.22).dx,
        p(0.03, 0.22).dy,
        p(0.1, 0.28).dx,
        p(0.1, 0.28).dy,
      );
    for (final m in trail.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += w * 0.022) {
        canvas.drawPath(m.extractPath(d, d + w * 0.011), Doodle.stroke(w * 0.0045));
      }
    }

    // Paper plane.
    final nose = p(0.38, 0.03), top = p(0.265, 0.058), fold = p(0.305, 0.078), bottom = p(0.315, 0.108);
    final wing = Path()
      ..moveTo(nose.dx, nose.dy)
      ..lineTo(top.dx, top.dy)
      ..lineTo(fold.dx, fold.dy)
      ..close();
    final keel = Path()
      ..moveTo(nose.dx, nose.dy)
      ..lineTo(fold.dx, fold.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..close();
    canvas.drawPath(wing, Doodle.fill(SketchColors.white));
    canvas.drawPath(keel, Doodle.fill(const Color(0xFFDDE7EE)));
    canvas.drawPath(wing, Doodle.stroke(w * 0.006));
    canvas.drawPath(keel, Doodle.stroke(w * 0.006));

    Doodle.sun(canvas, p(0.69, 0.097), w * 0.055);

    // Small gold star.
    final star = Path();
    final sc = p(0.48, 0.16);
    for (var i = 0; i < 10; i++) {
      final rr = (i.isEven ? 0.038 : 0.017) * w;
      final a = -math.pi / 2 + i * math.pi / 5;
      final q = sc + Offset(rr * math.cos(a), rr * math.sin(a));
      i == 0 ? star.moveTo(q.dx, q.dy) : star.lineTo(q.dx, q.dy);
    }
    star.close();
    canvas.drawPath(star, Doodle.fill(const Color(0xFFFFD23F)));
    canvas.drawPath(star, Doodle.stroke(w * 0.006));

    // Sun-ray marks beside the lettering.
    Doodle.rays(canvas, p(0.25, 0.47), math.pi, w * 0.07);
    Doodle.rays(canvas, p(0.79, 0.49), 0, w * 0.068);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// "Arrow" / "Game" lettering and the "- Sketch -" paper ribbon.
class _LetteringPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    Offset p(double u, double v) => Offset(u * w, v * w);

    Doodle.rimmedText(canvas, 'Arrow', p(0.51, 0.33), w * 0.57, Doodle.titleRed, angle: -0.04);
    Doodle.rimmedText(canvas, 'Game', p(0.53, 0.46), w * 0.5, Doodle.titleBlue, angle: -0.02);

    // Torn-paper ribbon.
    final c = p(0.537, 0.59);
    final rw = w * 0.5, rh = w * 0.088;
    final l = c.dx - rw / 2, rgt = c.dx + rw / 2, t = c.dy - rh / 2, b = c.dy + rh / 2;
    final ribbon = Path()
      ..moveTo(l, t + rh * 0.08)
      ..quadraticBezierTo(c.dx, t - rh * 0.12, rgt, t)
      ..lineTo(rgt - rh * 0.22, c.dy - rh * 0.05)
      ..lineTo(rgt + rh * 0.08, b + rh * 0.02)
      ..quadraticBezierTo(c.dx, b - rh * 0.1, l + rh * 0.05, b + rh * 0.08)
      ..lineTo(l + rh * 0.25, c.dy + rh * 0.02)
      ..close();
    canvas.drawPath(ribbon.shift(Offset(w * 0.006, w * 0.008)), Doodle.fill(Doodle.ink.withValues(alpha: 0.85)));
    canvas.drawPath(ribbon, Doodle.fill(const Color(0xFFF9E6B6)));
    canvas.drawPath(ribbon, Doodle.stroke(w * 0.006));
    Doodle.rimmedText(
      canvas,
      '- Sketch -',
      c + Offset(0, rh * 0.02),
      rw * 0.74,
      const Color(0xFF4A2C12),
      rim: null,
      textInk: const Color(0xFF4A2C12),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// The four chunky arrows, gently bobbing.
class _BobbingArrowsPainter extends CustomPainter {
  _BobbingArrowsPainter(this.anim) : super(repaint: anim);
  final Animation<double> anim;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final t = w * 0.036;
    List<Offset> pts(double phase, List<(double, double)> uv) {
      final dy = math.sin((anim.value + phase) * 2 * math.pi) * w * 0.008;
      return [for (final (u, v) in uv) Offset(u * w, v * w + dy)];
    }

    Doodle.chunkyArrow(canvas, pts(0, [(0.15, 0.335), (0.15, 0.215), (0.34, 0.195)]), Doodle.titleRed, t);
    Doodle.chunkyArrow(canvas, pts(0.3, [(0.895, 0.27), (0.885, 0.4)]), Doodle.titleBlue, t);
    Doodle.chunkyArrow(canvas, pts(0.6, [(0.215, 0.563), (0.04, 0.575)]), const Color(0xFF6FD06A), t);
    Doodle.chunkyArrow(canvas, pts(0.85, [(0.83, 0.565), (0.918, 0.567), (0.918, 0.68)]), const Color(0xFFA77BF0), t);
  }

  @override
  bool shouldRepaint(covariant _BobbingArrowsPainter old) => false;
}
