// test/memory_mcdu_integration_test.dart
// Phase 17D — Memory Game MCDU Integration Tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/app/app.dart';
import 'package:mcdu_app/features/game/memory/presentation/memory_display_view.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_screen.dart';

void main() {
  group('Phase 17D Memory Game MCDU Integration Tests', () {
    // Helper: navigate to GAME page from MENU
    Future<MCDUKeypadOverlay> navigateToGame(WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();
      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L')); // MENU -> GAME
      await tester.pumpAndSettle();
      return overlay;
    }

    // 1. MCDU MENU -> GAME using 4L
    testWidgets('1. MCDU MENU navigates to GAME page via 4L', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      expect(find.text('MCDU GAME MENU'), findsOneWidget);
      expect(find.text('<MEMORY'), findsOneWidget);
      expect(overlay, isNotNull);
    });

    // 2. GAME -> MEMORY using 3L
    testWidgets('2. Pressing 3L on GAME page enters Memory Game mode', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      expect(find.text('MCDU GAME MENU'), findsNothing);
      expect(find.byType(MemoryDisplayView), findsOneWidget);
    });

    // 3. Memory READY appears inside MCDU shell
    testWidgets('3. Memory READY screen renders inside MCDU shell', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      expect(find.text('MEMORY TRAINING\n\nPRESS START TO BEGIN'), findsOneWidget);
      expect(find.byType(MCDUScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 4. 6R starts MEMORY from READY state
    testWidgets('4. 6R in READY state starts game → MEMORIZING', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      expect(find.text('MEMORY TRAINING\n\nPRESS START TO BEGIN'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // start()
      await tester.pump();

      expect(find.text('MEMORY TRAINING\n\nPRESS START TO BEGIN'), findsNothing);
      expect(find.text('MEMORIZE SEQUENCE'), findsOneWidget);
    });

    // 5. MEMORIZING state appears correctly
    testWidgets('5. MEMORIZING state shows MEMORIZE SEQUENCE label', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // start
      await tester.pump();

      expect(find.text('MEMORIZE SEQUENCE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 6. Presentation progresses to RECALLING using deterministic test timing
    testWidgets('6. Presentation countdown elapses → RECALLING state', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // start
      await tester.pump();

      expect(find.text('MEMORIZE SEQUENCE'), findsOneWidget);

      // Advance clock by 4 seconds (level-1 presentation = 3.5s)
      for (int i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('RECALL & ENTER'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 7. Alphanumeric gameplay key reaches MemoryController
    testWidgets('7. Physical alphanumeric key is forwarded to MemoryController', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();
      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // start
      await tester.pump();

      // Capture target sequence text shown in MEMORIZE SEQUENCE state
      // The sequence is rendered as a large Text widget in the display
      // It is the only Text widget visible that is purely alphanumeric 3 chars
      // Use the MemoryDisplayView controller to get it
      final memoryView = tester.widget<MemoryDisplayView>(find.byType(MemoryDisplayView));
      final targetSeq = memoryView.controller.session.targetSequence;
      expect(targetSeq.length, equals(3)); // Level 1 sequence is 3 chars

      // Advance to RECALLING (level-1 = 3.5s)
      for (int i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('RECALL & ENTER'), findsOneWidget);
      expect(find.text('ENTERED: 0 / 3'), findsOneWidget);

      // Send the correct first character of the target sequence
      overlay.onKeyPressed(MCDUKeyEvent(keyId: targetSeq[0]));
      await tester.pump();

      // inputBuffer advanced 0 -> 1 — key was received and processed by MemoryController
      expect(find.text('ENTERED: 1 / 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 8. Normal MCDU input is blocked while Memory is active
    testWidgets('8. MCDU navigation keys are blocked during active Memory Game', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // start
      await tester.pump();

      // Fire hardware nav key MENU — must not trigger page change
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'MENU'));
      await tester.pump();

      expect(find.text('MEMORIZE SEQUENCE'), findsOneWidget);
      expect(find.text('MCDU MENU'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    // 9. 6R pauses during MEMORIZING
    testWidgets('9. 6R pauses the game during MEMORIZING', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // start
      await tester.pump();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // pause
      await tester.pump();

      expect(find.text('PAUSED\n\nPRESS 6R TO RESUME'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 10. 6R resumes after pause
    testWidgets('10. 6R resumes game from PAUSED state', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // start
      await tester.pump();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // pause
      await tester.pump();

      expect(find.text('PAUSED\n\nPRESS 6R TO RESUME'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // resume
      await tester.pump();

      expect(find.text('PAUSED\n\nPRESS 6R TO RESUME'), findsNothing);
      expect(find.text('MEMORIZE SEQUENCE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 11. 6L exits Memory and returns to GAME MENU
    testWidgets('11. 6L exits Memory Game and returns to MCDU GAME MENU', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // start
      await tester.pump();
      expect(find.text('MEMORIZE SEQUENCE'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L')); // abort
      await tester.pumpAndSettle();

      expect(find.text('MCDU GAME MENU'), findsOneWidget);
      expect(find.byType(MemoryDisplayView), findsNothing);
      expect(tester.takeException(), isNull);
    });

    // 12. Memory controller cleanup — no ticker leaks after exit
    testWidgets('12. Memory controller cleanup — no ticker leaks after exit', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // start
      await tester.pump();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L')); // exit
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });

    // 13. Re-entering Memory starts a clean READY session
    testWidgets('13. Re-entering Memory via 3L creates a clean READY session', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);

      // First entry
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // start
      await tester.pump();
      expect(find.text('MEMORIZE SEQUENCE'), findsOneWidget);

      // Exit
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();
      expect(find.text('MCDU GAME MENU'), findsOneWidget);

      // Re-enter
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      // Must be in READY state again
      expect(find.text('MEMORY TRAINING\n\nPRESS START TO BEGIN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 14. 1L Typing Test remains functional
    testWidgets('14. 1L Typing Test still works after Memory integration', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      expect(find.text('TYPING TEST'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 15. 2L Falling Code remains functional
    testWidgets('15. 2L Falling Code still works after Memory integration', (WidgetTester tester) async {
      final overlay = await navigateToGame(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      // MCDU GAME MENU disappears — Falling Code display takes over
      expect(find.text('MCDU GAME MENU'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
