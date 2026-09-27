// test/active_flt_plan_display_test.dart
// Phase 19E-D-C — ActiveFltPlanDisplayAdapter Unit Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/flt_plan_state.dart';
import 'package:mcdu_app/features/simulation/flt_plan/presentation/active_flt_plan_display_adapter.dart';

void main() {
  group('Phase 19E-D-C ActiveFltPlanDisplayAdapter Tests', () {
    // -------------------------------------------------------------------------
    // A. Empty Plan
    // -------------------------------------------------------------------------
    test('A. Empty plan renders ACTIVE FLT PLAN 1/1 with required prompts', () {
      final state = FltPlanState.initial();
      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(
        state,
        scratchpad: '',
      );

      expect(mcduState.currentPage.title, 'ACTIVE FLT PLAN 1/1');
      expect(mcduState.currentPage.rightLabels[0], '----'); // 1R DEST prompt
      expect(mcduState.currentPage.leftLabels[5], '◄FPL LIST'); // 6L
      expect(mcduState.currentPage.rightLabels[5], 'PERF INIT►'); // 6R
      expect(mcduState.currentPage.lines, contains('RECALL OR CREATE'));
      expect(mcduState.currentPage.lines, contains('FPL NAMED ----------'));
      expect(mcduState.currentPage.lines, contains('FPL STORAGE DEVICE'));
      expect(mcduState.currentPage.lines, contains('LAN'));
    });

    // -------------------------------------------------------------------------
    // B. Initialized Origin
    // -------------------------------------------------------------------------
    test('B. Initialized origin displays ORIGIN at 1L, DEST remains ---- and page 1/1', () {
      final state = FltPlanState.initial().copyWith(originIdent: 'VTBL');
      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(
        state,
        scratchpad: '',
      );

      expect(mcduState.currentPage.title, 'ACTIVE FLT PLAN 1/1');
      expect(mcduState.currentPage.leftLabels[0], 'VTBL'); // 1L
      expect(mcduState.currentPage.rightLabels[0], '----'); // 1R
      expect(mcduState.currentPage.leftLabels[5], '◄FPL LIST'); // 6L
      expect(mcduState.currentPage.rightLabels[5], 'PERF INIT►'); // 6R
    });

    // -------------------------------------------------------------------------
    // C. Origin + Destination
    // -------------------------------------------------------------------------
    test('C. Origin + Destination renders ACTIVE FLT PLAN 1/2 with DEPARTURE at 6L', () {
      final state = FltPlanState.initial().copyWith(
        originIdent: 'VTBL',
        destinationIdent: 'VTBH',
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: const [
          FltPlanLeg(
            fixIdent: 'VTBH',
            bearingTrack: '344T',
            distanceNm: '3.9NM',
            ete: '00+02',
            altitudeSpd: '---/0100',
          ),
        ],
      );

      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(
        state,
        scratchpad: '',
      );

      expect(mcduState.currentPage.title, 'ACTIVE FLT PLAN 1/2');
      expect(mcduState.currentPage.leftLabels[0], 'VTBL'); // 1L
      expect(mcduState.currentPage.leftLabels[1], 'VTBH'); // 2L
      expect(mcduState.currentPage.leftLabels[5], '◄DEPARTURE'); // 6L
      expect(mcduState.currentPage.rightLabels[5], 'PERF INIT►'); // 6R
      expect(mcduState.currentPage.lines, contains('344T 3.9NM'));
      expect(mcduState.currentPage.lines, contains('SAVE ACTIVE FLT'));
      expect(mcduState.currentPage.lines, contains('PLAN TO ----------'));
    });

    // -------------------------------------------------------------------------
    // D. Scratchpad Preservation
    // -------------------------------------------------------------------------
    test('D. Scratchpad content is preserved exactly and not mutated by adapter', () {
      final state = FltPlanState.initial();
      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(
        state,
        scratchpad: 'VTBH',
      );

      expect(mcduState.scratchpad, 'VTBH');
    });

    // -------------------------------------------------------------------------
    // E. No Fake Route Data Injection
    // -------------------------------------------------------------------------
    test('E. Adapter does NOT inject fake route data when leg details are null or empty', () {
      final state = FltPlanState.initial().copyWith(
        originIdent: 'VTBD',
        destinationIdent: 'VTCC',
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: const [
          FltPlanLeg(fixIdent: 'VTCC'), // No bearingTrack or distanceNm
        ],
      );

      final mcduState = ActiveFltPlanDisplayAdapter.toMCDUState(
        state,
        scratchpad: '',
      );

      expect(mcduState.currentPage.title, 'ACTIVE FLT PLAN 1/2');
      expect(mcduState.currentPage.lines.contains('344T 3.9NM'), isFalse);
    });

    // -------------------------------------------------------------------------
    // F. Immutability
    // -------------------------------------------------------------------------
    test('F. Calling adapter never modifies original FltPlanState', () {
      final original = FltPlanState.initial().copyWith(originIdent: 'VTBL');
      ActiveFltPlanDisplayAdapter.toMCDUState(original, scratchpad: 'TEST');

      expect(original.originIdent, 'VTBL');
      expect(original.destinationIdent, isNull);
      expect(original.page, FltPlanPage.init);
    });
  });
}
