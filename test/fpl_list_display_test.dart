// test/fpl_list_display_test.dart
// Phase 19E-E-C — FplListDisplayAdapter Unit Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/stored_flt_plan.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/flt_plan_list_state.dart';
import 'package:mcdu_app/features/simulation/flt_plan/presentation/fpl_list_display_adapter.dart';

void main() {
  group('Phase 19E-E-C FplListDisplayAdapter Tests', () {
    const plan1 = StoredFltPlan(
      id: 'id-1',
      name: 'VFR01',
      storageDevice: FltPlanStorageDevice.internal,
      originIdent: 'VTBD',
      destinationIdent: 'VTBS',
    );

    const plan2 = StoredFltPlan(
      id: 'id-2',
      name: 'IFR02',
      storageDevice: FltPlanStorageDevice.internal,
      originIdent: 'VTBS',
      destinationIdent: 'VTSP',
    );

    const plan3 = StoredFltPlan(
      id: 'id-3',
      name: 'TRAIN03',
      storageDevice: FltPlanStorageDevice.card,
      originIdent: 'VTBD',
      destinationIdent: 'VTCC',
    );

    // 1. empty list
    test('1. empty list renders blank rows without crashing or injecting fake plans', () {
      final state = FltPlanListState.initial();
      final mcduState = FplListDisplayAdapter.toMCDUState(state, scratchpad: '');

      expect(mcduState.currentPage.pageId, 'FPL_LIST');
      expect(mcduState.currentPage.title, contains('FPL LIST'));
      expect(mcduState.currentPage.leftLabels[0], isEmpty);
      expect(mcduState.currentPage.leftLabels[1], isEmpty);
      expect(mcduState.currentPage.leftLabels[2], isEmpty);
      expect(mcduState.currentPage.leftLabels[3], isEmpty);
      expect(mcduState.currentPage.leftLabels[4], isEmpty);
      expect(mcduState.currentPage.leftLabels[5], '◄FPL'); // 6L return prompt
    });

    // 2. one stored FPL
    test('2. one stored FPL renders plan name at 1L and blanks below', () {
      final state = FltPlanListState.initial().copyWith(plans: [plan1]);
      final mcduState = FplListDisplayAdapter.toMCDUState(state, scratchpad: '');

      expect(mcduState.currentPage.leftLabels[0], 'VFR01');
      expect(mcduState.currentPage.leftLabels[1], isEmpty);
      expect(mcduState.currentPage.leftLabels[2], isEmpty);
    });

    // 3. multiple stored FPLs
    test('3. multiple stored FPLs render in sequential order', () {
      final state = FltPlanListState.initial().copyWith(plans: [plan1, plan2, plan3]);
      final mcduState = FplListDisplayAdapter.toMCDUState(state, scratchpad: '');

      expect(mcduState.currentPage.leftLabels[0], 'VFR01');
      expect(mcduState.currentPage.leftLabels[1], 'IFR02');
      expect(mcduState.currentPage.leftLabels[2], 'TRAIN03');
    });

    // 4. selected item
    test('4. selected item reflects selection indicator', () {
      final state = FltPlanListState.initial().copyWith(
        plans: [plan1, plan2],
        selectedIndex: 1,
      );
      final mcduState = FplListDisplayAdapter.toMCDUState(state, scratchpad: '');

      expect(mcduState.currentPage.leftLabels[0], 'VFR01');
      expect(mcduState.currentPage.leftLabels[1], contains('IFR02'));
      expect(mcduState.currentPage.leftLabels[1], startsWith('* '));
    });

    // 5. page number
    test('5. page number reflects state pageIndex and totalPages', () {
      final state = FltPlanListState(
        plans: [plan1],
        pageIndex: 1,
        totalPages: 2,
      );
      final mcduState = FplListDisplayAdapter.toMCDUState(state, scratchpad: '');

      expect(mcduState.currentPage.title, 'FPL LIST       1/2');
    });

    // 6. title
    test('6. title contains FPL LIST', () {
      final state = FltPlanListState.initial();
      final mcduState = FplListDisplayAdapter.toMCDUState(state, scratchpad: '');

      expect(mcduState.currentPage.title, startsWith('FPL LIST'));
    });

    // 7. LSK placement
    test('7. LSK placement puts plans on 1L-5L and return prompt on 6L', () {
      final state = FltPlanListState.initial().copyWith(plans: [plan1]);
      final mcduState = FplListDisplayAdapter.toMCDUState(state, scratchpad: '');

      expect(mcduState.currentPage.leftLabels[0], 'VFR01'); // 1L
      expect(mcduState.currentPage.leftLabels[5], '◄FPL');  // 6L
      expect(mcduState.currentPage.leftLabels.length, 6);
      expect(mcduState.currentPage.rightLabels.length, 6);
    });

    // 8. PREV/NEXT labels if PDF confirmed
    test('8. PREV/NEXT labels: hardware PREV/NEXT keys drive paging (DEFERRED / NOT EVIDENCED on screen labels)', () {
      // In AW139 MCDU, PREV/NEXT are physical MCDU keys that update page number 1/2 -> 2/2.
      // Soft labels for PREV/NEXT are not drawn on 14x24 rows.
      final state = FltPlanListState(plans: [plan1], pageIndex: 2, totalPages: 2);
      final mcduState = FplListDisplayAdapter.toMCDUState(state, scratchpad: '');
      expect(mcduState.currentPage.title, contains('2/2'));
    });

    // 9. storage device if PDF confirmed
    test('9. storage device: stored in domain model (DEFERRED / NOT EVIDENCED on basic list line)', () {
      // Storage device field exists in StoredFltPlan model. Basic list layout displays names.
      final state = FltPlanListState.initial().copyWith(plans: [plan3]);
      expect(state.plans.first.storageDevice, FltPlanStorageDevice.card);
    });

    // 10. scratchpad preservation
    test('10. scratchpad is preserved exactly and not mutated', () {
      final state = FltPlanListState.initial();
      final mcduState = FplListDisplayAdapter.toMCDUState(state, scratchpad: 'VTBD');

      expect(mcduState.scratchpad, 'VTBD');
    });

    // 11. no fake FPL
    test('11. no fake FPL or hardcoded demo plans injected when list is empty', () {
      final state = FltPlanListState.initial();
      final mcduState = FplListDisplayAdapter.toMCDUState(state, scratchpad: '');

      for (int i = 0; i < 5; i++) {
        expect(mcduState.currentPage.leftLabels[i], isEmpty);
        expect(mcduState.currentPage.leftLabels[i].contains('VTBL'), isFalse);
        expect(mcduState.currentPage.leftLabels[i].contains('VTBH'), isFalse);
      }
    });

    // 12. no mutation of input state
    test('12. adapter never mutates input FltPlanListState', () {
      final state = FltPlanListState.initial().copyWith(plans: [plan1]);
      FplListDisplayAdapter.toMCDUState(state, scratchpad: 'MUTATE_TEST');

      expect(state.plans.length, 1);
      expect(state.plans.first, equals(plan1));
      expect(state.selectedIndex, isNull);
    });
  });
}
