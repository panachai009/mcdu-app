// lib/features/game/engine/game_session_engine.dart
// Domain engine managing the lifecycle and key input for GameSession.

import 'dart:async';
import '../../mcdu_core/presentation/mcdu_keypad_overlay.dart';
import '../domain/game_mode.dart';
import '../domain/game_modes.dart';
import '../domain/game_session.dart';
import '../domain/game_state.dart';

class GameSessionEngine {
  final GameMode gameMode;
  GameSession _session;

  final StreamController<GameSession> _sessionController =
      StreamController<GameSession>.broadcast();

  GameSessionEngine({
    GameMode? gameMode,
    GameSession? session,
  })  : gameMode = gameMode ?? session?.gameMode ?? GameModes.typingTest,
        _session = session ??
            GameSession(
              sessionId: 'game_${DateTime.now().millisecondsSinceEpoch}',
              gameMode: gameMode ?? GameModes.typingTest,
            );

  GameSession get session => _session;

  Stream<GameSession> get sessionStream => _sessionController.stream;

  /// Start the session: transitions from idle -> playing
  void start() {
    if (_session.isIdle) {
      _session = _session.copyWith(state: GameState.playing);
      _notify();
    }
  }

  /// Complete the session: transitions from playing -> completed
  void complete() {
    if (_session.isPlaying) {
      _session = _session.copyWith(state: GameState.completed);
      _notify();
    }
  }

  /// Reset the session: returns to idle with initial counters
  void reset() {
    _session = _session.reset();
    _notify();
  }

  /// Handle incoming MCDU key event.
  /// In Phase 12 (Foundation):
  /// - If completed or idle: ignores key event.
  /// - If playing: accepts MCDUKeyEvent without gameplay scoring or timer modifications.
  void handleKeyEvent(MCDUKeyEvent event) {
    if (_session.isCompleted) {
      return;
    }
    if (_session.isPlaying) {
      // Gameplay-specific scoring/evaluation is reserved for Phase 13+
      // Default foundation behavior: safe pass-through without unintended state modification
      return;
    }
  }

  void _notify() {
    if (!_sessionController.isClosed) {
      _sessionController.add(_session);
    }
  }

  void dispose() {
    _sessionController.close();
  }
}
