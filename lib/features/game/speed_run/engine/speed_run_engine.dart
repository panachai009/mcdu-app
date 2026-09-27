// lib/features/game/speed_run/engine/speed_run_engine.dart
// Pure Dart engine for Speed Run. Deterministic, testable, no Flutter dependencies.

import 'dart:math' as math;
import '../domain/speed_run_session.dart';
import '../domain/speed_run_task.dart';
import '../domain/speed_run_tasks_catalog.dart';

class SpeedRunEngine {
  SpeedRunSession _session;

  SpeedRunEngine({
    List<SpeedRunTask>? tasks,
    SpeedRunSession? session,
  }) : _session = session ??
            SpeedRunSession(
              status: SpeedRunStatus.ready,
              tasks: tasks ?? SpeedRunTasksCatalog.defaultTasks,
            );

  SpeedRunSession get session => _session;

  /// Start the session
  void start() {
    if (_session.isReady) {
      _session = _session.copyWith(
        status: SpeedRunStatus.playing,
        currentTaskIndex: 0,
        currentStepIndex: 0,
        scratchpadBuffer: '',
        elapsedTime: Duration.zero,
        penaltyTime: Duration.zero,
        score: 0,
        errors: 0,
        combo: 0,
        completedTasks: 0,
        difficultyLevel: 1,
      );
    }
  }

  /// Pause current session
  void pause() {
    if (_session.isPlaying) {
      _session = _session.copyWith(
        status: SpeedRunStatus.paused,
        previousStatus: _session.status,
      );
    }
  }

  /// Resume paused session
  void resume() {
    if (_session.isPaused) {
      _session = _session.copyWith(
        status: SpeedRunStatus.playing,
      );
    }
  }

  /// Reset to initial ready state
  void reset() {
    _session = SpeedRunSession(
      status: SpeedRunStatus.ready,
      tasks: _session.tasks,
      difficultyLevel: 1,
    );
  }

  /// Advance forward elapsed time (called deterministically or by ticker)
  void tick(Duration delta) {
    if (_session.isPlaying && delta > Duration.zero) {
      _session = _session.copyWith(
        elapsedTime: _session.elapsedTime + delta,
      );
    }
  }

  /// Process input key event
  void handleKey(String keyId) {
    if (!_session.isPlaying) return;

    final currentStep = _session.currentStep;
    if (currentStep == null) return;

    // Non-gameplay key check (e.g. BRT/DIM, or ignored system keys)
    if (_isIgnoredKey(keyId)) {
      return;
    }

    if (keyId == currentStep.expectedKeyId) {
      _handleCorrectKey(keyId, currentStep);
    } else {
      _handleWrongKey();
    }
  }

  void _handleCorrectKey(String keyId, dynamic step) {
    final newCombo = _session.combo + 1;
    final nextStepIndex = _session.currentStepIndex + 1;
    final currentTask = _session.currentTask!;

    String newScratchpad = _session.scratchpadBuffer;
    if (step.isScratchpadChar) {
      // If the expected key was DOT, represent as '.' in scratchpad, else keyId
      final char = keyId == 'DOT' ? '.' : keyId;
      newScratchpad += char;
    }

    // Step points: base 20 pts + combo bonus
    final stepPoints = 20 + (newCombo * 5);
    final newScore = _session.score + stepPoints;

    // Check if task is finished
    if (nextStepIndex >= currentTask.totalSteps) {
      final newCompletedTasks = _session.completedTasks + 1;
      final nextTaskIndex = _session.currentTaskIndex + 1;
      final nextLevel = math.min(5, _session.difficultyLevel + 1);

      // Task completion bonus (par time calculation)
      final taskParTimeMs = currentTask.parTime.inMilliseconds;
      final taskBonus = math.max(100, taskParTimeMs ~/ 10);
      final finalScore = newScore + taskBonus;

      // Check if all tasks in session are finished
      if (nextTaskIndex >= _session.tasks.length) {
        _session = _session.copyWith(
          status: SpeedRunStatus.completed,
          currentTaskIndex: nextTaskIndex,
          currentStepIndex: 0,
          scratchpadBuffer: '',
          score: finalScore + 500, // Course completion bonus
          combo: newCombo,
          completedTasks: newCompletedTasks,
          difficultyLevel: nextLevel,
        );
      } else {
        // Transition to next task
        _session = _session.copyWith(
          currentTaskIndex: nextTaskIndex,
          currentStepIndex: 0,
          scratchpadBuffer: '',
          score: finalScore,
          combo: newCombo,
          completedTasks: newCompletedTasks,
          difficultyLevel: nextLevel,
        );
      }
    } else {
      // Advance to next step in current task
      _session = _session.copyWith(
        currentStepIndex: nextStepIndex,
        scratchpadBuffer: newScratchpad,
        score: newScore,
        combo: newCombo,
      );
    }
  }

  void _handleWrongKey() {
    _session = _session.copyWith(
      errors: _session.errors + 1,
      combo: 0,
      penaltyTime: _session.penaltyTime + const Duration(seconds: 1),
    );
  }

  bool _isIgnoredKey(String keyId) {
    return keyId == 'BRT/DIM';
  }
}
