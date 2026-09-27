// test/active_flt_plan_route_display_test.dart
// Phase 19E-G-C — ActiveFltPlanDisplayAdapter Route & Pagination Display Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/flt_plan_state.dart';
import 'package:mcdu_app/features/simulation/flt_plan/presentation/active_flt_plan_display_adapter.dart';

void main() {
  group('Phase 19E-G-C ActiveFltPlanDisplayAdapter Route & Pagination Display Tests', () {
    // -------------------------------------------------------------------------
    // 1. Basic Rendering
    // -------------------------------------------------------------------------
    test('1. renders initial 1/1 unpopulated page with correct prompts', () {
      final state = FltPlanState.initial();
      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(state, scratchpad: '');

      expect(mcduState.currentPage.title, 'ACTIVE FLT PLAN 1/1');
      expect(mcduState.currentPage.rightLabels[0], '----');
      expect(mcduState.currentPage.leftLabels[5], '◄FPL LIST');
      expect(mcduState.currentPage.rightLabels[5], 'PERF INIT►');
    });

    test('2. renders populated active plan with title, legs, and departure prompt', () {
      final state = const FltPlanState(
        originIdent: 'KPHX',
        destinationIdent: 'KMSP',
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [
          FltPlanLeg(fixIdent: 'DRK'),
        ],
      );

      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(state, scratchpad: '');

      expect(mcduState.currentPage.title, 'ACTIVE FLT PLAN 1/2');
      expect(mcduState.currentPage.leftLabels[0], 'KPHX');
      expect(mcduState.currentPage.leftLabels[1], 'DRK');
      expect(mcduState.currentPage.leftLabels[5], '◄DEPARTURE');
      expect(mcduState.currentPage.rightLabels[5], 'PERF INIT►');
    });

    test('3. preserves origin identifier at 1L', () {
      final state = FltPlanState.initial().copyWith(originIdent: 'VTBD');
      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(state, scratchpad: '');

      expect(mcduState.currentPage.leftLabels[0], 'VTBD');
    });

    test('4. preserves destination identifier at 1R/2R according to page mode', () {
      // Unpopulated mode: DEST prompt at 1R
      final sInit = FltPlanState.initial().copyWith(destinationIdent: 'VTBS');
      final mcduInit = ActiveFltPlanDisplayAdapter.toMCDUState(sInit, scratchpad: '');
      expect(mcduInit.currentPage.rightLabels[0], 'VTBS');

      // Populated single leg mode: DEST at 2R
      final sRoute = const FltPlanState(
        originIdent: 'VTBD',
        destinationIdent: 'VTBS',
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [FltPlanLeg(fixIdent: 'VTBS')],
      );
      final mcduRoute = ActiveFltPlanDisplayAdapter.toMCDUState(sRoute, scratchpad: '');
      expect(mcduRoute.currentPage.rightLabels[2], 'DEST');
      expect(mcduRoute.currentPage.rightLabels[3], 'VTBS');
    });

    test('5. preserves scratchpad exactly without mutation or clearing', () {
      final state = FltPlanState.initial();
      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(
        state,
        scratchpad: '*DELETE*',
      );

      expect(mcduState.scratchpad, '*DELETE*');
    });

    // -------------------------------------------------------------------------
    // 2. Page State & Indicator Rendering
    // -------------------------------------------------------------------------
    test('6. renders 1/1 page title', () {
      const state = FltPlanState(
        originIdent: 'VTBD',
        destinationIdent: null,
        page: FltPlanPage.init,
        pageIndex: 1,
        totalPages: 1,
        legs: [],
      );

      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(state, scratchpad: '');
      expect(mcduState.currentPage.title, 'ACTIVE FLT PLAN 1/1');
    });

    test('7. renders 1/2 page title', () {
      const state = FltPlanState(
        originIdent: 'VTBD',
        destinationIdent: 'VTBS',
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [FltPlanLeg(fixIdent: 'VTBS')],
      );

      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(state, scratchpad: '');
      expect(mcduState.currentPage.title, 'ACTIVE FLT PLAN 1/2');
    });

    test('8. renders 1/5 when state provides totalPages: 5', () {
      const state = FltPlanState(
        originIdent: 'RW13L',
        destinationIdent: 'CLL',
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 5,
        legs: [
          FltPlanLeg(fixIdent: 'TTT'),
          FltPlanLeg(fixIdent: 'ARDIA'),
          FltPlanLeg(fixIdent: 'ELLVR'),
          FltPlanLeg(fixIdent: 'CLL'),
        ],
      );

      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(state, scratchpad: '');
      expect(mcduState.currentPage.title, 'ACTIVE FLT PLAN 1/5');
    });

    test('9. preserves supplied pageIndex and totalPages dynamically (e.g. 2/5)', () {
      const state = FltPlanState(
        originIdent: 'RW13L',
        destinationIdent: 'CLL',
        page: FltPlanPage.route,
        pageIndex: 2,
        totalPages: 5,
        legs: [FltPlanLeg(fixIdent: 'CLL')],
      );

      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(state, scratchpad: '');
      expect(mcduState.currentPage.title, 'ACTIVE FLT PLAN 2/5');
    });

    // -------------------------------------------------------------------------
    // 3. Multi-Leg Route Rendering
    // -------------------------------------------------------------------------
    test('10. renders multiple legs from state sequentially on rows 2L–5L', () {
      const state = FltPlanState(
        originIdent: 'KPHX',
        destinationIdent: 'KMSP',
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [
          FltPlanLeg(fixIdent: 'DRK'),
          FltPlanLeg(fixIdent: 'INW'),
          FltPlanLeg(fixIdent: 'CNY'),
          FltPlanLeg(fixIdent: 'KMSP'),
        ],
      );

      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(state, scratchpad: '');

      expect(mcduState.currentPage.leftLabels[0], 'KPHX'); // 1L Origin
      expect(mcduState.currentPage.leftLabels[1], 'DRK');  // 2L Leg 1
      expect(mcduState.currentPage.leftLabels[2], 'INW');  // 3L Leg 2
      expect(mcduState.currentPage.leftLabels[3], 'CNY');  // 4L Leg 3
      expect(mcduState.currentPage.leftLabels[4], 'KMSP'); // 5L Leg 4
      expect(mcduState.currentPage.leftLabels[5], '◄DEPARTURE'); // 6L
    });

    test('11. preserves route order exactly as provided by legs list', () {
      const state = FltPlanState(
        originIdent: 'ORIG',
        destinationIdent: 'DEST',
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [
          FltPlanLeg(fixIdent: 'WPT1'),
          FltPlanLeg(fixIdent: 'WPT2'),
          FltPlanLeg(fixIdent: 'WPT3'),
        ],
      );

      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(state, scratchpad: '');

      expect(mcduState.currentPage.leftLabels[1], 'WPT1');
      expect(mcduState.currentPage.leftLabels[2], 'WPT2');
      expect(mcduState.currentPage.leftLabels[3], 'WPT3');
      expect(mcduState.currentPage.leftLabels[4], isEmpty);
    });

    test('12. does not inject fake waypoints when legs list has fewer items', () {
      const state = FltPlanState(
        originIdent: 'ORIG',
        destinationIdent: 'DEST',
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [
          FltPlanLeg(fixIdent: 'WPT1'),
          FltPlanLeg(fixIdent: 'WPT2'),
        ],
      );

      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(state, scratchpad: '');

      expect(mcduState.currentPage.leftLabels[1], 'WPT1');
      expect(mcduState.currentPage.leftLabels[2], 'WPT2');
      expect(mcduState.currentPage.leftLabels[3], isEmpty);
      expect(mcduState.currentPage.leftLabels[4], isEmpty);
    });

    test('13. does not calculate fake navigation data when leg tracking fields are null', () {
      const state = FltPlanState(
        originIdent: 'KPHX',
        destinationIdent: 'KMSP',
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [
          FltPlanLeg(fixIdent: 'DRK'), // No bearingTrack, distanceNm, ete
          FltPlanLeg(fixIdent: 'INW'),
        ],
      );

      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(state, scratchpad: '');

      // Right labels for legs should remain empty (no fake altitudeSpd)
      expect(mcduState.currentPage.rightLabels[1], isEmpty);
      expect(mcduState.currentPage.rightLabels[2], isEmpty);
      expect(mcduState.currentPage.lines.contains('344T 3.9NM'), isFalse);
    });

    // -------------------------------------------------------------------------
    // 4. LSK Prompts
    // -------------------------------------------------------------------------
    test('14. initial page has ◄FPL LIST at 6L and PERF INIT► at 6R', () {
      final state = FltPlanState.initial();
      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(state, scratchpad: '');

      expect(mcduState.currentPage.leftLabels[5], '◄FPL LIST');
      expect(mcduState.currentPage.rightLabels[5], 'PERF INIT►');
    });

    test('15. populated page has ◄DEPARTURE at 6L', () {
      const state = FltPlanState(
        originIdent: 'VTBD',
        destinationIdent: 'VTBS',
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [FltPlanLeg(fixIdent: 'VTBS')],
      );

      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(state, scratchpad: '');
      expect(mcduState.currentPage.leftLabels[5], '◄DEPARTURE');
    });

    test('16. populated page has PERF INIT► at 6R and SAVE ACTIVE FLT prompt in lines', () {
      const state = FltPlanState(
        originIdent: 'VTBD',
        destinationIdent: 'VTBS',
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [FltPlanLeg(fixIdent: 'VTBS')],
      );

      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(state, scratchpad: '');

      expect(mcduState.currentPage.rightLabels[5], 'PERF INIT►');
      expect(mcduState.currentPage.lines, contains('SAVE ACTIVE FLT'));
      expect(mcduState.currentPage.lines, contains('PLAN TO ----------'));
    });

    // -------------------------------------------------------------------------
    // 5. Isolation & Immutability
    // -------------------------------------------------------------------------
    test('17. adapter has no StoredFltPlan dependency (pure FltPlanState)', () {
      const state = FltPlanState(
        originIdent: 'VTBD',
        destinationIdent: 'VTBS',
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [FltPlanLeg(fixIdent: 'VTBS')],
      );

      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(state, scratchpad: '');
      expect(mcduState.currentPage.pageId, 'FPL');
    });

    test('18. adapter has no CREATE dependency', () {
      final state = FltPlanState.initial();
      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(state, scratchpad: '');
      expect(mcduState.currentPage.title, isNot(contains('CREATE')));
    });

    test('19. adapter has no MCDUScreen dependency', () {
      final state = FltPlanState.initial();
      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(state, scratchpad: '');
      expect(mcduState, isNotNull);
    });

    test('20. adapter does not mutate input state', () {
      const original = FltPlanState(
        originIdent: 'KPHX',
        destinationIdent: 'KMSP',
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 3,
        legs: [FltPlanLeg(fixIdent: 'DRK'), FltPlanLeg(fixIdent: 'KMSP')],
      );

      ActiveFltPlanDisplayAdapter.toMCDUState(original, scratchpad: 'SCRATCH');

      expect(original.originIdent, 'KPHX');
      expect(original.destinationIdent, 'KMSP');
      expect(original.pageIndex, 1);
      expect(original.totalPages, 3);
      expect(original.legs.length, 2);
    });
  });
}
