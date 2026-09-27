import 'dart:async';
import 'dart:math';

import '../../../mcdu_core/presentation/mcdu_keypad_overlay.dart';
import '../domain/falling_code.dart';
import '../domain/falling_code_session.dart';
import '../domain/reporting_point.dart';
import '../domain/reporting_points_catalog.dart';

typedef TargetSelectionStrategy = FallingCode? Function(List<FallingCode> candidates);

class FallingCodeEngine {
  FallingCodeSession _session;
  final Random _random;
  final TargetSelectionStrategy targetSelector;

  final StreamController<FallingCodeSession> _sessionController =
      StreamController<FallingCodeSession>.broadcast();

  int _nextId = 1;

  FallingCodeEngine({
    FallingCodeSession? session,
    Random? random,
    TargetSelectionStrategy? targetSelector,
  })  : _session = session ?? const FallingCodeSession(),
        _random = random ?? Random(),
        targetSelector = targetSelector ?? defaultTargetSelector;

  FallingCodeSession get session => _session;
  Stream<FallingCodeSession> get sessionStream => _sessionController.stream;

  /// Pure difficulty formula: level = min(10, 1 + floor(completedTargets / 5))
  static int calculateLevel(int completedTargets) {
    final lvl = 1 + (completedTargets ~/ 5);
    return lvl > 10 ? 10 : (lvl < 1 ? 1 : lvl);
  }

  /// Pure difficulty formula: fallSpeed(level) = min(0.235, 0.10 + ((level - 1) * 0.015))
  static double calculateFallSpeed(int level) {
    final clampedLevel = level > 10 ? 10 : (level < 1 ? 1 : level);
    final speed = 0.10 + ((clampedLevel - 1) * 0.015);
    return speed > 0.235 ? 0.235 : speed;
  }

  /// Pure difficulty formula: spawnInterval(level) = max(1.00, 1.80 - ((level - 1) * 0.08))
  static double calculateSpawnInterval(int level) {
    final clampedLevel = level > 10 ? 10 : (level < 1 ? 1 : level);
    final interval = 1.80 - ((clampedLevel - 1) * 0.08);
    return interval < 1.00 ? 1.00 : interval;
  }

  /// Current fall speed for newly spawned objects according to current level
  double get currentFallSpeed => calculateFallSpeed(_session.level);

  /// Current spawn interval according to current level
  double get currentSpawnInterval => calculateSpawnInterval(_session.level);

  /// Default Target Selection Rule (MVP):
  /// Object closest to the bottom (greatest progress) among active objects with progress < 1.0.
  static FallingCode? defaultTargetSelector(List<FallingCode> candidates) {
    final active = candidates.where((c) => c.isActive && c.progress < 1.0).toList();
    if (active.isEmpty) return null;
    active.sort((a, b) => b.progress.compareTo(a.progress));
    return active.first;
  }

  /// Start the game: READY -> PLAYING
  void start() {
    if (_session.isReady) {
      _session = _session.copyWith(status: FallingCodeStatus.playing);
      _notify();
    }
  }

  /// Pause the game: PLAYING -> PAUSED
  void pause() {
    if (_session.isPlaying) {
      _session = _session.copyWith(status: FallingCodeStatus.paused);
      _notify();
    }
  }

  /// Resume the game: PAUSED -> PLAYING
  void resume() {
    if (_session.isPaused) {
      _session = _session.copyWith(status: FallingCodeStatus.playing);
      _notify();
    }
  }

  /// Reset the game: return to clean initial READY state
  void reset() {
    _nextId = 1;
    _session = _session.reset();
    _notify();
  }

  /// Spawns a new FallingCode object.
  /// If [reportingPoint] is omitted, picks one from [ReportingPointsCatalog.all]
  /// using the provided [Random] instance.
  FallingCode spawnCode({
    ReportingPoint? reportingPoint,
    double speed = 0.1,
    double initialProgress = 0.0,
  }) {
    final point = reportingPoint ?? _pickRandomReportingPoint();
    final newCode = FallingCode(
      id: 'fc_${_nextId++}',
      code: point.code,
      reportingPoint: point,
      progress: initialProgress,
      speed: speed,
      state: FallingCodeState.active,
      typedLength: 0,
    );

    final updatedList = List<FallingCode>.from(_session.activeCodes)..add(newCode);
    _session = _session.copyWith(activeCodes: updatedList);
    _notify();
    return newCode;
  }

  ReportingPoint _pickRandomReportingPoint() {
    final catalog = ReportingPointsCatalog.all;
    if (_session.activeCodes.isEmpty) {
      return catalog[_random.nextInt(catalog.length)];
    }

    // Try to avoid immediately duplicating already active codes on screen
    final activeCodes = _session.activeCodes.map((c) => c.code).toSet();
    final available = catalog.where((p) => !activeCodes.contains(p.code)).toList();
    if (available.isNotEmpty) {
      return available[_random.nextInt(available.length)];
    }
    return catalog[_random.nextInt(catalog.length)];
  }

  /// Advance falling objects by [delta].
  /// Progress += speed * (delta in seconds).
  /// If progress >= 1.0, object MISSES:
  /// - missedCount + 1
  /// - lives - 1
  /// - combo = 0
  /// - target removed
  /// If lives <= 0 -> GAME_OVER
  void tick(Duration delta) {
    if (!_session.isPlaying) return;

    final seconds = delta.inMicroseconds / 1000000.0;
    final updatedActive = <FallingCode>[];
    int missedDelta = 0;
    int lives = _session.lives;
    int combo = _session.combo;

    for (final code in _session.activeCodes) {
      if (!code.isActive) continue;

      final newProgress = code.progress + (code.speed * seconds);
      if (newProgress >= 1.0) {
        // Bottom collision / Miss
        missedDelta++;
        lives--;
        combo = 0;
      } else {
        updatedActive.add(code.copyWith(progress: newProgress));
      }
    }

    final isGameOver = lives <= 0;
    final newStatus = isGameOver ? FallingCodeStatus.gameOver : _session.status;

    _session = _session.copyWith(
      status: newStatus,
      activeCodes: updatedActive,
      elapsedTime: _session.elapsedTime + delta,
      missedCount: _session.missedCount + missedDelta,
      lives: lives < 0 ? 0 : lives,
      combo: combo,
    );
    _notify();
  }

  /// Process an MCDU key event.
  /// Selects the active target using [targetSelector] (nearest bottom).
  /// If correct character:
  /// - typedLength + 1
  /// - correctCount + 1
  /// - combo + 1
  /// - score += 10 + (combo * 2)
  /// - If full word completed:
  ///   - score += 50 (completion bonus)
  ///   - remove target from active list
  /// If wrong character:
  /// - errorCount + 1
  /// - combo = 0
  /// - target remains active
  void handleKeyEvent(MCDUKeyEvent event) {
    if (!_session.isPlaying) return;

    final target = targetSelector(_session.activeCodes);
    if (target == null) return;

    final expectedChar = target.nextChar;
    if (expectedChar == null) return;

    final pressedKey = event.keyId.toUpperCase().trim();

    if (pressedKey == expectedChar) {
      // Correct character
      final newTypedLength = target.typedLength + 1;
      final newCombo = _session.combo + 1;
      final newMaxCombo = max(_session.maxCombo, newCombo);

      // Score formula:
      // Base per char = 10
      // Combo bonus = combo * 2
      final charScore = 10 + (newCombo * 2);
      var totalScoreGain = charScore;

      final isCompleted = newTypedLength == target.code.length;
      final updatedList = List<FallingCode>.from(_session.activeCodes);
      final index = updatedList.indexWhere((c) => c.id == target.id);

      var newCompletedTargets = _session.completedTargets;
      var newLevel = _session.level;

      if (isCompleted) {
        // Target fully typed: +50 completion bonus, remove from active
        totalScoreGain += 50;
        newCompletedTargets++;
        newLevel = calculateLevel(newCompletedTargets);
        if (index != -1) {
          updatedList.removeAt(index);
        }
      } else {
        // Advance target typing progress
        if (index != -1) {
          updatedList[index] = target.copyWith(typedLength: newTypedLength);
        }
      }

      _session = _session.copyWith(
        score: _session.score + totalScoreGain,
        combo: newCombo,
        maxCombo: newMaxCombo,
        correctCount: _session.correctCount + 1,
        completedTargets: newCompletedTargets,
        level: newLevel,
        activeCodes: updatedList,
      );
      _notify();
    } else {
      // Incorrect character
      _session = _session.copyWith(
        errorCount: _session.errorCount + 1,
        combo: 0,
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
