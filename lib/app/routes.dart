import 'package:flutter/material.dart';

import '../features/gameplay/screens/game_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/level_select_screen.dart';
import '../features/settings/settings_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const levels = '/levels';
  static const game = '/game';
  static const settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    final Widget page = switch (s.name) {
      levels => const LevelSelectScreen(),
      game => GameScreen(levelNumber: (s.arguments as int?) ?? 1),
      settings => const SettingsScreen(),
      _ => const HomeScreen(),
    };
    return PageRouteBuilder(
      settings: s,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, anim, _, child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
  }
}
