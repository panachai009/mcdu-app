// test/speed_run_display_view_test.dart
// Widget tests for SpeedRunDisplayView rendering, overlays, and overflow protection.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/game/speed_run/domain/speed_run_session.dart';
import 'package:mcdu_app/features/game/speed_run/domain/speed_run_step.dart';
import 'package:mcdu_app/features/game/speed_run/domain/speed_run_task.dart';
import 'package:mcdu_app/features/game/speed_run/engine/speed_run_engine.dart';
import 'package:mcdu_app/features/game/speed_run/presentation/speed_run_controller.dart';
import 'package:mcdu_app/features/game/speed_run/presentation/speed_run_display_view.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';

void main() {
  group('SpeedRunDisplayView Widget Tests', () {
    testWidgets('1. READY state renders prompt, task count and START button without overflow', (tester) async {
      final controller = SpeedRunController(vsync: tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeedRunDisplayView(
              controller: controller,
              width: 270,
              height: 228,
            ),
          ),
        ),
      );

      expect(find.text('SPEED RUN\nPROCEDURAL FLOW'), findsOneWidget);
      expect(find.text('5 FLIGHT TASKS\n\nPRESS START TO BEGIN'), findsOneWidget);
      expect(find.text('<ABORT'), findsOneWidget);
      expect(find.text('START>'), findsOneWidget);
      expect(tester.takeException(), isNull);

      controller.dispose();
    });

    testWidgets('2. PLAYING state renders task, step prompt, timer, and score', (tester) async {
      final controller = SpeedRunController(vsync: tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeedRunDisplayView(
              controller: controller,
              width: 270,
              height: 228,
            ),
          ),
        ),
      );

      controller.start();
      await tester.pump();

      expect(find.text('DIRECT TO BKK'), findsOneWidget);
      expect(find.text('OPEN DIR PAGE'), findsOneWidget);
      expect(find.text('PAUSE>'), findsOneWidget);
      expect(find.text('<ABORT'), findsOneWidget);
      expect(tester.takeException(), isNull);

      controller.dispose();
    });

    testWidgets('3. PAUSED state renders overlay and RESUME button', (tester) async {
      final controller = SpeedRunController(vsync: tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeedRunDisplayView(
              controller: controller,
              width: 270,
              height: 228,
            ),
          ),
        ),
      );

      controller.start();
      await tester.pump();
      controller.pause();
      await tester.pump();

      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('RESUME>'), findsOneWidget);
      expect(tester.takeException(), isNull);

      controller.dispose();
    });

    testWidgets('4. COMPLETED state renders summary stats and RETRY button', (tester) async {
      final singleTask = SpeedRunTask(
        taskId: 'T1',
        title: 'SINGLE TASK',
        category: 'TEST',
        parTime: const Duration(seconds: 4),
        steps: const [
          SpeedRunStep(stepId: 's1', prompt: 'PRESS FPL', expectedKeyId: 'FPL'),
        ],
      );

      final engine = SpeedRunEngine(tasks: [singleTask]);
      final controller = SpeedRunController(vsync: tester, engine: engine);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeedRunDisplayView(
              controller: controller,
              width: 270,
              height: 228,
            ),
          ),
        ),
      );

      controller.start();
      await tester.pump();

      controller.handleKeyEvent(MCDUKeyEvent(keyId: 'FPL'));
      await tester.pump();

      expect(find.text('SPEED RUN COMPLETE'), findsOneWidget);
      expect(find.text('TASKS: 1/1'), findsOneWidget);
      expect(find.text('RETRY>'), findsOneWidget);
      expect(tester.takeException(), isNull);

      controller.dispose();
    });

    testWidgets('5. Active step in step flow is highlighted', (tester) async {
      final controller = SpeedRunController(vsync: tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeedRunDisplayView(
              controller: controller,
              width: 270,
              height: 228,
            ),
          ),
        ),
      );

      controller.start();
      await tester.pump();

      expect(find.text('DIR'), findsOneWidget);
      expect(find.text('OPEN DIR PAGE'), findsOneWidget);

      // Advance first step
      controller.handleKeyEvent(MCDUKeyEvent(keyId: 'DIR'));
      await tester.pump();

      expect(find.text('TYPE B'), findsOneWidget);
      expect(tester.takeException(), isNull);

      controller.dispose();
    });

    testWidgets('6. Scratchpad line displays buffer correctly', (tester) async {
      final controller = SpeedRunController(vsync: tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeedRunDisplayView(
              controller: controller,
              width: 270,
              height: 228,
            ),
          ),
        ),
      );

      controller.start();
      await tester.pump();

      controller.handleKeyEvent(MCDUKeyEvent(keyId: 'DIR')); // Step 1: DIR
      controller.handleKeyEvent(MCDUKeyEvent(keyId: 'B'));   // Step 2: B
      await tester.pump();

      expect(find.textContaining('B___________'), findsOneWidget);
      expect(tester.takeException(), isNull);

      controller.dispose();
    });

    testWidgets('7. Standard 270x228 aperture produces no RenderFlex overflow', (tester) async {
      final controller = SpeedRunController(vsync: tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeedRunDisplayView(
              controller: controller,
              width: 270,
              height: 228,
            ),
          ),
        ),
      );

      controller.start();
      await tester.pump();

      // Cycle a couple steps
      controller.handleKeyEvent(MCDUKeyEvent(keyId: 'DIR'));
      await tester.pump();

      expect(tester.takeException(), isNull);

      controller.dispose();
    });

    testWidgets('8. Longer task titles and step flows do not overflow aperture', (tester) async {
      final longTask = SpeedRunTask(
        taskId: 'LONG-01',
        title: 'EXTREMELY LONG PROCEDURAL FLIGHT PLAN TASK TITLE',
        category: 'COMPLEX',
        parTime: const Duration(seconds: 10),
        steps: const [
          SpeedRunStep(stepId: 's1', prompt: 'PRESS RADIO KEY', expectedKeyId: 'RADIO'),
          SpeedRunStep(stepId: 's2', prompt: 'NUM 1', expectedKeyId: '1', isScratchpadChar: true),
          SpeedRunStep(stepId: 's3', prompt: 'NUM 1', expectedKeyId: '1', isScratchpadChar: true),
          SpeedRunStep(stepId: 's4', prompt: 'NUM 8', expectedKeyId: '8', isScratchpadChar: true),
          SpeedRunStep(stepId: 's5', prompt: 'DOT', expectedKeyId: 'DOT', isScratchpadChar: true),
          SpeedRunStep(stepId: 's6', prompt: 'NUM 1', expectedKeyId: '1', isScratchpadChar: true),
          SpeedRunStep(stepId: 's7', prompt: 'NUM 5', expectedKeyId: '5', isScratchpadChar: true),
          SpeedRunStep(stepId: 's8', prompt: 'TRANSFER STANDBY FREQUENCY 2L', expectedKeyId: '2L'),
        ],
      );

      final engine = SpeedRunEngine(tasks: [longTask]);
      final controller = SpeedRunController(vsync: tester, engine: engine);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeedRunDisplayView(
              controller: controller,
              width: 270,
              height: 228,
            ),
          ),
        ),
      );

      controller.start();
      await tester.pump();

      expect(tester.takeException(), isNull);

      controller.dispose();
    });

    testWidgets('9. HUD displays difficulty level LV 01 initially', (tester) async {
      final controller = SpeedRunController(vsync: tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeedRunDisplayView(
              controller: controller,
              width: 270,
              height: 228,
            ),
          ),
        ),
      );

      expect(find.textContaining('LV 01'), findsOneWidget);
      expect(tester.takeException(), isNull);

      controller.dispose();
    });

    testWidgets('10. Higher difficulty level LV 03 renders without overflow', (tester) async {
      final engine = SpeedRunEngine(
        session: SpeedRunSession(
          status: SpeedRunStatus.playing,
          difficultyLevel: 3,
        ),
      );
      final controller = SpeedRunController(vsync: tester, engine: engine);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeedRunDisplayView(
              controller: controller,
              width: 270,
              height: 228,
            ),
          ),
        ),
      );

      expect(find.textContaining('LV 03'), findsOneWidget);
      expect(tester.takeException(), isNull);

      controller.dispose();
    });
  });
}
