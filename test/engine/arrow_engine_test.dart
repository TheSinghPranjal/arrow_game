import 'package:arrow_game/core/utils/grid_utils.dart';
import 'package:arrow_game/features/gameplay/engine/arrow_engine.dart';
import 'package:arrow_game/features/gameplay/engine/dependency_graph.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('Arrow movement in all four directions', () {
    for (final d in Direction.values) {
      test('lone arrow pointing ${d.name} escapes and exits the grid', () {
        final a = arrow(0, [(2, 2)], d);
        final occ = ArrowEngine.occupancy([a], 5, 5);
        expect(ArrowEngine.canEscape(a, occ, 5, 5), isTrue);
        final path = ArrowEngine.exitPath(a, 5, 5);
        expect(path.first, const Cell(2, 2));
        expect(path.last.inBounds(5, 5), isFalse, reason: 'path must leave the board');
        for (var i = 1; i < path.length; i++) {
          expect(Direction.between(path[i - 1], path[i]), d);
        }
      });
    }

    test('bent arrow exit path follows its body, then its head ray', () {
      final a = arrow(0, [(3, 0), (3, 1), (2, 1)], Direction.up);
      final path = ArrowEngine.exitPath(a, 5, 5);
      expect(path.take(5).toList(), const [Cell(3, 0), Cell(3, 1), Cell(2, 1), Cell(1, 1), Cell(0, 1)]);
      expect(path.length, 5 + a.length + 1);
    });
  });

  group('Path detection', () {
    test('clear path when nothing lies on the ray', () {
      final a = arrow(0, [(2, 2)], Direction.right);
      final b = arrow(1, [(0, 4)], Direction.up); // same column as ray end but other row
      final occ = ArrowEngine.occupancy([a, b], 5, 5);
      expect(ArrowEngine.firstBlocker(a, occ, 5, 5), isNull);
    });

    test('blocked by an adjacent arrow', () {
      final a = arrow(0, [(2, 2)], Direction.right);
      final b = arrow(1, [(2, 3)], Direction.up);
      final block = ArrowEngine.firstBlocker(a, ArrowEngine.occupancy([a, b], 5, 5), 5, 5);
      expect(block?.blockerId, 1);
      expect(block?.freeSteps, 0);
    });

    test('blocked by a distant arrow in the same row (whole ray is checked)', () {
      final a = arrow(0, [(2, 0)], Direction.right);
      final far = arrow(1, [(2, 4)], Direction.down);
      final block = ArrowEngine.firstBlocker(a, ArrowEngine.occupancy([a, far], 5, 5), 5, 5);
      expect(block?.blockerId, 1);
      expect(block?.freeSteps, 3);
    });

    test('blocked by the body of a bent arrow', () {
      final a = arrow(0, [(4, 2)], Direction.up);
      final b = arrow(1, [(1, 1), (1, 2), (1, 3)], Direction.right);
      expect(ArrowEngine.canEscape(a, ArrowEngine.occupancy([a, b], 5, 5), 5, 5), isFalse);
    });

    test('removed arrows no longer block', () {
      final a = arrow(0, [(2, 0)], Direction.right);
      final b = arrow(1, [(2, 3)], Direction.up).copyWith(isRemoved: true);
      expect(ArrowEngine.canEscape(a, ArrowEngine.occupancy([a, b], 5, 5), 5, 5), isTrue);
    });

    test('removable() lists exactly the free arrows', () {
      final a = arrow(0, [(2, 0)], Direction.right);
      final b = arrow(1, [(2, 3)], Direction.up);
      expect(ArrowEngine.removable([a, b], 5, 5).map((x) => x.id), [1]);
    });
  });

  group('Dependency graph', () {
    test('detects a deadlock cycle', () {
      final a = arrow(0, [(2, 0)], Direction.right);
      final b = arrow(1, [(2, 4)], Direction.left);
      final g = DependencyGraph.build([a, b], 5, 5);
      expect(g.isAcyclic, isFalse);
    });

    test('topological order respects blockers', () {
      final a = arrow(0, [(2, 0)], Direction.right);
      final b = arrow(1, [(2, 3)], Direction.up);
      final c = arrow(2, [(0, 3)], Direction.left); // blocks nothing
      final order = DependencyGraph.build([a, b, c], 5, 5).topologicalOrder()!;
      expect(order.indexOf(1), lessThan(order.indexOf(0)));
    });
  });
}
