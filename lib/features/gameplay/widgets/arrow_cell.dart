import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/grid_utils.dart';
import '../models/arrow_model.dart';
import '../painters/shape_board_painter.dart';

/// Non-interactive rendering of a set of arrows on a grid, scaled to fit.
/// Used for the solved-pattern card on the completion screen and for the
/// decorative doodles on the home screen.
class ArrowPreview extends StatelessWidget {
  const ArrowPreview({super.key, required this.mask, required this.arrows, this.showDots = false});

  final List<List<bool>> mask;
  final List<ArrowModel> arrows;
  final bool showDots;

  @override
  Widget build(BuildContext context) {
    final rows = mask.length, cols = mask.isEmpty ? 1 : mask.first.length;
    return LayoutBuilder(
      builder: (context, c) {
        final cs = math.min(c.maxWidth / cols, c.maxHeight / rows);
        return Center(
          child: SizedBox(
            width: cs * cols,
            height: cs * rows,
            child: CustomPaint(
              painter: ShapeBoardPainter(mask: mask, arrows: arrows, cellSize: cs, showDots: showDots),
            ),
          ),
        );
      },
    );
  }
}

/// A single decorative arrow (e.g. in the logo).
class ArrowCell extends StatelessWidget {
  const ArrowCell({
    super.key,
    required this.cells,
    required this.direction,
    required this.colorIndex,
    this.cellSize = 26,
  });

  final List<Cell> cells;
  final Direction direction;
  final int colorIndex;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final rows = cells.map((c) => c.row).reduce(math.max) + 1;
    final cols = cells.map((c) => c.col).reduce(math.max) + 1;
    final arrow = ArrowModel(
      id: colorIndex * 13 + cells.length,
      cells: cells,
      direction: direction,
      colorIndex: colorIndex,
    );
    return SizedBox(
      width: cols * cellSize,
      height: rows * cellSize,
      child: CustomPaint(
        painter: ShapeBoardPainter(
          mask: List.generate(rows, (_) => List.filled(cols, false)),
          arrows: [arrow],
          cellSize: cellSize,
          showDots: false,
        ),
      ),
    );
  }
}
