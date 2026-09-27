// test/speed_run_engine_test.dart
// Unit tests for SpeedRunEngine domain and state transitions.

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/game/speed_run/domain/speed_run_session.dart';
import 'package:mcdu_app/features/game/speed_run/domain/speed_run_step.dart';
import 'package:mcdu_app/features/game/speed_run/domain/speed_run_task.dart';
import 'package:mcdu_app/features/game/speed_run/domain/speed_run_tasks_catalog.dart';
import 'package:mcdu_app/features/game/speed_run/engine/speed_run_engine.dart';

void main() {
  group('SpeedRunEngine Unit Tests', () {
    test('1. Initial state is ready with default tasks', () {
      final engine = SpeedRunEngine();
      expect(engine.session.status, SpeedRunStatus.ready);
      expect(engine.session.isReady, isTrue);
      expect(engine.session.tasks.length, SpeedRunTasksCatalog.defaultTasks.length);
      expect(engine.session.currentTaskIndex, 0);
      expect(engine.session.currentStepIndex, 0);
      expect(engine.session.scratchpadBuffer, '');
      expect(engine.session.score, 0);
      expect(engine.session.errors, 0);
      expect(engine.session.combo, 0);
      expect(engine.session.elapsedTime, Duration.zero);
      expect(engine.session.penaltyTime, Duration.zero);
    });

    test('2. start() transitions status from ready to playing', () {
      final engine = SpeedRunEngine();
      engine.start();
      expect(engine.session.status, SpeedRunStatus.playing);
      expect(engine.session.isPlaying, isTrue);
      expect(engine.session.currentTask, isNotNull);
      expect(engine.session.currentStep, isNotNull);
    });

    test('3. Correct key advances step and increases combo/score', () {
      final engine = SpeedRunEngine();
      engine.start();

      final firstStep = engine.session.currentStep!;
      engine.handleKey(firstStep.expectedKeyId);

      expect(engine.session.currentStepIndex, 1);
      expect(engine.session.combo, 1);
      expect(engine.session.score, greaterThan(0));
      expect(engine.session.errors, 0);
    });

    test('4. Wrong key increments errors, resets combo, and adds 1s penalty', () {
      final engine = SpeedRunEngine();
      engine.start();

      final firstStep = engine.session.currentStep!;
      engine.handleKey(firstStep.expectedKeyId); // correct -> combo 1
      expect(engine.session.combo, 1);

      // Strike wrong key
      final wrongKey = firstStep.expectedKeyId == 'Z' ? 'A' : 'Z';
      engine.handleKey(wrongKey);

      expect(engine.session.errors, 1);
      expect(engine.session.combo, 0);
      expect(engine.session.penaltyTime, const Duration(seconds: 1));
      // Does not advance step
      expect(engine.session.currentStepIndex, 1);
    });

    test('5. Scratchpad characters accumulate only when isScratchpadChar is true', () {
      final task = SpeedRunTask(
        taskId: 'TEST-01',
        title: 'TEST TASK',
        category: 'TEST',
        parTime: const Duration(seconds: 5),
        steps: const [
          SpeedRunStep(stepId: 's1', prompt: 'PAGE', expectedKeyId: 'DIR', isScratchpadChar: false),
          SpeedRunStep(stepId: 's2', prompt: 'CHAR B', expectedKeyId: 'B', isScratchpadChar: true),
          SpeedRunStep(stepId: 's3', prompt: 'CHAR K', expectedKeyId: 'K', isScratchpadChar: true),
          SpeedRunStep(stepId: 's4', prompt: 'INSERT', expectedKeyId: '1L', isScratchpadChar: false),
        ],
      );

      final engine = SpeedRunEngine(tasks: [task]);
      engine.start();

      engine.handleKey('DIR');
      expect(engine.session.scratchpadBuffer, '');

      engine.handleKey('B');
      expect(engine.session.scratchpadBuffer, 'B');

      engine.handleKey('K');
      expect(engine.session.scratchpadBuffer, 'BK');

      engine.handleKey('1L');
      // Task completes -> scratchpad cleared
      expect(engine.session.scratchpadBuffer, '');
    });

    test('6. DOT keyId accumulates as dot in scratchpad', () {
      final task = SpeedRunTask(
        taskId: 'TEST-02',
        title: 'DOT TASK',
        category: 'TEST',
        parTime: const Duration(seconds: 5),
        steps: const [
          SpeedRunStep(stepId: 's1', prompt: 'NUM 1', expectedKeyId: '1', isScratchpadChar: true),
          SpeedRunStep(stepId: 's2', prompt: 'DOT', expectedKeyId: 'DOT', isScratchpadChar: true),
          SpeedRunStep(stepId: 's3', prompt: 'NUM 2', expectedKeyId: '2', isScratchpadChar: true),
        ],
      );

      final engine = SpeedRunEngine(tasks: [task]);
      engine.start();

      engine.handleKey('1');
      engine.handleKey('DOT');
      expect(engine.session.scratchpadBuffer, '1.');
    });

    test('7. Task completion advances to next task and resets step index', () {
      final task1 = SpeedRunTask(
        taskId: 'T1',
        title: 'TASK 1',
        category: 'TEST',
        parTime: const Duration(seconds: 3),
        steps: const [
          SpeedRunStep(stepId: 's1', prompt: 'P1', expectedKeyId: 'FPL'),
        ],
      );
      final task2 = SpeedRunTask(
        taskId: 'T2',
        title: 'TASK 2',
        category: 'TEST',
        parTime: const Duration(seconds: 3),
        steps: const [
          SpeedRunStep(stepId: 's1', prompt: 'P2', expectedKeyId: 'DIR'),
        ],
      );

      final engine = SpeedRunEngine(tasks: [task1, task2]);
      engine.start();

      expect(engine.session.currentTaskIndex, 0);
      engine.handleKey('FPL');

      expect(engine.session.completedTasks, 1);
      expect(engine.session.currentTaskIndex, 1);
      expect(engine.session.currentStepIndex, 0);
      expect(engine.session.currentTask?.taskId, 'T2');
      expect(engine.session.isPlaying, isTrue);
    });

    test('8. Final task completion sets status to completed', () {
      final singleTask = SpeedRunTask(
        taskId: 'T1',
        title: 'SINGLE',
        category: 'TEST',
        parTime: const Duration(seconds: 3),
        steps: const [
          SpeedRunStep(stepId: 's1', prompt: 'P1', expectedKeyId: 'NAV'),
        ],
      );

      final engine = SpeedRunEngine(tasks: [singleTask]);
      engine.start();

      engine.handleKey('NAV');
      expect(engine.session.status, SpeedRunStatus.completed);
      expect(engine.session.isCompleted, isTrue);
      expect(engine.session.completedTasks, 1);
    });

    test('9. Keys are ignored when session is completed or not playing', () {
      final singleTask = SpeedRunTask(
        taskId: 'T1',
        title: 'SINGLE',
        category: 'TEST',
        parTime: const Duration(seconds: 3),
        steps: const [
          SpeedRunStep(stepId: 's1', prompt: 'P1', expectedKeyId: 'NAV'),
        ],
      );

      final engine = SpeedRunEngine(tasks: [singleTask]);
      // Before start() -> not playing
      engine.handleKey('NAV');
      expect(engine.session.status, SpeedRunStatus.ready);

      engine.start();
      engine.handleKey('NAV');
      expect(engine.session.status, SpeedRunStatus.completed);
      final scoreAtCompletion = engine.session.score;

      // After completion -> ignored
      engine.handleKey('NAV');
      expect(engine.session.score, scoreAtCompletion);
    });

    test('10. tick() advances elapsedTime only during playing status', () {
      final engine = SpeedRunEngine();
      engine.tick(const Duration(milliseconds: 500));
      expect(engine.session.elapsedTime, Duration.zero); // Not started

      engine.start();
      engine.tick(const Duration(milliseconds: 250));
      expect(engine.session.elapsedTime, const Duration(milliseconds: 250));

      engine.pause();
      engine.tick(const Duration(milliseconds: 250));
      expect(engine.session.elapsedTime, const Duration(milliseconds: 250)); // Paused

      engine.resume();
      engine.tick(const Duration(milliseconds: 250));
      expect(engine.session.elapsedTime, const Duration(milliseconds: 500));
    });

    test('11. pause() and resume() preserves exact session data', () {
      final engine = SpeedRunEngine();
      engine.start();

      final firstStep = engine.session.currentStep!;
      engine.handleKey(firstStep.expectedKeyId);
      final scoreBeforePause = engine.session.score;

      engine.pause();
      expect(engine.session.isPaused, isTrue);

      engine.resume();
      expect(engine.session.isPlaying, isTrue);
      expect(engine.session.score, scoreBeforePause);
      expect(engine.session.currentStepIndex, 1);
    });

    test('12. reset() restores session to ready with preserved tasks', () {
      final engine = SpeedRunEngine();
      engine.start();
      engine.handleKey(engine.session.currentStep!.expectedKeyId);
      engine.tick(const Duration(seconds: 2));

      engine.reset();
      expect(engine.session.isReady, isTrue);
      expect(engine.session.score, 0);
      expect(engine.session.errors, 0);
      expect(engine.session.elapsedTime, Duration.zero);
      expect(engine.session.currentStepIndex, 0);
    });

    test('13. Non-gameplay key BRT/DIM is ignored without error', () {
      final engine = SpeedRunEngine();
      engine.start();

      engine.handleKey('BRT/DIM');
      expect(engine.session.errors, 0);
      expect(engine.session.currentStepIndex, 0);
    });

    test('14. Total effective time correctly combines elapsed and penalty', () {
      final engine = SpeedRunEngine();
      engine.start();
      engine.tick(const Duration(seconds: 10));

      // Trigger 2 errors
      engine.handleKey('WRONG1');
      engine.handleKey('WRONG2');

      expect(engine.session.elapsedTime, const Duration(seconds: 10));
      expect(engine.session.penaltyTime, const Duration(seconds: 2));
      expect(engine.session.totalEffectiveTime, const Duration(seconds: 12));
    });

    test('15. Dynamic difficulty progression: initial level 1, task clear increases level, cap at 5, reset restores 1', () {
      final tasks = List.generate(
        6,
        (i) => SpeedRunTask(
          taskId: 'T$i',
          title: 'TASK $i',
          category: 'TEST',
          parTime: const Duration(seconds: 3),
          steps: const [
            SpeedRunStep(stepId: 's1', prompt: 'P1', expectedKeyId: '1'),
          ],
        ),
      );

      final engine = SpeedRunEngine(tasks: tasks);
      // 1. Initial state level 1
      expect(engine.session.difficultyLevel, 1);

      engine.start();
      expect(engine.session.difficultyLevel, 1);

      // Wrong key doesn't decrease level
      engine.handleKey('WRONG');
      expect(engine.session.difficultyLevel, 1);

      // Complete Task 0 -> LV 02
      engine.handleKey('1');
      expect(engine.session.completedTasks, 1);
      expect(engine.session.difficultyLevel, 2);

      // Complete Task 1 -> LV 03
      engine.handleKey('1');
      expect(engine.session.completedTasks, 2);
      expect(engine.session.difficultyLevel, 3);

      // Complete Task 2 -> LV 04
      engine.handleKey('1');
      expect(engine.session.completedTasks, 3);
      expect(engine.session.difficultyLevel, 4);

      // Complete Task 3 -> LV 05
      engine.handleKey('1');
      expect(engine.session.completedTasks, 4);
      expect(engine.session.difficultyLevel, 5);

      // Complete Task 4 -> Capped at LV 05
      engine.handleKey('1');
      expect(engine.session.completedTasks, 5);
      expect(engine.session.difficultyLevel, 5);

      // Reset -> restores LV 01
      engine.reset();
      expect(engine.session.difficultyLevel, 1);
    });

    test('16. Individual correct steps do not increase difficultyLevel before task completion', () {
      final multiStepTask = SpeedRunTask(
        taskId: 'MULTI-1',
        title: 'MULTI STEP',
        category: 'TEST',
        parTime: const Duration(seconds: 5),
        steps: const [
          SpeedRunStep(stepId: 's1', prompt: 'P1', expectedKeyId: '1'),
          SpeedRunStep(stepId: 's2', prompt: 'P2', expectedKeyId: '2'),
        ],
      );

      final engine = SpeedRunEngine(tasks: [multiStepTask]);
      engine.start();
      expect(engine.session.difficultyLevel, 1);

      // Step 1 correct
      engine.handleKey('1');
      expect(engine.session.currentStepIndex, 1);
      expect(engine.session.difficultyLevel, 1); // Remains 1

      // Step 2 completes task -> LV 02
      engine.handleKey('2');
      expect(engine.session.difficultyLevel, 2);
    });

    test('17. Real 5-task catalog full completion reaches exactly LV05 and completes session', () {
      final engine = SpeedRunEngine(); // uses SpeedRunTasksCatalog.defaultTasks
      expect(engine.session.tasks.length, 5);
      expect(engine.session.tasks, SpeedRunTasksCatalog.defaultTasks);
      expect(engine.session.difficultyLevel, 1);

      engine.start();
      expect(engine.session.difficultyLevel, 1);

      // Execute all 5 tasks sequentially from defaultTasks
      for (int taskIdx = 0; taskIdx < 5; taskIdx++) {
        final task = engine.session.tasks[taskIdx];
        expect(engine.session.currentTaskIndex, taskIdx);

        // Execute all steps in this task
        for (final step in task.steps) {
          engine.handleKey(step.expectedKeyId);
        }

        // Expected difficulty after task completion
        final expectedLevel = (taskIdx + 2).clamp(1, 5);
        expect(engine.session.completedTasks, taskIdx + 1);
        expect(engine.session.difficultyLevel, expectedLevel);
      }

      // Final assertions on full completion
      expect(engine.session.completedTasks, 5);
      expect(engine.session.currentTaskIndex, 5);
      expect(engine.session.difficultyLevel, 5);
      expect(engine.session.status, SpeedRunStatus.completed);
      expect(engine.session.isCompleted, isTrue);
    });
  });
}
