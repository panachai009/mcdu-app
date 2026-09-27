// test/memory_controller_test.dart

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/game/memory/domain/memory_session.dart';
import 'package:mcdu_app/features/game/memory/engine/memory_engine.dart';
import 'package:mcdu_app/features/game/memory/presentation/memory_controller.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';

void main() {
  group('MemoryController Unit Tests', () {
    // 1. Initial ready state
    testWidgets('1. Initial ready state conforms to requirements', (WidgetTester tester) async {
      final controller = MemoryController(vsync: tester);

      expect(controller.isReady, isTrue);
      expect(controller.isMemorizing, isFalse);
      expect(controller.isRecalling, isFalse);
      expect(controller.isPaused, isFalse);
      expect(controller.isGameOver, isFalse);
      expect(controller.presentationElapsed, Duration.zero);
      expect(controller.presentationProgress, 0.0);

      controller.dispose();
    });

    // 2. Start transitions to memorizing and starts ticker
    testWidgets('2. Start transitions to memorizing and resets presentation elapsed', (WidgetTester tester) async {
      final controller = MemoryController(vsync: tester);

      controller.start();
      expect(controller.isMemorizing, isTrue);
      expect(controller.session.targetSequence.length, 3);
      expect(controller.presentationElapsed, Duration.zero);

      controller.dispose();
    });

    // 3. Presentation duration per level table
    test('3. Presentation duration exact table matches specifications', () {
      expect(MemoryController.presentationDurationForLevel(1), const Duration(milliseconds: 3500));
      expect(MemoryController.presentationDurationForLevel(2), const Duration(milliseconds: 3280));
      expect(MemoryController.presentationDurationForLevel(3), const Duration(milliseconds: 3060));
      expect(MemoryController.presentationDurationForLevel(4), const Duration(milliseconds: 2830));
      expect(MemoryController.presentationDurationForLevel(5), const Duration(milliseconds: 2610));
      expect(MemoryController.presentationDurationForLevel(6), const Duration(milliseconds: 2390));
      expect(MemoryController.presentationDurationForLevel(7), const Duration(milliseconds: 2170));
      expect(MemoryController.presentationDurationForLevel(8), const Duration(milliseconds: 1940));
      expect(MemoryController.presentationDurationForLevel(9), const Duration(milliseconds: 1720));
      expect(MemoryController.presentationDurationForLevel(10), const Duration(milliseconds: 1500));
    });

    // 4. Presentation expiration transitions to recalling
    testWidgets('4. Presentation expiration automatically invokes beginRecall()', (WidgetTester tester) async {
      final controller = MemoryController(vsync: tester);

      controller.start();
      expect(controller.isMemorizing, isTrue);

      // Advance by 3500ms in 50ms frames to simulate natural ticker progression
      for (int i = 0; i < 75; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // After 3500ms, memorizing should transition to recalling
      expect(controller.isRecalling, isTrue);
      expect(controller.presentationElapsed, const Duration(milliseconds: 3500));

      controller.dispose();
    });

    // 5. Pause during memorizing preserves presentation progress
    testWidgets('5. Pause during memorizing preserves presentation progress', (WidgetTester tester) async {
      final controller = MemoryController(vsync: tester);

      controller.start();
      // Advance by 1000ms
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(controller.isMemorizing, isTrue);
      final elapsedBeforePause = controller.presentationElapsed;
      expect(elapsedBeforePause.inMilliseconds, greaterThanOrEqualTo(950));

      controller.pause();
      expect(controller.isPaused, isTrue);

      // Advance while paused: elapsed must not advance
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(controller.presentationElapsed, elapsedBeforePause);

      // Resume: continues timing
      controller.resume();
      expect(controller.isMemorizing, isTrue);
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(controller.presentationElapsed.inMilliseconds, greaterThan(elapsedBeforePause.inMilliseconds));

      controller.dispose();
    });

    // 6. Pause during recalling stops ticker and resume continues
    testWidgets('6. Pause during recalling stops ticker and resume continues', (WidgetTester tester) async {
      final controller = MemoryController(vsync: tester);

      controller.start();
      for (int i = 0; i < 75; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(controller.isRecalling, isTrue);

      final elapsedBefore = controller.session.elapsedTime;
      controller.pause();
      expect(controller.isPaused, isTrue);

      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(controller.session.elapsedTime, elapsedBefore);

      controller.resume();
      expect(controller.isRecalling, isTrue);
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(controller.session.elapsedTime.inMilliseconds, greaterThan(elapsedBefore.inMilliseconds));

      controller.dispose();
    });

    // 7. Successful round triggers next memorizing round with new presentation timer
    testWidgets('7. Successful round triggers next memorizing round with new presentation timer', (WidgetTester tester) async {
      final engine = MemoryEngine(random: Random(42));
      final controller = MemoryController(vsync: tester, engine: engine);

      controller.start();
      for (int i = 0; i < 75; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(controller.isRecalling, isTrue);

      // Type correct target sequence
      final target = controller.session.targetSequence;
      for (int i = 0; i < target.length; i++) {
        controller.handleKeyEvent(MCDUKeyEvent(keyId: target[i]));
      }

      // Round 1 completed -> transitions back to memorizing
      expect(controller.session.completedRounds, 1);
      expect(controller.isMemorizing, isTrue);
      expect(controller.presentationElapsed, Duration.zero);

      controller.dispose();
    });

    // 8. Reset restores clean ready state and stops ticker
    testWidgets('8. Reset restores clean ready state and stops ticker', (WidgetTester tester) async {
      final controller = MemoryController(vsync: tester);

      controller.start();
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(controller.isMemorizing, isTrue);

      controller.reset();
      expect(controller.isReady, isTrue);
      expect(controller.session.status, MemoryStatus.ready);
      expect(controller.presentationElapsed, Duration.zero);

      controller.dispose();
    });
  });
}
