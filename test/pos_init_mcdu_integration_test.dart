// test/pos_init_mcdu_integration_test.dart
// Phase 19D-C — Realistic Position Initialization (POS INIT) MCDU Integration Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/app/app.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_screen.dart';

void main() {
  group('Phase 19D-C Realistic POS INIT MCDU Integration Tests', () {
    // Helper: navigate to POS INIT page from initial MENU via NAV -> 3L -> 6R
    Future<MCDUKeypadOverlay> navigateToPosInit(WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();
      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV')); // NAV -> NAV INDEX 1/2
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));  // 3L -> NAV IDENT 1/1
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));  // 6R -> POSITION INIT 1/1
      await tester.pumpAndSettle();
      return overlay;
    }

    // 1. POS INIT header renders
    testWidgets('1. POS INIT header renders POSITION INIT 1/1', (WidgetTester tester) async {
      await navigateToPosInit(tester);
      expect(find.text('POSITION INIT   1/1'), findsOneWidget);
    });

    // 2. LAST POS renders
    testWidgets('2. LAST POS renders label, coordinates, and LOAD prompt', (WidgetTester tester) async {
      await navigateToPosInit(tester);
      expect(find.text('LAST POS'), findsOneWidget);
      expect(find.text('N14°53.2 E100°39.7'), findsNWidgets(2)); // LAST POS and GPS 1 POS share initial coords
      expect(find.text('LOAD►'), findsNWidgets(3)); // 1R, 2R, 3R
    });

    // 3. REF WPT renders
    testWidgets('3. REF WPT renders default ident VTBL and coordinates', (WidgetTester tester) async {
      await navigateToPosInit(tester);
      expect(find.text('VTBL REF WPT'), findsOneWidget);
      expect(find.text('N14°52.5 E100°39.8'), findsOneWidget);
    });

    // 4. GPS 1 POS renders
    testWidgets('4. GPS 1 POS renders section header', (WidgetTester tester) async {
      await navigateToPosInit(tester);
      expect(find.text('GPS 1 POS'), findsOneWidget);
    });

    // 5. POS SENSORS prompt renders
    testWidgets('5. POS SENSORS prompt renders at 6L', (WidgetTester tester) async {
      await navigateToPosInit(tester);
      expect(find.text('◄POS SENSORS'), findsOneWidget);
    });

    // 6. 6R blank before position loaded
    testWidgets('6. 6R is blank before position is loaded', (WidgetTester tester) async {
      await navigateToPosInit(tester);
      expect(find.text('FLT PLAN►'), findsNothing);
    });

    // 7. 1R loads LAST POS
    testWidgets('7. 1R loads LAST POS and displays FLT PLAN prompt', (WidgetTester tester) async {
      final overlay = await navigateToPosInit(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      expect(find.text('FLT PLAN►'), findsOneWidget);
    });

    // 8. 3R loads GPS POS
    testWidgets('8. 3R loads GPS 1 POS and displays FLT PLAN prompt', (WidgetTester tester) async {
      final overlay = await navigateToPosInit(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3R'));
      await tester.pumpAndSettle();

      expect(find.text('FLT PLAN►'), findsOneWidget);
    });

    // 9. 2R loads REF WPT
    testWidgets('9. 2R loads REF WPT and displays FLT PLAN prompt', (WidgetTester tester) async {
      final overlay = await navigateToPosInit(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2R'));
      await tester.pumpAndSettle();

      expect(find.text('FLT PLAN►'), findsOneWidget);
    });

    // 10. Successful load causes 6R FLT PLAN►
    testWidgets('10. Successful load causes 6R to show FLT PLAN►', (WidgetTester tester) async {
      final overlay = await navigateToPosInit(tester);
      expect(find.text('FLT PLAN►'), findsNothing);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      expect(find.text('FLT PLAN►'), findsOneWidget);
    });

    // 11. Loaded position is preserved across multiple LSKs
    testWidgets('11. Pushing 3R after 1R keeps position loaded', (WidgetTester tester) async {
      final overlay = await navigateToPosInit(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();
      expect(find.text('FLT PLAN►'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3R'));
      await tester.pumpAndSettle();
      expect(find.text('FLT PLAN►'), findsOneWidget);
    });

    // 12. Non-empty scratchpad on 1R does not trigger load if command is invalid
    testWidgets('12. Non-empty scratchpad on 1R is ignored or does not trigger load', (WidgetTester tester) async {
      final overlay = await navigateToPosInit(tester);
      // Type 'ABC' into scratchpad
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'A'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'B'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'C'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      expect(find.text('ABC'), findsOneWidget); // Scratchpad preserved
      expect(find.text('FLT PLAN►'), findsNothing); // Not loaded
    });

    // 13. Non-empty scratchpad on 3R is ignored or does not trigger load
    testWidgets('13. Non-empty scratchpad on 3R does not trigger load', (WidgetTester tester) async {
      final overlay = await navigateToPosInit(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3R'));
      await tester.pumpAndSettle();

      expect(find.text('12'), findsOneWidget);
      expect(find.text('FLT PLAN►'), findsNothing);
    });

    // 14. 6L POS SENSORS is a display-only no-op
    testWidgets('14. 6L POS SENSORS is a display-only no-op', (WidgetTester tester) async {
      final overlay = await navigateToPosInit(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      expect(find.text('POSITION INIT   1/1'), findsOneWidget);
    });

    // 15. Scratchpad display remains intact on POS INIT
    testWidgets('15. Scratchpad character typing works normally on POS INIT', (WidgetTester tester) async {
      final overlay = await navigateToPosInit(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'V'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'T'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'B'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'L'));
      await tester.pumpAndSettle();

      expect(find.text('VTBL'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'CLR'));
      await tester.pumpAndSettle();

      expect(find.text('VTB'), findsOneWidget);
    });

    // 16. PREV is no-op on 1/1
    testWidgets('16. PREV is no-op on 1/1 page', (WidgetTester tester) async {
      final overlay = await navigateToPosInit(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'PREV'));
      await tester.pumpAndSettle();

      expect(find.text('POSITION INIT   1/1'), findsOneWidget);
    });

    // 17. NEXT is no-op on 1/1
    testWidgets('17. NEXT is no-op on 1/1 page', (WidgetTester tester) async {
      final overlay = await navigateToPosInit(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NEXT'));
      await tester.pumpAndSettle();

      expect(find.text('POSITION INIT   1/1'), findsOneWidget);
    });

    // 18. Hardware MENU leaves page and returns to MENU
    testWidgets('18. Hardware MENU leaves POS INIT and returns to MENU', (WidgetTester tester) async {
      final overlay = await navigateToPosInit(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'MENU'));
      await tester.pumpAndSettle();

      expect(find.text('MCDU DEMO MENU'), findsOneWidget);
    });

    // 19. Returning to POS INIT preserves loaded state
    testWidgets('19. Returning to POS INIT from MENU preserves loaded state', (WidgetTester tester) async {
      final overlay = await navigateToPosInit(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R')); // Load position
      await tester.pumpAndSettle();
      expect(find.text('FLT PLAN►'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'MENU')); // Leave to MENU
      await tester.pumpAndSettle();
      expect(find.text('MCDU DEMO MENU'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pumpAndSettle();
      expect(find.text('POSITION INIT   1/1'), findsOneWidget);
      expect(find.text('FLT PLAN►'), findsOneWidget); // Still loaded
    });

    // 20. Game isolation: active minigame consumes keys and POS INIT receives none
    testWidgets('20. Game isolation: Typing test consumes keys without POS INIT receiving them', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      // Enter GAME -> Typing Test
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L')); // MENU -> GAME
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // GAME -> Typing Test
      await tester.pumpAndSettle();

      expect(find.text('TYPING TEST'), findsOneWidget);

      // Press 1R in Typing Test (1R is unmapped in typing test, should not load position)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      expect(find.text('TYPING TEST'), findsOneWidget);
      expect(find.text('POSITION INIT   1/1'), findsNothing);
    });

    // 21. Radio isolation: Radio page remains completely unaffected
    testWidgets('21. Radio isolation: RADIO page functions normally and independently', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2R')); // MENU 2R -> RADIO
      await tester.pumpAndSettle();

      expect(find.text('RADIO        1/2'), findsOneWidget);
      expect(find.text('<122.600'), findsOneWidget);

      // Swap COM1
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      expect(find.text('<127.000'), findsOneWidget); // COM1 active
    });

    // 22. 6R FLT PLAN► is a display-only prompt once loaded in this phase
    testWidgets('22. 6R FLT PLAN► is a display-only prompt once loaded', (WidgetTester tester) async {
      final overlay = await navigateToPosInit(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      expect(find.text('FLT PLAN►'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pumpAndSettle();

      // Stays on POSITION INIT 1/1 without crash
      expect(find.text('POSITION INIT   1/1'), findsOneWidget);
    });
  });
}
