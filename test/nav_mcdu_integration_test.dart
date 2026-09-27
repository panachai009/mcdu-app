// test/nav_mcdu_integration_test.dart
// Phase 19E-C-B — Realistic NAV + POS INIT MCDU Integration Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/app/app.dart';
import 'package:mcdu_app/features/mcdu_core/domain/mcdu_operating_mode.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_screen.dart';

void main() {
  group('Phase 19E-C-B Realistic NAV MCDU Integration Tests', () {
    Future<MCDUKeypadOverlay> pumpMCDU(WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();
      return tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
    }

    // 1. Hardware NAV key enters NAV INDEX 1/2
    testWidgets('1. Hardware NAV key opens NAV INDEX 1/2 from MENU', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();

      expect(find.text('NAV INDEX      1/2'), findsOneWidget);
      expect(find.text('◄FPL LIST'), findsOneWidget);
      expect(find.text('FPL SEL►'), findsOneWidget);
      expect(find.text('◄WPT LIST'), findsOneWidget);
      expect(find.text('DATA BASE►'), findsOneWidget);
      expect(find.text('◄NAV IDENT'), findsOneWidget);
      expect(find.text('FLT SUM►'), findsOneWidget);
      expect(find.text('◄POS SENSORS'), findsOneWidget);
      expect(find.text('◄CROSS PTS'), findsOneWidget);
      expect(find.text('PATTERNS►'), findsOneWidget);
      expect(find.text('◄DEPARTURE'), findsOneWidget);
      expect(find.text('ARRIVAL►'), findsOneWidget);
    });

    // 2. MENU 1R (NAV>) also opens NAV INDEX 1/2
    testWidgets('2. MENU 1R opens NAV INDEX 1/2', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R')); // MENU 1R -> NAV
      await tester.pumpAndSettle();

      expect(find.text('NAV INDEX      1/2'), findsOneWidget);
    });

    // 3. Index page cycling: NEXT -> INDEX 2/2, PREV -> INDEX 1/2
    testWidgets('3. NEXT transitions to INDEX 2/2 and PREV returns to INDEX 1/2', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();

      expect(find.text('NAV INDEX      1/2'), findsOneWidget);

      // NEXT -> 2/2
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NEXT'));
      await tester.pumpAndSettle();

      expect(find.text('NAV INDEX      2/2'), findsOneWidget);
      expect(find.text('◄POS INIT'), findsOneWidget);
      expect(find.text('CONVERSION►'), findsOneWidget);
      expect(find.text('◄DATA LOAD'), findsOneWidget);
      expect(find.text('MAINTENANCE►'), findsOneWidget);

      // PREV -> 1/2
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'PREV'));
      await tester.pumpAndSettle();

      expect(find.text('NAV INDEX      1/2'), findsOneWidget);
    });

    // 4. NAV IDENT navigation: INDEX 1/2 + 3L -> NAV IDENT 1/1
    testWidgets('4. INDEX 1/2 + 3L opens NAV IDENT 1/1 with grounded values', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L')); // 3L -> NAV IDENT
      await tester.pumpAndSettle();

      expect(find.text('NAV IDENT      1/1'), findsOneWidget);
      expect(find.text('24JAN17'), findsOneWidget);
      expect(find.text('10NOV 07DEC/16'), findsOneWidget);
      expect(find.text('0755z'), findsOneWidget);
      expect(find.text('13OCT 09NOV/16'), findsOneWidget);
      expect(find.text('NZ7.1.2'), findsOneWidget);
      expect(find.text('AW139-5-312'), findsOneWidget);
      expect(find.text('◄MAINTENANCE'), findsOneWidget);
      expect(find.text('POS INIT►'), findsOneWidget);
    });

    // 5. POS INIT Path A: NAV -> 3L -> 6R -> POSITION INIT 1/1
    testWidgets('5. POS INIT Path A: NAV -> 3L -> 6R enters POSITION INIT 1/1', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L')); // NAV IDENT
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // POS INIT►
      await tester.pumpAndSettle();

      expect(find.text('POSITION INIT   1/1'), findsOneWidget);
      expect(find.text('LAST POS'), findsOneWidget);
      expect(find.text('GPS 1 POS'), findsOneWidget);
    });

    // 6. POS INIT Path B: NAV -> NEXT -> 1L -> POSITION INIT 1/1
    testWidgets('6. POS INIT Path B: NAV -> NEXT -> 1L enters POSITION INIT 1/1', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NEXT')); // INDEX 2/2
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // ◄POS INIT
      await tester.pumpAndSettle();

      expect(find.text('POSITION INIT   1/1'), findsOneWidget);
      expect(find.text('LAST POS'), findsOneWidget);
      expect(find.text('GPS 1 POS'), findsOneWidget);
    });

    // 7. Unsupported LSK no-op behavior on INDEX 1/2 and 2/2
    testWidgets('7. Unsupported LSKs on NAV INDEX do not navigate away', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();

      // Pressing 1L on INDEX 1/2 (unimplemented FPL LIST) remains on INDEX 1/2
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();
      expect(find.text('NAV INDEX      1/2'), findsOneWidget);

      // Pressing 2R on INDEX 1/2 (DATA BASE) remains on INDEX 1/2
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2R'));
      await tester.pumpAndSettle();
      expect(find.text('NAV INDEX      1/2'), findsOneWidget);
    });

    // 8. Scratchpad preservation across NAV navigation
    testWidgets('8. NAV page navigation preserves existing scratchpad content', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'A'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'B'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'C'));
      await tester.pumpAndSettle();

      expect(find.text('ABC'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();

      expect(find.text('NAV INDEX      1/2'), findsOneWidget);
      expect(find.text('ABC'), findsOneWidget); // Preserved

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NEXT'));
      await tester.pumpAndSettle();

      expect(find.text('NAV INDEX      2/2'), findsOneWidget);
      expect(find.text('ABC'), findsOneWidget); // Preserved
    });

    // 9. Radio isolation: RADIO remains accessible and completely independent
    testWidgets('9. Radio subsystem remains accessible and isolated', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'RADIO'));
      await tester.pumpAndSettle();

      expect(find.text('RADIO        1/2'), findsOneWidget);
      expect(find.text('<122.600'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();

      expect(find.text('NAV INDEX      1/2'), findsOneWidget);
    });

    // 10. Game isolation: Minigames intercept inputs before NAV
    testWidgets('10. Game isolation: Typing test intercepts inputs without NAV interference', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L')); // MENU -> GAME
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // GAME -> Typing Test
      await tester.pumpAndSettle();

      expect(find.text('TYPING TEST'), findsOneWidget);

      // Typing in game
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'A'));
      await tester.pumpAndSettle();

      expect(find.text('TYPING TEST'), findsOneWidget);
      expect(find.text('NAV INDEX      1/2'), findsNothing);
    });

    // 11. 5L REALISTIC placeholder remains preserved
    testWidgets('11. 5L REALISTIC placeholder remains preserved from MENU', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '5L'));
      await tester.pumpAndSettle();

      expect(screenState.operatingMode, MCDUOperatingMode.realistic);
      expect(find.text('REALISTIC MCDU'), findsOneWidget);
      expect(find.text('AW139 FMS SIMULATION'), findsOneWidget);
      expect(find.text('PLACEHOLDER MODE'), findsOneWidget);
      expect(find.text('<MENU'), findsOneWidget);
    });
  });
}
