import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/game_constants.dart';

/// Overridden in `main()` with the real instance (and in tests with a mock).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

class PlayerProgress {
  const PlayerProgress({this.completed = const {}, this.bestScores = const {}, this.stars = const {}});

  final Set<int> completed;
  final Map<int, int> bestScores;
  final Map<int, int> stars;

  int get completedCount => completed.length;
  int get totalScore => bestScores.values.fold(0, (a, b) => a + b);
  int get bestLevelScore => bestScores.values.fold(0, (a, b) => a > b ? a : b);

  /// Highest playable level: one past the highest completed level.
  int get unlockedLevel {
    final maxDone = completed.isEmpty ? 0 : completed.reduce((a, b) => a > b ? a : b);
    return (maxDone + 1).clamp(1, GameConstants.totalLevels);
  }

  bool isUnlocked(int level) => level <= unlockedLevel;
}

/// SharedPreferences-backed persistence for progress.
class ProgressRepository {
  ProgressRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _kCompleted = 'progress.completed';
  static const _kBest = 'progress.bestScores';
  static const _kStars = 'progress.stars';

  PlayerProgress load() {
    final completed = (_prefs.getStringList(_kCompleted) ?? const []).map(int.parse).toSet();
    return PlayerProgress(
      completed: completed,
      bestScores: _decodeMap(_prefs.getString(_kBest)),
      stars: _decodeMap(_prefs.getString(_kStars)),
    );
  }

  Future<void> save(PlayerProgress p) async {
    await _prefs.setStringList(_kCompleted, [for (final l in p.completed) '$l']);
    await _prefs.setString(_kBest, jsonEncode({for (final e in p.bestScores.entries) '${e.key}': e.value}));
    await _prefs.setString(_kStars, jsonEncode({for (final e in p.stars.entries) '${e.key}': e.value}));
  }

  Future<void> reset() async {
    await _prefs.remove(_kCompleted);
    await _prefs.remove(_kBest);
    await _prefs.remove(_kStars);
  }

  static Map<int, int> _decodeMap(String? raw) {
    if (raw == null) return const {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return {for (final e in m.entries) int.parse(e.key): e.value as int};
    } catch (_) {
      return const {};
    }
  }
}

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(sharedPreferencesProvider)),
);

class ProgressNotifier extends Notifier<PlayerProgress> {
  @override
  PlayerProgress build() => ref.watch(progressRepositoryProvider).load();

  Future<void> recordCompletion(int level, int score, int stars) async {
    final s = state;
    final best = Map<int, int>.of(s.bestScores);
    final st = Map<int, int>.of(s.stars);
    if ((best[level] ?? 0) < score) best[level] = score;
    if ((st[level] ?? 0) < stars) st[level] = stars;
    state = PlayerProgress(completed: {...s.completed, level}, bestScores: best, stars: st);
    await ref.read(progressRepositoryProvider).save(state);
  }

  Future<void> reset() async {
    await ref.read(progressRepositoryProvider).reset();
    state = const PlayerProgress();
  }
}

final progressProvider = NotifierProvider<ProgressNotifier, PlayerProgress>(ProgressNotifier.new);

// ----------------------------------------------------------------------------

class GameSettings {
  const GameSettings({this.sound = true, this.music = true, this.haptics = true});
  final bool sound;
  final bool music;
  final bool haptics;

  GameSettings copyWith({bool? sound, bool? music, bool? haptics}) =>
      GameSettings(sound: sound ?? this.sound, music: music ?? this.music, haptics: haptics ?? this.haptics);
}

class SettingsNotifier extends Notifier<GameSettings> {
  static const _kSound = 'settings.sound';
  static const _kMusic = 'settings.music';
  static const _kHaptics = 'settings.haptics';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  GameSettings build() {
    final p = ref.watch(sharedPreferencesProvider);
    return GameSettings(
      sound: p.getBool(_kSound) ?? true,
      music: p.getBool(_kMusic) ?? true,
      haptics: p.getBool(_kHaptics) ?? true,
    );
  }

  Future<void> setSound(bool v) async {
    state = state.copyWith(sound: v);
    await _prefs.setBool(_kSound, v);
  }

  Future<void> setMusic(bool v) async {
    state = state.copyWith(music: v);
    await _prefs.setBool(_kMusic, v);
  }

  Future<void> setHaptics(bool v) async {
    state = state.copyWith(haptics: v);
    await _prefs.setBool(_kHaptics, v);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, GameSettings>(SettingsNotifier.new);
