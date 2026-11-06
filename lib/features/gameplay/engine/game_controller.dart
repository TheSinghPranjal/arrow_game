import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/game_constants.dart';
import '../../levels/level_repository.dart';
import '../../progression/progress_repository.dart';
import '../models/game_state.dart';
import '../models/level_model.dart';
import 'arrow_engine.dart';

enum TapOutcome { escaped, blocked, ignored }

/// Scoring rules, kept separate so they are easy to test and tweak.
abstract final class Scoring {
  static int completionBonus({required Difficulty difficulty, required int livesLost}) {
    var bonus = GameConstants.levelCompleteBonus;
    if (livesLost == 0) bonus += GameConstants.flawlessBonus;
    if (difficulty == Difficulty.hard) bonus += GameConstants.hardLevelBonus;
    return bonus;
  }

  static int stars(int livesLost) => (3 - livesLost).clamp(1, 3);
}

/// Owns the logical game state. The board is always authoritative and
/// up to date; animations in the UI are purely visual and are driven by
/// [GameState.lastEvent].
class GameController extends Notifier<GameState?> {
  int _serial = 0;

  @override
  GameState? build() => null;

  LevelRepository get _levels => ref.read(levelRepositoryProvider);

  void startLevel(int levelNumber) {
    final level = _levels.level(levelNumber);
    state = GameState(
      level: level,
      arrows: List.of(level.arrows),
      score: 0,
      lives: GameConstants.startingLives,
      hintsLeft: GameConstants.hintsPerLevel,
    );
  }

  void restart() {
    final s = state;
    if (s != null) startLevel(s.currentLevel);
  }

  /// Attempts to remove arrow [id]. Each call evaluates exactly once, so a
  /// single tap can never cost more than one heart.
  TapOutcome tapArrow(int id) {
    final s = state;
    if (s == null || !s.isInteractive) return TapOutcome.ignored;
    final idx = s.arrows.indexWhere((a) => a.id == id);
    if (idx < 0) return TapOutcome.ignored; // already removed (double tap)
    final arrow = s.arrows[idx];
    final rows = s.level.gridRows, cols = s.level.gridColumns;
    final occ = ArrowEngine.occupancy(s.arrows, rows, cols);
    final block = ArrowEngine.firstBlocker(arrow, occ, rows, cols);

    if (block != null) {
      final lives = s.lives - 1;
      state = s.copyWith(
        lives: lives,
        livesLost: s.livesLost + 1,
        isGameOver: lives <= 0,
        lastEvent: () => ArrowBlockedEvent(++_serial, arrow, block.blockerId, block.freeSteps),
      );
      return TapOutcome.blocked;
    }

    final remaining = [...s.arrows]..removeAt(idx);
    var score = s.score + GameConstants.pointsPerArrow;
    final done = remaining.isEmpty;
    var bonus = 0, stars = 0;
    if (done) {
      bonus = Scoring.completionBonus(difficulty: s.level.difficulty, livesLost: s.livesLost);
      stars = Scoring.stars(s.livesLost);
      score += bonus;
    }
    state = s.copyWith(
      arrows: remaining,
      score: score,
      isLevelCompleted: done,
      isAnimating: true,
      earnedBonus: bonus,
      stars: stars,
      hintedArrowId: () => s.hintedArrowId == id ? null : s.hintedArrowId,
      lastEvent: () => ArrowEscapedEvent(++_serial, arrow, ArrowEngine.exitPath(arrow, rows, cols)),
    );
    if (done) {
      ref.read(progressProvider.notifier).recordCompletion(s.currentLevel, score, stars);
    }
    return TapOutcome.escaped;
  }

  /// Highlights an arrow that can escape *right now* (computed from the
  /// current board, not the stored solution). Returns its id.
  int? useHint() {
    final s = state;
    if (s == null || !s.isInteractive || s.hintsLeft <= 0) return null;
    final free = ArrowEngine.removable(s.arrows, s.level.gridRows, s.level.gridColumns);
    if (free.isEmpty) return null;
    // Prefer the arrow that unblocks the most others so hints feel useful.
    final rows = s.level.gridRows, cols = s.level.gridColumns;
    final occ = ArrowEngine.occupancy(s.arrows, rows, cols);
    final blockedBy = <int, int>{};
    for (final a in s.arrows) {
      final b = ArrowEngine.firstBlocker(a, occ, rows, cols);
      if (b != null) blockedBy[b.blockerId] = (blockedBy[b.blockerId] ?? 0) + 1;
    }
    free.sort((a, b) => (blockedBy[b.id] ?? 0).compareTo(blockedBy[a.id] ?? 0));
    final pick = free.first.id;
    state = s.copyWith(
      hintsLeft: s.hintsLeft - 1,
      hintsUsed: s.hintsUsed + 1,
      hintedArrowId: () => pick,
      lastEvent: () => HintEvent(++_serial, pick),
    );
    return pick;
  }

  void clearHint() {
    final s = state;
    if (s != null && s.hintedArrowId != null) state = s.copyWith(hintedArrowId: () => null);
  }

  void animationsSettled() {
    final s = state;
    if (s != null && s.isAnimating) state = s.copyWith(isAnimating: false);
  }

  void pause() {
    final s = state;
    if (s != null && s.isInteractive) state = s.copyWith(isPaused: true);
  }

  void resume() {
    final s = state;
    if (s != null && s.isPaused) state = s.copyWith(isPaused: false);
  }
}

final gameControllerProvider = NotifierProvider<GameController, GameState?>(GameController.new);
