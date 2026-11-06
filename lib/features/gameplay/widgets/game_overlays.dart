import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/utils/grid_utils.dart';
import '../../../core/widgets/sketch_widgets.dart';
import '../models/level_model.dart';
import 'arrow_cell.dart';

/// Dimmed backdrop + centred sketch card that pops in.
class _OverlayShell extends StatelessWidget {
  const _OverlayShell({required this.child, this.dim = 0.35});
  final Widget child;
  final double dim;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: SketchColors.outline.withValues(alpha: dim),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.7, end: 1),
                duration: const Duration(milliseconds: 380),
                curve: Curves.elasticOut,
                builder: (_, s, c) => Transform.scale(scale: s, child: c),
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 380), child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.onResume, required this.onRestart, required this.onHome});
  final VoidCallback onResume, onRestart, onHome;

  @override
  Widget build(BuildContext context) {
    return _OverlayShell(
      child: SketchPanel(
        seed: 21,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Paused', style: SketchText.title, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            SketchButton(onPressed: onResume, color: SketchColors.mint, child: const Text('Resume')),
            const SizedBox(height: 12),
            SketchButton(onPressed: onRestart, color: SketchColors.yellow, seed: 5, child: const Text('Restart')),
            const SizedBox(height: 12),
            SketchButton(onPressed: onHome, color: SketchColors.sky, seed: 6, child: const Text('Home')),
          ],
        ),
      ),
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    super.key,
    required this.score,
    required this.remaining,
    required this.onRetry,
    required this.onHome,
  });
  final int score;
  final int remaining;
  final VoidCallback onRetry, onHome;

  @override
  Widget build(BuildContext context) {
    return _OverlayShell(
      dim: 0.45,
      child: SketchPanel(
        seed: 31,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Out of hearts!', style: SketchText.title, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SketchHeart(filled: false, size: 34),
                  SketchHeart(filled: false, size: 34),
                  SketchHeart(filled: false, size: 34),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Final score: $score', style: SketchText.heading, textAlign: TextAlign.center),
            Text('$remaining arrows were left on the board', style: SketchText.body, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            SketchButton(onPressed: onRetry, color: SketchColors.mint, child: const Text('Retry')),
            const SizedBox(height: 12),
            SketchButton(onPressed: onHome, color: SketchColors.sky, seed: 6, child: const Text('Home')),
          ],
        ),
      ),
    );
  }
}

class LevelCompleteOverlay extends StatelessWidget {
  const LevelCompleteOverlay({
    super.key,
    required this.level,
    required this.score,
    required this.bonus,
    required this.stars,
    required this.bestScore,
    required this.onNext,
    required this.onReplay,
    required this.onHome,
  });

  final LevelModel level;
  final int score;
  final int bonus;
  final int stars;
  final int bestScore;
  final VoidCallback? onNext;
  final VoidCallback onReplay, onHome;

  @override
  Widget build(BuildContext context) {
    final isLast = level.levelNumber >= GameConstants.totalLevels;
    return Positioned.fill(
      child: Stack(
        children: [
          const Positioned.fill(child: _Celebration()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.4, end: 1),
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.elasticOut,
                        builder: (_, s, c) => Transform.scale(scale: s, child: c),
                        child: Text(
                          isLast ? 'You did it all!' : 'Level Complete!',
                          textAlign: TextAlign.center,
                          style: SketchText.title.copyWith(
                            fontSize: 44,
                            color: SketchColors.white,
                            shadows: const [Shadow(color: SketchColors.outline, offset: Offset(2.5, 3))],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SketchPanel(
                        color: SketchColors.white,
                        seed: 41,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 170,
                              child: ArrowPreview(mask: level.occupancyMask, arrows: level.arrows),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < 3; i++) _PopStar(filled: i < stars, delayMs: 250 + i * 180),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${level.name} · ${level.difficulty.label}',
                              style: SketchText.body.copyWith(color: SketchColors.muted),
                            ),
                            TweenAnimationBuilder<int>(
                              tween: IntTween(begin: 0, end: score),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeOut,
                              builder: (_, v, _) => Text('+$v', style: SketchText.title.copyWith(fontSize: 46)),
                            ),
                            Text('incl. +$bonus bonus · best $bestScore', style: SketchText.body),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (!isLast)
                        SketchButton(
                          onPressed: onNext,
                          color: SketchColors.mint,
                          child: Column(
                            children: [
                              const Text('Next Level'),
                              Text('Level ${level.levelNumber + 1}', style: SketchText.body.copyWith(fontSize: 15)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SketchButton(
                              onPressed: onReplay,
                              color: SketchColors.yellow,
                              seed: 7,
                              child: const Text('Replay'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SketchButton(
                              onPressed: onHome,
                              color: SketchColors.sky,
                              seed: 8,
                              child: const Text('Home'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopStar extends StatefulWidget {
  const _PopStar({required this.filled, required this.delayMs});
  final bool filled;
  final int delayMs;

  @override
  State<_PopStar> createState() => _PopStarState();
}

class _PopStarState extends State<_PopStar> {
  bool _shown = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _shown ? 1 : 0.2,
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SketchStar(filled: widget.filled && _shown, size: 46),
      ),
    );
  }
}

/// Rotating sketch sunburst with falling paper confetti.
class _Celebration extends StatefulWidget {
  const _Celebration();
  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final List<_Confetto> _confetti = _makeConfetti();

  static List<_Confetto> _makeConfetti() {
    final rng = SeededRandom(DateTime.now().millisecondsSinceEpoch);
    return List.generate(90, (_) {
      return _Confetto(
        x: rng.nextDouble(),
        delay: rng.nextDouble(),
        speed: 0.6 + rng.nextDouble() * 0.8,
        sway: rng.nextDouble() * 2 * math.pi,
        size: 6 + rng.nextDouble() * 8,
        color: SketchColors.arrowPalette[rng.nextInt(SketchColors.arrowPalette.length)],
        spin: (rng.nextDouble() - 0.5) * 12,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(child: CustomPaint(painter: _CelebrationPainter(_c, _confetti))),
    );
  }
}

class _Confetto {
  _Confetto({
    required this.x,
    required this.delay,
    required this.speed,
    required this.sway,
    required this.size,
    required this.color,
    required this.spin,
  });
  final double x, delay, speed, sway, size, spin;
  final Color color;
}

class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter(this.anim, this.confetti) : super(repaint: anim);
  final Animation<double> anim;
  final List<_Confetto> confetti;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = SketchColors.sky.withValues(alpha: 0.92));

    // Sunburst rays.
    final c = Offset(size.width / 2, size.height * 0.42);
    final r = size.longestSide;
    final ray = Paint()..color = SketchColors.white.withValues(alpha: 0.22);
    const n = 16;
    for (var i = 0; i < n; i++) {
      final a0 = t * 2 * math.pi / 4 + i * 2 * math.pi / n;
      final a1 = a0 + math.pi / n;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + r * math.cos(a0), c.dy + r * math.sin(a0))
        ..lineTo(c.dx + r * math.cos(a1), c.dy + r * math.sin(a1))
        ..close();
      canvas.drawPath(path, ray);
    }

    // Confetti.
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = SketchColors.outline;
    for (final p in confetti) {
      final prog = ((t * 3 * p.speed + p.delay) % 1.0);
      final y = -20 + prog * (size.height + 40);
      final x = p.x * size.width + math.sin(prog * 6 + p.sway) * 18;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(prog * p.spin);
      final rr = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
        const Radius.circular(2),
      );
      canvas.drawRRect(rr, Paint()..color = p.color);
      canvas.drawRRect(rr, outline);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter old) => false;
}
