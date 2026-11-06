import '../../../core/utils/grid_utils.dart';
import '../models/arrow_model.dart';
import '../models/level_model.dart';
import 'arrow_engine.dart';
import 'dependency_graph.dart';

class ValidationReport {
  ValidationReport(this.errors);
  final List<String> errors;
  bool get isValid => errors.isEmpty;
  @override
  String toString() => isValid ? 'OK' : errors.join('\n');
}

/// Independent checks run on every generated level. Nothing here trusts the
/// generator: the solution order is re-simulated from scratch, the dependency
/// graph is rebuilt, and a greedy solver confirms that no arrow is trapped.
class LevelValidator {
  const LevelValidator();

  ValidationReport validate(LevelModel level) {
    final errors = <String>[
      ...validateShapeMask(level),
      ...validateArrowPositions(level),
      ...validateArrowDirections(level),
      ...validateNoOverlaps(level),
    ];
    // Solvability checks assume a structurally sound board.
    if (errors.isEmpty) {
      errors
        ..addAll(validateSolutionOrder(level))
        ..addAll(validateDependencyGraph(level))
        ..addAll(validateAllArrowsCanEscape(level));
    }
    return ValidationReport(errors);
  }

  List<String> validateShapeMask(LevelModel l) {
    final e = <String>[];
    if (l.occupancyMask.length != l.gridRows) e.add('mask rows ${l.occupancyMask.length} != ${l.gridRows}');
    if (l.occupancyMask.any((r) => r.length != l.gridColumns)) e.add('mask has a row with wrong width');
    if (l.maskCellCount < 4) e.add('mask too small (${l.maskCellCount} cells)');
    if (e.isEmpty) {
      if (!l.occupancyMask.first.contains(true) || !l.occupancyMask.last.contains(true)) {
        e.add('mask is not trimmed vertically');
      }
      if (!l.occupancyMask.any((r) => r.first) || !l.occupancyMask.any((r) => r.last)) {
        e.add('mask is not trimmed horizontally');
      }
    }
    return e;
  }

  List<String> validateArrowPositions(LevelModel l) {
    final e = <String>[];
    if (l.arrows.isEmpty) e.add('level has no arrows');
    for (final a in l.arrows) {
      if (a.cells.isEmpty) {
        e.add('arrow ${a.id} has no cells');
        continue;
      }
      for (final c in a.cells) {
        if (!c.inBounds(l.gridRows, l.gridColumns)) {
          e.add('arrow ${a.id} cell $c out of bounds');
        } else if (!l.occupancyMask[c.row][c.col]) {
          e.add('arrow ${a.id} cell $c outside shape mask');
        }
      }
      for (var i = 1; i < a.cells.length; i++) {
        if (!a.cells[i - 1].isAdjacentTo(a.cells[i])) e.add('arrow ${a.id} body is not contiguous');
      }
      if (a.cells.toSet().length != a.cells.length) e.add('arrow ${a.id} crosses itself');
    }
    return e;
  }

  List<String> validateArrowDirections(LevelModel l) {
    final e = <String>[];
    for (final a in l.arrows) {
      if (a.length >= 2) {
        final last = Direction.between(a.cells[a.length - 2], a.head);
        if (last != a.direction) e.add('arrow ${a.id} head points ${a.direction.name} but body enters ${last?.name}');
      }
      final ray = rayCells(a.head, a.direction, l.gridRows, l.gridColumns);
      if (ray.any(a.cells.contains)) e.add('arrow ${a.id} points into its own body');
    }
    return e;
  }

  List<String> validateNoOverlaps(LevelModel l) {
    final seen = <Cell, int>{};
    final e = <String>[];
    for (final a in l.arrows) {
      for (final c in a.cells) {
        final prev = seen[c];
        if (prev != null && prev != a.id) e.add('arrows $prev and ${a.id} overlap at $c');
        seen[c] = a.id;
      }
    }
    final ids = l.arrows.map((a) => a.id).toSet();
    if (ids.length != l.arrows.length) e.add('duplicate arrow ids');
    return e;
  }

  /// Plays the stored solution order on a simulated board.
  List<String> validateSolutionOrder(LevelModel l) {
    final byId = {for (final a in l.arrows) a.id: a};
    if (l.solutionOrder.length != l.arrows.length || l.solutionOrder.toSet().length != l.arrows.length) {
      return ['solution order is not a permutation of the arrows'];
    }
    var remaining = <ArrowModel>[...l.arrows];
    for (final id in l.solutionOrder) {
      final arrow = byId[id];
      if (arrow == null || !remaining.any((a) => a.id == id)) return ['solution step $id: arrow missing'];
      final occ = ArrowEngine.occupancy(remaining, l.gridRows, l.gridColumns);
      final block = ArrowEngine.firstBlocker(arrow, occ, l.gridRows, l.gridColumns);
      if (block != null) return ['solution step $id blocked by ${block.blockerId}'];
      remaining = [
        for (final a in remaining)
          if (a.id != id) a,
      ];
    }
    return remaining.isEmpty ? const [] : ['solution leaves ${remaining.length} arrows'];
  }

  List<String> validateDependencyGraph(LevelModel l) {
    final g = DependencyGraph.build(l.arrows, l.gridRows, l.gridColumns);
    final order = g.topologicalOrder();
    if (order == null) return ['dependency graph has a cycle'];
    // Every edge must be respected by the stored solution order.
    final pos = {for (var i = 0; i < l.solutionOrder.length; i++) l.solutionOrder[i]: i};
    for (final entry in g.blockersOf.entries) {
      for (final b in entry.value) {
        if (pos[b]! > pos[entry.key]!) return ['solution removes ${entry.key} before its blocker $b'];
      }
    }
    return const [];
  }

  /// Greedy solver ignoring the stored order: repeatedly remove any free
  /// arrow. Because removals never add obstacles, getting stuck here means an
  /// arrow is permanently trapped.
  List<String> validateAllArrowsCanEscape(LevelModel l) {
    var remaining = <ArrowModel>[...l.arrows];
    while (remaining.isNotEmpty) {
      final free = ArrowEngine.removable(remaining, l.gridRows, l.gridColumns);
      if (free.isEmpty) return ['${remaining.length} arrows are permanently trapped'];
      final ids = free.map((a) => a.id).toSet();
      remaining = [
        for (final a in remaining)
          if (!ids.contains(a.id)) a,
      ];
    }
    return const [];
  }
}
