abstract final class GameConstants {
  static const int totalLevels = 150;
  static const int startingLives = 3;
  static const int hintsPerLevel = 3;

  static const int pointsPerArrow = 10;
  static const int levelCompleteBonus = 50;
  static const int flawlessBonus = 25;
  static const int hardLevelBonus = 25;

  /// Duration of an arrow sliding off the board (scaled slightly by path length).
  static const int escapeBaseMs = 220;
  static const int escapeMaxMs = 420;
  static const int bounceMs = 320;
  static const int hintPulseMs = 2400;

  /// Delay between the final arrow leaving and the completion screen appearing.
  static const int completionDelayMs = 450;
}
