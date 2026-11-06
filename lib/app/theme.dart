import 'package:flutter/material.dart';

import '../core/constants/color_constants.dart';

ThemeData buildSketchTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'PatrickHand',
    scaffoldBackgroundColor: SketchColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: SketchColors.sky,
      surface: SketchColors.cream,
      primary: SketchColors.outline,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: SketchColors.outline,
      contentTextStyle: TextStyle(fontFamily: 'PatrickHand', fontSize: 18, color: SketchColors.cream),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
