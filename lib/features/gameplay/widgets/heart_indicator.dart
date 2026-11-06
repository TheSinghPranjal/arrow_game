import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/game_constants.dart';
import '../../../core/widgets/sketch_widgets.dart';

/// Row of hearts; a heart that is lost pops, shakes and turns grey.
class HeartIndicator extends StatelessWidget {
  const HeartIndicator({super.key, required this.lives, this.size = 24});
  final int lives;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$lives of ${GameConstants.startingLives} lives left',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < GameConstants.startingLives; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: _HeartSlot(filled: i < lives, size: size),
            ),
        ],
      ),
    );
  }
}

class _HeartSlot extends StatefulWidget {
  const _HeartSlot({required this.filled, required this.size});
  final bool filled;
  final double size;

  @override
  State<_HeartSlot> createState() => _HeartSlotState();
}

class _HeartSlotState extends State<_HeartSlot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));

  @override
  void didUpdateWidget(covariant _HeartSlot old) {
    super.didUpdateWidget(old);
    if (old.filled != widget.filled) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final active = _c.isAnimating;
        final scale = active ? 1 + 0.45 * math.sin(t * math.pi) : 1.0;
        final dx = active ? math.sin(t * math.pi * 6) * 4 * (1 - t) : 0.0;
        // Show the old (red) heart during the first half of a loss.
        final showFilled = widget.filled || (active && t < 0.45);
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.scale(
            scale: scale,
            child: SketchHeart(filled: showFilled, size: widget.size),
          ),
        );
      },
    );
  }
}
