import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/game/falling_code/domain/falling_code.dart';
import 'package:mcdu_app/features/game/falling_code/domain/falling_code_session.dart';
import 'package:mcdu_app/features/game/falling_code/domain/reporting_points_catalog.dart';
import 'package:mcdu_app/features/game/falling_code/engine/falling_code_engine.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';

void main() {
  group('FallingCodeEngine Tests', () {
    test('1. Initial state conforms to requirements', () {
      final engine = FallingCodeEngine();
      final session = engine.session;

      expect(session.status, FallingCodeStatus.ready);
      expect(session.isReady, isTrue);
      expect(session.score, 0);
      expect(session.combo, 0);
      expect(session.maxCombo, 0);
      expect(session.correctCount, 0);
      expect(session.errorCount, 0);
      expect(session.missedCount, 0);
      expect(session.lives, 3);
      expect(session.level, 1);
      expect(session.elapsedTime, Duration.zero);
      expect(session.activeCodes, isEmpty);
    });

    test('2. Lifecycle: start, pause, resume, reset, game over', () {
      final engine = FallingCodeEngine();

      expect(engine.session.isReady, isTrue);

      // start
      engine.start();
      expect(engine.session.isPlaying, isTrue);

      // pause
      engine.pause();
      expect(engine.session.isPaused, isTrue);

      // resume
      engine.resume();
      expect(engine.session.isPlaying, isTrue);

      // reset
      engine.reset();
      expect(engine.session.isReady, isTrue);
      expect(engine.session.score, 0);
      expect(engine.session.activeCodes, isEmpty);
    });

    test('3. Spawn: spawned code comes from catalog, deterministic random, unique IDs', () {
      final engine = FallingCodeEngine(random: Random(42));
      engine.start();

      final code1 = engine.spawnCode(speed: 0.2);
      final code2 = engine.spawnCode(speed: 0.2);

      expect(code1.id, isNot(equals(code2.id)));
      expect(engine.session.activeCodes.length, 2);

      // Must be present in catalog
      final catalogMatch1 = ReportingPointsCatalog.findByCode(code1.code);
      final catalogMatch2 = ReportingPointsCatalog.findByCode(code2.code);
      expect(catalogMatch1, isNotNull);
      expect(catalogMatch2, isNotNull);
      expect(code1.code, catalogMatch1!.code);
      expect(code2.code, catalogMatch2!.code);
    });

    test('4. Movement: tick advances progress proportionally to delta without Flutter dependency', () {
      final engine = FallingCodeEngine();
      engine.start();

      final point = ReportingPointsCatalog.findByCode('TPAD')!;
      engine.spawnCode(
        reportingPoint: point,
        speed: 0.5, // 0.5 per second
        initialProgress: 0.0,
      );

      expect(engine.session.activeCodes.first.progress, 0.0);

      // Advance by 500ms -> progress should increase by 0.5 * 0.5s = 0.25
      engine.tick(const Duration(milliseconds: 500));
      expect(engine.session.activeCodes.first.progress, closeTo(0.25, 0.0001));
      expect(engine.session.elapsedTime, const Duration(milliseconds: 500));

      // Advance by 1s -> progress should increase by 0.5 * 1.0s = 0.50 -> 0.75
      engine.tick(const Duration(seconds: 1));
      expect(engine.session.activeCodes.first.progress, closeTo(0.75, 0.0001));
      expect(engine.session.elapsedTime, const Duration(milliseconds: 1500));
    });

    test('5. Input: correct char, wrong char, multi-character target & completion', () {
      final engine = FallingCodeEngine();
      engine.start();

      // Spawn target with known code "3WBK"
      final point = ReportingPointsCatalog.findByCode('3WBK')!;
      engine.spawnCode(
        reportingPoint: point,
        speed: 0.1,
        initialProgress: 0.2,
      );

      // Wrong key first: 'A' instead of '3'
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'A'));
      expect(engine.session.errorCount, 1);
      expect(engine.session.correctCount, 0);
      expect(engine.session.combo, 0);
      expect(engine.session.activeCodes.length, 1);
      expect(engine.session.activeCodes.first.typedLength, 0);

      // Correct key 1: '3'
      engine.handleKeyEvent(MCDUKeyEvent(keyId: '3'));
      expect(engine.session.correctCount, 1);
      expect(engine.session.errorCount, 1);
      expect(engine.session.combo, 1);
      expect(engine.session.activeCodes.first.typedLength, 1);
      expect(engine.session.activeCodes.first.typedText, '3');
      expect(engine.session.activeCodes.first.remainingText, 'WBK');
      expect(engine.session.activeCodes.first.nextChar, 'W');
      // Score for char 1: base(10) + combo(1)*2 = 12
      expect(engine.session.score, 12);

      // Correct key 2: 'W'
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'W'));
      expect(engine.session.correctCount, 2);
      expect(engine.session.combo, 2);
      expect(engine.session.activeCodes.first.typedLength, 2);
      // Score: 12 + 10 + (2*2) = 26
      expect(engine.session.score, 26);

      // Correct key 3: 'B'
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'B'));
      expect(engine.session.correctCount, 3);
      expect(engine.session.combo, 3);
      // Score: 26 + 10 + (3*2) = 42
      expect(engine.session.score, 42);

      // Correct key 4 (final): 'K'
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'K'));
      expect(engine.session.correctCount, 4);
      expect(engine.session.combo, 4);
      expect(engine.session.maxCombo, 4);
      // Score: 42 + 10 + (4*2) + 50(completion) = 110
      expect(engine.session.score, 110);

      // Target should now be completed and removed from active list
      expect(engine.session.activeCodes, isEmpty);
    });

    test('6. Multiple objects: target selection chooses object closest to bottom', () {
      final engine = FallingCodeEngine();
      engine.start();

      final p1 = ReportingPointsCatalog.findByCode('AYUYA')!; // higher up (progress 0.3)
      final p2 = ReportingPointsCatalog.findByCode('TPAD')!;  // closest to bottom (progress 0.7)

      engine.spawnCode(reportingPoint: p1, initialProgress: 0.3);
      engine.spawnCode(reportingPoint: p2, initialProgress: 0.7);

      expect(engine.session.activeCodes.length, 2);

      // Nearest target is TPAD (starts with T)
      // Pressing 'T' should hit TPAD, not AYUYA
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'T'));

      expect(engine.session.correctCount, 1);
      final tpad = engine.session.activeCodes.firstWhere((c) => c.code == 'TPAD');
      final ayuya = engine.session.activeCodes.firstWhere((c) => c.code == 'AYUYA');
      expect(tpad.typedLength, 1);
      expect(ayuya.typedLength, 0);
    });

    test('7. Miss: bottom collision decrements lives, resets combo, triggers GAME_OVER at 0 lives', () {
      final engine = FallingCodeEngine();
      engine.start();

      final point = ReportingPointsCatalog.findByCode('CRMA')!;
      engine.spawnCode(reportingPoint: point, speed: 1.0, initialProgress: 0.9);

      // Give 1 combo first
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'C'));
      expect(engine.session.combo, 1);

      // Tick 200ms -> progress 0.9 + 0.2 = 1.1 >= 1.0 (Miss)
      engine.tick(const Duration(milliseconds: 200));

      expect(engine.session.missedCount, 1);
      expect(engine.session.lives, 2);
      expect(engine.session.combo, 0);
      expect(engine.session.activeCodes, isEmpty);
      expect(engine.session.isPlaying, isTrue);

      // Miss 2 more times to trigger GAME_OVER
      engine.spawnCode(reportingPoint: point, speed: 1.0, initialProgress: 0.95);
      engine.tick(const Duration(milliseconds: 100));
      expect(engine.session.lives, 1);
      expect(engine.session.isPlaying, isTrue);

      engine.spawnCode(reportingPoint: point, speed: 1.0, initialProgress: 0.95);
      engine.tick(const Duration(milliseconds: 100));
      expect(engine.session.lives, 0);
      expect(engine.session.isGameOver, isTrue);
      expect(engine.session.status, FallingCodeStatus.gameOver);

      // No input accepted after Game Over
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'C'));
      expect(engine.session.correctCount, 1); // unchanged
    });

    test('8. Score formula and combo multipliers are deterministic and pure', () {
      final engine = FallingCodeEngine();
      engine.start();

      final point = ReportingPointsCatalog.findByCode('KFC')!; // length 3: K, F, C
      engine.spawnCode(reportingPoint: point, speed: 0.0);

      // Hit K: combo 1 -> 10 + 1*2 = 12
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'K'));
      expect(engine.session.score, 12);
      expect(engine.session.combo, 1);

      // Hit F: combo 2 -> 12 + (10 + 2*2) = 26
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'F'));
      expect(engine.session.score, 26);
      expect(engine.session.combo, 2);

      // Hit C: combo 3 -> 26 + (10 + 3*2) + 50(bonus) = 92
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'C'));
      expect(engine.session.score, 92);
      expect(engine.session.combo, 3);
      expect(engine.session.maxCombo, 3);
    });

    test('9. Paused state ignores ticks and input', () {
      final engine = FallingCodeEngine();
      engine.start();

      final point = ReportingPointsCatalog.findByCode('VTBL')!;
      engine.spawnCode(reportingPoint: point, speed: 0.5, initialProgress: 0.0);

      engine.pause();
      expect(engine.session.isPaused, isTrue);

      // Tick while paused
      engine.tick(const Duration(seconds: 1));
      expect(engine.session.activeCodes.first.progress, 0.0);
      expect(engine.session.elapsedTime, Duration.zero);

      // Input while paused
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'V'));
      expect(engine.session.correctCount, 0);
      expect(engine.session.activeCodes.first.typedLength, 0);
    });

    test('10. Custom TargetSelectionStrategy can be injected', () {
      // Strategy: pick object with smallest progress (highest on screen)
      FallingCode? pickHighest(List<FallingCode> candidates) {
        final active = candidates.where((c) => c.isActive && c.progress < 1.0).toList();
        if (active.isEmpty) return null;
        active.sort((a, b) => a.progress.compareTo(b.progress));
        return active.first;
      }

      final engine = FallingCodeEngine(targetSelector: pickHighest);
      engine.start();

      final pLow = ReportingPointsCatalog.findByCode('TPAD')!; // progress 0.8
      final pHigh = ReportingPointsCatalog.findByCode('AYUYA')!; // progress 0.1

      engine.spawnCode(reportingPoint: pLow, initialProgress: 0.8);
      engine.spawnCode(reportingPoint: pHigh, initialProgress: 0.1);

      // Input 'A' hits AYUYA (the highest one) rather than TPAD
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'A'));
      expect(engine.session.correctCount, 1);
      final ayuya = engine.session.activeCodes.firstWhere((c) => c.code == 'AYUYA');
      expect(ayuya.typedLength, 1);
    });

    group('Dynamic Difficulty Tests', () {
      test('11. Initial: level == 1, completedTargets == 0, speed == 0.10, interval == 1.80', () {
        final engine = FallingCodeEngine();
        expect(engine.session.level, 1);
        expect(engine.session.completedTargets, 0);
        expect(engine.currentFallSpeed, closeTo(0.100, 0.0001));
        expect(engine.currentSpawnInterval, closeTo(1.80, 0.0001));
      });

      test('12. Level progression thresholds: 4, 5, 9, 10, 40, 45, 50+', () {
        expect(FallingCodeEngine.calculateLevel(0), 1);
        expect(FallingCodeEngine.calculateLevel(4), 1);
        expect(FallingCodeEngine.calculateLevel(5), 2);
        expect(FallingCodeEngine.calculateLevel(9), 2);
        expect(FallingCodeEngine.calculateLevel(10), 3);
        expect(FallingCodeEngine.calculateLevel(14), 3);
        expect(FallingCodeEngine.calculateLevel(15), 4);
        expect(FallingCodeEngine.calculateLevel(19), 4);
        expect(FallingCodeEngine.calculateLevel(20), 5);
        expect(FallingCodeEngine.calculateLevel(24), 5);
        expect(FallingCodeEngine.calculateLevel(25), 6);
        expect(FallingCodeEngine.calculateLevel(29), 6);
        expect(FallingCodeEngine.calculateLevel(30), 7);
        expect(FallingCodeEngine.calculateLevel(34), 7);
        expect(FallingCodeEngine.calculateLevel(35), 8);
        expect(FallingCodeEngine.calculateLevel(39), 8);
        expect(FallingCodeEngine.calculateLevel(40), 9);
        expect(FallingCodeEngine.calculateLevel(44), 9);
        expect(FallingCodeEngine.calculateLevel(45), 10);
        expect(FallingCodeEngine.calculateLevel(50), 10);
        expect(FallingCodeEngine.calculateLevel(100), 10);
      });

      test('13. Speed table matches exact expected values for Levels 1 to 10', () {
        final expectedSpeeds = [
          0.100, // L1
          0.115, // L2
          0.130, // L3
          0.145, // L4
          0.160, // L5
          0.175, // L6
          0.190, // L7
          0.205, // L8
          0.220, // L9
          0.235, // L10
        ];

        for (int lvl = 1; lvl <= 10; lvl++) {
          final speed = FallingCodeEngine.calculateFallSpeed(lvl);
          expect(speed, closeTo(expectedSpeeds[lvl - 1], 0.0001), reason: 'Failed at Level $lvl');
        }

        // Clamped at 10
        expect(FallingCodeEngine.calculateFallSpeed(11), closeTo(0.235, 0.0001));
        expect(FallingCodeEngine.calculateFallSpeed(20), closeTo(0.235, 0.0001));
      });

      test('14. Spawn interval table matches exact expected values for Levels 1 to 10', () {
        final expectedIntervals = [
          1.80, // L1
          1.72, // L2
          1.64, // L3
          1.56, // L4
          1.48, // L5
          1.40, // L6
          1.32, // L7
          1.24, // L8
          1.16, // L9
          1.08, // L10
        ];

        for (int lvl = 1; lvl <= 10; lvl++) {
          final interval = FallingCodeEngine.calculateSpawnInterval(lvl);
          expect(interval, closeTo(expectedIntervals[lvl - 1], 0.0001), reason: 'Failed at Level $lvl');
        }

        // Level 11 is clamped to Level 10 (1.08)
        expect(FallingCodeEngine.calculateSpawnInterval(11), closeTo(1.08, 0.0001));
      });

      test('15. Completing reporting points increments completedTargets and updates level', () {
        final engine = FallingCodeEngine();
        engine.start();

        final p = ReportingPointsCatalog.findByCode('TPAD')!; // 4 letters: T-P-A-D

        // Complete 4 targets
        for (int i = 0; i < 4; i++) {
          engine.spawnCode(reportingPoint: p);
          for (final char in ['T', 'P', 'A', 'D']) {
            engine.handleKeyEvent(MCDUKeyEvent(keyId: char));
          }
          expect(engine.session.completedTargets, i + 1);
          expect(engine.session.level, 1);
        }

        // Complete 5th target -> advances to Level 2
        engine.spawnCode(reportingPoint: p);
        for (final char in ['T', 'P', 'A', 'D']) {
          engine.handleKeyEvent(MCDUKeyEvent(keyId: char));
        }
        expect(engine.session.completedTargets, 5);
        expect(engine.session.level, 2);
        expect(engine.currentFallSpeed, closeTo(0.115, 0.0001));
        expect(engine.currentSpawnInterval, closeTo(1.72, 0.0001));
      });

      test('16. Wrong keystrokes, partial typing, and missed codes do NOT advance completedTargets', () {
        final engine = FallingCodeEngine();
        engine.start();

        final p = ReportingPointsCatalog.findByCode('TPAD')!;
        engine.spawnCode(reportingPoint: p);

        // 1. Partial typing (T, P)
        engine.handleKeyEvent(MCDUKeyEvent(keyId: 'T'));
        engine.handleKeyEvent(MCDUKeyEvent(keyId: 'P'));
        expect(engine.session.completedTargets, 0);

        // 2. Wrong keystroke
        engine.handleKeyEvent(MCDUKeyEvent(keyId: 'Z'));
        expect(engine.session.completedTargets, 0);

        // 3. Missed code via tick
        engine.tick(const Duration(seconds: 15)); // reaches bottom
        expect(engine.session.missedCount, 1);
        expect(engine.session.completedTargets, 0);
        expect(engine.session.level, 1);
      });

      test('17. Reset returns level 1, completedTargets 0, and base difficulty', () {
        final engine = FallingCodeEngine();
        engine.start();

        final p = ReportingPointsCatalog.findByCode('TPAD')!;
        for (int i = 0; i < 5; i++) {
          engine.spawnCode(reportingPoint: p);
          for (final char in ['T', 'P', 'A', 'D']) {
            engine.handleKeyEvent(MCDUKeyEvent(keyId: char));
          }
        }
        expect(engine.session.level, 2);

        engine.reset();
        expect(engine.session.level, 1);
        expect(engine.session.completedTargets, 0);
        expect(engine.currentFallSpeed, closeTo(0.100, 0.0001));
        expect(engine.currentSpawnInterval, closeTo(1.80, 0.0001));
      });

      test('18. Existing active objects retain their original speed after level-up', () {
        final engine = FallingCodeEngine();
        engine.start();

        final pTpad = ReportingPointsCatalog.findByCode('TPAD')!;
        final pAyuya = ReportingPointsCatalog.findByCode('AYUYA')!;

        // Spawn first object at level 1 (speed 0.10)
        final code1 = engine.spawnCode(reportingPoint: pAyuya, speed: engine.currentFallSpeed);
        expect(code1.speed, closeTo(0.100, 0.0001));

        // Complete 5 targets of TPAD to level up to Level 2
        for (int i = 0; i < 5; i++) {
          engine.spawnCode(reportingPoint: pTpad, initialProgress: 0.5); // lower than AYUYA
          for (final char in ['T', 'P', 'A', 'D']) {
            engine.handleKeyEvent(MCDUKeyEvent(keyId: char));
          }
        }
        expect(engine.session.level, 2);

        // Verify existing code1 still has speed 0.100
        final retainedCode1 = engine.session.activeCodes.firstWhere((c) => c.id == code1.id);
        expect(retainedCode1.speed, closeTo(0.100, 0.0001));

        // Spawn new code at level 2 -> uses speed 0.115
        final code2 = engine.spawnCode(reportingPoint: pTpad, speed: engine.currentFallSpeed);
        expect(code2.speed, closeTo(0.115, 0.0001));
      });
    });
  });
}
