import 'package:arrow_game/core/constants/game_constants.dart';
import 'package:arrow_game/core/utils/grid_utils.dart';
import 'package:arrow_game/features/gameplay/engine/arrow_engine.dart';
import 'package:arrow_game/features/gameplay/engine/game_controller.dart';
import 'package:arrow_game/features/gameplay/models/game_state.dart';
import 'package:arrow_game/features/progression/progress_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  // a: (2,0)→right is blocked by b at (2,3); b escapes up; c escapes left.
  final a = arrow(0, [(2, 0)], Direction.right);
  final b = arrow(1, [(3, 3), (2, 3)], Direction.up);
  final c = arrow(2, [(4, 1), (4, 0)], Direction.left);
  final easy = customLevel([a, b, c], levelNumber: 1);
  final hard = customLevel([a, b, c], levelNumber: 3);

  late ProviderContainer container;
  GameController ctrl() => container.read(gameControllerProvider.notifier);
  GameState st() => container.read(gameControllerProvider)!;

  setUp(() async {
    container = await makeContainer(levels: {1: easy, 2: easy, 3: hard});
    ctrl().startLevel(1);
  });
  tearDown(() => container.dispose());

  test('level starts with three hearts and all arrows', () {
    expect(st().lives, 3);
    expect(st().remainingArrows, 3);
    expect(st().score, 0);
  });

  test('tapping a blocked arrow costs exactly one heart and keeps the arrow', () {
    expect(ctrl().tapArrow(0), TapOutcome.blocked);
    expect(st().lives, 2);
    expect(st().remainingArrows, 3);
    expect(st().lastEvent, isA<ArrowBlockedEvent>().having((e) => e.blockerId, 'blocker', 1));
  });

  test('successful removal does not consume lives and adds points', () {
    expect(ctrl().tapArrow(1), TapOutcome.escaped);
    expect(st().lives, 3);
    expect(st().score, GameConstants.pointsPerArrow);
    expect(st().remainingArrows, 2);
  });

  test('double tap on an escaped arrow is ignored', () {
    ctrl().tapArrow(1);
    expect(ctrl().tapArrow(1), TapOutcome.ignored);
    expect(st().score, GameConstants.pointsPerArrow);
    expect(st().lives, 3);
  });

  test('previously blocked arrow escapes once its blocker is gone', () {
    ctrl().tapArrow(1);
    expect(ctrl().tapArrow(0), TapOutcome.escaped);
  });

  test('level completion with flawless bonus and stars', () {
    ctrl()
      ..tapArrow(1)
      ..tapArrow(0)
      ..tapArrow(2);
    expect(st().isLevelCompleted, isTrue);
    expect(st().score, 3 * 10 + GameConstants.levelCompleteBonus + GameConstants.flawlessBonus);
    expect(st().stars, 3);
    expect(container.read(progressProvider).completed, contains(1));
    expect(container.read(progressProvider).unlockedLevel, 2);
  });

  test('score after losing a heart has no flawless bonus', () {
    ctrl()
      ..tapArrow(0) // blocked
      ..tapArrow(1)
      ..tapArrow(0)
      ..tapArrow(2);
    expect(st().score, 30 + GameConstants.levelCompleteBonus);
    expect(st().stars, 2);
  });

  test('hard levels earn the extra hard bonus', () {
    ctrl().startLevel(3);
    ctrl()
      ..tapArrow(1)
      ..tapArrow(0)
      ..tapArrow(2);
    expect(
      st().score,
      30 + GameConstants.levelCompleteBonus + GameConstants.flawlessBonus + GameConstants.hardLevelBonus,
    );
  });

  test('game over at zero hearts and further taps are ignored', () {
    ctrl()
      ..tapArrow(0)
      ..tapArrow(0)
      ..tapArrow(0);
    expect(st().lives, 0);
    expect(st().isGameOver, isTrue);
    expect(ctrl().tapArrow(1), TapOutcome.ignored);
    expect(st().remainingArrows, 3);
  });

  test('restart resets board, hearts, score and hints', () {
    ctrl()
      ..tapArrow(0) // blocked: -1 heart
      ..tapArrow(1) // escaped: +10
      ..useHint();
    expect(st().lives, 2);
    expect(st().score, 10);
    ctrl().restart();
    expect(st().lives, 3);
    expect(st().score, 0);
    expect(st().remainingArrows, 3);
    expect(st().hintsLeft, GameConstants.hintsPerLevel);
    expect(st().isGameOver, isFalse);
    expect(st().lastEvent, isNull);
  });

  test('hint always selects a currently removable arrow, using the live board', () {
    final id = ctrl().useHint()!;
    final s = st();
    final free = ArrowEngine.removable(s.arrows, s.level.gridRows, s.level.gridColumns).map((a) => a.id);
    expect(free, contains(id));
    expect(s.hintsLeft, GameConstants.hintsPerLevel - 1);
    expect(s.hintsUsed, 1);
    expect(s.remainingArrows, 3, reason: 'hint must not remove the arrow');
    // Remove in a different order from the stored solution, then hint again.
    ctrl().tapArrow(2);
    final id2 = ctrl().useHint()!;
    final s2 = st();
    expect(ArrowEngine.removable(s2.arrows, 5, 5).map((a) => a.id), contains(id2));
  });

  test('hints run out', () {
    for (var i = 0; i < GameConstants.hintsPerLevel; i++) {
      expect(ctrl().useHint(), isNotNull);
    }
    expect(ctrl().useHint(), isNull);
  });

  test('pause blocks taps, resume re-enables them', () {
    ctrl().pause();
    expect(ctrl().tapArrow(1), TapOutcome.ignored);
    ctrl().resume();
    expect(ctrl().tapArrow(1), TapOutcome.escaped);
  });

  test('Scoring helpers', () {
    expect(Scoring.stars(0), 3);
    expect(Scoring.stars(1), 2);
    expect(Scoring.stars(2), 1);
  });
}
