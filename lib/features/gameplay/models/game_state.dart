import '../../../core/utils/grid_utils.dart';
import 'arrow_model.dart';
import 'level_model.dart';

/// The last thing that happened on the board; the UI turns these into
/// animations. [serial] increases monotonically so identical consecutive
/// events are still distinguishable.
sealed class BoardEvent {
  const BoardEvent(this.serial);
  final int serial;
}

class ArrowEscapedEvent extends BoardEvent {
  const ArrowEscapedEvent(super.serial, this.arrow, this.exitPath);
  final ArrowModel arrow;

  /// Arrow cells followed by every cell the head passes on its way out,
  /// extended beyond the grid edge.
  final List<Cell> exitPath;
}

class ArrowBlockedEvent extends BoardEvent {
  const ArrowBlockedEvent(super.serial, this.arrow, this.blockerId, this.freeSteps);
  final ArrowModel arrow;
  final int blockerId;

  /// Number of empty cells between the head and the blocker.
  final int freeSteps;
}

class HintEvent extends BoardEvent {
  const HintEvent(super.serial, this.arrowId);
  final int arrowId;
}

class GameState {
  const GameState({
    required this.level,
    required this.arrows,
    required this.score,
    required this.lives,
    required this.hintsLeft,
    this.hintsUsed = 0,
    this.isPaused = false,
    this.isGameOver = false,
    this.isLevelCompleted = false,
    this.isAnimating = false,
    this.livesLost = 0,
    this.hintedArrowId,
    this.lastEvent,
    this.earnedBonus = 0,
    this.stars = 0,
  });

  final LevelModel level;

  /// Current arrows (removed ones are dropped from this list).
  final List<ArrowModel> arrows;
  final int score;
  final int lives;
  final int hintsLeft;
  final int hintsUsed;
  final bool isPaused;
  final bool isGameOver;
  final bool isLevelCompleted;

  /// True while an escape animation is in flight (informational for the UI;
  /// the logical board is always up to date).
  final bool isAnimating;
  final int livesLost;
  final int? hintedArrowId;
  final BoardEvent? lastEvent;
  final int earnedBonus;
  final int stars;

  int get currentLevel => level.levelNumber;
  int get remainingArrows => arrows.length;
  int get totalArrows => level.arrows.length;
  double get progress => totalArrows == 0 ? 1 : 1 - remainingArrows / totalArrows;
  bool get isInteractive => !isPaused && !isGameOver && !isLevelCompleted;

  GameState copyWith({
    List<ArrowModel>? arrows,
    int? score,
    int? lives,
    int? hintsLeft,
    int? hintsUsed,
    bool? isPaused,
    bool? isGameOver,
    bool? isLevelCompleted,
    bool? isAnimating,
    int? livesLost,
    int? Function()? hintedArrowId,
    BoardEvent? Function()? lastEvent,
    int? earnedBonus,
    int? stars,
  }) => GameState(
    level: level,
    arrows: arrows ?? this.arrows,
    score: score ?? this.score,
    lives: lives ?? this.lives,
    hintsLeft: hintsLeft ?? this.hintsLeft,
    hintsUsed: hintsUsed ?? this.hintsUsed,
    isPaused: isPaused ?? this.isPaused,
    isGameOver: isGameOver ?? this.isGameOver,
    isLevelCompleted: isLevelCompleted ?? this.isLevelCompleted,
    isAnimating: isAnimating ?? this.isAnimating,
    livesLost: livesLost ?? this.livesLost,
    hintedArrowId: hintedArrowId != null ? hintedArrowId() : this.hintedArrowId,
    lastEvent: lastEvent != null ? lastEvent() : this.lastEvent,
    earnedBonus: earnedBonus ?? this.earnedBonus,
    stars: stars ?? this.stars,
  );
}
