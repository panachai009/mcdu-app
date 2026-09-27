// lib/features/game/domain/game_session.dart
// Immutable game session state for MCDU Game Foundation.

import 'game_mode.dart';
import 'game_state.dart';

class GameSession {
  final String sessionId;
  final GameMode gameMode;
  final GameState state;
  final int correctCount;
  final int errorCount;
  final Duration elapsedTime;
  final int score;

  const GameSession({
    required this.sessionId,
    required this.gameMode,
    this.state = GameState.idle,
    this.correctCount = 0,
    this.errorCount = 0,
    this.elapsedTime = Duration.zero,
    this.score = 0,
  });

  bool get isIdle => state == GameState.idle;
  bool get isPlaying => state == GameState.playing;
  bool get isCompleted => state == GameState.completed;

  GameSession copyWith({
    String? sessionId,
    GameMode? gameMode,
    GameState? state,
    int? correctCount,
    int? errorCount,
    Duration? elapsedTime,
    int? score,
  }) {
    return GameSession(
      sessionId: sessionId ?? this.sessionId,
      gameMode: gameMode ?? this.gameMode,
      state: state ?? this.state,
      correctCount: correctCount ?? this.correctCount,
      errorCount: errorCount ?? this.errorCount,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      score: score ?? this.score,
    );
  }

  GameSession reset() {
    return GameSession(
      sessionId: sessionId,
      gameMode: gameMode,
      state: GameState.idle,
      correctCount: 0,
      errorCount: 0,
      elapsedTime: Duration.zero,
      score: 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameSession &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          gameMode == other.gameMode &&
          state == other.state &&
          correctCount == other.correctCount &&
          errorCount == other.errorCount &&
          elapsedTime == other.elapsedTime &&
          score == other.score;

  @override
  int get hashCode => Object.hash(
        sessionId,
        gameMode,
        state,
        correctCount,
        errorCount,
        elapsedTime,
        score,
      );

  @override
  String toString() =>
      'GameSession(sessionId: $sessionId, mode: ${gameMode.gameModeId}, state: $state, correct: $correctCount, errors: $errorCount, score: $score)';
}
