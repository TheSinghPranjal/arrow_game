import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/widgets/sketch_widgets.dart';
import '../../progression/progress_repository.dart';
import '../engine/game_controller.dart';
import '../widgets/arrow_board.dart';
import '../widgets/game_header.dart';
import '../widgets/game_overlays.dart';
import '../widgets/game_scenery.dart';
import '../widgets/hint_button.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.levelNumber});
  final int levelNumber;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> with WidgetsBindingObserver {
  late int _activeLevel = widget.levelNumber;
  bool _started = false;
  bool _showComplete = false;
  bool _showGameOver = false;
  Timer? _overlayTimer;

  GameController get _controller => ref.read(gameControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start after the first frame so we never mutate providers mid-build.
    Future.microtask(() => _start(widget.levelNumber));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _overlayTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) _controller.pause();
  }

  void _start(int level) {
    if (!mounted) return;
    _overlayTimer?.cancel();
    setState(() {
      _activeLevel = level;
      _started = true;
      _showComplete = false;
      _showGameOver = false;
    });
    _controller.startLevel(level);
  }

  void _goHome() => Navigator.of(context).popUntil((r) => r.settings.name == AppRoutes.home || r.isFirst);

  @override
  Widget build(BuildContext context) {
    ref.listen(gameControllerProvider, (prev, next) {
      if (next == null) return;
      if (next.isLevelCompleted && !(prev?.isLevelCompleted ?? false)) {
        _overlayTimer = Timer(
          const Duration(milliseconds: GameConstants.escapeMaxMs + GameConstants.completionDelayMs),
          () {
            if (mounted) setState(() => _showComplete = true);
          },
        );
      }
      if (next.isGameOver && !(prev?.isGameOver ?? false)) {
        _overlayTimer = Timer(const Duration(milliseconds: 700), () {
          if (mounted) setState(() => _showGameOver = true);
        });
      }
    });

    final s = ref.watch(gameControllerProvider);
    final ready = _started && s != null && s.currentLevel == _activeLevel;

    return PopScope(
      canPop: true,
      child: Scaffold(
        body: SketchBackground(
          child: !ready
              ? const Center(child: CircularProgressIndicator(color: SketchColors.outline))
              : Stack(
                  children: [
                    const Positioned.fill(child: CustomPaint(painter: GameSceneryPainter())),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        child: Column(
                          children: [
                            GameHeader(
                              score: s.score,
                              level: s.currentLevel,
                              difficulty: s.level.difficulty,
                              lives: s.lives,
                              onPause: _controller.pause,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: SketchProgressBar(value: s.progress)),
                                const SizedBox(width: 10),
                                Text('${s.totalArrows - s.remainingArrows}/${s.totalArrows}', style: SketchText.body),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: LevelNameSign(name: s.level.name),
                            ),
                            const Expanded(
                              child: Padding(padding: EdgeInsets.fromLTRB(4, 10, 4, 14), child: ArrowBoard()),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SketchIconButton(
                                  size: 64,
                                  color: SketchColors.cream,
                                  semanticLabel: 'Restart level',
                                  icon: const Icon(Icons.refresh_rounded, size: 34),
                                  onPressed: () => _start(s.currentLevel),
                                ),
                                const SizedBox(width: 28),
                                HintButton(hintsLeft: s.hintsLeft, onPressed: _controller.useHint),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (s.isPaused)
                      PauseOverlay(
                        onResume: _controller.resume,
                        onRestart: () => _start(s.currentLevel),
                        onHome: _goHome,
                      ),
                    if (_showGameOver && s.isGameOver)
                      GameOverOverlay(
                        score: s.score,
                        remaining: s.remainingArrows,
                        onRetry: () => _start(s.currentLevel),
                        onHome: _goHome,
                      ),
                    if (_showComplete && s.isLevelCompleted)
                      LevelCompleteOverlay(
                        level: s.level,
                        score: s.score,
                        bonus: s.earnedBonus,
                        stars: s.stars,
                        bestScore: ref.watch(progressProvider).bestScores[s.currentLevel] ?? s.score,
                        onNext: s.currentLevel < GameConstants.totalLevels ? () => _start(s.currentLevel + 1) : null,
                        onReplay: () => _start(s.currentLevel),
                        onHome: _goHome,
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
