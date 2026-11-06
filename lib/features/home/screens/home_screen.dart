import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/widgets/sketch_widgets.dart';
import '../../progression/progress_repository.dart';
import '../widgets/home_doodles.dart';
import '../widgets/home_scenery.dart';
import '../widgets/home_title.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final next = progress.unlockedLevel;
    final allDone = progress.completedCount >= GameConstants.totalLevels;

    return Scaffold(
      body: SketchBackground(
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: HomeSceneryPainter())),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth.clamp(0.0, 480.0);
                  return SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: c.maxHeight, maxWidth: w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const SizedBox(height: 6),
                            const HomeTitle(),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _StatsPanel(
                                score: progress.totalScore,
                                best: progress.bestLevelScore,
                                completed: progress.completedCount,
                              ),
                            ),
                            _WithRays(
                              rayRow: true,
                              child: SizedBox(
                                width: w * 0.72,
                                child: SketchButton(
                                  color: const Color(0xFF8BD764),
                                  seed: 21,
                                  radius: 26,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  onPressed: () => Navigator.pushNamed(context, AppRoutes.game, arguments: next),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const PlayTriangle(size: 46),
                                        const SizedBox(width: 14),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              allDone ? 'Play Again' : 'Play',
                                              style: const TextStyle(fontSize: 46, height: 1.05),
                                            ),
                                            Text(
                                              'Level $next',
                                              style: SketchText.body.copyWith(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w700,
                                                height: 1.1,
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
                            SizedBox(
                              width: w * 0.66,
                              child: SketchButton(
                                color: const Color(0xFFFFD54A),
                                seed: 9,
                                radius: 24,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.levels),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      BarsIcon(size: 30),
                                      SizedBox(width: 16),
                                      Text('Levels', style: TextStyle(fontSize: 32)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            _WithRays(
                              rayRow: false,
                              child: Text(
                                'Tap an arrow to slide it out.\nBlocked arrows cost a heart!',
                                textAlign: TextAlign.center,
                                style: SketchText.body.copyWith(fontSize: 18, height: 1.25),
                              ),
                            ),
                            // Room for the hills along the bottom.
                            SizedBox(height: w * HomeSceneryPainter.hillsFraction),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 14, 0),
                  child: SketchIconButton(
                    size: 56,
                    icon: const Icon(Icons.settings_rounded, size: 32),
                    semanticLabel: 'Settings',
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Places sun-ray marks on both sides of [child].
class _WithRays extends StatelessWidget {
  const _WithRays({required this.child, required this.rayRow});
  final Widget child;

  /// Big rays (beside the Play button) vs. small ones (beside the tip).
  final bool rayRow;

  @override
  Widget build(BuildContext context) {
    final size = rayRow ? 30.0 : 18.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RayMarks(right: false, size: size),
        SizedBox(width: rayRow ? 6 : 4),
        Flexible(child: child),
        SizedBox(width: rayRow ? 6 : 4),
        RayMarks(right: true, size: size),
      ],
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.score, required this.best, required this.completed});
  final int score;
  final int best;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return SketchPanel(
      seed: 51,
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _Stat(icon: const TrophyIcon(size: 34), label: 'TOTAL SCORE', value: '$score'),
            ),
            const _DashedDivider(),
            Expanded(
              child: _Stat(icon: const SketchStar(filled: true, size: 32), label: 'BEST LEVEL', value: '$best'),
            ),
            const _DashedDivider(),
            Expanded(
              child: _Stat(
                icon: const CheckIcon(size: 30),
                label: 'COMPLETED',
                value: '$completed/${GameConstants.totalLevels}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});
  final Widget icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: SketchText.label.copyWith(color: SketchColors.outline, fontSize: 13)),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(value, style: SketchText.value.copyWith(fontSize: 26)),
          ],
        ),
      ],
    ),
  );
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();
  @override
  Widget build(BuildContext context) => const SizedBox(width: 10, child: CustomPaint(painter: _DashPainter()));
}

class _DashPainter extends CustomPainter {
  const _DashPainter();
  @override
  void paint(Canvas canvas, Size s) {
    final paint = Doodle.stroke(2);
    for (var y = 4.0; y < s.height - 4; y += 9) {
      canvas.drawLine(Offset(s.width / 2, y), Offset(s.width / 2, (y + 4.5).clamp(0, s.height - 4)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
