// test/typing_test_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_screen.dart';
import 'package:mcdu_app/features/game/typing_test/presentation/typing_test_screen.dart';
import 'package:mcdu_app/features/game/typing_test/presentation/typing_test_status_panel.dart';

void main() {
  group('Phase 14A & 14B TypingTestScreen Widget Tests', () {
    // 1. TypingTestScreen renders
    testWidgets('1. TypingTestScreen renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TypingTestScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TypingTestScreen), findsOneWidget);
      expect(find.byType(TypingTestStatusPanel), findsOneWidget);
      expect(find.byType(MCDUScreen), findsOneWidget);
    });

    // 2. Initial state shows READY, 00.00s time, 0.0% accuracy
    testWidgets('2. Initial state shows READY, 00.00s time, 0.0% accuracy', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TypingTestScreen()));
      await tester.pumpAndSettle();

      expect(find.text('READY'), findsOneWidget);
      expect(find.text('00.00s'), findsOneWidget);
      expect(find.text('0.0%'), findsOneWidget);
    });

    // 3. Target ABC123 is visible
    testWidgets('3. Target ABC123 is visible', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TypingTestScreen()));
      await tester.pumpAndSettle();

      expect(find.text('ABC123'), findsOneWidget);
    });

    // 4. typed text initially empty
    testWidgets('4. typed text initially empty', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TypingTestScreen()));
      await tester.pumpAndSettle();

      // Displays '-' when typed text is empty
      expect(find.text('-'), findsOneWidget);
    });

    // 5. correct/error counters initially 0
    testWidgets('5. correct/error counters initially 0', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TypingTestScreen()));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsNWidgets(2)); // Correct: 0, Errors: 0
    });

    // 6. START changes state to PLAYING
    testWidgets('6. START changes state to PLAYING', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TypingTestScreen()));
      await tester.pumpAndSettle();

      final startBtn = find.widgetWithText(ElevatedButton, 'START');
      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      expect(find.text('PLAYING'), findsOneWidget);
    });

    // 7-13. Real MCDU Keypad input A,B,C,1,2,3 completes test with accuracy, time, score
    testWidgets('7-13. Real MCDU Keypad input A,B,C,1,2,3 completes test with accuracy, time, score', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TypingTestScreen()));
      await tester.pumpAndSettle();

      // Start game
      await tester.tap(find.widgetWithText(ElevatedButton, 'START'));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      final typedDisplay = find.byKey(const Key('typed_text_display'));

      // 7. A updates typed text & accuracy (1/1 = 100.0%)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'A'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(typedDisplay).data, 'A');
      expect(find.text('1'), findsOneWidget); // Correct: 1
      expect(find.text('100.0%'), findsOneWidget);

      // 8. B updates typed text
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'B'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(typedDisplay).data, 'AB');

      // 9. C updates typed text
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'C'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(typedDisplay).data, 'ABC');

      // 10. 1 updates typed text
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(typedDisplay).data, 'ABC1');

      // 11. 2 updates typed text
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(typedDisplay).data, 'ABC12');

      // 12. 3 completes the test
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3'));
      await tester.pumpAndSettle();

      // 13. completion displays COMPLETE, TEST COMPLETE banner, final score, and 100.0% accuracy
      expect(find.text('COMPLETE'), findsOneWidget);
      expect(find.text('TEST COMPLETE'), findsOneWidget);
      expect(find.byKey(const Key('completion_score_display')), findsOneWidget);
      expect(tester.widget<Text>(typedDisplay).data, 'ABC123');
      expect(find.text('6'), findsOneWidget); // Correct: 6
      expect(find.text('100.0%'), findsOneWidget);
    });

    // 14-15. Wrong key increments errors, calculates accuracy accurately, does not change typed text
    testWidgets('14-15. Wrong key increments errors, updates accuracy, and does not change typed text', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TypingTestScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'START'));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      final typedDisplay = find.byKey(const Key('typed_text_display'));

      // Correct A (1/1 = 100%)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'A'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(typedDisplay).data, 'A');
      expect(find.text('100.0%'), findsOneWidget);

      // Wrong key X (1 correct, 1 error -> 1/2 = 50.0%)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'X'));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(typedDisplay).data, 'A'); // Still 'A'
      expect(find.text('1'), findsNWidgets(2)); // Correct: 1, Errors: 1
      expect(find.text('50.0%'), findsOneWidget);
    });

    // 16-18. RESET / RESTART returns to READY and clears all metrics
    testWidgets('16-18. RESET / RESTART returns to READY and clears typed text, timer, and counters', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TypingTestScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'START'));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'A'));
      await tester.pumpAndSettle();

      // Tap RESET
      await tester.tap(find.widgetWithText(ElevatedButton, 'RESET'));
      await tester.pumpAndSettle();

      expect(find.text('READY'), findsOneWidget);
      expect(find.text('00.00s'), findsOneWidget);
      expect(find.text('0.0%'), findsOneWidget);
      expect(find.text('-'), findsOneWidget); // Typed text cleared
      expect(find.text('0'), findsNWidgets(2)); // Both counters reset to 0
    });

    // 19. RESTART button on completion resets cleanly
    testWidgets('19. RESTART button on completion resets cleanly to READY', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TypingTestScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'START'));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      for (final k in ['A', 'B', 'C', '1', '2', '3']) {
        overlay.onKeyPressed(MCDUKeyEvent(keyId: k));
        await tester.pumpAndSettle();
      }

      expect(find.text('COMPLETE'), findsOneWidget);

      final restartBtn = find.widgetWithText(ElevatedButton, 'RESTART');
      expect(restartBtn, findsOneWidget);
      await tester.tap(restartBtn);
      await tester.pumpAndSettle();

      expect(find.text('READY'), findsOneWidget);
      expect(find.text('00.00s'), findsOneWidget);
      expect(find.text('0.0%'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
    });

    // 20-21. Responsive layout in portrait and landscape preserves 707:961 aspect ratio without overflow
    testWidgets('20-21. Responsive layout in portrait and landscape preserves 707:961 aspect ratio without overflow', (WidgetTester tester) async {
      // Portrait (820 x 1180)
      tester.view.physicalSize = const Size(820, 1180);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: TypingTestScreen()));
      await tester.pumpAndSettle();

      final aspectRatios = tester.widgetList<AspectRatio>(find.byType(AspectRatio));
      for (final ar in aspectRatios) {
        expect(ar.aspectRatio, closeTo(707 / 961, 0.001));
      }

      // Landscape (1180 x 820)
      tester.view.physicalSize = const Size(1180, 820);
      await tester.pumpWidget(const MaterialApp(home: TypingTestScreen()));
      await tester.pumpAndSettle();

      final landscapeAspectRatios = tester.widgetList<AspectRatio>(find.byType(AspectRatio));
      for (final ar in landscapeAspectRatios) {
        expect(ar.aspectRatio, closeTo(707 / 961, 0.001));
      }
    });
  });
}
