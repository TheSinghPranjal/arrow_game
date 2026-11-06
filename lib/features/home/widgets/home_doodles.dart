import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/constants/color_constants.dart';

/// Shared hand-drawn doodle primitives for the home screen.
abstract final class Doodle {
  static const ink = SketchColors.outline;
  static const titleRed = Color(0xFFEF4B43);
  static const titleBlue = Color(0xFF27A4EE);
  static const ray = Color(0xFFFFCF33);
  static const grassLight = Color(0xFFA6DE73);
  static const grassDark = Color(0xFF79C74B);
  static const leaf = Color(0xFF63B946);
  static const bark = Color(0xFF9A6234);
  static const wood = Color(0xFFC0844A);

  static Paint stroke(double w, [Color c = ink]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = c;

  static Paint fill(Color c) => Paint()..color = c;

  /// Puffy white cloud centred on [c], [w] wide.
  static void cloud(Canvas canvas, Offset c, double w) {
    final h = w * 0.42;
    final base = Rect.fromCenter(center: c + Offset(0, h * 0.18), width: w, height: h * 0.55);
    var p = Path()..addRRect(RRect.fromRectAndRadius(base, Radius.circular(h * 0.28)));
    for (final (dx, dy, r) in [(-0.26, 0.02, 0.2), (-0.02, -0.12, 0.28), (0.25, 0.0, 0.2), (0.4, 0.12, 0.12)]) {
      p = Path.combine(
        PathOperation.union,
        p,
        Path()..addOval(Rect.fromCircle(center: c + Offset(dx * w, dy * w), radius: r * w)),
      );
    }
    canvas.drawPath(p, fill(SketchColors.white));
    canvas.drawPath(p, stroke(w * 0.022));
  }

  /// Smiling sun of radius [r] with a ring of rays.
  static void sun(Canvas canvas, Offset c, double r, {bool face = true}) {
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6 + 0.2;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * r * 1.4, c + d * r * (i.isEven ? 1.95 : 1.75), stroke(r * 0.2, ray));
    }
    canvas.drawCircle(c, r, fill(const Color(0xFFFFD93B)));
    canvas.drawCircle(c - Offset(r * 0.25, r * 0.25), r * 0.45, fill(Colors.white.withValues(alpha: 0.3)));
    canvas.drawCircle(c, r, stroke(r * 0.09, const Color(0xFFE0A100)));
    if (!face) return;
    final f = stroke(r * 0.075, const Color(0xFFB07A00));
    for (final sx in [-1.0, 1.0]) {
      canvas.drawArc(
        Rect.fromCircle(center: c + Offset(sx * r * 0.35, -r * 0.1), radius: r * 0.13),
        math.pi,
        math.pi,
        false,
        f,
      );
    }
    canvas.drawArc(Rect.fromCircle(center: c + Offset(0, r * 0.15), radius: r * 0.3), 0.5, math.pi - 1, false, f);
  }

  /// Rough wooden plank filling [r], with grain lines and nails.
  static void plank(Canvas canvas, Rect r) {
    final h = r.height;
    final path = Path()
      ..moveTo(r.left + h * 0.12, r.top + h * 0.04)
      ..lineTo(r.right - h * 0.18, r.top)
      ..lineTo(r.right, r.top + h * 0.12)
      ..lineTo(r.right - h * 0.06, r.bottom - h * 0.02)
      ..lineTo(r.left + h * 0.1, r.bottom)
      ..lineTo(r.left, r.bottom - h * 0.16)
      ..lineTo(r.left + h * 0.04, r.top + h * 0.2)
      ..close();
    canvas.drawPath(path.shift(Offset(h * 0.05, h * 0.08)), fill(ink.withValues(alpha: 0.85)));
    canvas.drawPath(
      path,
      Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, const [Color(0xFFF0BD7A), Color(0xFFD9964F)]),
    );
    final grain = stroke(h * 0.025, const Color(0xFFB0713A).withValues(alpha: 0.7));
    for (final (y, x0, x1) in [(0.3, 0.08, 0.34), (0.72, 0.18, 0.46), (0.36, 0.6, 0.88), (0.7, 0.66, 0.92)]) {
      final yy = r.top + h * y;
      final g = Path()
        ..moveTo(r.left + r.width * x0, yy)
        ..quadraticBezierTo(r.left + r.width * (x0 + x1) / 2, yy - h * 0.06, r.left + r.width * x1, yy);
      canvas.drawPath(g, grain);
    }
    for (final x in [r.left + h * 0.32, r.right - h * 0.32]) {
      canvas.drawCircle(Offset(x, r.center.dy), h * 0.06, fill(const Color(0xFF6B4320)));
    }
    canvas.drawPath(path, stroke(h * 0.05));
  }

  /// Three short sun-ray dashes fanning out from [o] toward [angle].
  static void rays(Canvas canvas, Offset o, double angle, double len, {double spread = 0.55}) {
    final paint = stroke(len * 0.24, ray);
    for (final a in [angle - spread, angle, angle + spread]) {
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(o + d * len * 0.75, o + d * len * 1.5, paint);
    }
  }

  /// Chunky outlined arrow along [pts]; the head sits on the last point.
  static void chunkyArrow(Canvas canvas, List<Offset> pts, Color color, double t) {
    final end = pts.last;
    final prev = pts[pts.length - 2];
    final dir = (end - prev) / (end - prev).distance;
    final nrm = Offset(-dir.dy, dir.dx);
    final headLen = t * 1.6;
    final base = end - dir * headLen;
    final head = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo((base + nrm * t * 1.25).dx, (base + nrm * t * 1.25).dy)
      ..lineTo((base - nrm * t * 1.25).dx, (base - nrm * t * 1.25).dy)
      ..close();
    final body = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.sublist(1, pts.length - 1)) {
      body.lineTo(p.dx, p.dy);
    }
    body.lineTo(base.dx + dir.dx * 2, base.dy + dir.dy * 2);

    final outline = t * 0.22;
    canvas.drawPath(body, stroke(t + outline * 2));
    canvas.drawPath(head, stroke(outline * 2));
    canvas.drawPath(body, stroke(t, color));
    // Inset the head fill so the outline stays visible.
    final inner = Path()
      ..moveTo((end - dir * outline * 1.6).dx, (end - dir * outline * 1.6).dy)
      ..lineTo((base + nrm * (t * 1.25 - outline * 1.4)).dx, (base + nrm * (t * 1.25 - outline * 1.4)).dy)
      ..lineTo((base - nrm * (t * 1.25 - outline * 1.4)).dx, (base - nrm * (t * 1.25 - outline * 1.4)).dy)
      ..close();
    canvas.drawPath(head, fill(ink));
    canvas.drawPath(inner, fill(color));
    // Glossy highlight on the first segment.
    final a = pts.first, b = pts.length > 2 ? pts[1] : base;
    final sd = (b - a) / (b - a).distance;
    final sn = Offset(-sd.dy, sd.dx);
    canvas.drawLine(
      a + sd * t * 0.5 - sn * t * 0.22,
      a + (b - a) * 0.55 - sn * t * 0.22,
      stroke(t * 0.16, Colors.white.withValues(alpha: 0.55)),
    );
  }

  /// Text with a dark outline, thick white rim and coloured fill.
  static void rimmedText(
    Canvas canvas,
    String text,
    Offset center,
    double width,
    Color color, {
    double angle = 0,
    String font = 'Chewy',
    Color? rim = SketchColors.white,
    Color textInk = ink,
  }) {
    TextPainter tp(Paint fg, double size) => TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontFamily: font, fontSize: size, foreground: fg, letterSpacing: size * 0.02, height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final probe = tp(Paint(), 100);
    final size = 100 * width / probe.width;
    final layers = <TextPainter>[
      if (rim != null) tp(stroke(size * 0.17), size),
      if (rim != null) tp(stroke(size * 0.11, rim), size),
      tp(stroke(size * 0.05, textInk), size),
      tp(Paint()..color = color, size),
    ];
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    if (rim != null) {
      final shadow = tp(stroke(size * 0.17, ink.withValues(alpha: 0.85)), size);
      shadow.paint(canvas, Offset(-shadow.width / 2 + size * 0.03, -shadow.height / 2 + size * 0.05));
    }
    for (final l in layers) {
      l.paint(canvas, Offset(-l.width / 2, -l.height / 2));
    }
    // Soft highlight across the upper half of the letters.
    final hi = tp(
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(0, size),
          [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0)],
          [0.1, 0.4],
        ),
      size,
    );
    hi.paint(canvas, Offset(-hi.width / 2, -hi.height / 2));
    canvas.restore();
  }
}

/// Little bar-chart icon for the Levels button.
class BarsIcon extends StatelessWidget {
  const BarsIcon({super.key, this.size = 30});
  final double size;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _BarsPainter());
}

class _BarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    const colors = [Color(0xFF2A8FD8), Color(0xFF2FB3A3), Color(0xFF2A8FD8)];
    for (var i = 0; i < 3; i++) {
      final h = s.height * (0.45 + i * 0.27);
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * (0.04 + i * 0.33), s.height - h, w * 0.26, h),
        Radius.circular(w * 0.05),
      );
      canvas.drawRRect(r, Doodle.fill(colors[i]));
      canvas.drawRRect(r, Doodle.stroke(w * 0.06));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Dark green play triangle for the Play button.
class PlayTriangle extends StatelessWidget {
  const PlayTriangle({super.key, this.size = 44});
  final double size;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _PlayPainter());
}

class _PlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Path()
      ..moveTo(s.width * 0.14, s.height * 0.1)
      ..lineTo(s.width * 0.92, s.height * 0.5)
      ..lineTo(s.width * 0.14, s.height * 0.9)
      ..close();
    canvas.drawPath(p, Doodle.fill(const Color(0xFF1F6B3A)));
    canvas.drawPath(p, Doodle.stroke(s.width * 0.08));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Gold trophy cup.
class TrophyIcon extends StatelessWidget {
  const TrophyIcon({super.key, this.size = 34});
  final double size;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _TrophyPainter());
}

class _TrophyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    const gold = Color(0xFFF5B723);
    final line = Doodle.stroke(w * 0.07);
    // Handles.
    for (final sx in [-1.0, 1.0]) {
      final hp = Path()
        ..moveTo(w * 0.5 + sx * w * 0.26, h * 0.14)
        ..cubicTo(
          w * 0.5 + sx * w * 0.52,
          h * 0.12,
          w * 0.5 + sx * w * 0.5,
          h * 0.42,
          w * 0.5 + sx * w * 0.2,
          h * 0.46,
        );
      canvas.drawPath(hp, Doodle.stroke(w * 0.15));
      canvas.drawPath(hp, Doodle.stroke(w * 0.07, gold));
    }
    final cup = Path()
      ..moveTo(w * 0.22, h * 0.08)
      ..lineTo(w * 0.78, h * 0.08)
      ..cubicTo(w * 0.78, h * 0.42, w * 0.64, h * 0.56, w * 0.5, h * 0.58)
      ..cubicTo(w * 0.36, h * 0.56, w * 0.22, h * 0.42, w * 0.22, h * 0.08)
      ..close();
    canvas.drawPath(cup, Doodle.fill(gold));
    canvas.drawLine(Offset(w * 0.34, h * 0.16), Offset(w * 0.36, h * 0.36), Doodle.stroke(w * 0.06, Colors.white70));
    canvas.drawPath(cup, line);
    final stem = Rect.fromLTRB(w * 0.44, h * 0.58, w * 0.56, h * 0.76);
    canvas.drawRect(stem, Doodle.fill(gold));
    canvas.drawRect(stem, line);
    final base = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.26, h * 0.76, w * 0.74, h * 0.94),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(base, Doodle.fill(const Color(0xFFE09A1A)));
    canvas.drawRRect(base, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Green circle with a check mark.
class CheckIcon extends StatelessWidget {
  const CheckIcon({super.key, this.size = 32});
  final double size;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _CheckPainter());
}

class _CheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width * 0.44;
    canvas.drawCircle(c, r, Doodle.fill(const Color(0xFF5FCB6E)));
    canvas.drawCircle(c, r, Doodle.stroke(s.width * 0.08));
    final p = Path()
      ..moveTo(s.width * 0.3, s.height * 0.52)
      ..lineTo(s.width * 0.45, s.height * 0.66)
      ..lineTo(s.width * 0.72, s.height * 0.36);
    canvas.drawPath(p, Doodle.stroke(s.width * 0.11));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Sun-ray dashes beside a widget (left side fans left, right side fans right).
class RayMarks extends StatelessWidget {
  const RayMarks({super.key, required this.right, this.size = 30});
  final bool right;
  final double size;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(size, size * 1.4), painter: _RayMarksPainter(right));
}

class _RayMarksPainter extends CustomPainter {
  _RayMarksPainter(this.right);
  final bool right;
  @override
  void paint(Canvas canvas, Size s) {
    final o = Offset(right ? -s.width * 0.35 : s.width * 1.35, s.height / 2);
    Doodle.rays(canvas, o, right ? 0 : math.pi, s.width * 0.9, spread: 0.5);
  }

  @override
  bool shouldRepaint(covariant _RayMarksPainter old) => old.right != right;
}
