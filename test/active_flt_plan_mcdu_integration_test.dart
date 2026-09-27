// test/active_flt_plan_mcdu_integration_test.dart
// Phase 19E-D-D — Realistic ACTIVE FLT PLAN MCDU Integration Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/app/app.dart';
import 'package:mcdu_app/features/mcdu_core/domain/mcdu_operating_mode.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_screen.dart';

void main() {
  group('Phase 19E-D-D Realistic ACTIVE FLT PLAN MCDU Integration Tests', () {
    Future<MCDUKeypadOverlay> pumpMCDU(WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();
      return tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
    }

    // Helper: navigate to POS INIT page and load position
    Future<MCDUKeypadOverlay> loadPositionInit(WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV')); // NAV -> NAV INDEX 1/2
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));  // 3L -> NAV IDENT 1/1
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));  // 6R -> POSITION INIT 1/1
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));  // 1R -> Load LAST POS
      await tester.pumpAndSettle();
      return overlay;
    }

    // A. Hardware FPL key opens ACTIVE FLT PLAN 1/1 (not static demo page)
    testWidgets('A. Hardware FPL key opens ACTIVE FLT PLAN 1/1 without demo text', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'FPL'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE FLT PLAN 1/1'), findsOneWidget);
      expect(find.text('MCDU FPL'), findsNothing);
      expect(find.text('DEMO ONLY'), findsNothing);
      expect(find.text('----'), findsOneWidget); // 1R DEST prompt
      expect(find.text('◄FPL LIST'), findsOneWidget); // 6L
      expect(find.text('PERF INIT►'), findsOneWidget); // 6R
    });

    // B. FPL key after position init retains initialized origin
    testWidgets('B. FPL key after position init retains initialized origin and prompts DEST', (WidgetTester tester) async {
      final overlay = await loadPositionInit(tester);
      // Press hardware FPL key
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'FPL'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE FLT PLAN 1/1'), findsOneWidget);
      // Origin is VTBL (from POS INIT default refWptIdent)
      expect(find.text('VTBL'), findsOneWidget);
      expect(find.text('----'), findsOneWidget); // 1R DEST prompt
    });

    // C. POS INIT 6R navigates directly to ACTIVE FLT PLAN 1/1
    testWidgets('C. POS INIT 6R navigates directly to ACTIVE FLT PLAN 1/1 with origin loaded', (WidgetTester tester) async {
      final overlay = await loadPositionInit(tester);

      expect(find.text('FLT PLAN►'), findsOneWidget);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // 6R -> ACTIVE FLT PLAN
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE FLT PLAN 1/1'), findsOneWidget);
      expect(find.text('VTBL'), findsOneWidget);
      expect(find.text('----'), findsOneWidget);
      expect(find.text('◄FPL LIST'), findsOneWidget);
      expect(find.text('PERF INIT►'), findsOneWidget);
    });

    // D. Destination insertion transitions to ACTIVE FLT PLAN 1/2
    testWidgets('D. Inserting destination at 1R transitions to ACTIVE FLT PLAN 1/2', (WidgetTester tester) async {
      final overlay = await loadPositionInit(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // Enter ACTIVE FLT PLAN
      await tester.pumpAndSettle();

      // Type VTBH into scratchpad
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'V'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'T'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'B'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'H'));
      await tester.pumpAndSettle();
      expect(find.text('VTBH'), findsOneWidget);

      // Insert into 1R
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE FLT PLAN 1/2'), findsOneWidget);
      expect(find.text('VTBL'), findsOneWidget); // Origin
      expect(find.text('VTBH'), findsNWidgets(2)); // Leg and DEST
      expect(find.text('◄DEPARTURE'), findsOneWidget); // 6L
      expect(find.text('PERF INIT►'), findsOneWidget); // 6R
    });

    // E. Invalid destination keeps plan unchanged and shows INVALID ENTRY
    testWidgets('E. Invalid destination shows INVALID ENTRY and preserves state', (WidgetTester tester) async {
      final overlay = await loadPositionInit(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pumpAndSettle();

      // Type invalid entry '1' (too short)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE FLT PLAN 1/1'), findsOneWidget);
      expect(find.text('INVALID ENTRY'), findsOneWidget);
      expect(find.text('----'), findsOneWidget); // DEST still empty
    });

    // F. Scratchpad preservation
    testWidgets('F. Scratchpad content is preserved across page switches', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'A'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'B'));
      await tester.pumpAndSettle();

      expect(find.text('AB'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'FPL'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE FLT PLAN 1/1'), findsOneWidget);
      expect(find.text('AB'), findsOneWidget);
    });

    // G. Game isolation
    testWidgets('G. Active minigame intercepts inputs without FPL interference', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L')); // MENU -> GAME
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // GAME -> Typing Test
      await tester.pumpAndSettle();

      expect(find.text('TYPING TEST'), findsOneWidget);

      // Typing keys in game
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'A'));
      await tester.pumpAndSettle();

      expect(find.text('TYPING TEST'), findsOneWidget);
      expect(find.text('ACTIVE FLT PLAN 1/1'), findsNothing);
    });

    // H. Radio isolation
    testWidgets('H. Radio subsystem remains accessible and isolated', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'RADIO'));
      await tester.pumpAndSettle();

      expect(find.text('RADIO        1/2'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'FPL'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE FLT PLAN 1/1'), findsOneWidget);
    });

    // I. NAV and POS INIT isolation
    testWidgets('I. NAV and POS INIT routing remain functional', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();

      expect(find.text('NAV INDEX      1/2'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L')); // NAV IDENT
      await tester.pumpAndSettle();

      expect(find.text('NAV IDENT      1/1'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // POS INIT
      await tester.pumpAndSettle();

      expect(find.text('POSITION INIT   1/1'), findsOneWidget);
    });

    // J. MENU 5L REALISTIC placeholder remains unchanged
    testWidgets('J. MENU 5L continues to display REALISTIC placeholder', (WidgetTester tester) async {
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
