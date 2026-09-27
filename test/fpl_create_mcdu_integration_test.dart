// test/fpl_create_mcdu_integration_test.dart
// Phase 19E-F2-C-D-B — CREATE FPL MCDU Integration Tests
// AW139 Manual Reference: Procedure 6-1 (p41-44), Figures 6-4, 6-5, 6-6

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/app/app.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_screen.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/flt_plan_state.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/stored_flt_plan.dart';
import 'package:mcdu_app/features/simulation/flt_plan/engine/flt_plan_engine.dart';

void main() {
  group('Phase 19E-F2-C-D-B CREATE FPL MCDU Integration Tests', () {
    const testPlan1 = StoredFltPlan(
      id: 'plan-01',
      name: 'VFR01',
      originIdent: 'VTBD',
      destinationIdent: 'VTBS',
      legs: [
        FltPlanLeg(fixIdent: 'VTBS'),
      ],
    );

    Future<MCDUKeypadOverlay> pumpMCDU(WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();
      return tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
    }

    Future<MCDUKeypadOverlay> enterFplList(WidgetTester tester, {List<StoredFltPlan>? plans}) async {
      final overlay = await pumpMCDU(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      screenState.loadStoredPlansForTesting(plans ?? [testPlan1]);
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'FPL'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L')); // ◄FPL LIST from 1/1
      await tester.pumpAndSettle();

      return overlay;
    }

    void typeText(WidgetTester tester, String text) {
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      screenState.setScratchpadForTesting(text);
    }

    // 1. New plan name + FPL LIST 1L -> CREATE
    testWidgets('1. New plan name + FPL LIST 1L navigates to CREATE definition screen', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      expect(find.text('FPL LIST       1/1'), findsOneWidget);

      typeText(tester, 'KPHX-KMSP');
      await tester.pumpAndSettle();
      expect(screenState.currentScratchpad, 'KPHX-KMSP');

      // 1L SHOW FPL with new name
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      expect(screenState.isFplCreateActiveForTesting, isTrue);
      expect(screenState.currentScratchpad, isEmpty);
      expect(find.text('KPHX-KMSP FPL 1/1'), findsOneWidget);
    });

    // 2. Existing plan name + FPL LIST 1L -> SHOW FPL
    testWidgets('2. Existing plan name + FPL LIST 1L opens review SHOW FPL screen', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, 'VFR01');
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      expect(screenState.isFplCreateActiveForTesting, isFalse);
      expect(find.text('SHOW FPL       1/1'), findsOneWidget);
      expect(find.text('PLAN: VFR01'), findsOneWidget);
    });

    // 3. FPL LIST 1R remains SHOW FPL review
    testWidgets('3. FPL LIST 1R remains SHOW FPL review shortcut', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      // Select plan 1
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      // Clear scratchpad
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'CLR'));
      await tester.pumpAndSettle();

      // Press 1R
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      expect(screenState.isFplCreateActiveForTesting, isFalse);
      expect(find.text('SHOW FPL       1/1'), findsOneWidget);
      expect(find.text('PLAN: VFR01'), findsOneWidget);
    });

    // 4. Standard name KPHX-KMSP pre-populates origin and destination
    testWidgets('4. Standard name KPHX-KMSP pre-populates origin and destination', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, 'KPHX-KMSP');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      final createState = screenState.fltPlanCreateStateForTesting;
      expect(createState, isNotNull);
      expect(createState!.originIdent, 'KPHX');
      expect(createState.destinationIdent, 'KMSP');
      expect(find.text('KPHX'), findsOneWidget);
      expect(find.text('KMSP'), findsOneWidget);
    });

    // 5. Standard name with suffix KPHX-KMSP1 pre-populates origin and destination
    testWidgets('5. Standard name with suffix KPHX-KMSP1 pre-populates origin and destination', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, 'KPHX-KMSP1');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      final createState = screenState.fltPlanCreateStateForTesting;
      expect(createState, isNotNull);
      expect(createState!.originIdent, 'KPHX');
      expect(createState.destinationIdent, 'KMSP');
      expect(find.text('KPHX-KMSP1 FPL 1/1'), findsOneWidget);
    });

    // 6. Non-standard name PATROL01 starts with origin/destination blank
    testWidgets('6. Non-standard name PATROL01 starts with origin and destination dashes', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, 'PATROL01');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      final createState = screenState.fltPlanCreateStateForTesting;
      expect(createState, isNotNull);
      expect(createState!.originIdent, isNull);
      expect(createState.destinationIdent, isNull);
      expect(find.text('PATROL01 FPL 1/1'), findsOneWidget);
      expect(find.text('----'), findsNWidgets(2)); // Origin and Destination
    });

    // 7. Manual origin entry via 1L in CREATE
    testWidgets('7. Manual origin entry via 1L updates origin and clears scratchpad', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, 'PATROL01');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      typeText(tester, 'VTBD');
      await tester.pumpAndSettle();
      expect(screenState.currentScratchpad, 'VTBD');

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      expect(screenState.currentScratchpad, isEmpty);
      expect(screenState.fltPlanCreateStateForTesting!.originIdent, 'VTBD');
      expect(find.text('VTBD'), findsOneWidget);
    });

    // 8. Manual destination entry via 2R in CREATE
    testWidgets('8. Manual destination entry via 2R updates destination and clears scratchpad', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, 'PATROL01');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      typeText(tester, 'VTBK');
      await tester.pumpAndSettle();
      expect(screenState.currentScratchpad, 'VTBK');

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2R'));
      await tester.pumpAndSettle();

      expect(screenState.currentScratchpad, isEmpty);
      expect(screenState.fltPlanCreateStateForTesting!.destinationIdent, 'VTBK');
      expect(find.text('VTBK'), findsOneWidget);
    });

    // 9. Default groundspeed 120 displayed in CREATE
    testWidgets('9. Default groundspeed 120 displayed at 1R in CREATE', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, 'KPHX-KMSP');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      expect(screenState.fltPlanCreateStateForTesting!.groundspeed, 120);
      expect(find.text('120'), findsOneWidget);
    });

    // 10. Groundspeed 250 entered via 1R updates speed
    testWidgets('10. Groundspeed 250 entered via 1R updates speed', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, 'KPHX-KMSP');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      typeText(tester, '250');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      expect(screenState.fltPlanCreateStateForTesting!.groundspeed, 250);
      expect(find.text('250'), findsOneWidget);
      expect(screenState.currentScratchpad, isEmpty);
    });

    // 11. Route Waypoint via 2L
    testWidgets('11. Route waypoint via 2L appends leg to create state', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, 'KPHX-KMSP');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      typeText(tester, 'DRK');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      expect(screenState.currentScratchpad, isEmpty);
      expect(screenState.fltPlanCreateStateForTesting!.legs.length, 1);
      expect(screenState.fltPlanCreateStateForTesting!.legs[0].fixIdent, 'DRK');
      expect(find.text('DRK'), findsOneWidget);
    });

    // 12. Sequential Route Waypoints via 3L–5L
    testWidgets('12. Sequential route waypoints via 3L-5L', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, 'KPHX-KMSP');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      typeText(tester, 'DRK');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      typeText(tester, 'INW');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      typeText(tester, 'CNY');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      expect(screenState.fltPlanCreateStateForTesting!.legs.length, 3);
      expect(find.text('DRK'), findsOneWidget);
      expect(find.text('INW'), findsOneWidget);
      expect(find.text('CNY'), findsOneWidget);
    });

    // 13. Destination transferred from right side (2R) into scratchpad
    testWidgets('13. Pressing 2R with empty scratchpad transfers destination to scratchpad', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, 'KPHX-KMSP');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      expect(screenState.currentScratchpad, isEmpty);

      // Press 2R
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2R'));
      await tester.pumpAndSettle();

      expect(screenState.currentScratchpad, 'KMSP');
    });

    // 14. Destination can be inserted as final route leg
    testWidgets('14. Destination can be inserted into route as final waypoint', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, 'KPHX-KMSP');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      // Right-to-left transfer
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2R'));
      await tester.pumpAndSettle();
      expect(screenState.currentScratchpad, 'KMSP');

      // Insert at 2L
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      expect(screenState.currentScratchpad, isEmpty);
      expect(screenState.fltPlanCreateStateForTesting!.legs.last.fixIdent, 'KMSP');
    });

    // 15. CREATE does not finalize merely from setDestination
    testWidgets('15. CREATE does not finalize merely from setDestination', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, 'PATROL01');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      typeText(tester, 'VTBK');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2R'));
      await tester.pumpAndSettle();

      expect(screenState.isFplCreateActiveForTesting, isTrue);
      expect(screenState.fltPlanCreateStateForTesting!.isFinalized, isFalse);
    });

    // 16-18. Valid finalization creates StoredFltPlan, adds to list, and returns to FPL LIST
    testWidgets('16-18. Valid finalization via 6R creates StoredFltPlan, adds to list, and returns to FPL LIST', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, 'KPHX-KMSP');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      // Insert waypoint DRK
      typeText(tester, 'DRK');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      // Insert final destination leg KMSP
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2R'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      // Finalize via 6R FPL SEL►
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pumpAndSettle();

      // Returned to FPL LIST
      expect(screenState.isFplCreateActiveForTesting, isFalse);
      expect(find.text('FPL LIST       1/1'), findsOneWidget);

      // Verify newly created plan is in storedPlans
      final plans = screenState.storedPlansForTesting;
      expect(plans.any((p) => p.name == 'KPHX-KMSP'), isTrue);
      final newPlan = plans.firstWhere((p) => p.name == 'KPHX-KMSP');
      expect(newPlan.originIdent, 'KPHX');
      expect(newPlan.destinationIdent, 'KMSP');
      expect(newPlan.legs.length, 2);
      expect(newPlan.legs.last.fixIdent, 'KMSP');
      expect(find.text('KPHX-KMSP'), findsOneWidget);
    });

    // 19. Active FltPlanState unchanged during CREATE
    testWidgets('19. Active FltPlanState remains completely unchanged before, during, and after CREATE', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      const fltEngine = FltPlanEngine();
      var active = FltPlanState.initial();
      active = fltEngine.initializeOrigin(active, 'VTBD').state;
      active = fltEngine.setDestination(active, 'VTBS').state;
      screenState.setFltPlanStateForTesting(active);
      await tester.pumpAndSettle();

      final activeSnapshotBefore = screenState.fltPlanStateForTesting;

      // Navigate to FPL LIST
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      // Enter CREATE
      typeText(tester, 'KPHX-KMSP');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      // Insert final waypoint
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2R'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      // Finalize
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pumpAndSettle();

      final activeSnapshotAfter = screenState.fltPlanStateForTesting;
      expect(activeSnapshotAfter.originIdent, activeSnapshotBefore.originIdent);
      expect(activeSnapshotAfter.destinationIdent, activeSnapshotBefore.destinationIdent);
      expect(activeSnapshotAfter.page, activeSnapshotBefore.page);
      expect(activeSnapshotAfter.legs.length, activeSnapshotBefore.legs.length);
    });

    // 20. Hardware FPL aborts CREATE without creating a plan
    testWidgets('20. Hardware FPL key aborts CREATE and returns to ACTIVE FLT PLAN without saving', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      final initialPlanCount = screenState.storedPlansForTesting.length;

      typeText(tester, 'ABORT01');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();
      expect(screenState.isFplCreateActiveForTesting, isTrue);

      // Press hardware FPL key
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'FPL'));
      await tester.pumpAndSettle();

      expect(screenState.isFplCreateActiveForTesting, isFalse);
      expect(screenState.fltPlanCreateStateForTesting, isNull);
      expect(screenState.storedPlansForTesting.length, initialPlanCount);
      expect(find.text('ACTIVE FLT PLAN 1/1'), findsOneWidget);
    });

    // 21. Validation: invalid origin entry
    testWidgets('21. Invalid origin entry displays INVALID ENTRY', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, 'PATROL01');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      typeText(tester, '1'); // Invalid length < 2
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      expect(screenState.currentScratchpad, 'INVALID ENTRY');
    });

    // 22. Validation: invalid destination entry
    testWidgets('22. Invalid destination entry displays INVALID ENTRY', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, 'PATROL01');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      typeText(tester, 'TOOLONGIDENT'); // Invalid length > 5
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2R'));
      await tester.pumpAndSettle();

      expect(screenState.currentScratchpad, 'INVALID ENTRY');
    });

    // 23. Validation: invalid groundspeed entry
    testWidgets('23. Invalid groundspeed entry displays INVALID ENTRY', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, 'KPHX-KMSP');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      typeText(tester, '0'); // Invalid speed <= 0
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      expect(screenState.currentScratchpad, 'INVALID ENTRY');
    });

    // 24. Validation: incomplete finalization
    testWidgets('24. Incomplete finalization when final leg is not destination displays INVALID ENTRY', (WidgetTester tester) async {
      final overlay = await enterFplList(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, 'KPHX-KMSP');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      // Only enter DRK, missing destination KMSP as final leg
      typeText(tester, 'DRK');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      // Finalize attempt
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pumpAndSettle();

      expect(screenState.currentScratchpad, 'INVALID ENTRY');
      expect(screenState.isFplCreateActiveForTesting, isTrue);
    });

    // 25. Subsystem isolation: RADIO, NAV, POS INIT, GAME
    testWidgets('25. Subsystem isolation: Radio, NAV, POS INIT, and Game modes remain isolated and functional', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);

      // Check RADIO
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'RADIO'));
      await tester.pumpAndSettle();
      expect(find.text('RADIO        1/2'), findsOneWidget);

      // Check NAV
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();
      expect(find.text('NAV INDEX      1/2'), findsOneWidget);

      // Check FPL return
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'FPL'));
      await tester.pumpAndSettle();
      expect(find.text('ACTIVE FLT PLAN 1/1'), findsOneWidget);
    });
  });
}
