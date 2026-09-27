// test/flt_plan_management_mcdu_integration_test.dart
// Phase 19E-F1 — FPL DELETE + SHOW FPL MCDU Integration Tests
// AW139 Manual Reference: p41-45 (Procedure 6-1, 6-2), p46-48 (Procedure 6-3)

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/app/app.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_screen.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/flt_plan_state.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/stored_flt_plan.dart';

void main() {
  group('Phase 19E-F1 FPL Management Integration Tests (DELETE & SHOW FPL)', () {
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

    // -------------------------------------------------------------------------
    // DELETE TESTS
    // -------------------------------------------------------------------------

    // 1. DEL + 1L deletes first stored FPL
    testWidgets('1. DEL + 1L deletes first stored FPL', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      expect(find.text('VFR01'), findsOneWidget);

      // Press DEL key
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'DEL'));
      await tester.pumpAndSettle();

      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      expect(screenState.currentScratchpad, 'DEL');

      // Press 1L
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      // VFR01 should be deleted; IFR02 should move to 1L
      expect(find.text('VFR01'), findsNothing);
      expect(find.text('IFR02'), findsOneWidget);
      expect(find.text('TRN03'), findsOneWidget);
      expect(screenState.storedPlansForTesting.length, 2);
      expect(screenState.currentScratchpad, isEmpty);
    });

    // 2. DEL + 2L deletes second stored FPL
    testWidgets('2. DEL + 2L deletes second stored FPL', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      expect(find.text('IFR02'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'DEL'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      // IFR02 should be deleted; VFR01 and TRN03 remain
      expect(find.text('IFR02'), findsNothing);
      expect(find.text('VFR01'), findsOneWidget);
      expect(find.text('TRN03'), findsOneWidget);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      expect(screenState.storedPlansForTesting.length, 2);
    });

    // 3. remaining plans preserve ordering
    testWidgets('3. remaining plans preserve ordering after deletion', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'DEL'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // Delete plan 1
      await tester.pumpAndSettle();

      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      expect(screenState.storedPlansForTesting[0].name, 'IFR02');
      expect(screenState.storedPlansForTesting[1].name, 'TRN03');
    });

    // 4. deleting selected plan updates selection safely
    testWidgets('4. deleting selected plan updates selection safely', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);

      // Select plan 1 (1L)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      // Delete plan 1
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'DEL'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      expect(screenState.storedPlansForTesting.length, 2);
      expect(find.byType(MCDUScreen), findsOneWidget);
    });

    // 5. deleting stored FPL does not modify active FltPlanState
    testWidgets('5. deleting stored FPL does not modify active FltPlanState', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      // Setup active flight plan: VTBL -> VTBH
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

      // Delete plan 1
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'DEL'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      // Check active plan is still VTBL -> VTBH
      expect(screenState.fltPlanStateForTesting.originIdent, 'VTBL');
      expect(screenState.fltPlanStateForTesting.destinationIdent, 'VTBH');
    });

    // 6. delete outside FPL LIST preserves existing behavior
    testWidgets('6. delete outside FPL LIST does not crash or trigger plan deletion', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);

      // On MENU page, press DEL
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'DEL'));
      await tester.pumpAndSettle();

      expect(find.byType(MCDUScreen), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // SHOW FPL TESTS
    // -------------------------------------------------------------------------

    // 7. FPL LIST → SHOW FPL
    testWidgets('7. FPL LIST 1R navigates to SHOW FPL when plan is selected', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);

      // Select plan 1 (VFR01)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      // Press 1R SHOW FPL►
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      expect(find.text('SHOW FPL       1/1'), findsOneWidget);
      expect(find.text('PLAN: VFR01'), findsOneWidget);
      expect(find.text('◄FPL LIST'), findsOneWidget);
    });

    // 8. SHOW FPL displays selected stored plan
    testWidgets('8. SHOW FPL displays selected stored plan origin and destination', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // VFR01: VTBD -> VTBS
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R')); // SHOW FPL►
      await tester.pumpAndSettle();

      expect(find.text('VTBD'), findsOneWidget); // Origin at 1L
      expect(find.text('VTBS'), findsAtLeastNWidgets(1)); // Destination at 1R
    });

    // 9. SHOW FPL displays actual route legs
    testWidgets('9. SHOW FPL displays actual route legs from StoredFltPlan', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L')); // IFR02 has leg WAYP1
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R')); // SHOW FPL►
      await tester.pumpAndSettle();

      expect(find.text('PLAN: IFR02'), findsOneWidget);
      expect(find.text('WAYP1'), findsOneWidget);
    });

    // 10. SHOW FPL does not activate plan
    testWidgets('10. SHOW FPL does not activate plan', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // VFR01
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R')); // SHOW FPL►
      await tester.pumpAndSettle();

      expect(find.text('SHOW FPL       1/1'), findsOneWidget);
      // Active plan must NOT be VFR01
      expect(screenState.fltPlanStateForTesting.originIdent, isNot('VTBD'));
      expect(screenState.fltPlanStateForTesting.destinationIdent, isNot('VTBS'));
    });

    // 11. SHOW FPL does not modify active FltPlanState
    testWidgets('11. SHOW FPL does not modify existing active FltPlanState', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      // Setup active flight plan: VTBL -> VTBH
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
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R')); // SHOW FPL►
      await tester.pumpAndSettle();

      expect(screenState.fltPlanStateForTesting.originIdent, 'VTBL');
      expect(screenState.fltPlanStateForTesting.destinationIdent, 'VTBH');
    });

    // 12. SHOW FPL does not mutate StoredFltPlan
    testWidgets('12. SHOW FPL does not mutate StoredFltPlan object', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      final plan = screenState.storedPlansForTesting[1];
      expect(plan.name, 'IFR02');
      expect(plan.originIdent, 'VTBS');
      expect(plan.destinationIdent, 'VTSP');
      expect(plan.legs.length, 2);
    });

    // 13. return from SHOW FPL returns to appropriate FPL context (FPL LIST)
    testWidgets('13. 6L on SHOW FPL returns to FPL LIST', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R')); // SHOW FPL►
      await tester.pumpAndSettle();

      expect(find.text('SHOW FPL       1/1'), findsOneWidget);

      // Press 6L ◄FPL LIST
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      expect(find.text('FPL LIST       1/1'), findsOneWidget);
      expect(find.text('SHOW FPL       1/1'), findsNothing);
    });

    // 14. FPL SELECT / ACTIVATE still works after SHOW integration
    testWidgets('14. FPL SELECT and ACTIVATE still work normally', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      // Enter FLT PLAN SELECT via 6R
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pumpAndSettle();

      expect(find.text('FLT PLAN SELECT 1/1'), findsOneWidget);
      expect(find.text('ACTIVATE►'), findsOneWidget);

      // Activate via 1R
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE FLT PLAN 1/2'), findsOneWidget);
      expect(find.text('VTBD'), findsOneWidget);
    });

    // 15. Game isolation
    testWidgets('15. Game mode remains isolated', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L')); // MENU -> GAME
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // GAME -> Typing Test
      await tester.pumpAndSettle();

      expect(find.text('TYPING TEST'), findsOneWidget);
    });

    // 16. Radio isolation
    testWidgets('16. Radio subsystem remains isolated', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'RADIO'));
      await tester.pumpAndSettle();

      expect(find.text('RADIO        1/2'), findsOneWidget);
    });

    // 17. NAV isolation
    testWidgets('17. NAV subsystem remains isolated', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();

      expect(find.text('NAV INDEX      1/2'), findsOneWidget);
    });

    // 18. POS INIT isolation
    testWidgets('18. POS INIT subsystem remains isolated', (WidgetTester tester) async {
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
