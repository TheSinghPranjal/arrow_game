import 'package:flutter/material.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/widgets/sketch_widgets.dart';

/// Light-bulb hint button with a remaining-count badge.
class HintButton extends StatelessWidget {
  const HintButton({super.key, required this.hintsLeft, required this.onPressed});
  final int hintsLeft;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SketchIconButton(
          size: 64,
          color: SketchColors.yellow,
          semanticLabel: 'Hint, $hintsLeft left',
          icon: const Icon(Icons.lightbulb_outline_rounded, size: 32),
          onPressed: hintsLeft > 0 ? onPressed : null,
        ),
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hintsLeft > 0 ? SketchColors.sky : SketchColors.heartGrey,
              shape: BoxShape.circle,
              border: Border.all(color: SketchColors.outline, width: 2),
            ),
            child: Text(
              '$hintsLeft',
              style: const TextStyle(fontFamily: 'Chewy', fontSize: 15, color: SketchColors.outline),
            ),
          ),
        ),
      ],
    );
  }
}
