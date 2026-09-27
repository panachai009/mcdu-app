// lib/features/game/memory/engine/memory_engine.dart

import 'dart:async';
import 'dart:math';

import '../../../mcdu_core/presentation/mcdu_keypad_overlay.dart';
import '../domain/memory_sequence.dart';
import '../domain/memory_session.dart';

class MemoryEngine {
  MemorySession _session;
  final Random _random;

  final StreamController<MemorySession> _sessionController =
      StreamController<MemorySession>.broadcast();

  static const String characterSet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  MemoryEngine({
    MemorySession? session,
    Random? random,
  })  : _session = session ?? const MemorySession(),
        _random = random ?? Random();

  MemorySession get session => _session;
  Stream<MemorySession> get sessionStream => _sessionController.stream;

  /// Pure difficulty formula: level = min(10, 1 + (completedRounds ~/ 5))
  static int calculateLevel(int completedRounds) {
    final lvl = 1 + (completedRounds ~/ 5);
    return lvl > 10 ? 10 : (lvl < 1 ? 1 : lvl);
  }

  /// Pure difficulty formula for sequence length per level:
  /// Level 1 = 3
  /// Level 2 = 3
  /// Level 3 = 4
  /// Level 4 = 4
  /// Level 5 = 5
  /// Level 6 = 5
  /// Level 7 = 6
  /// Level 8 = 6
  /// Level 9 = 7
  /// Level 10 = 8
  static int sequenceLengthForLevel(int level) {
    final clamped = level > 10 ? 10 : (level < 1 ? 1 : level);
    switch (clamped) {
      case 1:
      case 2:
        return 3;
      case 3:
      case 4:
        return 4;
      case 5:
      case 6:
        return 5;
      case 7:
      case 8:
        return 6;
      case 9:
        return 7;
      case 10:
      default:
        return 8;
    }
  }

  /// Generate a random sequence using the injected Random instance
  MemorySequence generateSequence({int? level}) {
    final targetLevel = level ?? _session.level;
    final length = sequenceLengthForLevel(targetLevel);
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      final index = _random.nextInt(characterSet.length);
      buffer.write(characterSet[index]);
    }
    return MemorySequence(value: buffer.toString(), level: targetLevel);
  }

  /// Start game: READY -> MEMORIZING
  void start() {
    if (_session.isReady) {
      final sequence = generateSequence(level: _session.level);
      _session = _session.copyWith(
        status: MemoryStatus.memorizing,
        targetSequence: sequence.value,
        inputBuffer: '',
      );
      _notify();
    }
  }

  /// Transition from MEMORIZING -> RECALLING
  void beginRecall() {
    if (_session.isMemorizing) {
      _session = _session.copyWith(
        status: MemoryStatus.recalling,
        inputBuffer: '',
      );
      _notify();
    }
  }

  /// Pause game
  void pause() {
    if (_session.isMemorizing || _session.isRecalling) {
      _session = _session.copyWith(
        status: MemoryStatus.paused,
        previousStatus: _session.status,
      );
      _notify();
    }
  }

  /// Resume game
  void resume() {
    if (_session.isPaused) {
      final targetStatus = _session.previousStatus ?? MemoryStatus.recalling;
      _session = _session.copyWith(
        status: targetStatus,
        previousStatus: null,
      );
      _notify();
    }
  }

  /// Reset game
  void reset() {
    _session = _session.reset();
    _notify();
  }

  /// Advance elapsed time (pure method without internal timers)
  void tick(Duration delta) {
    if (_session.isMemorizing || _session.isRecalling) {
      _session = _session.copyWith(
        elapsedTime: _session.elapsedTime + delta,
      );
      _notify();
    }
  }

  /// Handle incoming physical MCDU key event
  void handleKeyEvent(MCDUKeyEvent event) {
    // Only accept gameplay inputs during RECALLING
    if (!_session.isRecalling) return;

    final key = event.keyId.trim().toUpperCase();
    final isAlphanumeric = RegExp(r'^[A-Z0-9]$').hasMatch(key);
    if (!isAlphanumeric) return;

    final target = _session.targetSequence;
    final currentInput = _session.inputBuffer;
    final nextIndex = currentInput.length;

    if (nextIndex >= target.length) return; // Already full

    final expectedChar = target[nextIndex];

    if (key == expectedChar) {
      // Correct character
      final newInput = currentInput + key;
      final isRoundCompleted = newInput.length == target.length;

      if (isRoundCompleted) {
        // Complete round
        final newRounds = _session.completedRounds + 1;
        final newLevel = calculateLevel(newRounds);
        final newCombo = _session.combo + 1;

        // Score formula:
        // base score = sequence.length * 100
        // combo bonus = combo * 25
        final baseScore = target.length * 100;
        final comboBonus = newCombo * 25;
        final roundScore = baseScore + comboBonus;

        // Generate next sequence for the new round
        final nextSeq = generateSequence(level: newLevel);

        _session = _session.copyWith(
          status: MemoryStatus.memorizing,
          level: newLevel,
          targetSequence: nextSeq.value,
          inputBuffer: '',
          completedRounds: newRounds,
          combo: newCombo,
          score: _session.score + roundScore,
        );
      } else {
        // Partial correct character
        _session = _session.copyWith(
          inputBuffer: newInput,
        );
      }
      _notify();
    } else {
      // Wrong character input
      final newLives = _session.lives - 1;
      final isGameOver = newLives <= 0;

      _session = _session.copyWith(
        lives: newLives < 0 ? 0 : newLives,
        combo: 0,
        status: isGameOver ? MemoryStatus.gameOver : _session.status,
      );
      _notify();
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
