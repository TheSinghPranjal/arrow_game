import 'package:flutter/rendering.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/utils/grid_utils.dart';
import '../models/arrow_model.dart';
import 'arrow_painter.dart';

/// Static layer: the silhouette's pencil dots and every resting arrow.
/// Repaints only when the set of resting arrows changes.
class ShapeBoardPainter extends CustomPainter {
  ShapeBoardPainter({
    required this.mask,
    required this.arrows,
    required this.cellSize,
    this.hiddenIds = const {},
    this.showDots = true,
  });

  final List<List<bool>> mask;
  final List<ArrowModel> arrows;
  final double cellSize;

  /// Arrows drawn by the animation layer instead (e.g. bouncing).
  final Set<int> hiddenIds;
  final bool showDots;

  @override
  void paint(Canvas canvas, Size size) {
    final g = BoardGeometry(cellSize: cellSize, origin: Offset.zero);
    if (showDots) {
      // Pale silhouette so the shape reads even when arrows are sparse.
      final silhouette = Path();
      final inset = cellSize * 0.04;
      for (var r = 0; r < mask.length; r++) {
        for (var c = 0; c < mask[r].length; c++) {
          if (!mask[r][c]) continue;
          silhouette.addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c * cellSize - inset, r * cellSize - inset, cellSize + inset * 2, cellSize + inset * 2),
              Radius.circular(cellSize * 0.3),
            ),
          );
        }
      }
      canvas.drawPath(silhouette, Paint()..color = SketchColors.white.withValues(alpha: 0.45));
      final dot = Paint()..color = SketchColors.outline.withValues(alpha: 0.18);
      for (var r = 0; r < mask.length; r++) {
        for (var c = 0; c < mask[r].length; c++) {
          if (mask[r][c]) canvas.drawCircle(g.center(Cell(r, c)), cellSize * 0.07, dot);
        }
      }
    }
    for (final a in arrows) {
      if (!hiddenIds.contains(a.id)) ArrowPainter.paintArrow(canvas, g, a);
    }
  }

  @override
  bool shouldRepaint(covariant ShapeBoardPainter old) =>
      !identical(old.arrows, arrows) ||
      old.cellSize != cellSize ||
      !identical(old.mask, mask) ||
      old.hiddenIds.length != hiddenIds.length ||
      !old.hiddenIds.containsAll(hiddenIds);
}
