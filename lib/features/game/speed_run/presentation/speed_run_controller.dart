// lib/features/game/speed_run/presentation/speed_run_controller.dart
// Presentation layer Controller for Speed Run. Manages Ticker, input forwarding, and stream notifications.

import 'dart:async';
import 'package:flutter/scheduler.dart';
import '../../../mcdu_core/presentation/mcdu_keypad_overlay.dart';
import '../domain/speed_run_session.dart';
import '../engine/speed_run_engine.dart';

class SpeedRunController {
  final TickerProvider vsync;
  final SpeedRunEngine _engine;

  late final Ticker _ticker;
  Duration? _lastElapsed;

  final StreamController<SpeedRunSession> _changeNotifier =
      StreamController<SpeedRunSession>.broadcast();

  SpeedRunController({
    required this.vsync,
    SpeedRunEngine? engine,
  }) : _engine = engine ?? SpeedRunEngine() {
    _ticker = vsync.createTicker(_onTick);
  }

  SpeedRunSession get session => _engine.session;
  Stream<SpeedRunSession> get changes => _changeNotifier.stream;

  bool get isReady => _engine.session.isReady;
  bool get isPlaying => _engine.session.isPlaying;
  bool get isPaused => _engine.session.isPaused;
  bool get isCompleted => _engine.session.isCompleted;

  /// Start the Speed Run session
  void start() {
    if (isReady) {
      _engine.start();
      _lastElapsed = null;
      if (!_ticker.isActive) {
        _ticker.start();
      }
      _notify();
    }
  }

  /// Pause current session
  void pause() {
    if (isPlaying) {
      _engine.pause();
      _lastElapsed = null;
      if (_ticker.isActive) {
        _ticker.stop();
      }
      _notify();
    }
  }

  /// Resume paused session
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

  /// Reset to initial ready state
  void reset() {
    if (_ticker.isActive) {
      _ticker.stop();
    }
    _lastElapsed = null;
    _engine.reset();
    _notify();
  }

  /// Forward key event from MCDU keypad
  void handleKeyEvent(MCDUKeyEvent event) {
    if (!isPlaying) return;

    _engine.handleKey(event.keyId);

    // If task or course completed, stop ticker if finished
    if (_engine.session.isCompleted && _ticker.isActive) {
      _ticker.stop();
    }

    _notify();
  }

  void _onTick(Duration elapsed) {
    if (!isPlaying) {
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

    if (delta > Duration.zero) {
      _engine.tick(delta);
      _notify();
    }
  }

  void _notify() {
    if (!_changeNotifier.isClosed) {
      _changeNotifier.add(_engine.session);
    }
  }

  /// Clean up Ticker and StreamController
  void dispose() {
    if (_ticker.isActive) {
      _ticker.stop();
    }
    _ticker.dispose();
    _changeNotifier.close();
  }
}
