// test/speed_run_controller_test.dart
// Unit tests for SpeedRunController ticker, event delegation, and lifecycle.

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/game/speed_run/domain/speed_run_session.dart';
import 'package:mcdu_app/features/game/speed_run/domain/speed_run_step.dart';
import 'package:mcdu_app/features/game/speed_run/domain/speed_run_task.dart';
import 'package:mcdu_app/features/game/speed_run/engine/speed_run_engine.dart';
import 'package:mcdu_app/features/game/speed_run/presentation/speed_run_controller.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';

void main() {
  group('SpeedRunController Unit Tests', () {
    testWidgets('1. Initial state is READY with no active ticker', (tester) async {
      final controller = SpeedRunController(vsync: tester);
      expect(controller.isReady, isTrue);
      expect(controller.isPlaying, isFalse);
      expect(controller.isPaused, isFalse);
      expect(controller.isCompleted, isFalse);
      expect(controller.session.status, SpeedRunStatus.ready);

      controller.dispose();
    });

    testWidgets('2. start() transitions to PLAYING and starts ticker', (tester) async {
      final controller = SpeedRunController(vsync: tester);
      controller.start();

      expect(controller.isPlaying, isTrue);
      expect(controller.session.status, SpeedRunStatus.playing);

      // Advance frames (at least 2 ticks needed for delta calculation)
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(controller.session.elapsedTime, greaterThan(Duration.zero));

      controller.dispose();
    });

    testWidgets('3. pause() stops ticker and preserves elapsed time', (tester) async {
      final controller = SpeedRunController(vsync: tester);
      controller.start();
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final elapsedBeforePause = controller.session.elapsedTime;
      expect(elapsedBeforePause, greaterThan(Duration.zero));

      controller.pause();
      expect(controller.isPaused, isTrue);

      // Advance frames while paused -> should not advance
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(controller.session.elapsedTime, elapsedBeforePause);

      controller.dispose();
    });

    testWidgets('4. resume() restarts ticker from where it left off', (tester) async {
      final controller = SpeedRunController(vsync: tester);
      controller.start();
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      controller.pause();
      final elapsedAtPause = controller.session.elapsedTime;

      controller.resume();
      expect(controller.isPlaying, isTrue);

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(controller.session.elapsedTime, greaterThan(elapsedAtPause));

      controller.dispose();
    });

    testWidgets('5. reset() returns to initial READY state', (tester) async {
      final controller = SpeedRunController(vsync: tester);
      controller.start();
      await tester.pump(const Duration(milliseconds: 200));
      controller.handleKeyEvent(MCDUKeyEvent(keyId: controller.session.currentStep!.expectedKeyId));

      controller.reset();
      expect(controller.isReady, isTrue);
      expect(controller.session.score, 0);
      expect(controller.session.elapsedTime, Duration.zero);

      controller.dispose();
    });

    testWidgets('6. handleKeyEvent forwards keyId to engine', (tester) async {
      final controller = SpeedRunController(vsync: tester);
      controller.start();

      final expectedKey = controller.session.currentStep!.expectedKeyId;
      controller.handleKeyEvent(MCDUKeyEvent(keyId: expectedKey));

      expect(controller.session.currentStepIndex, 1);
      expect(controller.session.combo, 1);

      controller.dispose();
    });

    testWidgets('7. Keys are ignored when controller is not playing', (tester) async {
      final controller = SpeedRunController(vsync: tester);
      // In ready
      controller.handleKeyEvent(MCDUKeyEvent(keyId: 'DIR'));
      expect(controller.session.currentStepIndex, 0);
      expect(controller.isReady, isTrue);

      controller.dispose();
    });

    testWidgets('8. Completed session stops gameplay timing', (tester) async {
      final task = SpeedRunTask(
        taskId: 'T1',
        title: 'ONE STEP',
        category: 'TEST',
        parTime: const Duration(seconds: 2),
        steps: const [
          SpeedRunStep(stepId: 's1', prompt: 'PRESS FPL', expectedKeyId: 'FPL'),
        ],
      );

      final engine = SpeedRunEngine(tasks: [task]);
      final controller = SpeedRunController(vsync: tester, engine: engine);

      controller.start();
      await tester.pump(const Duration(milliseconds: 100));

      controller.handleKeyEvent(MCDUKeyEvent(keyId: 'FPL'));
      expect(controller.isCompleted, isTrue);

      final timeAtCompletion = controller.session.elapsedTime;

      // Pump more frames -> elapsed time should stop advancing
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.session.elapsedTime, timeAtCompletion);

      controller.dispose();
    });

    test('9. changes stream emits state updates on tick and key events', () async {
      final engine = SpeedRunEngine();
      final vsync = const TestVSync();
      final controller = SpeedRunController(vsync: vsync, engine: engine);
      final emittedStates = <SpeedRunSession>[];
      final sub = controller.changes.listen(emittedStates.add);

      controller.start();
      await Future<void>.delayed(Duration.zero);
      expect(emittedStates.length, 1);
      expect(emittedStates.first.isPlaying, isTrue);

      controller.handleKeyEvent(MCDUKeyEvent(keyId: controller.session.currentStep!.expectedKeyId));
      await Future<void>.delayed(Duration.zero);
      expect(emittedStates.length, 2);

      controller.pause();
      await Future<void>.delayed(Duration.zero);
      expect(emittedStates.length, 3);
      expect(emittedStates.last.isPaused, isTrue);

      await sub.cancel();
      controller.dispose();
    });

    testWidgets('10. dispose() cleans up resources without leaks', (tester) async {
      final controller = SpeedRunController(vsync: tester);
      controller.start();
      await tester.pump(const Duration(milliseconds: 50));

      controller.dispose();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
