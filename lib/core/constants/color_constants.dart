import 'package:flutter/painting.dart';

/// Sketch-notebook palette used across the whole game.
abstract final class SketchColors {
  static const background = Color(0xFFC8EDFC);
  static const backgroundSecondary = Color(0xFFD9F3FC);
  static const notebookLine = Color(0xFFA8D9EC);
  static const dot = Color(0xFFA9D7E9);
  static const outline = Color(0xFF292929);
  static const cream = Color(0xFFFFF8E8);
  static const white = Color(0xFFFFFFFF);
  static const heartRed = Color(0xFFF36D65);
  static const heartGrey = Color(0xFFBFC6CC);
  static const muted = Color(0xFF6B7780);
  static const lockedGrey = Color(0xFFDCE3E8);

  static const coral = Color(0xFFF36D65);
  static const yellow = Color(0xFFFFD45C);
  static const sky = Color(0xFF72C9F2);
  static const mint = Color(0xFF78D69A);
  static const purple = Color(0xFFB99AEF);
  static const orange = Color(0xFFFFAA63);
  static const pink = Color(0xFFF49AC2);

  /// Arrow fill colours, indexed by `ArrowModel.colorIndex`.
  static const arrowPalette = <Color>[coral, yellow, sky, mint, purple, orange, pink];

  static const easy = mint;
  static const medium = yellow;
  static const hard = coral;
}
