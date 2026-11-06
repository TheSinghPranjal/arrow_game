import 'package:flutter/material.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/widgets/sketch_widgets.dart';
import '../models/level_model.dart';
import 'heart_indicator.dart';

/// [ PAUSE ] [ SCORE ] [ LEVEL ] [ ♥ ♥ ♥ ]
class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.score,
    required this.level,
    required this.difficulty,
    required this.lives,
    required this.onPause,
  });

  final int score;
  final int level;
  final Difficulty difficulty;
  final int lives;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final diffColor = switch (difficulty) {
      Difficulty.easy => SketchColors.easy,
      Difficulty.medium => SketchColors.medium,
      Difficulty.hard => SketchColors.hard,
    };
    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SketchIconButton(icon: const PauseGlyph(), onPressed: onPause, size: 56, semanticLabel: 'Pause'),
          const SizedBox(width: 6),
          Expanded(
            flex: 5,
            child: SketchPanel(
              seed: 11,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SCORE', style: SketchText.label),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(end: score),
                      duration: const Duration(milliseconds: 300),
                      builder: (_, v, _) => Text('$v', style: SketchText.value),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 5,
            child: SketchPanel(
              seed: 12,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(difficulty.label.toUpperCase(), style: SketchText.label),
                        const SizedBox(width: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: diffColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: SketchColors.outline, width: 1.2),
                          ),
                        ),
                      ],
                    ),
                    Text('LEVEL $level', style: SketchText.value),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SketchPanel(
            seed: 13,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Center(child: HeartIndicator(lives: lives, size: 22)),
          ),
        ],
      ),
    );
  }
}
