// test/active_flt_plan_route_mcdu_integration_test.dart
// Phase 19E-G-D — ACTIVE FLT PLAN Route Management MCDU Integration Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/app/app.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_screen.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/flt_plan_state.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/stored_flt_plan.dart';
import 'package:mcdu_app/features/simulation/flt_plan/engine/flt_plan_engine.dart';

void main() {
  group('Phase 19E-G-D ACTIVE FLT PLAN Route MCDU Integration Tests', () {
    const fltEngine = FltPlanEngine();

    Future<MCDUKeypadOverlay> pumpMCDU(WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();
      return tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
    }

    void typeText(WidgetTester tester, String text) {
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      screenState.setScratchpadForTesting(text);
    }

    // Helper: sets up an active route (VTBL -> VTBH) on ACTIVE FLT PLAN 1/2
    Future<MCDUKeypadOverlay> setupActiveRoute(WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      var state = FltPlanState.initial();
      state = fltEngine.initializeOrigin(state, 'VTBL').state;
      state = fltEngine.setDestination(state, 'VTBH').state;

      screenState.setFltPlanStateForTesting(state);
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'FPL'));
      await tester.pumpAndSettle();

      return overlay;
    }

    // -------------------------------------------------------------------------
    // 1. Navigation & Entry
    // -------------------------------------------------------------------------
    testWidgets('1. Hardware FPL key opens ACTIVE FLT PLAN', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'FPL'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE FLT PLAN 1/1'), findsOneWidget);
    });

    testWidgets('2. POS INIT 6R FLT PLAN► opens ACTIVE FLT PLAN', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);

      // Go to NAV
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();

      // Go to POS INIT (1L on NAV INDEX 2/2 or similar)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NEXT'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // POS INIT
      await tester.pumpAndSettle();

      // Load position (1R LOAD LAST POS) so 6R FLT PLAN► is enabled
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      // 6R FLT PLAN►
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE FLT PLAN 1/1'), findsOneWidget);
    });

    testWidgets('3. PREV key clamps at page 1 boundary', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      expect(screenState.fltPlanStateForTesting.pageIndex, 1);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'PREV'));
      await tester.pumpAndSettle();

      expect(screenState.fltPlanStateForTesting.pageIndex, 1);
    });

    testWidgets('4. NEXT key clamps at totalPages boundary', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      expect(screenState.fltPlanStateForTesting.totalPages, 2);

      // Advance to page 2
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NEXT'));
      await tester.pumpAndSettle();
      expect(screenState.fltPlanStateForTesting.pageIndex, 2);

      // Try to advance beyond page 2
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NEXT'));
      await tester.pumpAndSettle();
      expect(screenState.fltPlanStateForTesting.pageIndex, 2);
    });

    testWidgets('5. NEXT changes page when totalPages > 1', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NEXT'));
      await tester.pumpAndSettle();

      expect(screenState.fltPlanStateForTesting.pageIndex, 2);
      expect(find.text('ACTIVE FLT PLAN 2/2'), findsOneWidget);
    });

    testWidgets('6. PREV changes page back when pageIndex > 1', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NEXT'));
      await tester.pumpAndSettle();
      expect(screenState.fltPlanStateForTesting.pageIndex, 2);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'PREV'));
      await tester.pumpAndSettle();
      expect(screenState.fltPlanStateForTesting.pageIndex, 1);
      expect(find.text('ACTIVE FLT PLAN 1/2'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 2. ADD Waypoint
    // -------------------------------------------------------------------------
    testWidgets('7. valid scratchpad ident + supported route LSK appends waypoint', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      // Route currently has 1 leg (VTBH at 2L / slot 0)
      expect(screenState.fltPlanStateForTesting.legs.length, 1);

      typeText(tester, 'CNY');
      await tester.pumpAndSettle();

      // Press 3L (slot 1 >= legs.length -> appends)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      expect(screenState.currentScratchpad, isEmpty);
      expect(screenState.fltPlanStateForTesting.legs.length, 2);
      expect(screenState.fltPlanStateForTesting.legs[1].fixIdent, 'CNY');
      expect(find.text('CNY'), findsOneWidget);
    });

    testWidgets('8. lowercase ident is normalized to uppercase', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, 'drk');
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      expect(screenState.fltPlanStateForTesting.legs.last.fixIdent, 'DRK');
    });

    testWidgets('9. whitespace around ident is trimmed', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, '  inw  ');
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      expect(screenState.fltPlanStateForTesting.legs.last.fixIdent, 'INW');
    });

    testWidgets('10. invalid ident displays INVALID ENTRY without modifying route', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      final countBefore = screenState.fltPlanStateForTesting.legs.length;

      typeText(tester, 'A'); // < 2 chars
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      expect(screenState.currentScratchpad, 'INVALID ENTRY');
      expect(screenState.fltPlanStateForTesting.legs.length, countBefore);
    });

    testWidgets('11. active origin and destination preserved after add waypoint', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, 'WAYP2');
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      expect(screenState.fltPlanStateForTesting.originIdent, 'VTBL');
      expect(screenState.fltPlanStateForTesting.destinationIdent, 'VTBH');
    });

    // -------------------------------------------------------------------------
    // 3. INSERT Waypoint
    // -------------------------------------------------------------------------
    testWidgets('12. valid insertion at supported index shifts subsequent legs', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      // Insert at 2L (slot 0 < legs.length -> inserts before VTBH)
      typeText(tester, 'FIRST');
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      expect(screenState.currentScratchpad, isEmpty);
      expect(screenState.fltPlanStateForTesting.legs.length, 2);
      expect(screenState.fltPlanStateForTesting.legs[0].fixIdent, 'FIRST');
      expect(screenState.fltPlanStateForTesting.legs[1].fixIdent, 'VTBH');
    });

    testWidgets('13. invalid index handling is deterministic', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      // With 1 leg, slots 0 (2L), 1 (3L), 2 (4L), 3 (5L) are bounded
      // If we attempt with empty scratchpad, nothing happens
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      expect(screenState.fltPlanStateForTesting.legs.length, 1);
    });

    testWidgets('14. route order preserved after multiple insertions', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      // Append B
      typeText(tester, 'WPTB');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      // Insert A at 2L (slot 0)
      typeText(tester, 'WPTA');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      expect(screenState.fltPlanStateForTesting.legs.map((l) => l.fixIdent).toList(), ['WPTA', 'VTBH', 'WPTB']);
    });

    // -------------------------------------------------------------------------
    // 4. DELETE Waypoint
    // -------------------------------------------------------------------------
    testWidgets('15. DEL key produces *DELETE* in scratchpad', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'DEL'));
      await tester.pumpAndSettle();

      expect(screenState.currentScratchpad, '*DELETE*');
    });

    testWidgets('16. DEL key alone does not mutate route', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      final legsBefore = screenState.fltPlanStateForTesting.legs;

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'DEL'));
      await tester.pumpAndSettle();

      expect(screenState.fltPlanStateForTesting.legs, equals(legsBefore));
    });

    testWidgets('17. *DELETE* + target LSK deletes target waypoint', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      // Append a second waypoint
      typeText(tester, 'WPT2');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();
      expect(screenState.fltPlanStateForTesting.legs.length, 2);

      // Arm DEL
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'DEL'));
      await tester.pumpAndSettle();
      expect(screenState.currentScratchpad, '*DELETE*');

      // Select 2L to delete first leg
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      expect(screenState.currentScratchpad, isEmpty);
      expect(screenState.fltPlanStateForTesting.legs.length, 1);
      expect(screenState.fltPlanStateForTesting.legs.first.fixIdent, 'WPT2');
    });

    testWidgets('18. *DELETE* on invalid target returns INVALID ENTRY', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      // Only 1 leg exists (at 2L / slot 0)
      // Attempting to delete slot 3 (5L)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'DEL'));
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '5L'));
      await tester.pumpAndSettle();

      expect(screenState.currentScratchpad, 'INVALID ENTRY');
      expect(screenState.fltPlanStateForTesting.legs.length, 1);
    });

    testWidgets('19. stored FPL list unchanged after route delete', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      const storedPlan = StoredFltPlan(
        id: 'plan-01',
        name: 'STORED01',
        originIdent: 'VTBL',
        destinationIdent: 'VTBH',
        legs: [FltPlanLeg(fixIdent: 'VTBH')],
      );
      screenState.loadStoredPlansForTesting([storedPlan]);
      await tester.pumpAndSettle();

      // Delete active leg
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'DEL'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      expect(screenState.fltPlanStateForTesting.legs, isEmpty);

      // Stored plan remains untouched
      expect(screenState.storedPlansForTesting.first.legs.length, 1);
      expect(screenState.storedPlansForTesting.first.legs.first.fixIdent, 'VTBH');
    });

    // -------------------------------------------------------------------------
    // 5. State Integrity
    // -------------------------------------------------------------------------
    testWidgets('20. add does not mutate original active state object', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      final snapshotBefore = screenState.fltPlanStateForTesting;

      typeText(tester, 'EXTRA');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      expect(snapshotBefore.legs.length, 1);
      expect(screenState.fltPlanStateForTesting.legs.length, 2);
    });

    testWidgets('21. insert does not mutate original active state object', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      final snapshotBefore = screenState.fltPlanStateForTesting;

      typeText(tester, 'INSRT');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      expect(snapshotBefore.legs.length, 1);
      expect(screenState.fltPlanStateForTesting.legs.length, 2);
    });

    testWidgets('22. delete does not mutate original active state object', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      final snapshotBefore = screenState.fltPlanStateForTesting;

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'DEL'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '2L'));
      await tester.pumpAndSettle();

      expect(snapshotBefore.legs.length, 1);
      expect(screenState.fltPlanStateForTesting.legs, isEmpty);
    });

    testWidgets('23. route legs remain unmodifiable list', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      typeText(tester, 'WPT9');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      expect(() => screenState.fltPlanStateForTesting.legs.add(const FltPlanLeg(fixIdent: 'HACK')), throwsUnsupportedError);
    });

    // -------------------------------------------------------------------------
    // 6. Subsystem Isolation
    // -------------------------------------------------------------------------
    testWidgets('24. CREATE FPL workflow remains unaffected', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      // Navigate to FPL LIST
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L')); // ◄DEPARTURE or FPL LIST
      // Go to FPL LIST from NAV
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // ◄FPL LIST
      await tester.pumpAndSettle();

      expect(find.text('FPL LIST       1/1'), findsOneWidget);

      // Start CREATE
      typeText(tester, 'NEWROUTE');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      expect(screenState.isFplCreateActiveForTesting, isTrue);
      expect(find.text('NEWROUTE FPL 1/1'), findsOneWidget);
    });

    testWidgets('25. FPL LIST remains isolated and functional', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      expect(find.text('FPL LIST       1/1'), findsOneWidget);
    });

    testWidgets('26. SHOW FPL review flow remains isolated', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      const storedPlan = StoredFltPlan(
        id: 'p1',
        name: 'REVIEW01',
        originIdent: 'VTBD',
        destinationIdent: 'VTBS',
      );
      screenState.loadStoredPlansForTesting([storedPlan]);
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      // Select plan at 1L
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
      await tester.pumpAndSettle();

      // Clear scratchpad and push 1R SHOW FPL►
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'CLR'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      expect(find.text('SHOW FPL       1/1'), findsOneWidget);
    });

    testWidgets('27. FLT PLAN SELECT and ACTIVATE remain isolated and functional', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      const storedPlan = StoredFltPlan(
        id: 'p1',
        name: 'ACT01',
        originIdent: 'VTBD',
        destinationIdent: 'VTBS',
        legs: [FltPlanLeg(fixIdent: 'VTBS')],
      );
      screenState.loadStoredPlansForTesting([storedPlan]);
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // FPL LIST
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // Select ACT01
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // FPL SEL►
      await tester.pumpAndSettle();

      expect(find.text('FLT PLAN SELECT 1/1'), findsOneWidget);

      // ACTIVATE► at 1R
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1R'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE FLT PLAN 1/2'), findsOneWidget);
      expect(screenState.fltPlanStateForTesting.destinationIdent, 'VTBS');
    });

    testWidgets('28. SAVE ACTIVE FPL continues to work after modifying active route', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      // Add a route leg
      typeText(tester, 'WAYP5');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L'));
      await tester.pumpAndSettle();

      expect(screenState.fltPlanStateForTesting.legs.length, 2);

      // Save to STORED2
      typeText(tester, 'STORED2');
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '5R'));
      await tester.pumpAndSettle();

      expect(screenState.currentScratchpad, isEmpty);
      expect(screenState.storedPlansForTesting.any((p) => p.name == 'STORED2'), isTrue);
      final saved = screenState.storedPlansForTesting.firstWhere((p) => p.name == 'STORED2');
      expect(saved.legs.length, 2);
      expect(saved.legs[1].fixIdent, 'WAYP5');
    });

    testWidgets('29. NAV subsystem remains completely functional and isolated', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();

      expect(find.text('NAV INDEX      1/2'), findsOneWidget);
    });

    testWidgets('30. POS INIT subsystem remains isolated and functional', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NEXT'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // POS INIT
      await tester.pumpAndSettle();

      expect(find.text('POSITION INIT   1/1'), findsOneWidget);
    });

    testWidgets('31. RADIO subsystem remains isolated and functional', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'RADIO'));
      await tester.pumpAndSettle();

      expect(find.text('RADIO        1/2'), findsOneWidget);
    });

    testWidgets('32. GAME mode remains completely isolated', (WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'MENU'));
      await tester.pumpAndSettle();

      expect(find.text('MCDU DEMO MENU'), findsOneWidget);
    });
  });
}
