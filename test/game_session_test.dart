// test/game_session_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/mcdu_core/domain/mcdu_key.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';
import 'package:mcdu_app/features/game/domain/game_mode.dart';
import 'package:mcdu_app/features/game/domain/game_modes.dart';
import 'package:mcdu_app/features/game/domain/game_session.dart';
import 'package:mcdu_app/features/game/domain/game_state.dart';
import 'package:mcdu_app/features/game/engine/game_session_engine.dart';

void main() {
  group('Phase 12 Game Foundation Unit Tests', () {
    // 1. GameMode creation
    test('1. GameMode creation works with required fields', () {
      const mode = GameMode(
        gameModeId: 'custom_mode',
        title: 'Custom Mode',
        description: 'Test Description',
      );
      expect(mode.gameModeId, 'custom_mode');
      expect(mode.title, 'Custom Mode');
      expect(mode.description, 'Test Description');
    });

    // 2. GameMode equality
    test('2. GameMode equality works as value object', () {
      const mode1 = GameMode(
        gameModeId: 'typing_test',
        title: 'Typing Test',
        description: 'Practice rapid alphanumeric MCDU typing and accuracy.',
      );
      const mode2 = GameMode(
        gameModeId: 'typing_test',
        title: 'Typing Test',
        description: 'Practice rapid alphanumeric MCDU typing and accuracy.',
      );
      const mode3 = GameMode(
        gameModeId: 'other',
        title: 'Other',
        description: 'Other description',
      );
      expect(mode1, equals(mode2));
      expect(mode1.hashCode, equals(mode2.hashCode));
      expect(mode1, isNot(equals(mode3)));
    });

    // 3. GameMode catalog contains exactly 5 modes
    test('3. GameMode catalog contains exactly 5 modes', () {
      expect(GameModes.all.length, 5);
      final ids = GameModes.all.map((m) => m.gameModeId).toSet();
      expect(
        ids,
        containsAll([
          'typing_test',
          'word_rain',
          'memory',
          'speed_run',
          'mcdu_flow',
        ]),
      );
    });

    // 4. findById works
    test('4. findById works for all 5 catalog modes', () {
      expect(GameModes.findById('typing_test'), equals(GameModes.typingTest));
      expect(GameModes.findById('word_rain'), equals(GameModes.wordRain));
      expect(GameModes.findById('memory'), equals(GameModes.memory));
      expect(GameModes.findById('speed_run'), equals(GameModes.speedRun));
      expect(GameModes.findById('mcdu_flow'), equals(GameModes.mcduFlow));
    });

    // 5. unknown mode returns null
    test('5. unknown mode returns null in findById', () {
      expect(GameModes.findById('non_existent_mode'), isNull);
      expect(GameModes.findById(''), isNull);
    });

    // 6. initial GameSession is idle
    test('6. initial GameSession is idle', () {
      final engine = GameSessionEngine(gameMode: GameModes.typingTest);
      expect(engine.session.state, GameState.idle);
      expect(engine.session.isIdle, isTrue);
      expect(engine.session.isPlaying, isFalse);
      expect(engine.session.isCompleted, isFalse);
      engine.dispose();
    });

    // 7. start() changes idle -> playing
    test('7. start() changes idle -> playing', () {
      final engine = GameSessionEngine(gameMode: GameModes.typingTest);
      expect(engine.session.isIdle, isTrue);

      engine.start();
      expect(engine.session.state, GameState.playing);
      expect(engine.session.isPlaying, isTrue);
      expect(engine.session.isIdle, isFalse);
      expect(engine.session.isCompleted, isFalse);
      engine.dispose();
    });

    // 8. complete() changes playing -> completed
    test('8. complete() changes playing -> completed', () {
      final engine = GameSessionEngine(gameMode: GameModes.typingTest);
      engine.start();
      expect(engine.session.isPlaying, isTrue);

      engine.complete();
      expect(engine.session.state, GameState.completed);
      expect(engine.session.isCompleted, isTrue);
      expect(engine.session.isPlaying, isFalse);
      expect(engine.session.isIdle, isFalse);
      engine.dispose();
    });

    // 9. completed ignores key events
    test('9. completed ignores key events', () {
      final engine = GameSessionEngine(gameMode: GameModes.typingTest);
      engine.start();
      engine.complete();

      final initialSnapshot = engine.session;
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'A'));
      engine.handleKeyEvent(MCDUKeyEvent(keyId: MCDUKey.menu));

      expect(engine.session, equals(initialSnapshot));
      expect(engine.session.isCompleted, isTrue);
      engine.dispose();
    });

    // 10. reset() returns session to initial state
    test('10. reset() returns session to initial state', () {
      final engine = GameSessionEngine(gameMode: GameModes.speedRun);
      engine.start();
      engine.complete();
      expect(engine.session.isCompleted, isTrue);

      engine.reset();
      expect(engine.session.state, GameState.idle);
      expect(engine.session.isIdle, isTrue);
      expect(engine.session.correctCount, 0);
      expect(engine.session.errorCount, 0);
      expect(engine.session.score, 0);
      expect(engine.session.elapsedTime, Duration.zero);
      engine.dispose();
    });

    // 11. correctCount starts at 0
    test('11. correctCount starts at 0', () {
      const session = GameSession(
        sessionId: 'test_11',
        gameMode: GameModes.typingTest,
      );
      expect(session.correctCount, 0);
    });

    // 12. errorCount starts at 0
    test('12. errorCount starts at 0', () {
      const session = GameSession(
        sessionId: 'test_12',
        gameMode: GameModes.typingTest,
      );
      expect(session.errorCount, 0);
    });

    // 13. score starts at 0
    test('13. score starts at 0', () {
      const session = GameSession(
        sessionId: 'test_13',
        gameMode: GameModes.typingTest,
      );
      expect(session.score, 0);
    });

    // 14. elapsedTime starts at Duration.zero
    test('14. elapsedTime starts at Duration.zero', () {
      const session = GameSession(
        sessionId: 'test_14',
        gameMode: GameModes.typingTest,
      );
      expect(session.elapsedTime, Duration.zero);
    });

    // 15. MCDUKeyEvent can be passed into GameSessionEngine
    test('15. MCDUKeyEvent can be passed into GameSessionEngine without crash', () {
      final engine = GameSessionEngine(gameMode: GameModes.wordRain);
      engine.start();

      expect(
        () => engine.handleKeyEvent(MCDUKeyEvent(keyId: MCDUKey.fpl)),
        returnsNormally,
      );
      expect(
        () => engine.handleKeyEvent(MCDUKeyEvent(keyId: '1')),
        returnsNormally,
      );
      expect(
        () => engine.handleKeyEvent(MCDUKeyEvent(keyId: '1L')),
        returnsNormally,
      );
      engine.dispose();
    });

    // 16. key event does not accidentally implement gameplay scoring in Phase 12
    test('16. key event does not modify score, correctCount, or errorCount in Phase 12 Foundation', () {
      final engine = GameSessionEngine(gameMode: GameModes.typingTest);
      engine.start();

      final before = engine.session;
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'A'));
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'B'));
      engine.handleKeyEvent(MCDUKeyEvent(keyId: MCDUKey.clr));

      expect(engine.session.correctCount, before.correctCount);
      expect(engine.session.errorCount, before.errorCount);
      expect(engine.session.score, before.score);
      expect(engine.session.elapsedTime, before.elapsedTime);
      expect(engine.session.state, GameState.playing);
      engine.dispose();
    });
  });
}
