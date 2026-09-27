// test/save_active_flt_plan_mcdu_integration_test.dart
// Phase 19E-F2-B — SAVE ACTIVE FLT PLAN MCDU Integration Tests
// AW139 Manual Reference: p76–77 (ACTIVE FLT PLAN 1/2, LSK 5R)

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/app/app.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_screen.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/flt_plan_state.dart';
import 'package:mcdu_app/features/simulation/flt_plan/engine/flt_plan_engine.dart';

void main() {
  group('Phase 19E-F2-B SAVE ACTIVE FLT PLAN Integration Tests', () {
    const fltEngine = FltPlanEngine();

    Future<MCDUKeypadOverlay> pumpMCDU(WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();
      return tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
    }

    // Helper: sets up an active route (VTBL -> VTBH) on ACTIVE FLT PLAN 1/2
    Future<MCDUKeypadOverlay> setupActiveRoute(WidgetTester tester) async {
      final overlay = await pumpMCDU(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      // Build active plan with origin and destination
      var state = FltPlanState.initial();
      state = fltEngine.initializeOrigin(state, 'VTBL').state;
      state = fltEngine.setDestination(state, 'VTBH').state;

      screenState.setFltPlanStateForTesting(state);
      await tester.pumpAndSettle();

      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'FPL'));
      await tester.pumpAndSettle();

      return overlay;
    }

    testWidgets('1. ACTIVE FLT PLAN 1/2 displays SAVE ACTIVE FLT prompt and 5R saves active plan', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      expect(find.text('ACTIVE FLT PLAN 1/2'), findsOneWidget);
      expect(find.text('SAVE ACTIVE FLT'), findsOneWidget);
      expect(find.text('PLAN TO ----------'), findsOneWidget);

      final activeSnapshotBefore = screenState.fltPlanStateForTesting;

      // Type name "VTBLVTBH" into scratchpad
      for (final char in 'VTBLVTBH'.split('')) {
        overlay.onKeyPressed(MCDUKeyEvent(keyId: char));
      }
      await tester.pumpAndSettle();
      expect(screenState.currentScratchpad, 'VTBLVTBH');

      // Press LSK 5R
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '5R'));
      await tester.pumpAndSettle();

      // Scratchpad cleared
      expect(screenState.currentScratchpad, isEmpty);

      // Verify stored plans list updated
      final storedPlans = screenState.storedPlansForTesting;
      expect(storedPlans.length, 1);
      final saved = storedPlans.first;
      expect(saved.name, 'VTBLVTBH');
      expect(saved.originIdent, 'VTBL');
      expect(saved.destinationIdent, 'VTBH');
      expect(saved.legs.length, activeSnapshotBefore.legs.length);
      expect(saved.legs.first.fixIdent, activeSnapshotBefore.legs.first.fixIdent);

      // Verify ACTIVE FLT PLAN remains intact and unchanged
      final activeSnapshotAfter = screenState.fltPlanStateForTesting;
      expect(activeSnapshotAfter, equals(activeSnapshotBefore));
      expect(activeSnapshotAfter.originIdent, 'VTBL');
      expect(activeSnapshotAfter.destinationIdent, 'VTBH');
      expect(activeSnapshotAfter.page, FltPlanPage.route);
    });

    testWidgets('2. Saved plan is visible when navigating to FPL LIST', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);

      // Type name and save
      for (final char in 'MYTRIP'.split('')) {
        overlay.onKeyPressed(MCDUKeyEvent(keyId: char));
      }
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '5R'));
      await tester.pumpAndSettle();

      // Go to FPL LIST via 6L from ACTIVE FLT PLAN
      // (Or via NAV INDEX 1/2 -> 1L FPL LIST after resetting FPL)
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L')); // ◄FPL LIST
      await tester.pumpAndSettle();

      expect(find.text('FPL LIST       1/1'), findsOneWidget);
      expect(find.text('MYTRIP'), findsOneWidget);
    });

    testWidgets('3. Empty scratchpad on 5R displays INVALID ENTRY and does not create stored plan', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);
      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));

      expect(screenState.currentScratchpad, isEmpty);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '5R'));
      await tester.pumpAndSettle();

      expect(screenState.currentScratchpad, 'INVALID ENTRY');
      expect(screenState.storedPlansForTesting, isEmpty);
    });

    testWidgets('4. Subsystem isolation: SAVE ACTIVE FLT PLAN does not alter Game, Radio, NAV, or POS INIT', (WidgetTester tester) async {
      final overlay = await setupActiveRoute(tester);

      // Save a plan
      for (final char in 'SAVED1'.split('')) {
        overlay.onKeyPressed(MCDUKeyEvent(keyId: char));
      }
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '5R'));
      await tester.pumpAndSettle();

      // Check Radio
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'RADIO'));
      await tester.pumpAndSettle();
      expect(find.text('RADIO        1/2'), findsOneWidget);

      // Check NAV
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'NAV'));
      await tester.pumpAndSettle();
      expect(find.text('NAV INDEX      1/2'), findsOneWidget);

      // Check POS INIT
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '3L')); // NAV IDENT
      await tester.pumpAndSettle();
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6R')); // POS INIT
      await tester.pumpAndSettle();
      expect(find.text('POSITION INIT   1/1'), findsOneWidget);

      // Check MENU / GAME
      overlay.onKeyPressed(MCDUKeyEvent(keyId: 'MENU'));
      await tester.pumpAndSettle();
      expect(find.text('MCDU MENU'), findsOneWidget);

      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L')); // MENU -> GAMES
      await tester.pumpAndSettle();
      expect(find.text('MCDU GAME MENU'), findsOneWidget);
    });
  });
}
