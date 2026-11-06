import 'package:flutter/material.dart';

import 'routes.dart';
import 'theme.dart';

class SketchArrowsApp extends StatelessWidget {
  const SketchArrowsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arrow Game - Sketch',
      debugShowCheckedModeBanner: false,
      theme: buildSketchTheme(),
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
