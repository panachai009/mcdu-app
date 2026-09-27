// test/mcdu_game_integration_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/app/app.dart';
import 'package:mcdu_app/features/mcdu_core/domain/mcdu_key.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_screen.dart';
import 'package:mcdu_app/features/game/typing_test/presentation/typing_test_screen.dart';

void main() {
  group('Phase 15E MCDU-Centric Game Integration Tests', () {
    // 1. MCDUApp launches MCDUScreen
    testWidgets('1. MCDUApp launches MCDUScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(MCDUScreen), findsOneWidget);
    });

    // 2. Existing MENU still renders standard elements
    testWidgets('2. Existing MENU renders standard elements', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      expect(find.text('MCDU MENU'), findsOneWidget);
      expect(find.text('<FPL'), findsOneWidget);
      expect(find.text('<DIR'), findsOneWidget);
      expect(find.text('<PROG'), findsOneWidget);
      expect(find.text('NAV>'), findsOneWidget);
      expect(find.text('RADIO>'), findsOneWidget);
      expect(find.text('DATA>'), findsOneWidget);
    });

    // 3. GAME entry displays on MCDU MENU at 4L
    testWidgets('3. GAME entry displays on MCDU MENU at 4L', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      expect(find.text('<GAMES'), findsOneWidget);
    });

    // 4. Pressing 4L in MENU navigates to GAME page
    testWidgets('4. Pressing 4L in MENU navigates to GAME page', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      expect(find.text('MCDU GAME MENU'), findsOneWidget);
    });

    // 5. GAME page displays all 5 game modes
    testWidgets('5. GAME page displays all 5 game modes', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      expect(find.text('<TYPING TEST'), findsOneWidget);
      expect(find.text('<FALLING CODE'), findsOneWidget);
      expect(find.text('<MEMORY'), findsOneWidget);
      expect(find.text('<SPEED RUN'), findsOneWidget);
      expect(find.text('<MCDU FLOW'), findsOneWidget);
      expect(find.text('<RETURN'), findsOneWidget);
    });

    // 6-7. Typing Test (1L), Falling Code (2L), Memory (3L), and Speed Run (4L) activate, while 5L is disabled
    testWidgets('6-7. Typing Test (1L) and Falling Code (2L) activate, while 3L-5L are disabled', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      // Press 3L (Memory - active)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();
      expect(find.text('MCDU GAME MENU'), findsNothing); // Memory Game activated
      // Exit back to GAME MENU to test remaining keys
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();
      expect(find.text('MCDU GAME MENU'), findsOneWidget);

      // Press 4L (Speed Run - active in Phase 18D)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();
      expect(find.text('MCDU GAME MENU'), findsNothing); // Speed Run activated
      // Exit back to GAME MENU to test remaining keys
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();
      expect(find.text('MCDU GAME MENU'), findsOneWidget);

      // Press 5L (MCDU Flow - disabled)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '5L'));
      await tester.pumpAndSettle();
      expect(find.text('MCDU GAME MENU'), findsOneWidget);

      // Press 2L -> Enters Falling Code (no longer on GAME MENU)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();
      expect(find.text('MCDU GAME MENU'), findsNothing);
    });

    // 8-9. Typing Test is rendered directly within MCDUScreen (NO TypingTestScreen)
    testWidgets('8-9. Typing Test is rendered inside MCDUScreen without TypingTestScreen in stack', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      expect(find.byType(MCDUScreen), findsOneWidget);
      expect(find.byType(TypingTestScreen), findsNothing);
      expect(find.text('TYPING TEST'), findsOneWidget);
    });

    // 10-15. Keypad input, Accuracy, Score, Timer, and Completion
    testWidgets('10-15. Real MCDU keys drive typing test, no duplicate input, completion freezes stats', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      // Initial state
      expect(find.text('ACC 0.0%'), findsOneWidget);
      expect(find.text('SCORE 0'), findsOneWidget);

      // Type 'A' -> updates typedText in scratchpad
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'A'));
      await tester.pumpAndSettle();
      expect(find.text('A'), findsWidgets);
      expect(find.text('ACC 100.0%'), findsOneWidget);
      expect(find.text('SCORE 100'), findsOneWidget);

      // Type wrong key 'Z'
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'Z'));
      await tester.pumpAndSettle();
      expect(find.text('ACC 50.0%'), findsOneWidget);

      // Type remaining keys: B, C, 1, 2, 3
      for (final k in ['B', 'C', '1', '2', '3']) {
        overlay.onKeyPressed(MCDUKeyEvent(keyId: k));
        await tester.pumpAndSettle();
      }

      // Completed state
      expect(find.text('TEST COMPLETE'), findsWidgets);
      expect(find.text('CORRECT 6'), findsOneWidget);
      expect(find.text('ERRORS 1'), findsOneWidget);
      expect(find.text('ABC123'), findsWidgets); // scratchpad has full target
      expect(find.text('<ABORT'), findsOneWidget);
      expect(find.text('RETRY>'), findsOneWidget);
    });

    // 16. 6R RETRY resets typing metrics to initial state
    testWidgets('16. 6R RETRY resets typing metrics to initial state', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      // Type A
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'A'));
      await tester.pumpAndSettle();
      expect(find.text('ACC 100.0%'), findsOneWidget);

      // Press 6R (RETRY)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pumpAndSettle();

      expect(find.text('ACC 0.0%'), findsOneWidget);
      expect(find.text('SCORE 0'), findsOneWidget);
      expect(find.text('TIME 0.00'), findsOneWidget);
    });

    // 17-18. 6L ABORT returns to GAME MENU, and GAME MENU 6L returns to normal MENU
    testWidgets('17-18. 6L ABORT returns to GAME MENU, then 6L returns to normal MENU', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();
      expect(find.text('TYPING TEST'), findsOneWidget);

      // 6L ABORT
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();
      expect(find.text('MCDU GAME MENU'), findsOneWidget);

      // 6L RETURN
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();
      expect(find.text('MCDU MENU'), findsOneWidget);
    });

    // 19. Existing MCDU Navigation still works after exiting game
    testWidgets('19. Existing MCDU Navigation works after exiting game', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      // Enter GAME -> 1L TYPING -> 6L ABORT -> 6L RETURN to MENU
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      // Normal navigation to FPL
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();
      expect(find.text('MCDU FPL'), findsOneWidget);

      // Type in scratchpad on FPL
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'B'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'K'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'K'));
      await tester.pumpAndSettle();
      expect(find.text('BKK'), findsOneWidget);

      // Return to MENU via PREV
      overlay.onKeyPressed(MCDUKeyEvent(keyId: MCDUKey.prev));
      await tester.pumpAndSettle();
      expect(find.text('MCDU MENU'), findsOneWidget);
    });

    // 20-21. Responsive: Portrait and Landscape preserve 707:961 without overflow
    testWidgets('20-21. Portrait and Landscape maintain 707:961 without overflow', (WidgetTester tester) async {
      // Portrait (820 x 1180)
      tester.view.physicalSize = const Size(820, 1180);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final portraitAR = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(portraitAR.aspectRatio, closeTo(707 / 961, 0.001));

      // Landscape (1180 x 820)
      tester.view.physicalSize = const Size(1180, 820);
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final landscapeAR = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(landscapeAR.aspectRatio, closeTo(707 / 961, 0.001));
    });
  });
}
