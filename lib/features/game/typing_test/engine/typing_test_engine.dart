// lib/features/game/typing_test/engine/typing_test_engine.dart
// Engine for managing Typing Test session lifecycle, Stopwatch timing, and MCDU key input.

import 'dart:async';
import '../../../mcdu_core/presentation/mcdu_keypad_overlay.dart';
import '../../domain/game_state.dart';
import '../domain/typing_test_prompt.dart';
import '../domain/typing_test_prompts.dart';
import '../domain/typing_test_session.dart';

class TypingTestEngine {
  final TypingTestPrompt prompt;
  TypingTestSession _session;
  final Stopwatch _stopwatch = Stopwatch();

  final StreamController<TypingTestSession> _sessionController =
      StreamController<TypingTestSession>.broadcast();

  TypingTestEngine({
    TypingTestPrompt? prompt,
    TypingTestSession? session,
  })  : prompt = prompt ?? session?.prompt ?? TypingTestPrompts.abc123,
        _session = session ??
            TypingTestSession(
              prompt: prompt ?? TypingTestPrompts.abc123,
            );

  TypingTestSession get session {
    if (_session.isPlaying) {
      return _session.copyWith(elapsedTime: _stopwatch.elapsed);
    }
    return _session;
  }

  Stream<TypingTestSession> get sessionStream => _sessionController.stream;

  /// Start the typing test: changes state from idle -> playing and starts timer
  void start() {
    if (_session.isIdle) {
      _stopwatch.reset();
      _stopwatch.start();
      _session = _session.copyWith(
        state: GameState.playing,
        typedText: '',
        correctCount: 0,
        errorCount: 0,
        elapsedTime: Duration.zero,
      );
      _notify();
    }
  }

  /// Reset the typing test: stops timer and returns to initial idle state
  void reset() {
    _stopwatch.reset();
    _session = _session.reset();
    _notify();
  }

  /// Handle incoming MCDU key event
  void handleKeyEvent(MCDUKeyEvent event) {
    if (!_session.isPlaying) {
      return;
    }

    final targetText = _session.prompt.targetText;
    final currentIndex = _session.typedText.length;

    if (currentIndex >= targetText.length) {
      // Already completed
      if (!_session.isCompleted) {
        _stopwatch.stop();
        _session = _session.copyWith(
          state: GameState.completed,
          elapsedTime: _stopwatch.elapsed,
        );
        _notify();
      }
      return;
    }

    final expectedChar = targetText[currentIndex];
    final pressedKey = event.keyId;

    if (pressedKey == expectedChar) {
      // Correct input
      final updatedTypedText = _session.typedText + expectedChar;
      final isNowCompleted = updatedTypedText.length == targetText.length;

      if (isNowCompleted) {
        _stopwatch.stop();
      }

      _session = _session.copyWith(
        typedText: updatedTypedText,
        correctCount: _session.correctCount + 1,
        elapsedTime: _stopwatch.elapsed,
        state: isNowCompleted ? GameState.completed : GameState.playing,
      );
      _notify();
    } else {
      // Incorrect input: typedText does not advance, errorCount increments
      _session = _session.copyWith(
        errorCount: _session.errorCount + 1,
        elapsedTime: _stopwatch.elapsed,
      );
      _notify();
    }
  }

  /// Explicitly update elapsed time (e.g. for testing or timer ticker ticks)
  void updateElapsedTime(Duration duration) {
    if (_session.isPlaying) {
      _session = _session.copyWith(elapsedTime: duration);
      _notify();
    }
  }

  void _notify() {
    if (!_sessionController.isClosed) {
      _sessionController.add(session);
    }
  }

  void dispose() {
    _stopwatch.stop();
    _sessionController.close();
  }
}
