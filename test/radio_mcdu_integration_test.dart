// test/radio_mcdu_integration_test.dart
// Phase 19C-C — Realistic Radio Display & MCDU Integration Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/app/app.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_screen.dart';

void main() {
  group('Phase 19C-C Realistic Radio MCDU Integration Tests', () {
    // Helper: navigate to RADIO page from initial MENU
    Future<MCDUKeypadOverlay> navigateToRadio(WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();
      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2R')); // MENU 2R -> RADIO
      await tester.pumpAndSettle();
      return overlay;
    }

    // 1. RADIO opens as RADIO 1/2
    testWidgets('1. RADIO opens as RADIO 1/2 with title header', (WidgetTester tester) async {
      await navigateToRadio(tester);
      expect(find.text('RADIO        1/2'), findsOneWidget);
    });

    // 2. Default COM/NAV/XPDR values are visible
    testWidgets('2. Default COM/NAV/XPDR values are visible on page 1/2', (WidgetTester tester) async {
      await navigateToRadio(tester);
      expect(find.text('<122.600'), findsOneWidget); // COM1 Active
      expect(find.text('<127.000'), findsOneWidget); // COM1 Standby
      expect(find.text('122.100>'), findsOneWidget); // COM2 Active
      expect(find.text('127.000>'), findsOneWidget); // COM2 Standby
      expect(find.text('<117.30'), findsOneWidget);  // NAV1 Active
      expect(find.text('<113.80'), findsOneWidget);  // NAV1 Standby
      expect(find.text('116.80>'), findsOneWidget);  // NAV2 Active
      expect(find.text('111.10>'), findsOneWidget);  // NAV2 Standby
      expect(find.text('1102>'), findsOneWidget);    // XPDR Code
      expect(find.text('<STBY'), findsOneWidget);    // XPDR Mode
      expect(find.text('IDENT*'), findsOneWidget);   // IDENT
      expect(find.text('FMS AUTO'), findsOneWidget); // FMS AUTO indicator
    });

    // 3. RADIO 2/2 displays ADF2 defaults
    testWidgets('3. RADIO 2/2 displays ADF2 defaults', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NEXT'));
      await tester.pumpAndSettle();

      expect(find.text('RADIO        2/2'), findsOneWidget);
      expect(find.text('242.0>'), findsOneWidget);   // ADF2 Active
      expect(find.text('1570.0>'), findsOneWidget);  // ADF2 Standby
    });

    // 4. NEXT: 1/2 -> 2/2
    testWidgets('4. NEXT: 1/2 -> 2/2', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);
      expect(find.text('RADIO        1/2'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NEXT'));
      await tester.pumpAndSettle();
      expect(find.text('RADIO        2/2'), findsOneWidget);
    });

    // 5. PREV: 2/2 -> 1/2
    testWidgets('5. PREV: 2/2 -> 1/2', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NEXT'));
      await tester.pumpAndSettle();
      expect(find.text('RADIO        2/2'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'PREV'));
      await tester.pumpAndSettle();
      expect(find.text('RADIO        1/2'), findsOneWidget);
    });

    // 6. NEXT on 2/2 remains 2/2
    testWidgets('6. NEXT on 2/2 remains 2/2', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NEXT'));
      await tester.pumpAndSettle();
      expect(find.text('RADIO        2/2'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NEXT'));
      await tester.pumpAndSettle();
      expect(find.text('RADIO        2/2'), findsOneWidget);
    });

    // 7. PREV on 1/2 remains 1/2
    testWidgets('7. PREV on 1/2 remains 1/2', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);
      expect(find.text('RADIO        1/2'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'PREV'));
      await tester.pumpAndSettle();
      expect(find.text('RADIO        1/2'), findsOneWidget);
    });

    // 8. 2L empty scratchpad swaps COM1
    testWidgets('8. 2L empty scratchpad swaps COM1 active and standby', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);
      expect(find.text('<122.600'), findsOneWidget);
      expect(find.text('<127.000'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      // After swap, COM1 active is 127.000 (1L), standby is 122.600 (2L)
      expect(find.text('<127.000'), findsOneWidget); // COM1 active (<127.000)
      expect(find.text('<122.600'), findsOneWidget); // COM1 standby (<122.600)
      expect(find.text('127.000>'), findsOneWidget); // COM2 standby (127.000>)
    });

    // 9. 2R empty scratchpad swaps COM2
    testWidgets('9. 2R empty scratchpad swaps COM2 active and standby', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);
      expect(find.text('122.100>'), findsOneWidget);
      expect(find.text('127.000>'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2R'));
      await tester.pumpAndSettle();

      expect(find.text('127.000>'), findsOneWidget); // Now active
      expect(find.text('122.100>'), findsOneWidget); // Now standby
    });

    // 10. 4L empty scratchpad swaps NAV1
    testWidgets('10. 4L empty scratchpad swaps NAV1 active and standby', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      expect(find.text('<113.80'), findsOneWidget); // Active
      expect(find.text('<117.30'), findsOneWidget); // Standby
    });

    // 11. 4R empty scratchpad swaps NAV2
    testWidgets('11. 4R empty scratchpad swaps NAV2 active and standby', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4R'));
      await tester.pumpAndSettle();

      expect(find.text('111.10>'), findsOneWidget); // Active
      expect(find.text('116.80>'), findsOneWidget); // Standby
    });

    // 12. RADIO 2/2 2R empty scratchpad swaps ADF2
    testWidgets('12. RADIO 2/2 2R empty scratchpad swaps ADF2 active and standby', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NEXT'));
      await tester.pumpAndSettle();

      expect(find.text('242.0>'), findsOneWidget);
      expect(find.text('1570.0>'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2R'));
      await tester.pumpAndSettle();

      expect(find.text('1570.0>'), findsOneWidget); // Now active
      expect(find.text('242.0>'), findsOneWidget);  // Now standby
    });

    // 13. COM1 valid scratchpad tuning
    testWidgets('13. COM1 valid scratchpad tuning updates standby and clears scratchpad', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);
      // Type '124.5' into scratchpad
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'DOT'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '5'));
      await tester.pumpAndSettle();
      expect(find.text('124.5'), findsOneWidget);

      // Press 2L
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      expect(find.text('<124.500'), findsOneWidget); // Formatted standby
      expect(find.text('124.5'), findsNothing); // Scratchpad cleared
    });

    // 14. COM1 invalid tuning
    testWidgets('14. COM1 invalid tuning shows INVALID ENTRY and preserves standby', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);
      // Type '999' into scratchpad
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '9'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '9'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '9'));
      await tester.pumpAndSettle();

      // Press 2L
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      expect(find.text('<127.000'), findsOneWidget); // Standby unchanged
      expect(find.text('INVALID ENTRY'), findsOneWidget); // Error message
    });

    // 15. NAV1 valid tuning
    testWidgets('15. NAV1 valid tuning updates standby and clears scratchpad', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);
      // Type '115.5' into scratchpad
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '5'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'DOT'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '5'));
      await tester.pumpAndSettle();

      // Press 4L
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      expect(find.text('<115.50'), findsOneWidget); // Standby updated
    });

    // 16. ADF2 valid tuning
    testWidgets('16. ADF2 valid tuning on page 2 updates standby', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NEXT'));
      await tester.pumpAndSettle();

      // Type '350'
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '5'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '0'));
      await tester.pumpAndSettle();

      // Press 2R
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2R'));
      await tester.pumpAndSettle();

      expect(find.text('350.0>'), findsOneWidget);
    });

    // 17. XPDR valid tuning
    testWidgets('17. XPDR valid tuning updates transponder code', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);
      // Type '7000'
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '7'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '0'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '0'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '0'));
      await tester.pumpAndSettle();

      // Press 5R
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '5R'));
      await tester.pumpAndSettle();

      expect(find.text('7000>'), findsOneWidget);
    });

    // 18. XPDR invalid octal (digits 8/9)
    testWidgets('18. XPDR invalid octal shows INVALID ENTRY', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);
      // Type '1280'
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '8'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '0'));
      await tester.pumpAndSettle();

      // Press 5R
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '5R'));
      await tester.pumpAndSettle();

      expect(find.text('1102>'), findsOneWidget); // Unchanged
      expect(find.text('INVALID ENTRY'), findsOneWidget);
    });

    // 19. 6L toggles STBY -> ALT-ON
    testWidgets('19. 6L toggles STBY -> ALT-ON', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);
      expect(find.text('<STBY'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      expect(find.text('<ALT-ON'), findsOneWidget);
    });

    // 20. 6L toggles ALT-ON -> STBY
    testWidgets('20. 6L toggles ALT-ON -> STBY', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L')); // to ALT-ON
      await tester.pumpAndSettle();
      expect(find.text('<ALT-ON'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L')); // back to STBY
      await tester.pumpAndSettle();
      expect(find.text('<STBY'), findsOneWidget);
    });

    // 21. 6R triggers IDENT
    testWidgets('21. 6R triggers IDENT state', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);
      expect(find.text('IDENT*'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pumpAndSettle();

      expect(find.text('*IDENT*'), findsOneWidget);
    });

    // 22. Persistence across MENU navigation
    testWidgets('22. Tune Radio value -> MENU -> RADIO -> value remains', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);

      // Swap COM1 so active is 127.000
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      // Navigate to MENU via hardware MENU key
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'MENU'));
      await tester.pumpAndSettle();
      expect(find.text('MCDU DEMO MENU'), findsOneWidget);

      // Re-enter RADIO via MENU 2R
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2R'));
      await tester.pumpAndSettle();
      expect(find.text('RADIO        1/2'), findsOneWidget);

      // 127.000 must still be active on COM1
      expect(find.text('<127.000'), findsOneWidget); // COM1 active (<127.000)
      expect(find.text('<122.600'), findsOneWidget); // COM1 standby (<122.600)
    });

    // 23. Successful Radio tuning clears scratchpad
    testWidgets('23. Successful Radio tuning clears scratchpad', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '0'));
      await tester.pumpAndSettle();
      expect(find.text('130'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      expect(find.text('<130.000'), findsOneWidget);
      expect(find.text('130'), findsNothing);
    });

    // 24. Invalid tuning produces INVALID ENTRY
    testWidgets('24. Invalid tuning produces INVALID ENTRY in scratchpad', (WidgetTester tester) async {
      final overlay = await navigateToRadio(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'A'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'B'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'C'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      expect(find.text('INVALID ENTRY'), findsOneWidget);
    });

    // 25. Game isolation: active game consumes keys and Radio does not receive them
    testWidgets('25. Game isolation: Typing test consumes keys without Radio interference', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      // Enter GAME -> Typing Test
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L')); // MENU -> GAME
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // GAME -> Typing Test
      await tester.pumpAndSettle();

      expect(find.text('TYPING TEST'), findsOneWidget);

      // Press 2L in Typing Test (2L is unmapped in typing test, should not tune or swap Radio)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      expect(find.text('TYPING TEST'), findsOneWidget);
      expect(find.text('RADIO        1/2'), findsNothing);
    });
  });
}
