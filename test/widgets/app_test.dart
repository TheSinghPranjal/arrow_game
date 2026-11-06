import 'package:arrow_game/app/app.dart';
import 'package:arrow_game/features/gameplay/engine/game_controller.dart';
import 'package:arrow_game/features/progression/progress_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(sp)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const SketchArrowsApp()));
    await tester.pump();
    return container;
  }

  testWidgets('app launches to the home screen', (tester) async {
    await pumpApp(tester);
    expect(find.text('Sketch'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Levels'), findsOneWidget);
  });

  testWidgets('play a full level through the UI', (tester) async {
    final container = await pumpApp(tester);
    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final s = container.read(gameControllerProvider)!;
    expect(s.currentLevel, 1);
    expect(find.text('LEVEL 1'), findsOneWidget);

    // Remove every arrow via the controller (UI hit-testing covered below).
    for (final id in s.level.solutionOrder) {
      container.read(gameControllerProvider.notifier).tapArrow(id);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Level Complete!'), findsOneWidget);
    expect(find.text('Next Level'), findsOneWidget);

    await tester.tap(find.text('Next Level'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(gameControllerProvider)!.currentLevel, 2);
    expect(find.text('LEVEL 2'), findsOneWidget);
  });

  testWidgets('tapping an arrow on the board removes it', (tester) async {
    final container = await pumpApp(tester);
    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final s = container.read(gameControllerProvider)!;
    final first = s.level.arrows.firstWhere((a) => a.id == s.level.solutionOrder.first);

    final board = find.byKey(const Key('arrow-board'));
    final box = tester.getRect(board);
    final cs = box.width / s.level.gridColumns;
    final pos = box.topLeft + Offset((first.head.col + 0.5) * cs, (first.head.row + 0.5) * cs);
    await tester.tapAt(pos);
    await tester.pump(const Duration(milliseconds: 500));
    expect(container.read(gameControllerProvider)!.remainingArrows, s.totalArrows - 1);
    expect(container.read(gameControllerProvider)!.score, 10);
  });

  testWidgets('pause overlay and level select render', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.bySemanticsLabel('Pause'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Paused'), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Levels'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('0/150'), findsOneWidget);
  });
}
