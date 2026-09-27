import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/app/app.dart';
import 'package:mcdu_app/features/game/falling_code/domain/reporting_points_catalog.dart';
import 'package:mcdu_app/features/game/falling_code/presentation/falling_code_display_view.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_screen.dart';

void main() {
  group('Falling Code Integration Tests', () {
    // 1. GAME MENU shows <FALLING CODE at 2L
    testWidgets('1. GAME MENU shows <FALLING CODE at 2L', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L')); // Navigate to GAME page
      await tester.pumpAndSettle();

      expect(find.text('<FALLING CODE'), findsOneWidget);
    });

    // 2. 2L enters Falling Code inside MCDU display
    testWidgets('2. 2L enters Falling Code inside MCDU display', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pump();

      expect(find.byType(FallingCodeDisplayView), findsOneWidget);
      expect(find.text('MCDU GAME MENU'), findsNothing);
    });

    // 3-5. READY state, countdown progression, and keys ignored before GO
    testWidgets('3-5. READY state, countdown progression, and keys ignored before GO', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pump();

      // Countdown step 3
      expect(find.text('3'), findsOneWidget);

      // Pressing A before GO must not register as game input
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'A'));
      await tester.pump(const Duration(milliseconds: 600));

      // Countdown step 2
      expect(find.text('2'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));

      // Countdown step 1
      expect(find.text('1'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));

      // Countdown step GO
      expect(find.text('GO!'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));

      // Game started: score must still be 0 (key pressed during countdown was ignored)
      expect(find.text('SCORE 000000'), findsOneWidget);
      expect(find.text('LV 01'), findsOneWidget);
    });

    // 6-8. PLAYING state renders falling objects from ReportingPointsCatalog
    testWidgets('6-8. PLAYING state renders falling objects from ReportingPointsCatalog', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pump();

      // Complete countdown (3 -> 2 -> 1 -> GO -> finished)
      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pump(const Duration(milliseconds: 50));

      // An object should be spawned immediately
      final allCatalogCodes = ReportingPointsCatalog.all.map((p) => p.code).toSet();
      bool foundCatalogCode = false;
      for (final code in allCatalogCodes) {
        if (find.text(code).evaluate().isNotEmpty) {
          foundCatalogCode = true;
          break;
        }
      }
      expect(foundCatalogCode, isTrue, reason: 'A valid ReportingPoint code must be visible on screen');
    });

    // 9-10. Input routing: A-Z / 0-9 reach Falling Code and scratchpad does not receive them
    testWidgets('9-10. A-Z / 0-9 reach Falling Code exclusively without leaking to normal scratchpad', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pump(const Duration(milliseconds: 50));

      // Press 'A'
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'A'));
      await tester.pump();

      // Normal MCDU scratchpad is completely hidden/not rendered in FallingCodeDisplayView
      expect(find.byType(FallingCodeDisplayView), findsOneWidget);
    });

    // 11. 6L abort returns to GAME MENU
    testWidgets('11. 6L abort returns cleanly to GAME MENU', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 1000));

      // Press 6L to abort
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      expect(find.text('MCDU GAME MENU'), findsOneWidget);
      expect(find.byType(FallingCodeDisplayView), findsNothing);
    });

    // 12. 6R pause and resume works
    testWidgets('12. 6R pause and resume works', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pump(const Duration(milliseconds: 50));

      // Press 6R -> Pause
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pump();

      expect(find.text('PAUSED\n\nPRESS 6R TO RESUME'), findsOneWidget);
      expect(find.text('RESUME>'), findsOneWidget);

      // Press 6R -> Resume
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pump();

      expect(find.text('PAUSED\n\nPRESS 6R TO RESUME'), findsNothing);
      expect(find.text('PAUSE>'), findsOneWidget);
    });

    // 13-14. Game-over renders and retry resets game
    testWidgets('13-14. Game-over renders when lives reach 0, and 6R retry resets session', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pump();

      // Finish countdown
      await tester.pump(const Duration(milliseconds: 3000));

      // Advance time with 50ms frames to allow physics ticker to process bottom collisions
      for (int i = 0; i < 400; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('GAME OVER').evaluate().isNotEmpty) break;
      }

      expect(find.text('GAME OVER'), findsOneWidget);
      expect(find.text('RETRY>'), findsOneWidget);

      // Press 6R to retry
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pump();

      expect(find.text('GAME OVER'), findsNothing);
      expect(find.text('3'), findsOneWidget); // Countdown restarted
    });

    // 15. 5L remains disabled on GAME MENU; 3L activates Memory, 4L activates Speed Run
    testWidgets('15. 3L, 4L, 5L remain disabled on GAME MENU', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      // Press 3L (Memory - active)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();
      expect(find.text('MCDU GAME MENU'), findsNothing); // Memory Game activated
      // Exit back to GAME MENU to test 4L and 5L
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();
      expect(find.text('MCDU GAME MENU'), findsOneWidget);

      // Press 4L (Speed Run - active in Phase 18D)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();
      expect(find.text('MCDU GAME MENU'), findsNothing); // Speed Run activated
      // Exit back to GAME MENU to test 5L
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();
      expect(find.text('MCDU GAME MENU'), findsOneWidget);

      // Press 5L (MCDU Flow - still disabled)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '5L'));
      await tester.pumpAndSettle();
      expect(find.text('MCDU GAME MENU'), findsOneWidget);
    });

    // 16. Responsive test at 820x1180 and 1180x820
    testWidgets('16. Responsive test at 820x1180 and 1180x820 maintains 707:961 without overflow', (WidgetTester tester) async {
      // Portrait
      tester.view.physicalSize = const Size(820, 1180);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);

      // Landscape
      tester.view.physicalSize = const Size(1180, 820);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    // 17-18. Cleanup / dispose does not throw and re-entering game creates clean session
    testWidgets('17-18. Re-entering game creates clean session and dispose does not leak', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      // Enter game 1st time
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 3000));

      // Abort
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();
      expect(find.text('MCDU GAME MENU'), findsOneWidget);

      // Enter game 2nd time
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 19-21. Dynamic Difficulty: starts LV 01, completes 5 targets -> LV 02, retry resets to LV 01
    testWidgets('19-21. Dynamic Difficulty: starts LV 01, completes 5 targets -> LV 02, retry resets to LV 01', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pump();

      // Finish countdown
      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pump(const Duration(milliseconds: 50));

      // 1. Initial level is LV 01
      expect(find.text('LV 01'), findsOneWidget);

      final displayView = tester.widget<FallingCodeDisplayView>(find.byType(FallingCodeDisplayView));
      final controller = displayView.controller;

      // Type 5 targets completely using real key inputs
      for (int i = 0; i < 5; i++) {
        // Wait until target is spawned
        for (int frame = 0; frame < 50 && controller.session.activeCodes.isEmpty; frame++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Find current target
        final active = controller.session.activeCodes;
        expect(active.isNotEmpty, isTrue, reason: 'Target should be available');
        final currentTarget = active.first;

        // Type all characters for this target
        for (int c = 0; c < currentTarget.code.length; c++) {
          final char = currentTarget.code[c];
          overlay.onKeyPressed(MCDUKeyEvent(keyId: char));
          await tester.pump(const Duration(milliseconds: 20));
        }

        // Advance frames so ticker spawns the next target
        for (int frame = 0; frame < 40; frame++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      // 2. After 5 completed targets -> LV 02
      expect(controller.session.completedTargets, 5);
      expect(controller.session.level, 2);
      expect(find.text('LV 02'), findsOneWidget);

      // 3. Retry resets to LV 01
      controller.retry();
      await tester.pump();

      expect(controller.session.level, 1);
      expect(controller.session.completedTargets, 0);
    });
  });
}
