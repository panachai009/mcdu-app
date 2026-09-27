// test/memory_engine_test.dart

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/game/memory/domain/memory_sequence.dart';
import 'package:mcdu_app/features/game/memory/domain/memory_session.dart';
import 'package:mcdu_app/features/game/memory/engine/memory_engine.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';

void main() {
  group('MemoryEngine Unit Tests', () {
    // 1. Initial State
    test('1. Initial state conforms to requirements', () {
      final engine = MemoryEngine();
      final session = engine.session;

      expect(session.status, MemoryStatus.ready);
      expect(session.isReady, isTrue);
      expect(session.level, 1);
      expect(session.targetSequence, '');
      expect(session.inputBuffer, '');
      expect(session.lives, 3);
      expect(session.score, 0);
      expect(session.combo, 0);
      expect(session.completedRounds, 0);
      expect(session.elapsedTime, Duration.zero);
    });

    // 2. MemorySequence domain model helpers
    test('2. MemorySequence helpers: characterAt, isComplete, matchesInput', () {
      const seq = MemorySequence(value: 'VTBS', level: 1);

      expect(seq.length, 4);
      expect(seq.characterAt(0), 'V');
      expect(seq.characterAt(3), 'S');
      expect(seq.characterAt(4), isNull);
      expect(seq.characterAt(-1), isNull);

      expect(seq.matchesInput('V'), isTrue);
      expect(seq.matchesInput('VT'), isTrue);
      expect(seq.matchesInput('VTBS'), isTrue);
      expect(seq.matchesInput('VTBA'), isFalse);
      expect(seq.matchesInput('VTBSX'), isFalse);

      expect(seq.isComplete('VTBS'), isTrue);
      expect(seq.isComplete('VTB'), isFalse);
    });

    // 3. Sequence Length per Level
    test('3. Sequence length per level conforms to difficulty specs and capped at 8', () {
      expect(MemoryEngine.sequenceLengthForLevel(1), 3);
      expect(MemoryEngine.sequenceLengthForLevel(2), 3);
      expect(MemoryEngine.sequenceLengthForLevel(3), 4);
      expect(MemoryEngine.sequenceLengthForLevel(4), 4);
      expect(MemoryEngine.sequenceLengthForLevel(5), 5);
      expect(MemoryEngine.sequenceLengthForLevel(6), 5);
      expect(MemoryEngine.sequenceLengthForLevel(7), 6);
      expect(MemoryEngine.sequenceLengthForLevel(8), 6);
      expect(MemoryEngine.sequenceLengthForLevel(9), 7);
      expect(MemoryEngine.sequenceLengthForLevel(10), 8);

      // Clamped beyond 10
      expect(MemoryEngine.sequenceLengthForLevel(11), 8);
      expect(MemoryEngine.sequenceLengthForLevel(20), 8);
    });

    // 4. Deterministic Sequence Generation
    test('4. Sequence generation is deterministic with Random seed and uses A-Z 0-9', () {
      final engine1 = MemoryEngine(random: Random(42));
      final engine2 = MemoryEngine(random: Random(42));

      final seq1 = engine1.generateSequence(level: 1);
      final seq2 = engine2.generateSequence(level: 1);

      expect(seq1.value, seq2.value);
      expect(seq1.length, 3);

      final validPattern = RegExp(r'^[A-Z0-9]+$');
      expect(validPattern.hasMatch(seq1.value), isTrue);
    });

    // 5. Lifecycle: start -> memorizing, beginRecall -> recalling
    test('5. Lifecycle: start sets memorizing, beginRecall sets recalling', () {
      final engine = MemoryEngine(random: Random(100));

      engine.start();
      expect(engine.session.status, MemoryStatus.memorizing);
      expect(engine.session.targetSequence.length, 3);
      expect(engine.session.inputBuffer, '');

      engine.beginRecall();
      expect(engine.session.status, MemoryStatus.recalling);
      expect(engine.session.inputBuffer, '');
    });

    // 6. Input during MEMORIZING is ignored
    test('6. Input during MEMORIZING is ignored', () {
      final engine = MemoryEngine(random: Random(100));
      engine.start();

      expect(engine.session.isMemorizing, isTrue);
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'A'));

      expect(engine.session.inputBuffer, '');
      expect(engine.session.lives, 3);
    });

    // 7. Input during RECALLING: correct prefix appends to buffer
    test('7. Input during RECALLING: correct prefix appends to buffer', () {
      final engine = MemoryEngine(random: Random(100));
      engine.start();
      final target = engine.session.targetSequence;
      engine.beginRecall();

      final firstChar = target[0];
      engine.handleKeyEvent(MCDUKeyEvent(keyId: firstChar));

      expect(engine.session.inputBuffer, firstChar);
      expect(engine.session.lives, 3);
    });

    // 8. Input during RECALLING: wrong key decrements lives and resets combo
    test('8. Input during RECALLING: wrong key decrements lives and resets combo', () {
      final engine = MemoryEngine(random: Random(100));
      engine.start();
      final target = engine.session.targetSequence;
      engine.beginRecall();

      // Find an incorrect character
      final wrongChar = target[0] == 'A' ? 'B' : 'A';
      engine.handleKeyEvent(MCDUKeyEvent(keyId: wrongChar));

      expect(engine.session.lives, 2);
      expect(engine.session.combo, 0);
      expect(engine.session.completedRounds, 0);
      expect(engine.session.level, 1);
    });

    // 9. Lives reach 0 -> gameOver, and subsequent input is ignored
    test('9. Lives reach 0 -> gameOver and subsequent input is ignored', () {
      final engine = MemoryEngine(random: Random(100));
      engine.start();
      final target = engine.session.targetSequence;
      engine.beginRecall();

      final wrongChar = target[0] == 'A' ? 'B' : 'A';

      // 3 wrong inputs -> 0 lives
      engine.handleKeyEvent(MCDUKeyEvent(keyId: wrongChar));
      expect(engine.session.lives, 2);
      engine.handleKeyEvent(MCDUKeyEvent(keyId: wrongChar));
      expect(engine.session.lives, 1);
      engine.handleKeyEvent(MCDUKeyEvent(keyId: wrongChar));
      expect(engine.session.lives, 0);
      expect(engine.session.status, MemoryStatus.gameOver);
      expect(engine.session.isGameOver, isTrue);

      // Input after game over is ignored
      engine.handleKeyEvent(MCDUKeyEvent(keyId: target[0]));
      expect(engine.session.inputBuffer, '');
      expect(engine.session.lives, 0);
    });

    // 10. Completing sequence increases completedRounds, combo, score, and prepares next sequence
    test('10. Completing sequence increases completedRounds, combo, score, and generates next sequence', () {
      final engine = MemoryEngine(random: Random(100));
      engine.start();
      final target1 = engine.session.targetSequence;
      engine.beginRecall();

      // Type full target sequence
      for (int i = 0; i < target1.length; i++) {
        engine.handleKeyEvent(MCDUKeyEvent(keyId: target1[i]));
      }

      // Round 1 completed:
      // base score = 3 * 100 = 300
      // combo bonus = 1 * 25 = 25
      // total score = 325
      expect(engine.session.completedRounds, 1);
      expect(engine.session.combo, 1);
      expect(engine.session.score, 325);
      expect(engine.session.status, MemoryStatus.memorizing); // Prepares next round
      expect(engine.session.inputBuffer, '');
      expect(engine.session.targetSequence.length, 3); // Level 1 still 3 chars
    });

    // 11. Level Progression Formula: every 5 completed rounds advances level
    test('11. Level progression formula: min(10, 1 + (completedRounds ~/ 5))', () {
      expect(MemoryEngine.calculateLevel(0), 1);
      expect(MemoryEngine.calculateLevel(4), 1);
      expect(MemoryEngine.calculateLevel(5), 2);
      expect(MemoryEngine.calculateLevel(9), 2);
      expect(MemoryEngine.calculateLevel(10), 3);
      expect(MemoryEngine.calculateLevel(14), 3);
      expect(MemoryEngine.calculateLevel(15), 4);
      expect(MemoryEngine.calculateLevel(19), 4);
      expect(MemoryEngine.calculateLevel(20), 5);
      expect(MemoryEngine.calculateLevel(24), 5);
      expect(MemoryEngine.calculateLevel(25), 6);
      expect(MemoryEngine.calculateLevel(29), 6);
      expect(MemoryEngine.calculateLevel(30), 7);
      expect(MemoryEngine.calculateLevel(34), 7);
      expect(MemoryEngine.calculateLevel(35), 8);
      expect(MemoryEngine.calculateLevel(39), 8);
      expect(MemoryEngine.calculateLevel(40), 9);
      expect(MemoryEngine.calculateLevel(44), 9);
      expect(MemoryEngine.calculateLevel(45), 10);
      expect(MemoryEngine.calculateLevel(50), 10);
      expect(MemoryEngine.calculateLevel(100), 10);
    });

    // 12. Actual gameplay level up after 5 completed rounds
    test('12. Actual gameplay advances from Level 1 to Level 2 after 5 rounds', () {
      final engine = MemoryEngine(random: Random(500));
      engine.start();

      for (int round = 0; round < 5; round++) {
        expect(engine.session.level, 1);
        engine.beginRecall();
        final target = engine.session.targetSequence;
        for (int i = 0; i < target.length; i++) {
          engine.handleKeyEvent(MCDUKeyEvent(keyId: target[i]));
        }
      }

      // After 5 completed rounds -> Level 2
      expect(engine.session.completedRounds, 5);
      expect(engine.session.level, 2);
      expect(engine.session.combo, 5);
      expect(engine.session.targetSequence.length, 3); // Level 2 length is still 3
    });

    // 13. Pause and Resume preserves exact state
    test('13. Pause and resume preserves exact state', () {
      final engine = MemoryEngine(random: Random(500));
      engine.start();
      engine.beginRecall();

      final target = engine.session.targetSequence;
      engine.handleKeyEvent(MCDUKeyEvent(keyId: target[0])); // type 1st char

      engine.pause();
      expect(engine.session.isPaused, isTrue);

      // Input during pause is ignored
      engine.handleKeyEvent(MCDUKeyEvent(keyId: target[1]));
      expect(engine.session.inputBuffer, target[0]);

      // Tick during pause is ignored
      engine.tick(const Duration(seconds: 5));
      expect(engine.session.elapsedTime, Duration.zero);

      engine.resume();
      expect(engine.session.isRecalling, isTrue);
      expect(engine.session.inputBuffer, target[0]);
      expect(engine.session.targetSequence, target);
    });

    // 14. Reset restores initial state cleanly
    test('14. Reset restores initial state cleanly', () {
      final engine = MemoryEngine(random: Random(500));
      engine.start();
      engine.beginRecall();
      final target = engine.session.targetSequence;
      for (int i = 0; i < target.length; i++) {
        engine.handleKeyEvent(MCDUKeyEvent(keyId: target[i]));
      }
      expect(engine.session.completedRounds, 1);

      engine.reset();
      final session = engine.session;
      expect(session.status, MemoryStatus.ready);
      expect(session.level, 1);
      expect(session.targetSequence, '');
      expect(session.inputBuffer, '');
      expect(session.lives, 3);
      expect(session.score, 0);
      expect(session.combo, 0);
      expect(session.completedRounds, 0);
      expect(session.elapsedTime, Duration.zero);
    });

    // 15. Stream emits state updates on lifecycle and inputs
    test('15. Session stream emits on changes and disposes cleanly', () async {
      final engine = MemoryEngine(random: Random(100));
      final emitted = <MemoryStatus>[];

      final sub = engine.sessionStream.listen((s) {
        emitted.add(s.status);
      });

      engine.start();
      engine.beginRecall();
      engine.pause();
      engine.resume();
      engine.reset();

      await pumpEventQueue();

      expect(emitted, [
        MemoryStatus.memorizing,
        MemoryStatus.recalling,
        MemoryStatus.paused,
        MemoryStatus.recalling,
        MemoryStatus.ready,
      ]);

      await sub.cancel();
      engine.dispose();
    });
  });
}
