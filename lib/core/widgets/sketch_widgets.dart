import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/gameplay/painters/sketch_background_painter.dart';
import '../constants/color_constants.dart';

/// Full-screen notebook background.
class SketchBackground extends StatelessWidget {
  const SketchBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: SketchColors.background,
      child: CustomPaint(painter: const SketchBackgroundPainter(), isComplex: true, willChange: false, child: child),
    );
  }
}

/// Cream panel with a hand-drawn border and flat offset shadow.
class SketchPanel extends StatelessWidget {
  const SketchPanel({
    super.key,
    required this.child,
    this.color = SketchColors.cream,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.radius = 16,
    this.seed = 1,
    this.shadow = true,
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final double radius;
  final int seed;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SketchPanelPainter(fill: color, radius: radius, seed: seed, shadow: shadow),
      child: Padding(padding: padding + const EdgeInsets.only(right: 3, bottom: 4), child: child),
    );
  }
}

/// Chunky doodle button that squashes when pressed.
class SketchButton extends StatefulWidget {
  const SketchButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = SketchColors.yellow,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.radius = 18,
    this.seed = 3,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final double radius;
  final int seed;

  @override
  State<SketchButton> createState() => _SketchButtonState();
}

class _SketchButtonState extends State<SketchButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                HapticFeedback.selectionClick();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.94 : 1,
          duration: const Duration(milliseconds: 90),
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: SketchPanel(
              color: widget.color,
              padding: widget.padding,
              radius: widget.radius,
              seed: widget.seed,
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  fontFamily: 'Chewy',
                  fontSize: 24,
                  color: SketchColors.outline,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
                child: IconTheme.merge(
                  data: const IconThemeData(color: SketchColors.outline, size: 26),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Square icon button (pause, settings, back…).
class SketchIconButton extends StatelessWidget {
  const SketchIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = SketchColors.cream,
    this.size = 48,
    this.semanticLabel,
  });
  final Widget icon;
  final VoidCallback? onPressed;
  final Color color;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: SketchButton(
          onPressed: onPressed,
          color: color,
          padding: EdgeInsets.zero,
          radius: 12,
          seed: size.toInt(),
          child: Center(child: icon),
        ),
      ),
    );
  }
}

/// Two hand-drawn pause bars.
class PauseGlyph extends StatelessWidget {
  const PauseGlyph({super.key});
  @override
  Widget build(BuildContext context) {
    Widget bar() => Container(
      width: 6,
      height: 18,
      decoration: BoxDecoration(color: SketchColors.outline, borderRadius: BorderRadius.circular(3)),
    );
    return Row(mainAxisSize: MainAxisSize.min, children: [bar(), const SizedBox(width: 5), bar()]);
  }
}

/// Doodled heart icon.
class SketchHeart extends StatelessWidget {
  const SketchHeart({super.key, required this.filled, this.size = 26});
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _HeartPainter(filled));
}

class _HeartPainter extends CustomPainter {
  _HeartPainter(this.filled);
  final bool filled;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final path = Path()
      ..moveTo(w * 0.5, h * 0.92)
      ..cubicTo(w * 0.1, h * 0.64, -w * 0.02, h * 0.36, w * 0.18, h * 0.16)
      ..cubicTo(w * 0.32, h * 0.02, w * 0.48, h * 0.1, w * 0.5, h * 0.28)
      ..cubicTo(w * 0.53, h * 0.08, w * 0.7, h * 0.02, w * 0.83, h * 0.15)
      ..cubicTo(w * 1.03, h * 0.38, w * 0.9, h * 0.64, w * 0.5, h * 0.92)
      ..close();
    canvas.drawPath(path, Paint()..color = filled ? SketchColors.heartRed : SketchColors.heartGrey);
    if (filled) {
      canvas.drawLine(
        Offset(w * 0.24, h * 0.3),
        Offset(w * 0.3, h * 0.22),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..strokeWidth = w * 0.08
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.09
        ..strokeJoin = StrokeJoin.round
        ..color = SketchColors.outline,
    );
  }

  @override
  bool shouldRepaint(covariant _HeartPainter old) => old.filled != filled;
}

/// Doodled star used for rewards.
class SketchStar extends StatelessWidget {
  const SketchStar({super.key, required this.filled, this.size = 40});
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _StarPainter(filled));
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.filled);
  final bool filled;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = (i.isEven ? 0.48 : 0.22) * s.width;
      final a = -1.5708 + i * 3.14159 / 5;
      final p = c + Offset(r * math.cos(a), r * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = filled ? SketchColors.yellow : SketchColors.lockedGrey);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = s.width * 0.07
        ..color = SketchColors.outline,
    );
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.filled != filled;
}

/// Hand-drawn progress bar.
class SketchProgressBar extends StatelessWidget {
  const SketchProgressBar({super.key, required this.value, this.height = 14});
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, c) {
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: SketchPanelPainter(
                    fill: SketchColors.white,
                    radius: height / 2,
                    shadow: false,
                    strokeWidth: 2,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                margin: const EdgeInsets.all(4),
                width: ((c.maxWidth - 8) * value.clamp(0.0, 1.0)),
                decoration: BoxDecoration(color: SketchColors.mint, borderRadius: BorderRadius.circular(height)),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Shared text styles.
abstract final class SketchText {
  static const title = TextStyle(fontFamily: 'Chewy', fontSize: 40, color: SketchColors.outline, letterSpacing: 1.5);
  static const heading = TextStyle(fontFamily: 'Chewy', fontSize: 26, color: SketchColors.outline, letterSpacing: 1);
  static const label = TextStyle(
    fontFamily: 'PatrickHand',
    fontSize: 13,
    color: SketchColors.muted,
    height: 1,
    letterSpacing: 1,
  );
  static const value = TextStyle(fontFamily: 'Chewy', fontSize: 22, color: SketchColors.outline, height: 1.1);
  static const body = TextStyle(fontFamily: 'PatrickHand', fontSize: 18, color: SketchColors.outline);
}
