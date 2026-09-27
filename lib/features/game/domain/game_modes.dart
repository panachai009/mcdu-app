// lib/features/game/domain/game_modes.dart
// Catalog of available Game Modes.

import 'game_mode.dart';

class GameModes {
  static const GameMode typingTest = GameMode(
    gameModeId: 'typing_test',
    title: 'Typing Test',
    description: 'Practice rapid alphanumeric MCDU typing and accuracy.',
  );

  static const GameMode wordRain = GameMode(
    gameModeId: 'word_rain',
    title: 'Word Rain',
    description: 'Type falling aviation terms and fixes before they reach the bottom.',
  );

  static const GameMode memory = GameMode(
    gameModeId: 'memory',
    title: 'Memory',
    description: 'Memorize and reproduce complex MCDU waypoints and flight sequences.',
  );

  static const GameMode speedRun = GameMode(
    gameModeId: 'speed_run',
    title: 'Speed Run',
    description: 'Complete full pre-flight MCDU setups under strict time limits.',
  );

  static const GameMode mcduFlow = GameMode(
    gameModeId: 'mcdu_flow',
    title: 'MCDU Flow',
    description: 'Master standard airline operating procedures and page flows.',
  );

  static const List<GameMode> all = [
    typingTest,
    wordRain,
    memory,
    speedRun,
    mcduFlow,
  ];

  static GameMode? findById(String gameModeId) {
    for (final mode in all) {
      if (mode.gameModeId == gameModeId) {
        return mode;
      }
    }
    return null;
  }
}
