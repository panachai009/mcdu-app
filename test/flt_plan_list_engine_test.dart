// test/flt_plan_list_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/stored_flt_plan.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/flt_plan_list_state.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/flt_plan_state.dart';
import 'package:mcdu_app/features/simulation/flt_plan/engine/flt_plan_list_engine.dart';

void main() {
  group('FltPlanListEngine Targeted Tests', () {
    const engine = FltPlanListEngine();

    const plan1 = StoredFltPlan(
      id: 'plan-1',
      name: 'VFR-VTBD',
      storageDevice: FltPlanStorageDevice.internal,
      originIdent: 'VTBD',
      destinationIdent: 'VTBS',
    );

    const plan2 = StoredFltPlan(
      id: 'plan-2',
      name: 'IFR-VTBS',
      storageDevice: FltPlanStorageDevice.internal,
      originIdent: 'VTBS',
      destinationIdent: 'VTSP',
    );

    const plan3 = StoredFltPlan(
      id: 'plan-3',
      name: 'TRAIN-01',
      storageDevice: FltPlanStorageDevice.card,
      originIdent: 'VTBD',
      destinationIdent: 'VTCC',
    );

    test('1. empty initial state', () {
      final state = engine.createInitialState();
      expect(state.plans, isEmpty);
      expect(state.isEmpty, isTrue);
      expect(state.isNotEmpty, isFalse);
      expect(state.count, 0);
      expect(state.selectedIndex, isNull);
      expect(state.selectedPlan, isNull);
    });

    test('2. load one stored plan', () {
      final initial = engine.createInitialState();
      final loaded = engine.loadPlans(initial, [plan1]);

      expect(loaded.plans.length, 1);
      expect(loaded.plans.first, equals(plan1));
      expect(loaded.selectedIndex, isNull);
      expect(loaded.selectedPlan, isNull);
    });

    test('3. load multiple stored plans', () {
      final initial = engine.createInitialState();
      final loaded = engine.loadPlans(initial, [plan1, plan2, plan3]);

      expect(loaded.plans.length, 3);
      expect(loaded.plans[0], equals(plan1));
      expect(loaded.plans[1], equals(plan2));
      expect(loaded.plans[2], equals(plan3));
    });

    test('4. select valid index', () {
      final state = engine.loadPlans(engine.createInitialState(), [plan1, plan2, plan3]);
      final selected = engine.selectIndex(state, 1);

      expect(selected.selectedIndex, 1);
      expect(selected.selectedPlan, equals(plan2));

      final selectedById = engine.selectById(state, 'plan-3');
      expect(selectedById.selectedIndex, 2);
      expect(selectedById.selectedPlan, equals(plan3));
    });

    test('5. select invalid index', () {
      final state = engine.loadPlans(engine.createInitialState(), [plan1, plan2]);
      
      // Negative index
      final neg = engine.selectIndex(state, -1);
      expect(neg.selectedIndex, isNull);

      // Out of bounds index
      final outOfBounds = engine.selectIndex(state, 5);
      expect(outOfBounds.selectedIndex, isNull);

      // On empty list
      final emptySelected = engine.selectIndex(engine.createInitialState(), 0);
      expect(emptySelected.selectedIndex, isNull);
    });

    test('6. next selection', () {
      final state = engine.loadPlans(engine.createInitialState(), [plan1, plan2, plan3]);
      
      // When null, next selects index 0
      final step0 = engine.next(state);
      expect(step0.selectedIndex, 0);
      expect(step0.selectedPlan, equals(plan1));

      // Advance from 0 to 1
      final step1 = engine.next(step0);
      expect(step1.selectedIndex, 1);
      expect(step1.selectedPlan, equals(plan2));

      // Advance from 1 to 2
      final step2 = engine.next(step1);
      expect(step2.selectedIndex, 2);
      expect(step2.selectedPlan, equals(plan3));
    });

    test('7. previous selection', () {
      var state = engine.loadPlans(engine.createInitialState(), [plan1, plan2, plan3]);
      state = engine.selectIndex(state, 2);
      expect(state.selectedIndex, 2);

      // Step back to 1
      final prev1 = engine.previous(state);
      expect(prev1.selectedIndex, 1);
      expect(prev1.selectedPlan, equals(plan2));

      // Step back to 0
      final prev0 = engine.previous(prev1);
      expect(prev0.selectedIndex, 0);
      expect(prev0.selectedPlan, equals(plan1));
    });

    test('8. next at boundary', () {
      var state = engine.loadPlans(engine.createInitialState(), [plan1, plan2]);
      state = engine.selectIndex(state, 1); // last item

      final nextState = engine.next(state);
      expect(nextState.selectedIndex, 1, reason: 'Must clamp to last item without overflow or wrap');
    });

    test('9. previous at boundary', () {
      var state = engine.loadPlans(engine.createInitialState(), [plan1, plan2]);
      state = engine.selectIndex(state, 0); // first item

      final prevState = engine.previous(state);
      expect(prevState.selectedIndex, 0, reason: 'Must clamp to first item without underflow or wrap');
    });

    test('10. deterministic ordering', () {
      final inputOrder = [plan2, plan3, plan1];
      final state = engine.loadPlans(engine.createInitialState(), inputOrder);

      expect(state.plans[0].id, 'plan-2');
      expect(state.plans[1].id, 'plan-3');
      expect(state.plans[2].id, 'plan-1');
    });

    test('11. duplicate FPL names if supported', () {
      const dup1 = StoredFltPlan(id: 'uuid-1', name: 'FLIGHT1', originIdent: 'VTBD');
      const dup2 = StoredFltPlan(id: 'uuid-2', name: 'FLIGHT1', originIdent: 'VTBS');

      final state = engine.loadPlans(engine.createInitialState(), [dup1, dup2]);
      expect(state.plans.length, 2);
      expect(state.plans[0].name, 'FLIGHT1');
      expect(state.plans[1].name, 'FLIGHT1');

      final sel1 = engine.selectById(state, 'uuid-1');
      expect(sel1.selectedIndex, 0);
      expect(sel1.selectedPlan?.originIdent, 'VTBD');

      final sel2 = engine.selectById(state, 'uuid-2');
      expect(sel2.selectedIndex, 1);
      expect(sel2.selectedPlan?.originIdent, 'VTBS');
    });

    test('12. add/create plan behavior if implemented', () {
      var state = engine.createInitialState();
      state = engine.addPlan(state, plan1);
      expect(state.plans.length, 1);
      expect(state.plans.first.id, 'plan-1');

      state = engine.addPlan(state, plan2);
      expect(state.plans.length, 2);
      expect(state.plans[1].id, 'plan-2');
    });

    test('13. delete behavior if implemented', () {
      var state = engine.loadPlans(engine.createInitialState(), [plan1, plan2, plan3]);
      state = engine.selectIndex(state, 1); // select plan2

      // Delete non-selected plan3
      state = engine.deletePlanById(state, 'plan-3');
      expect(state.plans.length, 2);
      expect(state.selectedIndex, 1);

      // Delete currently selected plan2
      state = engine.deletePlanById(state, 'plan-2');
      expect(state.plans.length, 1);
      expect(state.selectedIndex, 0);
      expect(state.selectedPlan?.id, 'plan-1');

      // Delete remaining plan1
      state = engine.deletePlanById(state, 'plan-1');
      expect(state.plans.isEmpty, isTrue);
      expect(state.selectedIndex, isNull);
    });

    test('14. state immutability', () {
      final initial = engine.createInitialState();
      final loaded = engine.loadPlans(initial, [plan1]);

      expect(initial.plans, isEmpty);
      expect(loaded.plans.length, 1);

      expect(() => (loaded.plans as dynamic).add(plan2), throwsUnsupportedError);

      final nextState = engine.next(loaded);
      expect(loaded.selectedIndex, isNull);
      expect(nextState.selectedIndex, 0);
    });

    test('15. active FltPlanState is not modified', () {
      final activeState = FltPlanState.initial();
      final initialListState = engine.createInitialState();
      final loadedListState = engine.loadPlans(initialListState, [plan1]);
      engine.next(loadedListState);

      // Verify activeState remains totally pristine
      expect(activeState.originIdent, isNull);
      expect(activeState.destinationIdent, isNull);
      expect(activeState.page, FltPlanPage.init);
      expect(activeState.pageIndex, 1);
      expect(activeState.totalPages, 1);
      expect(activeState.legs, isEmpty);
    });
  });
}
