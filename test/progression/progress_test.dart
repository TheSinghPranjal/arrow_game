import 'package:arrow_game/core/constants/game_constants.dart';
import 'package:arrow_game/features/progression/progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

void main() {
  test('progress persists across app restarts', () async {
    final c1 = await makeContainer();
    await c1.read(progressProvider.notifier).recordCompletion(1, 105, 3);
    await c1.read(progressProvider.notifier).recordCompletion(2, 80, 2);
    await c1.read(settingsProvider.notifier).setHaptics(false);
    c1.dispose();

    // "Restart": new container over the same stored preferences.
    final sp = await SharedPreferences.getInstance();
    final values = {for (final k in sp.getKeys()) k: sp.get(k)!};
    final c2 = await makeContainer(prefs: values);
    final p = c2.read(progressProvider);
    expect(p.completed, {1, 2});
    expect(p.bestScores, {1: 105, 2: 80});
    expect(p.stars[1], 3);
    expect(p.totalScore, 185);
    expect(p.unlockedLevel, 3);
    expect(c2.read(settingsProvider).haptics, isFalse);
    c2.dispose();
  });

  test('best score and stars only improve', () async {
    final c = await makeContainer();
    final n = c.read(progressProvider.notifier);
    await n.recordCompletion(1, 120, 3);
    await n.recordCompletion(1, 60, 1);
    expect(c.read(progressProvider).bestScores[1], 120);
    expect(c.read(progressProvider).stars[1], 3);
    c.dispose();
  });

  test('level progression unlocks the next level only', () async {
    final c = await makeContainer();
    expect(c.read(progressProvider).unlockedLevel, 1);
    expect(c.read(progressProvider).isUnlocked(2), isFalse);
    await c.read(progressProvider.notifier).recordCompletion(1, 50, 3);
    expect(c.read(progressProvider).isUnlocked(2), isTrue);
    expect(c.read(progressProvider).isUnlocked(3), isFalse);
    c.dispose();
  });

  test('unlocked level never exceeds the last level', () {
    final p = PlayerProgress(completed: {for (var i = 1; i <= GameConstants.totalLevels; i++) i});
    expect(p.unlockedLevel, GameConstants.totalLevels);
  });

  test('reset clears progress', () async {
    final c = await makeContainer();
    await c.read(progressProvider.notifier).recordCompletion(1, 50, 3);
    await c.read(progressProvider.notifier).reset();
    expect(c.read(progressProvider).completedCount, 0);
    expect(c.read(progressRepositoryProvider).load().completed, isEmpty);
    c.dispose();
  });
}
