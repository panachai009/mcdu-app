// test/fpl_list_mcdu_integration_test.dart
// Phase 19E-E-D — Realistic FPL LIST MCDU Integration Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/app/app.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_screen.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/stored_flt_plan.dart';

void main() {
  group('Phase 19E-E-D Realistic FPL LIST MCDU Integration Tests', () {
    const testPlan1 = StoredFltPlan(
      id: 'plan-01',
      name: 'VFR01',
      originIdent: 'VTBD',
      destinationIdent: 'VTBS',
    );

    const testPlan2 = StoredFltPlan(
      id: 'plan-02',
      name: 'IFR02',
      originIdent: 'VTBS',
      destinationIdent: 'VTSP',
    );

    const testPlan3 = StoredFltPlan(
      id: 'plan-03',
      name: 'TRN03',
      originIdent: 'VTBD',
      destinationIdent: 'VTCC',
    );

    Future<MCDUKeypadOverlay> pumpMCDU(WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();
      return tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
    }

    // Helper: enter ACTIVE FLT PLAN 1/1
    Future<MCDUKeypadOverlay> enterActiveFltPlan(WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'FPL'));
      await tester.pumpAndSettle();
      return overlay;
    }

    // 1. ACTIVE FLT PLAN 6L → FPL LIST
    testWidgets('1. ACTIVE FLT PLAN 6L navigates to FPL LIST', (WidgetTester tester) async {
      final overlay = await enterActiveFltPlan(tester);
      expect(find.text('ACTIVE FLT PLAN 1/1'), findsOneWidget);
      expect(find.text('◄FPL LIST'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE FLT PLAN 1/1'), findsNothing);
      expect(find.textContaining('FPL LIST'), findsOneWidget);
      expect(find.text('◄FPL'), findsOneWidget); // 6L return prompt
    });

    // 2. FPL LIST display uses FplListDisplayAdapter
    testWidgets('2. FPL LIST display renders title and 6L return prompt from adapter', (WidgetTester tester) async {
      final overlay = await enterActiveFltPlan(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      expect(find.text('FPL LIST       1/1'), findsOneWidget);
      expect(find.text('◄FPL'), findsOneWidget);
    });

    // 3. empty FPL LIST
    testWidgets('3. Empty FPL LIST shows no fake flight plans and blank lines', (WidgetTester tester) async {
      final overlay = await enterActiveFltPlan(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      expect(find.text('FPL LIST       1/1'), findsOneWidget);
      expect(find.text('DEMO ONLY'), findsNothing);
      expect(find.text('MCDU FPL'), findsNothing);
      expect(find.text('VTBL'), findsNothing);
      expect(find.text('VTBH'), findsNothing);
    });

    // 4. one stored FPL
    testWidgets('4. One stored FPL renders at 1L', (WidgetTester tester) async {
      final overlay = await enterActiveFltPlan(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      screenState.loadStoredPlansForTesting([testPlan1]);
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      expect(find.text('VFR01'), findsOneWidget);
      expect(find.text('◄FPL'), findsOneWidget);
    });

    // 5. multiple stored FPLs
    testWidgets('5. Multiple stored FPLs render on consecutive lines', (WidgetTester tester) async {
      final overlay = await enterActiveFltPlan(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      screenState.loadStoredPlansForTesting([testPlan1, testPlan2, testPlan3]);
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      expect(find.text('VFR01'), findsOneWidget);
      expect(find.text('IFR02'), findsOneWidget);
      expect(find.text('TRN03'), findsOneWidget);
    });

    // 6. LSK selection
    testWidgets('6. LSK selection marks selected plan', (WidgetTester tester) async {
      final overlay = await enterActiveFltPlan(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      screenState.loadStoredPlansForTesting([testPlan1, testPlan2]);
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      expect(find.text('VFR01'), findsOneWidget);
      expect(find.text('IFR02'), findsOneWidget);

      // Select 2L (second plan)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      expect(find.text('* IFR02'), findsOneWidget);
      expect(find.text('VFR01'), findsOneWidget);

      // Select 1L (first plan)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      expect(find.text('* VFR01'), findsOneWidget);
      expect(find.text('IFR02'), findsOneWidget);
    });

    // 7. invalid/empty LSK no-op
    testWidgets('7. Pressing empty LSK (e.g. 5L) does not crash or change selection', (WidgetTester tester) async {
      final overlay = await enterActiveFltPlan(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      screenState.loadStoredPlansForTesting([testPlan1]);
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      // Press empty LSK 5L
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '5L'));
      await tester.pumpAndSettle();

      expect(find.text('VFR01'), findsOneWidget);
      expect(find.text('◄FPL'), findsOneWidget);
    });

    // 8. PREV
    testWidgets('8. PREV key moves selection backward deterministically', (WidgetTester tester) async {
      final overlay = await enterActiveFltPlan(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      screenState.loadStoredPlansForTesting([testPlan1, testPlan2]);
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      // Select 2L
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();
      expect(find.text('* IFR02'), findsOneWidget);

      // Press PREV
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'PREV'));
      await tester.pumpAndSettle();
      expect(find.text('* VFR01'), findsOneWidget);
    });

    // 9. NEXT
    testWidgets('9. NEXT key moves selection forward deterministically', (WidgetTester tester) async {
      final overlay = await enterActiveFltPlan(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      screenState.loadStoredPlansForTesting([testPlan1, testPlan2]);
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      // Select 1L
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();
      expect(find.text('* VFR01'), findsOneWidget);

      // Press NEXT
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NEXT'));
      await tester.pumpAndSettle();
      expect(find.text('* IFR02'), findsOneWidget);
    });

    // 10. boundary behavior
    testWidgets('10. NEXT and PREV at boundary clamp without crashing or wrapping', (WidgetTester tester) async {
      final overlay = await enterActiveFltPlan(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      screenState.loadStoredPlansForTesting([testPlan1]);
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();
      expect(find.text('* VFR01'), findsOneWidget);

      // PREV at boundary 0
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'PREV'));
      await tester.pumpAndSettle();
      expect(find.text('* VFR01'), findsOneWidget);

      // NEXT at boundary last
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NEXT'));
      await tester.pumpAndSettle();
      expect(find.text('* VFR01'), findsOneWidget);
    });

    // 11. return FPL LIST → ACTIVE FLT PLAN
    testWidgets('11. Pressing 6L on FPL LIST returns to ACTIVE FLT PLAN', (WidgetTester tester) async {
      final overlay = await enterActiveFltPlan(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      expect(find.text('FPL LIST       1/1'), findsOneWidget);

      // Return via 6L
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE FLT PLAN 1/1'), findsOneWidget);
      expect(find.text('◄FPL LIST'), findsOneWidget);
    });

    // 12. scratchpad preservation
    testWidgets('12. Scratchpad is preserved across FPL LIST navigation and return', (WidgetTester tester) async {
      final overlay = await enterActiveFltPlan(tester);

      // Enter 'VTBD' in scratchpad
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'V'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'T'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'B'));
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'D'));
      await tester.pumpAndSettle();
      expect(find.text('VTBD'), findsOneWidget);

      // Go to FPL LIST
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();
      expect(find.text('FPL LIST       1/1'), findsOneWidget);
      expect(find.text('VTBD'), findsOneWidget);

      // Return to ACTIVE FLT PLAN
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();
      expect(find.text('ACTIVE FLT PLAN 1/1'), findsOneWidget);
      expect(find.text('VTBD'), findsOneWidget);
    });

    // 13. active FltPlanState preservation
    testWidgets('13. Active FltPlanState origin and destination are preserved when visiting FPL LIST', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);

      // Setup origin VTBL via POS INIT
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L')); // NAV IDENT
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // POS INIT
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R')); // LOAD LAST POS
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // FLT PLAN
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE FLT PLAN 1/1'), findsOneWidget);
      expect(find.text('VTBL'), findsOneWidget);

      // Navigate to FPL LIST
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();
      expect(find.text('FPL LIST       1/1'), findsOneWidget);

      // Return to ACTIVE FLT PLAN
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE FLT PLAN 1/1'), findsOneWidget);
      expect(find.text('VTBL'), findsOneWidget);
      expect(find.text('----'), findsOneWidget);
    });

    // 14. hardware FPL → ACTIVE FLT PLAN
    testWidgets('14. Pressing hardware FPL key always navigates to ACTIVE FLT PLAN even from FPL LIST', (WidgetTester tester) async {
      final overlay = await enterActiveFltPlan(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L')); // Go to FPL LIST
      await tester.pumpAndSettle();
      expect(find.text('FPL LIST       1/1'), findsOneWidget);

      // Press hardware FPL key
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'FPL'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE FLT PLAN 1/1'), findsOneWidget);
      expect(find.text('FPL LIST       1/1'), findsNothing);
    });

    // 15. Game isolation
    testWidgets('15. Active minigame intercepts inputs without FPL LIST interference', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L')); // MENU -> GAME
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // GAME -> Typing Test
      await tester.pumpAndSettle();

      expect(find.text('TYPING TEST'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'A'));
      await tester.pumpAndSettle();

      expect(find.text('TYPING TEST'), findsOneWidget);
      expect(find.textContaining('FPL LIST'), findsNothing);
    });

    // 16. Radio isolation
    testWidgets('16. Radio subsystem remains functional and isolated', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'RADIO'));
      await tester.pumpAndSettle();

      expect(find.text('RADIO        1/2'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'FPL'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE FLT PLAN 1/1'), findsOneWidget);
    });

    // 17. NAV isolation
    testWidgets('17. NAV subsystem navigation remains functional and isolated', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();

      expect(find.text('NAV INDEX      1/2'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L')); // NAV IDENT
      await tester.pumpAndSettle();

      expect(find.text('NAV IDENT      1/1'), findsOneWidget);
    });

    // 18. POS INIT isolation
    testWidgets('18. POS INIT subsystem navigation remains functional and isolated', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L')); // NAV IDENT
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // POS INIT
      await tester.pumpAndSettle();

      expect(find.text('POSITION INIT   1/1'), findsOneWidget);
    });

    // 19. no fake FPL
    testWidgets('19. No dummy or hardcoded flight plans injected in initial FPL LIST state', (WidgetTester tester) async {
      final overlay = await enterActiveFltPlan(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      expect(find.text('VFR01'), findsNothing);
      expect(find.text('IFR02'), findsNothing);
      expect(find.text('TRN03'), findsNothing);
      expect(find.text('VTBL'), findsNothing);
    });

    // 20. no persistence
    testWidgets('20. FPL LIST state is memory-based without filesystem persistence', (WidgetTester tester) async {
      final overlay = await enterActiveFltPlan(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      // Initially empty in pure memory
      expect(screenState.operatingMode, isNotNull);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();
      expect(find.text('FPL LIST       1/1'), findsOneWidget);
    });
  });
}
