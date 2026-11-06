import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/widgets/sketch_widgets.dart';
import '../../progression/progress_repository.dart';
import '../widgets/home_logo.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final next = progress.unlockedLevel;
    final allDone = progress.completedCount >= GameConstants.totalLevels;

    return Scaffold(
      body: SketchBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight - 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: SketchIconButton(
                          icon: const Icon(Icons.settings_rounded),
                          semanticLabel: 'Settings',
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const HomeLogo(),
                      const SizedBox(height: 24),
                      SketchPanel(
                        seed: 51,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: _Stat(label: 'TOTAL SCORE', value: '${progress.totalScore}'),
                            ),
                            Expanded(
                              child: _Stat(label: 'BEST LEVEL', value: '${progress.bestLevelScore}'),
                            ),
                            Expanded(
                              child: _Stat(
                                label: 'COMPLETED',
                                value: '${progress.completedCount}/${GameConstants.totalLevels}',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: SketchButton(
                          color: SketchColors.mint,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.game, arguments: next),
                          child: Column(
                            children: [
                              Text(allDone ? 'Play Again' : 'Play', style: const TextStyle(fontSize: 34)),
                              Text('Level $next', style: SketchText.body.copyWith(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: SketchButton(
                          color: SketchColors.yellow,
                          seed: 9,
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.levels),
                          child: const Text('Levels'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Tap an arrow to slide it out.\nBlocked arrows cost a heart!',
                        textAlign: TextAlign.center,
                        style: SketchText.body.copyWith(color: SketchColors.muted),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, style: SketchText.label),
      ),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(value, style: SketchText.value),
      ),
    ],
  );
}
