// test/flt_plan_save_active_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/stored_flt_plan.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/flt_plan_state.dart';
import 'package:mcdu_app/features/simulation/flt_plan/engine/flt_plan_engine.dart';
import 'package:mcdu_app/features/simulation/flt_plan/engine/flt_plan_list_engine.dart';

void main() {
  group('FltPlanEngine.createStoredPlanFromActiveState & Save Active Workflow Unit Tests', () {
    const fltEngine = FltPlanEngine();
    const listEngine = FltPlanListEngine();

    test('1. successfully copies active plan into immutable StoredFltPlan', () {
      final originRes = fltEngine.initializeOrigin(FltPlanState.initial(), 'VTBL');
      final routeRes = fltEngine.setDestination(originRes.state, 'VTBH');
      final activeState = routeRes.state;

      expect(activeState.page, FltPlanPage.route);
      expect(activeState.originIdent, 'VTBL');
      expect(activeState.destinationIdent, 'VTBH');
      expect(activeState.legs, isNotEmpty);

      // Snapshot before save
      final beforeSnapshot = activeState;

      final storedPlan = fltEngine.createStoredPlanFromActiveState(
        state: activeState,
        name: 'VTBL-VTBH',
        id: 'test-save-1',
      );

      expect(storedPlan, isNotNull);
      expect(storedPlan!.id, 'test-save-1');
      expect(storedPlan.name, 'VTBL-VTBH');
      expect(storedPlan.originIdent, 'VTBL');
      expect(storedPlan.destinationIdent, 'VTBH');
      expect(storedPlan.legs.length, activeState.legs.length);
      expect(storedPlan.legs.first.fixIdent, activeState.legs.first.fixIdent);
      expect(storedPlan.legs.first.bearingTrack, activeState.legs.first.bearingTrack);
      expect(storedPlan.legs.first.distanceNm, activeState.legs.first.distanceNm);
      expect(storedPlan.storageDevice, FltPlanStorageDevice.internal);

      // Verify active state immutability
      expect(activeState, equals(beforeSnapshot));
      expect(activeState.originIdent, beforeSnapshot.originIdent);
      expect(activeState.destinationIdent, beforeSnapshot.destinationIdent);
      expect(activeState.page, beforeSnapshot.page);
      expect(activeState.legs, equals(beforeSnapshot.legs));
    });

    test('2. trims plan name whitespace', () {
      final originRes = fltEngine.initializeOrigin(FltPlanState.initial(), 'VTBL');
      final routeRes = fltEngine.setDestination(originRes.state, 'VTBH');

      final storedPlan = fltEngine.createStoredPlanFromActiveState(
        state: routeRes.state,
        name: '   MY-FPL-01   ',
        id: 'test-save-trim',
      );

      expect(storedPlan, isNotNull);
      expect(storedPlan!.name, 'MY-FPL-01');
    });

    test('3. returns null if plan name is empty or all whitespace', () {
      final originRes = fltEngine.initializeOrigin(FltPlanState.initial(), 'VTBL');
      final routeRes = fltEngine.setDestination(originRes.state, 'VTBH');

      final storedPlanEmpty = fltEngine.createStoredPlanFromActiveState(
        state: routeRes.state,
        name: '',
        id: 'test-empty',
      );
      final storedPlanWhitespace = fltEngine.createStoredPlanFromActiveState(
        state: routeRes.state,
        name: '    ',
        id: 'test-spaces',
      );

      expect(storedPlanEmpty, isNull);
      expect(storedPlanWhitespace, isNull);
    });

    test('4. returns null if active plan is not a populated route (missing destination or origin)', () {
      final uninitPlan = FltPlanState.initial();
      final originOnly = fltEngine.initializeOrigin(uninitPlan, 'VTBL').state;

      expect(originOnly.isRouteActive, isFalse);

      final storedFromUninit = fltEngine.createStoredPlanFromActiveState(
        state: uninitPlan,
        name: 'PLAN-A',
        id: 'test-uninit',
      );
      final storedFromOriginOnly = fltEngine.createStoredPlanFromActiveState(
        state: originOnly,
        name: 'PLAN-B',
        id: 'test-orig-only',
      );

      expect(storedFromUninit, isNull);
      expect(storedFromOriginOnly, isNull);
    });

    test('5. adding saved plan to FltPlanListState via addPlan preserves immutability and list state', () {
      final originRes = fltEngine.initializeOrigin(FltPlanState.initial(), 'VTBL');
      final routeRes = fltEngine.setDestination(originRes.state, 'VTBH');

      final storedPlan = fltEngine.createStoredPlanFromActiveState(
        state: routeRes.state,
        name: 'VTBL-VTBH',
        id: 'saved-id-1',
      )!;

      final initialListState = listEngine.createInitialState();
      final updatedListState = listEngine.addPlan(initialListState, storedPlan);

      expect(initialListState.plans, isEmpty);
      expect(updatedListState.plans.length, 1);
      expect(updatedListState.plans.first, equals(storedPlan));

      // Append another plan
      final secondStoredPlan = storedPlan.copyWith(id: 'saved-id-2', name: 'ROUTE-02');
      final stateWithTwo = listEngine.addPlan(updatedListState, secondStoredPlan);

      expect(updatedListState.plans.length, 1);
      expect(stateWithTwo.plans.length, 2);
      expect(stateWithTwo.plans[0], equals(storedPlan));
      expect(stateWithTwo.plans[1], equals(secondStoredPlan));
    });

    test('6. duplicate plan name appends deterministically without mutating previous state', () {
      final originRes = fltEngine.initializeOrigin(FltPlanState.initial(), 'VTBL');
      final routeRes = fltEngine.setDestination(originRes.state, 'VTBH');

      final planA = fltEngine.createStoredPlanFromActiveState(
        state: routeRes.state,
        name: 'DUP-NAME',
        id: 'id-dup-1',
      )!;

      final planB = fltEngine.createStoredPlanFromActiveState(
        state: routeRes.state,
        name: 'DUP-NAME',
        id: 'id-dup-2',
      )!;

      var listState = listEngine.createInitialState();
      listState = listEngine.addPlan(listState, planA);
      listState = listEngine.addPlan(listState, planB);

      expect(listState.plans.length, 2);
      expect(listState.plans[0].name, 'DUP-NAME');
      expect(listState.plans[1].name, 'DUP-NAME');
      expect(listState.plans[0].id, 'id-dup-1');
      expect(listState.plans[1].id, 'id-dup-2');
    });
  });
}
