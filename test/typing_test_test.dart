// test/typing_test_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/mcdu_core/domain/mcdu_key.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';
import 'package:mcdu_app/features/game/domain/game_state.dart';
import 'package:mcdu_app/features/game/typing_test/domain/typing_test_prompt.dart';
import 'package:mcdu_app/features/game/typing_test/domain/typing_test_prompts.dart';
import 'package:mcdu_app/features/game/typing_test/domain/typing_test_session.dart';
import 'package:mcdu_app/features/game/typing_test/engine/typing_test_engine.dart';

void main() {
  group('Phase 13 & 14B Typing Test Unit Tests', () {
    // 1. Prompt creation
    test('1. Prompt creation works with valid fields', () {
      const prompt = TypingTestPrompt(
        promptId: 'test_p',
        targetText: 'ABC',
      );
      expect(prompt.promptId, 'test_p');
      expect(prompt.targetText, 'ABC');
    });

    // 2. Prompt equality
    test('2. Prompt equality works for value objects', () {
      const p1 = TypingTestPrompt(promptId: 'abc', targetText: 'ABC');
      const p2 = TypingTestPrompt(promptId: 'abc', targetText: 'ABC');
      const p3 = TypingTestPrompt(promptId: 'other', targetText: 'XYZ');

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
    });

    // 3. Prompt catalog contains exactly 5 prompts
    test('3. Prompt catalog contains exactly 5 prompts', () {
      expect(TypingTestPrompts.all.length, 5);
      final ids = TypingTestPrompts.all.map((p) => p.promptId).toSet();
      expect(ids, containsAll(['abc123', 'mod1l', 'fpl', 'dir', 'nav']));
    });

    // 4. findById works
    test('4. findById works for all 5 catalog prompts', () {
      expect(TypingTestPrompts.findById('abc123'), equals(TypingTestPrompts.abc123));
      expect(TypingTestPrompts.findById('mod1l'), equals(TypingTestPrompts.mod1l));
      expect(TypingTestPrompts.findById('fpl'), equals(TypingTestPrompts.fpl));
      expect(TypingTestPrompts.findById('dir'), equals(TypingTestPrompts.dir));
      expect(TypingTestPrompts.findById('nav'), equals(TypingTestPrompts.nav));
    });

    // 5. unknown prompt returns null
    test('5. unknown prompt returns null in findById', () {
      expect(TypingTestPrompts.findById('unknown_xyz'), isNull);
      expect(TypingTestPrompts.findById(''), isNull);
    });

    // 6. Initial session is idle, elapsedTime=0, accuracy=0, score=0
    test('6. Initial session is idle with zero elapsedTime, accuracy, score', () {
      final engine = TypingTestEngine(prompt: TypingTestPrompts.abc123);
      expect(engine.session.state, GameState.idle);
      expect(engine.session.isIdle, isTrue);
      expect(engine.session.isPlaying, isFalse);
      expect(engine.session.isCompleted, isFalse);
      expect(engine.session.elapsedTime, Duration.zero);
      expect(engine.session.accuracy, 0.0);
      expect(engine.session.score, 0);
      engine.dispose();
    });

    // 7. start() changes idle -> playing
    test('7. start() changes idle -> playing', () {
      final engine = TypingTestEngine(prompt: TypingTestPrompts.abc123);
      engine.start();

      expect(engine.session.state, GameState.playing);
      expect(engine.session.isPlaying, isTrue);
      expect(engine.session.isIdle, isFalse);
      expect(engine.session.isCompleted, isFalse);
      engine.dispose();
    });

    // 8. typedText starts empty
    test('8. typedText starts empty', () {
      final engine = TypingTestEngine(prompt: TypingTestPrompts.abc123);
      expect(engine.session.typedText, '');
      engine.start();
      expect(engine.session.typedText, '');
      engine.dispose();
    });

    // 9. correct key advances progress
    test('9. correct key advances progress', () {
      final engine = TypingTestEngine(prompt: TypingTestPrompts.abc123);
      engine.start();

      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'A'));
      expect(engine.session.typedText, 'A');
      expect(engine.session.progress, closeTo(1 / 6, 0.001));
      expect(engine.session.remainingText, 'BC123');
      engine.dispose();
    });

    // 10. wrong key increments errorCount
    test('10. wrong key increments errorCount', () {
      final engine = TypingTestEngine(prompt: TypingTestPrompts.abc123);
      engine.start();

      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'Z'));
      expect(engine.session.errorCount, 1);
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'X'));
      expect(engine.session.errorCount, 2);
      engine.dispose();
    });

    // 11. wrong key does not change typedText
    test('11. wrong key does not change typedText', () {
      final engine = TypingTestEngine(prompt: TypingTestPrompts.abc123);
      engine.start();

      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'A'));
      expect(engine.session.typedText, 'A');

      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'Z'));
      expect(engine.session.typedText, 'A');
      expect(engine.session.remainingText, 'BC123');
      engine.dispose();
    });

    // 12. correctCount increments correctly
    test('12. correctCount increments correctly', () {
      final engine = TypingTestEngine(prompt: TypingTestPrompts.abc123);
      engine.start();

      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'A'));
      expect(engine.session.correctCount, 1);
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'B'));
      expect(engine.session.correctCount, 2);
      engine.dispose();
    });

    // 13. ABC123 completes correctly
    test('13. ABC123 completes correctly', () {
      final engine = TypingTestEngine(prompt: TypingTestPrompts.abc123);
      engine.start();

      final keys = ['A', 'B', 'C', '1', '2', '3'];
      for (final k in keys) {
        engine.handleKeyEvent(MCDUKeyEvent(keyId: k));
      }

      expect(engine.session.typedText, 'ABC123');
      expect(engine.session.correctCount, 6);
      expect(engine.session.errorCount, 0);
      expect(engine.session.state, GameState.completed);
      expect(engine.session.isCompleted, isTrue);
      expect(engine.session.progress, 1.0);
      expect(engine.session.remainingText, '');
      engine.dispose();
    });

    // 14. MOD1L completes correctly
    test('14. MOD1L completes correctly', () {
      final engine = TypingTestEngine(prompt: TypingTestPrompts.mod1l);
      engine.start();

      final keys = ['M', 'O', 'D', '1', 'L'];
      for (final k in keys) {
        engine.handleKeyEvent(MCDUKeyEvent(keyId: k));
      }

      expect(engine.session.typedText, 'MOD1L');
      expect(engine.session.correctCount, 5);
      expect(engine.session.errorCount, 0);
      expect(engine.session.isCompleted, isTrue);
      engine.dispose();
    });

    // 15. FPL completes correctly
    test('15. FPL completes correctly', () {
      final engine = TypingTestEngine(prompt: TypingTestPrompts.fpl);
      engine.start();

      final keys = ['F', 'P', 'L'];
      for (final k in keys) {
        engine.handleKeyEvent(MCDUKeyEvent(keyId: k));
      }

      expect(engine.session.typedText, 'FPL');
      expect(engine.session.correctCount, 3);
      expect(engine.session.isCompleted, isTrue);
      engine.dispose();
    });

    // 16. DIR completes correctly
    test('16. DIR completes correctly', () {
      final engine = TypingTestEngine(prompt: TypingTestPrompts.dir);
      engine.start();

      final keys = ['D', 'I', 'R'];
      for (final k in keys) {
        engine.handleKeyEvent(MCDUKeyEvent(keyId: k));
      }

      expect(engine.session.typedText, 'DIR');
      expect(engine.session.correctCount, 3);
      expect(engine.session.isCompleted, isTrue);
      engine.dispose();
    });

    // 17. NAV completes correctly
    test('17. NAV completes correctly', () {
      final engine = TypingTestEngine(prompt: TypingTestPrompts.nav);
      engine.start();

      final keys = ['N', 'A', 'V'];
      for (final k in keys) {
        engine.handleKeyEvent(MCDUKeyEvent(keyId: k));
      }

      expect(engine.session.typedText, 'NAV');
      expect(engine.session.correctCount, 3);
      expect(engine.session.isCompleted, isTrue);
      engine.dispose();
    });

    // 18. key after completion is ignored
    test('18. key after completion is ignored', () {
      final engine = TypingTestEngine(prompt: TypingTestPrompts.fpl);
      engine.start();

      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'F'));
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'P'));
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'L'));
      expect(engine.session.isCompleted, isTrue);

      final snapshot = engine.session;
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'A'));
      engine.handleKeyEvent(MCDUKeyEvent(keyId: MCDUKey.menu));

      expect(engine.session, equals(snapshot));
      engine.dispose();
    });

    // 19. reset returns session to initial state
    test('19. reset returns session to initial state', () {
      final engine = TypingTestEngine(prompt: TypingTestPrompts.dir);
      engine.start();
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'D'));
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'Z')); // error

      expect(engine.session.typedText, 'D');
      expect(engine.session.correctCount, 1);
      expect(engine.session.errorCount, 1);

      engine.reset();
      expect(engine.session.state, GameState.idle);
      expect(engine.session.isIdle, isTrue);
      expect(engine.session.typedText, '');
      expect(engine.session.correctCount, 0);
      expect(engine.session.errorCount, 0);
      expect(engine.session.elapsedTime, Duration.zero);
      expect(engine.session.accuracy, 0.0);
      expect(engine.session.score, 0);
      expect(engine.session.progress, 0.0);
      expect(engine.session.remainingText, 'DIR');
      engine.dispose();
    });

    // 20. incomplete target remains playing
    test('20. incomplete target remains playing', () {
      final engine = TypingTestEngine(prompt: TypingTestPrompts.nav);
      engine.start();

      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'N'));
      expect(engine.session.state, GameState.playing);
      expect(engine.session.isPlaying, isTrue);
      expect(engine.session.isCompleted, isFalse);

      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'A'));
      expect(engine.session.state, GameState.playing);
      expect(engine.session.isPlaying, isTrue);
      expect(engine.session.isCompleted, isFalse);
      engine.dispose();
    });

    // 21. Accuracy formula tests (deterministic)
    test('21. Accuracy formula calculates correctly', () {
      // 6 correct / 0 errors = 100.0%
      const s1 = TypingTestSession(
        prompt: TypingTestPrompts.abc123,
        correctCount: 6,
        errorCount: 0,
      );
      expect(s1.accuracy, 100.0);

      // 6 correct / 2 errors = 75.0%
      const s2 = TypingTestSession(
        prompt: TypingTestPrompts.abc123,
        correctCount: 6,
        errorCount: 2,
      );
      expect(s2.accuracy, 75.0);

      // 0 correct / 0 errors = 0.0%
      const s3 = TypingTestSession(
        prompt: TypingTestPrompts.abc123,
        correctCount: 0,
        errorCount: 0,
      );
      expect(s3.accuracy, 0.0);
    });

    // 22. Score formula tests (deterministic)
    test('22. Score formula with known values and non-negative floor', () {
      // 6 correct * 100 - 0 * 25 - 4s * 5 = 600 - 0 - 20 = 580
      const s1 = TypingTestSession(
        prompt: TypingTestPrompts.abc123,
        correctCount: 6,
        errorCount: 0,
        elapsedTime: Duration(seconds: 4),
      );
      expect(s1.score, 580);

      // 6 correct * 100 - 2 * 25 - 10s * 5 = 600 - 50 - 50 = 500
      const s2 = TypingTestSession(
        prompt: TypingTestPrompts.abc123,
        correctCount: 6,
        errorCount: 2,
        elapsedTime: Duration(seconds: 10),
      );
      expect(s2.score, 500);

      // Extreme errors / elapsed time: cannot be negative (floors to 0)
      const s3 = TypingTestSession(
        prompt: TypingTestPrompts.abc123,
        correctCount: 1,
        errorCount: 20,
        elapsedTime: Duration(seconds: 200),
      );
      expect(s3.score, 0);
    });

    // 23. Completion freezes elapsed time and subsequent input does not modify it
    test('23. Completion freezes elapsed time and ignores subsequent keys', () {
      final engine = TypingTestEngine(prompt: TypingTestPrompts.fpl);
      engine.start();

      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'F'));
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'P'));
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'L'));

      expect(engine.session.isCompleted, isTrue);
      final finalElapsed = engine.session.elapsedTime;
      final finalScore = engine.session.score;

      // Extra input
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'A'));
      expect(engine.session.elapsedTime, equals(finalElapsed));
      expect(engine.session.score, equals(finalScore));

      engine.dispose();
    });
  });
}
