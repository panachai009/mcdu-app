// test/speed_run_mcdu_integration_test.dart
// Phase 18D — Speed Run MCDU Integration Tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/app/app.dart';
import 'package:mcdu_app/features/game/speed_run/presentation/speed_run_display_view.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_screen.dart';

void main() {
  group('Phase 18D Speed Run MCDU Integration Tests', () {
    // Helper: navigate to GAME page from MENU
    Future<MCDUKeypadOverlay> navigateToGame(WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();
      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L')); // MENU -> GAME
      await tester.pumpAndSettle();
      return overlay;
    }

    // 1. GAME page has 4L Speed Run
    testWidgets('1. GAME page has 4L <SPEED RUN label', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      expect(find.text('MCDU GAME MENU'), findsOneWidget);
      expect(find.text('<SPEED RUN'), findsOneWidget);
      expect(overlay, isNotNull);
    });

    // 2. 4L launches Speed Run inside MCDU display
    testWidgets('2. Pressing 4L on GAME page enters Speed Run mode', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      expect(find.text('MCDU GAME MENU'), findsNothing);
      expect(find.byType(SpeedRunDisplayView), findsOneWidget);
      expect(find.byType(MCDUScreen), findsOneWidget);
    });

    // 3. Speed Run starts in READY state (does not auto-start)
    testWidgets('3. Speed Run starts in READY state with START button', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      expect(find.text('SPEED RUN\nPROCEDURAL FLOW'), findsOneWidget);
      expect(find.text('START>'), findsOneWidget);
      expect(find.text('<ABORT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 4. 6R in READY state transitions to PLAYING
    testWidgets('4. 6R in READY state transitions to PLAYING', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // START
      await tester.pump();

      expect(find.text('SPEED RUN\nPROCEDURAL FLOW'), findsNothing);
      expect(find.text('PAUSE>'), findsOneWidget);
      expect(find.text('DIRECT TO BKK'), findsOneWidget);
    });

    // 5-7. Gameplay keys reach SpeedRunController, correct key advances, wrong key increments error
    testWidgets('5-7. Gameplay keys reach Speed Run: correct advances step, wrong increments error', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // START
      await tester.pump();

      final speedRunView = tester.widget<SpeedRunDisplayView>(find.byType(SpeedRunDisplayView));
      final controller = speedRunView.controller;

      expect(controller.isPlaying, isTrue);
      expect(controller.session.currentStepIndex, 0);
      expect(controller.session.errors, 0);

      // Wrong key: press 'Z' when expected is 'DIR'
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'Z'));
      await tester.pump();

      expect(controller.session.errors, 1);
      expect(controller.session.currentStepIndex, 0);

      // Correct key: press 'DIR'
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'DIR'));
      await tester.pump();

      expect(controller.session.currentStepIndex, 1);
      expect(controller.session.combo, 1);
      expect(tester.takeException(), isNull);
    });

    // 8. 6R PLAYING -> PAUSED
    testWidgets('8. 6R pauses game during PLAYING state', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // START
      await tester.pump();

      final speedRunView = tester.widget<SpeedRunDisplayView>(find.byType(SpeedRunDisplayView));
      expect(speedRunView.controller.isPlaying, isTrue);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // PAUSE
      await tester.pump();

      expect(speedRunView.controller.isPaused, isTrue);
      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('RESUME>'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 9. 6R PAUSED -> PLAYING
    testWidgets('9. 6R resumes game from PAUSED state', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // START
      await tester.pump();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // PAUSE
      await tester.pump();

      final speedRunView = tester.widget<SpeedRunDisplayView>(find.byType(SpeedRunDisplayView));
      expect(speedRunView.controller.isPaused, isTrue);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // RESUME
      await tester.pump();

      expect(speedRunView.controller.isPlaying, isTrue);
      expect(find.text('PAUSED'), findsNothing);
      expect(find.text('PAUSE>'), findsOneWidget);
    });

    // 10-12. Input isolation: MENU, PREV, NEXT, FPL, DIR do NOT navigate normal MCDU
    testWidgets('10-12. Normal MCDU keys do not leak while Speed Run is active', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // START
      await tester.pump();

      // Press MENU - must NOT navigate back to normal MCDU MENU
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'MENU'));
      await tester.pump();
      expect(find.text('MCDU MENU'), findsNothing);
      expect(find.byType(SpeedRunDisplayView), findsOneWidget);

      // Press PREV / NEXT - must NOT navigate normal MCDU pages
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'PREV'));
      await tester.pump();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NEXT'));
      await tester.pump();
      expect(find.byType(SpeedRunDisplayView), findsOneWidget);

      // Press FPL - must NOT navigate to Flight Plan page
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'FPL'));
      await tester.pump();
      expect(find.byType(SpeedRunDisplayView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 13. 6L exits to GAME menu
    testWidgets('13. 6L exits Speed Run and returns cleanly to MCDU GAME MENU', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // START
      await tester.pump();
      expect(find.byType(SpeedRunDisplayView), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L')); // ABORT
      await tester.pumpAndSettle();

      expect(find.text('MCDU GAME MENU'), findsOneWidget);
      expect(find.byType(SpeedRunDisplayView), findsNothing);
      expect(tester.takeException(), isNull);
    });

    // 14. Controller is disposed after exit with no ticker leaks
    testWidgets('14. Controller is disposed after exit with no ticker leaks', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // START
      await tester.pump();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L')); // ABORT
      await tester.pumpAndSettle();

      // Dispose entire widget tree -> must be clean without orphan animation
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });

    // 15-17. Re-entering Speed Run creates a clean session, no duplicate controller
    testWidgets('15-17. Re-entering Speed Run creates clean session without duplicate listeners', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);

      // First run: complete Task 1 (DIR -> B -> K -> K -> 1L) to advance to LV 02
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // START
      await tester.pump();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'DIR'));
      await tester.pump();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'B'));
      await tester.pump();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'K'));
      await tester.pump();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'K'));
      await tester.pump();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pump();

      // Verify task completed and difficulty advanced to LV 02 in first run
      final firstRunView = tester.widget<SpeedRunDisplayView>(find.byType(SpeedRunDisplayView));
      expect(firstRunView.controller.session.completedTasks, 1);
      expect(firstRunView.controller.session.difficultyLevel, 2);

      // Exit via 6L ABORT
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();
      expect(find.text('MCDU GAME MENU'), findsOneWidget);

      // Re-enter Speed Run
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      // Must be back in clean READY state with difficultyLevel reset to 1
      final speedRunView = tester.widget<SpeedRunDisplayView>(find.byType(SpeedRunDisplayView));
      expect(speedRunView.controller.isReady, isTrue);
      expect(speedRunView.controller.session.difficultyLevel, 1);
      expect(speedRunView.controller.session.completedTasks, 0);
      expect(speedRunView.controller.session.currentTaskIndex, 0);
      expect(speedRunView.controller.session.currentStepIndex, 0);
      expect(find.text('SPEED RUN\nPROCEDURAL FLOW'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
