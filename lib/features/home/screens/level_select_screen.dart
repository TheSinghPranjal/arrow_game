import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/widgets/sketch_widgets.dart';
import '../../gameplay/models/level_model.dart';
import '../../levels/level_repository.dart';
import '../../progression/progress_repository.dart';

class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final repo = ref.watch(levelRepositoryProvider);

    return Scaffold(
      body: SketchBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    SketchIconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      semanticLabel: 'Back',
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text('Levels', style: SketchText.title, textAlign: TextAlign.center),
                    ),
                    SketchPanel(
                      seed: 61,
                      child: Text('${progress.completedCount}/${GameConstants.totalLevels}', style: SketchText.value),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Legend(color: SketchColors.easy, label: 'Easy'),
                    _Legend(color: SketchColors.medium, label: 'Medium'),
                    _Legend(color: SketchColors.hard, label: 'Hard'),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 110,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: GameConstants.totalLevels,
                  itemBuilder: (context, i) {
                    final n = i + 1;
                    return _LevelTile(
                      number: n,
                      mask: repo.mask(n),
                      difficulty: Difficulty.forLevel(n),
                      completed: progress.completed.contains(n),
                      current: n == progress.unlockedLevel && !progress.completed.contains(n),
                      unlocked: progress.isUnlocked(n),
                      stars: progress.stars[n] ?? 0,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.game, arguments: n),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Row(
      children: [
        _DiffDots(
          difficulty: label == 'Easy'
              ? Difficulty.easy
              : label == 'Medium'
              ? Difficulty.medium
              : Difficulty.hard,
        ),
        const SizedBox(width: 4),
        Text(label, style: SketchText.body.copyWith(fontSize: 15)),
      ],
    ),
  );
}

/// Three dots; 1/2/3 filled for Easy/Medium/Hard.
class _DiffDots extends StatelessWidget {
  const _DiffDots({required this.difficulty, this.dim = false});
  final Difficulty difficulty;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final filled = difficulty.index + 1;
    final color = switch (difficulty) {
      Difficulty.easy => SketchColors.easy,
      Difficulty.medium => SketchColors.medium,
      Difficulty.hard => SketchColors.hard,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.2),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? (dim ? SketchColors.heartGrey : color) : Colors.transparent,
              border: Border.all(color: SketchColors.outline.withValues(alpha: dim ? 0.4 : 1), width: 1.2),
            ),
          ),
      ],
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.number,
    required this.mask,
    required this.difficulty,
    required this.completed,
    required this.current,
    required this.unlocked,
    required this.stars,
    required this.onTap,
  });

  final int number;
  final List<List<bool>> mask;
  final Difficulty difficulty;
  final bool completed, current, unlocked;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = !unlocked
        ? SketchColors.lockedGrey
        : current
        ? SketchColors.yellow
        : completed
        ? const Color(0xFFDDF5E5)
        : SketchColors.cream;
    return Semantics(
      button: unlocked,
      label:
          'Level $number, ${difficulty.label}${completed ? ', completed, $stars stars' : ''}${unlocked ? '' : ', locked'}',
      child: GestureDetector(
        onTap: unlocked ? onTap : null,
        child: SketchPanel(
          color: color,
          seed: 100 + number,
          radius: 14,
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$number',
                    style: SketchText.value.copyWith(
                      fontSize: 20,
                      color: unlocked ? SketchColors.outline : SketchColors.muted,
                    ),
                  ),
                  _DiffDots(difficulty: difficulty, dim: !unlocked),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: unlocked
                      ? CustomPaint(size: Size.infinite, painter: _MaskIconPainter(mask, difficulty))
                      : const Center(child: Icon(Icons.lock_rounded, color: SketchColors.muted, size: 26)),
                ),
              ),
              SizedBox(
                height: 16,
                child: completed
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [for (var i = 0; i < 3; i++) SketchStar(filled: i < stars, size: 15)],
                      )
                    : current
                    ? Text('PLAY', style: SketchText.label.copyWith(color: SketchColors.outline, fontSize: 14))
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiny silhouette of the level's shape.
class _MaskIconPainter extends CustomPainter {
  _MaskIconPainter(this.mask, this.difficulty);
  final List<List<bool>> mask;
  final Difficulty difficulty;

  @override
  void paint(Canvas canvas, Size size) {
    if (mask.isEmpty) return;
    final rows = mask.length, cols = mask.first.length;
    final cs = (size.width / cols < size.height / rows ? size.width / cols : size.height / rows);
    final ox = (size.width - cs * cols) / 2, oy = (size.height - cs * rows) / 2;
    final color = switch (difficulty) {
      Difficulty.easy => SketchColors.mint,
      Difficulty.medium => SketchColors.sky,
      Difficulty.hard => SketchColors.coral,
    };
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = SketchColors.outline.withValues(alpha: 0.7);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (!mask[r][c]) continue;
        final rect = Rect.fromLTWH(ox + c * cs + 0.6, oy + r * cs + 0.6, cs - 1.2, cs - 1.2);
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MaskIconPainter old) => !identical(old.mask, mask);
}
