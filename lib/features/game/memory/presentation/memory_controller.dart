// lib/features/game/memory/presentation/memory_controller.dart

import 'dart:async';
import 'package:flutter/scheduler.dart';
import '../../../mcdu_core/presentation/mcdu_keypad_overlay.dart';
import '../domain/memory_session.dart';
import '../engine/memory_engine.dart';

class MemoryController {
  final TickerProvider vsync;
  final MemoryEngine _engine;

  late final Ticker _ticker;
  Duration? _lastElapsed;

  Duration _presentationElapsed = Duration.zero;
  String _currentMemorizingTarget = '';

  final StreamController<void> _changeNotifier = StreamController<void>.broadcast();

  MemoryController({
    required this.vsync,
    MemoryEngine? engine,
  }) : _engine = engine ?? MemoryEngine() {
    _ticker = vsync.createTicker(_onTick);
  }

  MemorySession get session => _engine.session;
  Stream<void> get changes => _changeNotifier.stream;

  bool get isReady => _engine.session.isReady;
  bool get isMemorizing => _engine.session.isMemorizing;
  bool get isRecalling => _engine.session.isRecalling;
  bool get isPaused => _engine.session.isPaused;
  bool get isGameOver => _engine.session.isGameOver;
  bool get isCompleted => _engine.session.isCompleted;

  Duration get presentationElapsed => _presentationElapsed;

  /// Exact deterministic presentation duration table per level
  static Duration presentationDurationForLevel(int level) {
    final clamped = level > 10 ? 10 : (level < 1 ? 1 : level);
    switch (clamped) {
      case 1:
        return const Duration(milliseconds: 3500);
      case 2:
        return const Duration(milliseconds: 3280);
      case 3:
        return const Duration(milliseconds: 3060);
      case 4:
        return const Duration(milliseconds: 2830);
      case 5:
        return const Duration(milliseconds: 2610);
      case 6:
        return const Duration(milliseconds: 2390);
      case 7:
        return const Duration(milliseconds: 2170);
      case 8:
        return const Duration(milliseconds: 1940);
      case 9:
        return const Duration(milliseconds: 1720);
      case 10:
      default:
        return const Duration(milliseconds: 1500);
    }
  }

  Duration get presentationDuration => presentationDurationForLevel(_engine.session.level);

  double get presentationProgress {
    final total = presentationDuration.inMicroseconds;
    if (total <= 0) return 1.0;
    return (_presentationElapsed.inMicroseconds / total).clamp(0.0, 1.0);
  }

  /// Start the game
  void start() {
    if (isReady) {
      _engine.start();
      _presentationElapsed = Duration.zero;
      _currentMemorizingTarget = _engine.session.targetSequence;
      _lastElapsed = null;
      if (!_ticker.isActive) {
        _ticker.start();
      }
      _notify();
    }
  }

  /// Pause the game
  void pause() {
    if (isMemorizing || isRecalling) {
      _ticker.stop();
      _lastElapsed = null;
      _engine.pause();
      _notify();
    }
  }

  /// Resume the game
  void resume() {
    if (isPaused) {
      _engine.resume();
      _lastElapsed = null;
      if (!_ticker.isActive) {
        _ticker.start();
      }
      _notify();
    }
  }

  /// Reset the game
  void reset() {
    _ticker.stop();
    _lastElapsed = null;
    _presentationElapsed = Duration.zero;
    _currentMemorizingTarget = '';
    _engine.reset();
    _notify();
  }

  /// Handle incoming physical MCDU key event
  void handleKeyEvent(MCDUKeyEvent event) {
    if (!isRecalling) return;

    final key = event.keyId.trim().toUpperCase();
    final isAlphanumeric = RegExp(r'^[A-Z0-9]$').hasMatch(key);
    if (!isAlphanumeric) return;

    _engine.handleKeyEvent(event);

    // If typing the final character advanced the session to memorizing (new round)
    if (_engine.session.isMemorizing &&
        _engine.session.targetSequence != _currentMemorizingTarget) {
      _presentationElapsed = Duration.zero;
      _currentMemorizingTarget = _engine.session.targetSequence;
    }

    if (_engine.session.isGameOver) {
      _ticker.stop();
    }

    _notify();
  }

  void _onTick(Duration elapsed) {
    if (_engine.session.isPaused || _engine.session.isGameOver || _engine.session.isCompleted) {
      if (_ticker.isActive) _ticker.stop();
      return;
    }

    if (_lastElapsed == null) {
      _lastElapsed = elapsed;
      return;
    }

    Duration delta = elapsed - _lastElapsed!;
    _lastElapsed = elapsed;

    if (delta.isNegative) delta = Duration.zero;
    if (delta > const Duration(milliseconds: 100)) {
      delta = const Duration(milliseconds: 100);
    }

    // Forward elapsed time to pure engine
    _engine.tick(delta);

    // Manage presentation duration while in memorizing state
    if (_engine.session.isMemorizing) {
      _presentationElapsed += delta;
      if (_presentationElapsed >= presentationDuration) {
        _presentationElapsed = presentationDuration;
        _engine.beginRecall();
      }
    }

    _notify();
  }

  void _notify() {
    if (!_changeNotifier.isClosed) {
      _changeNotifier.add(null);
    }
  }

  void dispose() {
    _ticker.stop();
    _ticker.dispose();
    _changeNotifier.close();
    _engine.dispose();
  }
}
