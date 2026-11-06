import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/utils/grid_utils.dart';
import '../../../core/widgets/sketch_widgets.dart';
import '../../gameplay/widgets/arrow_cell.dart';

/// Game title with a few doodled arrows bobbing around it.
class HomeLogo extends StatefulWidget {
  const HomeLogo({super.key});
  @override
  State<HomeLogo> createState() => _HomeLogoState();
}

class _HomeLogoState extends State<HomeLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget bob(double phase, Widget child) => AnimatedBuilder(
      animation: _c,
      builder: (_, c) =>
          Transform.translate(offset: Offset(0, math.sin((_c.value + phase) * 2 * math.pi) * 5), child: c),
      child: child,
    );

    return SizedBox(
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            top: 6,
            child: bob(
              0,
              const ArrowCell(
                cells: [Cell(2, 0), Cell(1, 0), Cell(0, 0), Cell(0, 1), Cell(0, 2)],
                direction: Direction.right,
                colorIndex: 0,
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: 0,
            child: bob(
              0.3,
              const ArrowCell(cells: [Cell(0, 0), Cell(1, 0), Cell(2, 0)], direction: Direction.down, colorIndex: 2),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 2,
            child: bob(
              0.6,
              const ArrowCell(cells: [Cell(0, 2), Cell(0, 1), Cell(0, 0)], direction: Direction.left, colorIndex: 3),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 6,
            child: bob(
              0.8,
              const ArrowCell(
                cells: [Cell(0, 0), Cell(0, 1), Cell(1, 1), Cell(2, 1)],
                direction: Direction.down,
                colorIndex: 4,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: -0.04,
                  child: Text(
                    'Arrow Game',
                    style: SketchText.title.copyWith(
                      fontSize: 58,
                      color: SketchColors.coral,
                      shadows: const [Shadow(color: SketchColors.outline, offset: Offset(3, 3))],
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: 0.03,
                  child: Text(
                    '- Sketch',
                    style: SketchText.title.copyWith(
                      fontSize: 58,
                      color: SketchColors.yellow,
                      shadows: const [Shadow(color: SketchColors.outline, offset: Offset(3, 3))],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
