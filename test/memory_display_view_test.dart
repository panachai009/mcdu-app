// test/memory_display_view_test.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/game/memory/engine/memory_engine.dart';
import 'package:mcdu_app/features/game/memory/presentation/memory_controller.dart';
import 'package:mcdu_app/features/game/memory/presentation/memory_display_view.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';

void main() {
  group('MemoryDisplayView Widget Tests', () {
    // 1. READY state renders initial message and HUD
    testWidgets('1. READY state renders initial screen and HUD without overflow', (WidgetTester tester) async {
      final controller = MemoryController(vsync: tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemoryDisplayView(
              controller: controller,
              width: 270,
              height: 228,
            ),
          ),
        ),
      );

      expect(find.text('LV 01'), findsOneWidget);
      expect(find.text('SCORE 000000'), findsOneWidget);
      expect(find.text('COMBO X00'), findsOneWidget);
      expect(find.text('LIFE O O O'), findsOneWidget);
      expect(find.text('MEMORY TRAINING\n\nPRESS START TO BEGIN'), findsOneWidget);
      expect(find.text('<ABORT'), findsOneWidget);

      expect(tester.takeException(), isNull);
      controller.dispose();
    });

    // 2. MEMORIZING state renders target sequence and progress bar
    testWidgets('2. MEMORIZING state renders sequence and MEMORIZE SEQUENCE tag', (WidgetTester tester) async {
      final engine = MemoryEngine(random: Random(100));
      final controller = MemoryController(vsync: tester, engine: engine);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemoryDisplayView(
              controller: controller,
              width: 270,
              height: 228,
            ),
          ),
        ),
      );

      controller.start();
      await tester.pump();

      expect(find.text('MEMORIZE SEQUENCE'), findsOneWidget);
      final target = controller.session.targetSequence;
      expect(find.text(target), findsOneWidget);

      expect(tester.takeException(), isNull);
      controller.dispose();
    });

    // 3. RECALLING state masks unentered characters
    testWidgets('3. RECALLING state masks unentered characters and shows [ _ _ _ ]', (WidgetTester tester) async {
      final engine = MemoryEngine(random: Random(100));
      final controller = MemoryController(vsync: tester, engine: engine);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemoryDisplayView(
              controller: controller,
              width: 270,
              height: 228,
            ),
          ),
        ),
      );

      controller.start();
      // Advance until recalling
      for (int i = 0; i < 75; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(controller.isRecalling, isTrue);

      expect(find.text('RECALL & ENTER'), findsOneWidget);
      expect(find.text('ENTERED: 0 / 3'), findsOneWidget);

      // Enter first character
      final target = controller.session.targetSequence;
      controller.handleKeyEvent(MCDUKeyEvent(keyId: target[0]));
      await tester.pump();

      expect(find.text('ENTERED: 1 / 3'), findsOneWidget);

      expect(tester.takeException(), isNull);
      controller.dispose();
    });

    // 4. PAUSED state overlay
    testWidgets('4. PAUSED overlay renders correctly', (WidgetTester tester) async {
      final controller = MemoryController(vsync: tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemoryDisplayView(
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

      expect(find.text('PAUSED\n\nPRESS 6R TO RESUME'), findsOneWidget);
      expect(find.text('RESUME>'), findsOneWidget);

      expect(tester.takeException(), isNull);
      controller.dispose();
    });

    // 5. GAME OVER state debrief
    testWidgets('5. GAME OVER screen renders final stats and controls', (WidgetTester tester) async {
      final engine = MemoryEngine(random: Random(100));
      final controller = MemoryController(vsync: tester, engine: engine);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemoryDisplayView(
              controller: controller,
              width: 270,
              height: 228,
            ),
          ),
        ),
      );

      controller.start();
      for (int i = 0; i < 75; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(controller.isRecalling, isTrue);

      final target = controller.session.targetSequence;
      final wrongChar = target[0] == 'A' ? 'B' : 'A';

      // 3 wrong inputs -> Game over
      controller.handleKeyEvent(MCDUKeyEvent(keyId: wrongChar));
      controller.handleKeyEvent(MCDUKeyEvent(keyId: wrongChar));
      controller.handleKeyEvent(MCDUKeyEvent(keyId: wrongChar));
      await tester.pump();

      expect(find.text('GAME OVER'), findsOneWidget);
      expect(find.text('LEVEL REACHED: LV 01'), findsOneWidget);
      expect(find.text('ROUNDS CLEARED: 0'), findsOneWidget);
      expect(find.text('<ABORT       RETRY>'), findsOneWidget);

      expect(tester.takeException(), isNull);
      controller.dispose();
    });

    // 6. Responsive aspect ratio without overflow
    testWidgets('6. Responsive test maintains 707:961 MCDU aspect ratio without overflow', (WidgetTester tester) async {
      final controller = MemoryController(vsync: tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AspectRatio(
                aspectRatio: 707 / 961,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return MemoryDisplayView(
                      controller: controller,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
      controller.dispose();
    });
  });
}
