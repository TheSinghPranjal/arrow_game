import 'package:arrow_game/core/utils/grid_utils.dart';
import 'package:arrow_game/features/gameplay/models/arrow_model.dart';
import 'package:arrow_game/features/gameplay/models/level_model.dart';
import 'package:arrow_game/features/gameplay/models/shape_model.dart';
import 'package:arrow_game/features/levels/level_repository.dart';
import 'package:arrow_game/features/progression/progress_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

ArrowModel arrow(int id, List<(int, int)> cells, Direction d) =>
    ArrowModel(id: id, cells: [for (final (r, c) in cells) Cell(r, c)], direction: d, colorIndex: id % 7);

/// Hand-built level on a full rectangular mask.
LevelModel customLevel(
  List<ArrowModel> arrows, {
  int rows = 5,
  int cols = 5,
  int levelNumber = 1,
  List<int>? solution,
}) {
  return LevelModel(
    levelNumber: levelNumber,
    name: 'Test',
    shapeType: ShapeType.square,
    difficulty: Difficulty.forLevel(levelNumber),
    gridRows: rows,
    gridColumns: cols,
    occupancyMask: List.generate(rows, (_) => List.filled(cols, true)),
    arrows: arrows,
    solutionOrder: solution ?? [for (var i = arrows.length - 1; i >= 0; i--) arrows[i].id],
    seed: 0,
    targetArrowCount: arrows.length,
    params: DifficultyParams.of(Difficulty.forLevel(levelNumber)),
  );
}

class FakeLevelRepository extends LevelRepository {
  FakeLevelRepository(this.levels);
  final Map<int, LevelModel> levels;
  @override
  LevelModel level(int levelNumber) => levels[levelNumber] ?? super.level(levelNumber);
}

Future<ProviderContainer> makeContainer({Map<int, LevelModel>? levels, Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      if (levels != null) levelRepositoryProvider.overrideWithValue(FakeLevelRepository(levels)),
    ],
  );
  return container;
}
