import 'dart:async';
import 'dart:math';
import 'package:flutter/scheduler.dart';
import '../../../mcdu_core/presentation/mcdu_keypad_overlay.dart';
import '../domain/falling_code.dart';
import '../domain/falling_code_session.dart';
import '../engine/falling_code_engine.dart';

enum CountdownState {
  ready,
  count3,
  count2,
  count1,
  go,
  finished,
}

class FallingCodeController {
  final TickerProvider vsync;
  final FallingCodeEngine _engine;
  final Random _random;

  late final Ticker _ticker;
  Duration? _lastElapsed;

  CountdownState _countdownState = CountdownState.ready;
  Timer? _countdownTimer;

  // Presentation spawner tracking
  double _spawnTimerSec = 0.0;
  final double? _customSpawnIntervalSec;
  final double? _customFallSpeed;
  final int _maxActiveObjects;

  // Track lanes for active falling codes (1 to 4)
  final Map<String, int> _codeLanes = {};

  final StreamController<void> _changeNotifier = StreamController<void>.broadcast();

  FallingCodeController({
    required this.vsync,
    FallingCodeEngine? engine,
    Random? random,
    double? spawnIntervalSec,
    double? fallSpeed,
    int maxActiveObjects = 3,
  })  : _engine = engine ?? FallingCodeEngine(random: random),
        _random = random ?? Random(),
        _customSpawnIntervalSec = spawnIntervalSec,
        _customFallSpeed = fallSpeed,
        // ignore: prefer_initializing_formals
        _maxActiveObjects = maxActiveObjects {
    _ticker = vsync.createTicker(_onTick);
  }

  FallingCodeSession get session => _engine.session;
  CountdownState get countdownState => _countdownState;
  Stream<void> get changes => _changeNotifier.stream;

  bool get isReady => _countdownState == CountdownState.ready;
  bool get isCountingDown =>
      _countdownState != CountdownState.ready && _countdownState != CountdownState.finished;
  bool get isPlaying =>
      _countdownState == CountdownState.finished && _engine.session.isPlaying;
  bool get isPaused =>
      _countdownState == CountdownState.finished && _engine.session.isPaused;
  bool get isGameOver =>
      _countdownState == CountdownState.finished && _engine.session.isGameOver;

  int getLaneFor(FallingCode code) {
    return _codeLanes.putIfAbsent(code.id, () => (_random.nextInt(4) + 1));
  }

  double get currentSpawnInterval => _customSpawnIntervalSec ?? _engine.currentSpawnInterval;
  double get currentFallSpeed => _customFallSpeed ?? _engine.currentFallSpeed;

  /// Start the countdown sequence: READY -> 3 -> 2 -> 1 -> GO -> PLAYING
  void startCountdown() {
    if (_countdownState != CountdownState.ready) return;

    _countdownState = CountdownState.count3;
    _notify();

    _countdownTimer?.cancel();
    int currentStep = 3;

    _countdownTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      currentStep--;
      if (currentStep == 2) {
        _countdownState = CountdownState.count2;
        _notify();
      } else if (currentStep == 1) {
        _countdownState = CountdownState.count1;
        _notify();
      } else if (currentStep == 0) {
        _countdownState = CountdownState.go;
        _notify();
      } else {
        timer.cancel();
        _countdownTimer = null;
        _countdownState = CountdownState.finished;

        _engine.start();
        _lastElapsed = null;
        _spawnTimerSec = currentSpawnInterval; // Trigger immediate first spawn
        _ticker.start();
        _notify();
      }
    });
  }

  /// Pause game
  void pause() {
    if (isPlaying) {
      _ticker.stop();
      _lastElapsed = null;
      _engine.pause();
      _notify();
    }
  }

  /// Resume game
  void resume() {
    if (isPaused) {
      _engine.resume();
      _lastElapsed = null;
      _ticker.start();
      _notify();
    }
  }

  /// Retry / Reset
  void retry() {
    _ticker.stop();
    _lastElapsed = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;

    _engine.reset();
    _codeLanes.clear();
    _spawnTimerSec = 0.0;
    _countdownState = CountdownState.ready;
    _notify();

    startCountdown();
  }

  /// Abort and stop everything
  void abort() {
    _ticker.stop();
    _lastElapsed = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _notify();
  }

  /// Handle incoming MCDU physical key event
  void handleKeyEvent(MCDUKeyEvent event) {
    // Only accept A-Z / 0-9 gameplay keys when PLAYING (after GO)
    if (!isPlaying) return;

    final key = event.keyId.trim().toUpperCase();
    final isAlphanumeric = RegExp(r'^[A-Z0-9]$').hasMatch(key);

    if (isAlphanumeric) {
      _engine.handleKeyEvent(event);
      _cleanupMissingLanes();
      _notify();
    }
  }

  void _onTick(Duration elapsed) {
    if (!isPlaying) return;

    if (_lastElapsed == null) {
      _lastElapsed = elapsed;
      return;
    }

    Duration delta = elapsed - _lastElapsed!;
    _lastElapsed = elapsed;

    // Guard against negative delta or large frame spikes (e.g. backgrounding)
    if (delta.isNegative) delta = Duration.zero;
    if (delta > const Duration(milliseconds: 100)) {
      delta = const Duration(milliseconds: 100);
    }

    final deltaSeconds = delta.inMicroseconds / 1000000.0;

    // Spawner logic
    final currentInterval = currentSpawnInterval;
    if (_spawnTimerSec > currentInterval) {
      _spawnTimerSec = currentInterval;
    }

    if (_engine.session.activeCodes.length < _maxActiveObjects) {
      _spawnTimerSec += deltaSeconds;
      if (_spawnTimerSec >= currentInterval) {
        _spawnTimerSec = 0.0;
        final newCode = _engine.spawnCode(speed: currentFallSpeed);
        _codeLanes[newCode.id] = _random.nextInt(4) + 1;
      }
    }

    // Advance physics
    _engine.tick(delta);
    _cleanupMissingLanes();

    if (_engine.session.isGameOver) {
      _ticker.stop();
    }

    _notify();
  }

  void _cleanupMissingLanes() {
    final activeIds = _engine.session.activeCodes.map((c) => c.id).toSet();
    _codeLanes.removeWhere((id, _) => !activeIds.contains(id));
  }

  void _notify() {
    if (!_changeNotifier.isClosed) {
      _changeNotifier.add(null);
    }
  }

  void dispose() {
    _ticker.stop();
    _ticker.dispose();
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _changeNotifier.close();
    _engine.dispose();
  }
}
