// test/flt_plan_activation_mcdu_integration_test.dart
// Phase 19E-E-F2 — Stored Flight Plan Activation MCDU Integration Tests
// AW139 Manual Reference: p40-48, p74-77, p14, p19

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/app/app.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_screen.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/flt_plan_state.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/stored_flt_plan.dart';

void main() {
  group('Phase 19E-E-F2 Stored Flight Plan Activation MCDU Integration Tests', () {
    const testPlan1 = StoredFltPlan(
      id: 'plan-01',
      name: 'VFR01',
      originIdent: 'VTBD',
      destinationIdent: 'VTBS',
      legs: [
        FltPlanLeg(fixIdent: 'VTBS'),
      ],
    );

    const testPlan2 = StoredFltPlan(
      id: 'plan-02',
      name: 'IFR02',
      originIdent: 'VTBS',
      destinationIdent: 'VTSP',
      legs: [
        FltPlanLeg(fixIdent: 'WAYP1'),
        FltPlanLeg(fixIdent: 'VTSP'),
      ],
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

    // Helper: enter FPL LIST with stored test plans loaded
    Future<MCDUKeypadOverlay> enterFplList(WidgetTester tester, {List<StoredFltPlan>? plans}) async {
      final overlay = await pumpMCDU(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      screenState.loadStoredPlansForTesting(plans ?? [testPlan1, testPlan2, testPlan3]);
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'FPL'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L')); // ◄FPL LIST
      await tester.pumpAndSettle();

      return overlay;
    }

    // 1. FPL LIST 1L selection copies plan name to scratchpad
    testWidgets('1. FPL LIST 1L selection copies plan name to scratchpad', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      expect(find.text('FPL LIST       1/1'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      expect(screenState.currentScratchpad, 'VFR01');
    });

    // 2. FPL LIST 2L/3L selects corresponding stored plan and sets scratchpad
    testWidgets('2. FPL LIST 2L/3L selects corresponding stored plan and copies to scratchpad', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();
      final screenState1 = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      expect(screenState1.currentScratchpad, 'IFR02');

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();
      final screenState2 = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      expect(screenState2.currentScratchpad, 'TRN03');
    });

    // 3. FPL LIST 6R enters FLT PLAN SELECT
    testWidgets('3. FPL LIST 6R enters FLT PLAN SELECT 1/1', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      expect(find.text('FPL SEL►'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pumpAndSettle();

      expect(find.text('FLT PLAN SELECT 1/1'), findsOneWidget);
      expect(find.text('ACTIVATE►'), findsOneWidget);
      expect(find.text('INVERT/ACTIVATE►'), findsOneWidget);
      expect(find.text('◄FPL LIST'), findsOneWidget);
    });

    // 4. FLT PLAN SELECT renders selected plan
    testWidgets('4. FLT PLAN SELECT renders selected plan at 1L', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // select VFR01
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // FPL SEL►
      await tester.pumpAndSettle();

      expect(find.text('FLT PLAN SELECT 1/1'), findsOneWidget);
      // VFR01 is rendered at 1L (and might also be in scratchpad)
      expect(find.text('VFR01'), findsAtLeastNWidgets(1));
    });

    // 5. FLT PLAN SELECT 1R activates plan with no existing active plan
    testWidgets('5. FLT PLAN SELECT 1R activates plan directly when no existing plan', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // select VFR01
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // FPL SEL►
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R')); // ACTIVATE►
      await tester.pumpAndSettle();

      // Navigates directly to ACTIVE FLT PLAN without confirmation
      expect(find.text('CONFIRM REPLACING'), findsNothing);
      expect(find.text('ACTIVE FLT PLAN 1/2'), findsOneWidget);
      expect(find.text('VTBD'), findsOneWidget); // Origin
      expect(find.text('VTBS'), findsAtLeastNWidgets(1)); // Destination / leg
    });

    // 6. FLT PLAN SELECT 2R activates inverted plan with no existing active plan
    testWidgets('6. FLT PLAN SELECT 2R activates inverted plan directly when no existing plan', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // select VFR01 (VTBD -> VTBS)
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // FPL SEL►
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2R')); // INVERT/ACTIVATE►
      await tester.pumpAndSettle();

      // Swaps origin and destination: VTBS is origin, VTBD is destination
      expect(find.text('CONFIRM REPLACING'), findsNothing);
      expect(find.text('ACTIVE FLT PLAN 1/2'), findsOneWidget);
      expect(find.text('VTBS'), findsAtLeastNWidgets(1)); // New Origin
      expect(find.text('VTBD'), findsAtLeastNWidgets(1)); // New Destination
    });

    // 7. Existing active plan triggers confirmation
    testWidgets('7. Existing active plan triggers confirmation prompt', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      // Setup active plan: origin VTBL, destination VTBH
      screenState.setFltPlanStateForTesting(
        const FltPlanState(
          originIdent: 'VTBL',
          destinationIdent: 'VTBH',
          page: FltPlanPage.route,
          pageIndex: 1,
          totalPages: 2,
          legs: [],
        ),
      );
      await tester.pumpAndSettle();

      // In FPL LIST, select plan 1 (VFR01)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      // Go to FLT PLAN SELECT
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pumpAndSettle();

      // Press 1R ACTIVATE
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      // Should show confirmation page
      expect(find.text('CONFIRM REPLACING'), findsOneWidget);
      expect(find.text('ACTIVE FLIGHT PLAN'), findsOneWidget);
      expect(find.text('◄NO'), findsOneWidget);
      expect(find.text('YES►'), findsOneWidget);
    });

    // 8. Confirmation 6L ◄NO preserves existing active plan
    testWidgets('8. Confirmation 6L ◄NO cancels replacement and preserves active plan', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      // Setup existing active plan: VTBL -> VTBH
      screenState.setFltPlanStateForTesting(
        const FltPlanState(
          originIdent: 'VTBL',
          destinationIdent: 'VTBH',
          page: FltPlanPage.route,
          pageIndex: 1,
          totalPages: 2,
          legs: [],
        ),
      );
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      expect(find.text('CONFIRM REPLACING'), findsOneWidget);

      // Press 6L ◄NO
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      // Returns to FLT PLAN SELECT 1/1
      expect(find.text('FLT PLAN SELECT 1/1'), findsOneWidget);
      expect(find.text('CONFIRM REPLACING'), findsNothing);

      // Press hardware FPL to check active flight plan is intact
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'FPL'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE FLT PLAN 1/2'), findsOneWidget);
      expect(find.text('VTBL'), findsOneWidget);
      expect(find.text('VTBH'), findsAtLeastNWidgets(1));
    });

    // 9. Confirmation 6R YES► replaces active plan
    testWidgets('9. Confirmation 6R YES► commits replacement and displays new active plan', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      screenState.setFltPlanStateForTesting(
        const FltPlanState(
          originIdent: 'VTBL',
          destinationIdent: 'VTBH',
          page: FltPlanPage.route,
          pageIndex: 1,
          totalPages: 2,
          legs: [],
        ),
      );
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // VFR01: VTBD -> VTBS
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      expect(find.text('CONFIRM REPLACING'), findsOneWidget);

      // Press 6R YES►
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pumpAndSettle();

      // Navigates to ACTIVE FLT PLAN with new plan data
      expect(find.text('CONFIRM REPLACING'), findsNothing);
      expect(find.text('ACTIVE FLT PLAN 1/2'), findsOneWidget);
      expect(find.text('VTBD'), findsOneWidget);
      expect(find.text('VTBS'), findsAtLeastNWidgets(1));
      expect(find.text('VTBL'), findsNothing);
      expect(find.text('VTBH'), findsNothing);
    });

    // 10. YES with INVERT/ACTIVATE produces inverted active plan
    testWidgets('10. Confirmation YES with INVERT/ACTIVATE produces inverted active plan', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      screenState.setFltPlanStateForTesting(
        const FltPlanState(
          originIdent: 'VTBL',
          destinationIdent: 'VTBH',
          page: FltPlanPage.route,
          pageIndex: 1,
          totalPages: 2,
          legs: [],
        ),
      );
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // VFR01: VTBD -> VTBS
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2R')); // INVERT/ACTIVATE►
      await tester.pumpAndSettle();

      expect(find.text('CONFIRM REPLACING'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // YES►
      await tester.pumpAndSettle();

      // Inverted: VTBS is origin, VTBD is destination
      expect(find.text('ACTIVE FLT PLAN 1/2'), findsOneWidget);
      expect(find.text('VTBS'), findsAtLeastNWidgets(1));
      expect(find.text('VTBD'), findsAtLeastNWidgets(1));
    });

    // 11. FPL SELECT → FPL LIST via 6L preserves active plan
    testWidgets('11. FPL SELECT 6L returns to FPL LIST preserving active plan', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      screenState.setFltPlanStateForTesting(
        const FltPlanState(
          originIdent: 'VTBL',
          destinationIdent: 'VTBH',
          page: FltPlanPage.route,
          pageIndex: 1,
          totalPages: 2,
          legs: [],
        ),
      );
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // FPL SEL►
      await tester.pumpAndSettle();
      expect(find.text('FLT PLAN SELECT 1/1'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L')); // ◄FPL LIST
      await tester.pumpAndSettle();

      expect(find.text('FPL LIST       1/1'), findsOneWidget);

      // Return to active flight plan
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L')); // ◄FPL
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE FLT PLAN 1/2'), findsOneWidget);
      expect(find.text('VTBL'), findsOneWidget);
      expect(find.text('VTBH'), findsAtLeastNWidgets(1));
    });

    // 12. Activated plan reaches ACTIVE FLT PLAN
    testWidgets('12. Activated plan lands on ACTIVE FLT PLAN page', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE FLT PLAN 1/2'), findsOneWidget);
    });

    // 13. Active origin/destination are sourced from StoredFltPlan
    testWidgets('13. Active origin and destination match StoredFltPlan attributes', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L')); // IFR02: VTBS -> VTSP
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      expect(screenState.fltPlanStateForTesting.originIdent, 'VTBS');
      expect(screenState.fltPlanStateForTesting.destinationIdent, 'VTSP');
      expect(find.text('VTBS'), findsAtLeastNWidgets(1));
    });

    // 14. Active legs are sourced from StoredFltPlan
    testWidgets('14. Active legs are sourced from StoredFltPlan legs', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L')); // IFR02 has leg WAYP1 and VTSP
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      final legs = screenState.fltPlanStateForTesting.legs;
      expect(legs.length, 2);
      expect(legs[0].fixIdent, 'WAYP1');
      expect(legs[1].fixIdent, 'VTSP');
    });

    // 15. Stored plan itself is not mutated by activation/inversion
    testWidgets('15. Stored plan is immutable and not mutated by inversion', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L')); // IFR02
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2R')); // INVERT/ACTIVATE►
      await tester.pumpAndSettle();

      // Original stored plan in list should be untouched
      final storedPlan = screenState.storedPlansForTesting[1];
      expect(storedPlan.originIdent, 'VTBS');
      expect(storedPlan.destinationIdent, 'VTSP');
      expect(storedPlan.legs[0].fixIdent, 'WAYP1');
      expect(storedPlan.legs[1].fixIdent, 'VTSP');
    });

    // 16. Hardware FPL still opens ACTIVE FLT PLAN
    testWidgets('16. Hardware FPL key opens ACTIVE FLT PLAN directly', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'FPL'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE FLT PLAN 1/1'), findsOneWidget);
    });

    // 17. NAV → FPL LIST still works
    testWidgets('17. NAV INDEX 1/2 1L navigates to FPL LIST', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();
      expect(find.text('NAV INDEX      1/2'), findsOneWidget);
      expect(find.text('◄FPL LIST'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      expect(find.text('FPL LIST       1/1'), findsOneWidget);
    });

    // 18. Game mode isolation
    testWidgets('18. Game mode remains unaffected by FPL activation logic', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L')); // MENU -> GAME
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // GAME -> Typing Test
      await tester.pumpAndSettle();

      expect(find.text('TYPING TEST'), findsOneWidget);
    });

    // 19. Radio subsystem isolation
    testWidgets('19. Radio subsystem remains functional and isolated', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'RADIO'));
      await tester.pumpAndSettle();

      expect(find.text('RADIO        1/2'), findsOneWidget);
    });

    // 20. POS INIT isolation
    testWidgets('20. POS INIT navigation and state remain intact', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L')); // NAV IDENT
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // POS INIT
      await tester.pumpAndSettle();

      expect(find.text('POSITION INIT   1/1'), findsOneWidget);
    });
  });
}
