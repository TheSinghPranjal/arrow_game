import '../../../core/utils/grid_utils.dart';
import '../models/arrow_model.dart';

/// "B blocks A" ⇒ B must be removed before A.
///
/// Because removing an arrow never adds an obstacle, a board is solvable if
/// and only if this graph is acyclic; any topological order is a solution.
class DependencyGraph {
  DependencyGraph._(this.ids, this.blockersOf);

  factory DependencyGraph.build(List<ArrowModel> arrows, int rows, int cols) {
    final owner = <Cell, int>{};
    for (final a in arrows) {
      for (final c in a.cells) {
        owner[c] = a.id;
      }
    }
    final blockers = <int, Set<int>>{};
    for (final a in arrows) {
      final set = <int>{};
      for (final c in rayCells(a.head, a.direction, rows, cols)) {
        final o = owner[c];
        if (o != null && o != a.id) set.add(o);
      }
      blockers[a.id] = set;
    }
    return DependencyGraph._([for (final a in arrows) a.id], blockers);
  }

  final List<int> ids;

  /// arrow id → ids of arrows sitting on its escape ray.
  final Map<int, Set<int>> blockersOf;

  int get edgeCount => blockersOf.values.fold(0, (s, v) => s + v.length);

  /// Kahn's algorithm. Returns a removal order, or null if a cycle exists.
  List<int>? topologicalOrder() {
    final remaining = <int, int>{for (final id in ids) id: blockersOf[id]!.length};
    final dependents = <int, List<int>>{for (final id in ids) id: []};
    blockersOf.forEach((a, bs) {
      for (final b in bs) {
        dependents[b]!.add(a);
      }
    });
    final queue = [
      for (final id in ids)
        if (remaining[id] == 0) id,
    ];
    final order = <int>[];
    while (queue.isNotEmpty) {
      final id = queue.removeLast();
      order.add(id);
      for (final d in dependents[id]!) {
        remaining[d] = remaining[d]! - 1;
        if (remaining[d] == 0) queue.add(d);
      }
    }
    return order.length == ids.length ? order : null;
  }

  bool get isAcyclic => topologicalOrder() != null;

  /// Length of the longest blocking chain (a rough difficulty measure).
  int longestChain() {
    final memo = <int, int>{};
    int depth(int id) => memo[id] ??=
        1 +
        blockersOf[id]!.fold<int>(0, (m, b) {
          final d = depth(b);
          return d > m ? d : m;
        });
    var best = 0;
    for (final id in ids) {
      final d = depth(id);
      if (d > best) best = d;
    }
    return best;
  }
}
