import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/shape_utils.dart';
import '../gameplay/engine/level_generator.dart';
import '../gameplay/models/level_model.dart';
import 'level_definitions.dart';

/// Generates levels lazily and caches them. Generation is deterministic, so
/// a level always looks the same for every player.
class LevelRepository {
  LevelRepository({LevelGenerator? generator}) : _generator = generator ?? LevelGenerator();

  final LevelGenerator _generator;
  final Map<int, LevelModel> _cache = {};
  final Map<int, List<List<bool>>> _maskCache = {};

  int get levelCount => levelDefinitions.length;

  LevelDefinition definition(int levelNumber) {
    if (levelNumber < 1 || levelNumber > levelCount) {
      throw RangeError.range(levelNumber, 1, levelCount, 'levelNumber');
    }
    return levelDefinitions[levelNumber - 1];
  }

  LevelModel level(int levelNumber) =>
      _cache.putIfAbsent(levelNumber, () => _generator.generate(definition(levelNumber)));

  /// Cheap silhouette (no arrow generation) for level-select icons.
  List<List<bool>> mask(int levelNumber) =>
      _maskCache.putIfAbsent(levelNumber, () => ShapeUtils.buildMask(definition(levelNumber).shape));
}

final levelRepositoryProvider = Provider<LevelRepository>((ref) => LevelRepository());
