// test/flt_plan_create_engine_test.dart
// AW139 FMS MCDU Manual Reference:
// Flight Plan Creation Engine & Domain Tests — Section 3/4 FPL LIST / Procedure 6-1 (p41-44)

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/flt_plan_create_state.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/flt_plan_state.dart'
    show FltPlanLeg;
import 'package:mcdu_app/features/simulation/flt_plan/domain/stored_flt_plan.dart';
import 'package:mcdu_app/features/simulation/flt_plan/engine/flt_plan_create_engine.dart';

void main() {
  group('FltPlanCreateState Domain Model', () {
    test('1. Default values match specification', () {
      const state = FltPlanCreateState(name: 'TEST01');
      expect(state.name, 'TEST01');
      expect(state.originIdent, isNull);
      expect(state.destinationIdent, isNull);
      expect(state.groundspeed, 120);
      expect(state.legs, isEmpty);
      expect(state.isFinalized, isFalse);
    });

    test('2. copyWith creates new immutable instance with updated values', () {
      const initial = FltPlanCreateState(name: 'PLAN1');
      final updated = initial.copyWith(
        originIdent: 'KPHX',
        destinationIdent: 'KMSP',
        groundspeed: 150,
        isFinalized: true,
      );

      expect(initial.originIdent, isNull);
      expect(initial.isFinalized, isFalse);
      expect(updated.name, 'PLAN1');
      expect(updated.originIdent, 'KPHX');
      expect(updated.destinationIdent, 'KMSP');
      expect(updated.groundspeed, 150);
      expect(updated.isFinalized, isTrue);
    });

    test('3. Value equality and hashCode work correctly', () {
      const state1 = FltPlanCreateState(
        name: 'KPHX-KMSP',
        originIdent: 'KPHX',
        destinationIdent: 'KMSP',
        groundspeed: 120,
        legs: [FltPlanLeg(fixIdent: 'DRK'), FltPlanLeg(fixIdent: 'KMSP')],
        isFinalized: false,
      );

      const state2 = FltPlanCreateState(
        name: 'KPHX-KMSP',
        originIdent: 'KPHX',
        destinationIdent: 'KMSP',
        groundspeed: 120,
        legs: [FltPlanLeg(fixIdent: 'DRK'), FltPlanLeg(fixIdent: 'KMSP')],
        isFinalized: false,
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));

      final state3 = state1.copyWith(groundspeed: 140);
      expect(state1, isNot(equals(state3)));
    });

    test('4. Legs list in copyWith is unmodifiable', () {
      final mutableList = [const FltPlanLeg(fixIdent: 'DRK')];
      final state = const FltPlanCreateState(name: 'TEST').copyWith(legs: mutableList);

      expect(() => (state.legs as dynamic).add(const FltPlanLeg(fixIdent: 'INW')),
          throwsUnsupportedError);
    });
  });

  group('FltPlanCreateEngine.createInitialState', () {
    test('5. Empty or whitespace-only name returns failure', () {
      final res1 = FltPlanCreateEngine.createInitialState('');
      expect(res1.isSuccess, isFalse);
      expect(res1.errorMessage, 'INVALID NAME');

      final res2 = FltPlanCreateEngine.createInitialState('   ');
      expect(res2.isSuccess, isFalse);
    });

    test('6. Standard format AAAA-BBBB parses origin and destination', () {
      final res = FltPlanCreateEngine.createInitialState('KPHX-KMSP');
      expect(res.isSuccess, isTrue);
      expect(res.state.name, 'KPHX-KMSP');
      expect(res.state.originIdent, 'KPHX');
      expect(res.state.destinationIdent, 'KMSP');
      expect(res.state.groundspeed, 120);
      expect(res.state.legs, isEmpty);
      expect(res.state.isFinalized, isFalse);
    });

    test('7. Standard format with route number AAAA-BBBBx parses properly', () {
      final res = FltPlanCreateEngine.createInitialState('KPHX-KMSP1');
      expect(res.isSuccess, isTrue);
      expect(res.state.name, 'KPHX-KMSP1');
      expect(res.state.originIdent, 'KPHX');
      expect(res.state.destinationIdent, 'KMSP');
      expect(res.state.groundspeed, 120);
    });

    test('8. Case insensitivity and whitespace trimming on initial creation', () {
      final res = FltPlanCreateEngine.createInitialState('  kphx-kmsp2  ');
      expect(res.isSuccess, isTrue);
      expect(res.state.name, 'KPHX-KMSP2');
      expect(res.state.originIdent, 'KPHX');
      expect(res.state.destinationIdent, 'KMSP');
    });

    test('9. Non-standard name retains name with blank origin and destination', () {
      final res = FltPlanCreateEngine.createInitialState('PATROL01');
      expect(res.isSuccess, isTrue);
      expect(res.state.name, 'PATROL01');
      expect(res.state.originIdent, isNull);
      expect(res.state.destinationIdent, isNull);
      expect(res.state.groundspeed, 120);
      expect(res.state.legs, isEmpty);
    });

    test('10. Non-standard short or distinct name patterns', () {
      final res = FltPlanCreateEngine.createInitialState('TEST_RUN');
      expect(res.isSuccess, isTrue);
      expect(res.state.name, 'TEST_RUN');
      expect(res.state.originIdent, isNull);
      expect(res.state.destinationIdent, isNull);
    });
  });

  group('FltPlanCreateEngine.setOrigin & setDestination', () {
    test('11. setOrigin succeeds with valid 2-5 character identifier', () {
      final init = FltPlanCreateEngine.createInitialState('PATROL01').state;
      final res = FltPlanCreateEngine.setOrigin(init, 'vtbd');
      expect(res.isSuccess, isTrue);
      expect(res.state.originIdent, 'VTBD');
      // Original state remains unchanged
      expect(init.originIdent, isNull);
    });

    test('12. setOrigin rejects invalid characters or lengths', () {
      final init = FltPlanCreateEngine.createInitialState('PATROL01').state;
      final res1 = FltPlanCreateEngine.setOrigin(init, 'A'); // too short (<2)
      expect(res1.isSuccess, isFalse);
      expect(res1.errorMessage, 'INVALID ENTRY');

      final res2 = FltPlanCreateEngine.setOrigin(init, 'ABCDEF'); // too long (>5)
      expect(res2.isSuccess, isFalse);

      final res3 = FltPlanCreateEngine.setOrigin(init, 'VT-BD'); // invalid symbol
      expect(res3.isSuccess, isFalse);
    });

    test('13. setDestination succeeds with valid 2-5 character identifier', () {
      final init = FltPlanCreateEngine.createInitialState('PATROL01').state;
      final res = FltPlanCreateEngine.setDestination(init, 'vtbk');
      expect(res.isSuccess, isTrue);
      expect(res.state.destinationIdent, 'VTBK');
      expect(init.destinationIdent, isNull);
    });

    test('14. setDestination rejects invalid identifier', () {
      final init = FltPlanCreateEngine.createInitialState('PATROL01').state;
      final res = FltPlanCreateEngine.setDestination(init, '1');
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, 'INVALID ENTRY');
    });

    test('15. Cannot set origin or destination if already finalized', () {
      const finalized = FltPlanCreateState(
        name: 'PLAN1',
        originIdent: 'KPHX',
        destinationIdent: 'KMSP',
        isFinalized: true,
      );
      final resO = FltPlanCreateEngine.setOrigin(finalized, 'VTBD');
      expect(resO.isSuccess, isFalse);
      expect(resO.errorMessage, 'CANNOT MODIFY FINALIZED PLAN');

      final resD = FltPlanCreateEngine.setDestination(finalized, 'VTBK');
      expect(resD.isSuccess, isFalse);
      expect(resD.errorMessage, 'CANNOT MODIFY FINALIZED PLAN');
    });
  });

  group('FltPlanCreateEngine.setGroundspeed', () {
    test('16. setGroundspeed succeeds with valid integer or numeric string', () {
      final init = FltPlanCreateEngine.createInitialState('PLAN1').state;
      final res1 = FltPlanCreateEngine.setGroundspeed(init, 140);
      expect(res1.isSuccess, isTrue);
      expect(res1.state.groundspeed, 140);

      final res2 = FltPlanCreateEngine.setGroundspeed(init, ' 160 ');
      expect(res2.isSuccess, isTrue);
      expect(res2.state.groundspeed, 160);
    });

    test('17. setGroundspeed rejects non-numeric or <= 0 values', () {
      final init = FltPlanCreateEngine.createInitialState('PLAN1').state;
      final res1 = FltPlanCreateEngine.setGroundspeed(init, 0);
      expect(res1.isSuccess, isFalse);
      expect(res1.errorMessage, 'INVALID ENTRY');

      final res2 = FltPlanCreateEngine.setGroundspeed(init, -50);
      expect(res2.isSuccess, isFalse);

      final res3 = FltPlanCreateEngine.setGroundspeed(init, 'ABC');
      expect(res3.isSuccess, isFalse);
    });

    test('18. Cannot set groundspeed on finalized plan', () {
      const finalized = FltPlanCreateState(name: 'PLAN1', isFinalized: true);
      final res = FltPlanCreateEngine.setGroundspeed(finalized, 150);
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, 'CANNOT MODIFY FINALIZED PLAN');
    });
  });

  group('FltPlanCreateEngine.addWaypoint', () {
    test('19. Sequential addition of waypoints appends to legs list', () {
      final init = FltPlanCreateEngine.createInitialState('KPHX-KMSP').state;
      final res1 = FltPlanCreateEngine.addWaypoint(init, 'DRK');
      expect(res1.isSuccess, isTrue);
      expect(res1.state.legs.length, 1);
      expect(res1.state.legs.first.fixIdent, 'DRK');

      final res2 = FltPlanCreateEngine.addWaypoint(res1.state, 'INW');
      expect(res2.isSuccess, isTrue);
      expect(res2.state.legs.length, 2);
      expect(res2.state.legs[0].fixIdent, 'DRK');
      expect(res2.state.legs[1].fixIdent, 'INW');

      // Immutability check
      expect(init.legs, isEmpty);
      expect(res1.state.legs.length, 1);
    });

    test('20. Waypoint identifiers are trimmed and uppercased', () {
      final init = FltPlanCreateEngine.createInitialState('PLAN1').state;
      final res = FltPlanCreateEngine.addWaypoint(init, '  drk  ');
      expect(res.isSuccess, isTrue);
      expect(res.state.legs.first.fixIdent, 'DRK');
    });

    test('21. Rejects invalid waypoint ident length or characters', () {
      final init = FltPlanCreateEngine.createInitialState('PLAN1').state;
      final res1 = FltPlanCreateEngine.addWaypoint(init, 'W'); // <2
      expect(res1.isSuccess, isFalse);
      expect(res1.errorMessage, 'INVALID ENTRY');

      final res2 = FltPlanCreateEngine.addWaypoint(init, 'TOOLONG'); // >5
      expect(res2.isSuccess, isFalse);

      final res3 = FltPlanCreateEngine.addWaypoint(init, 'D*RK'); // symbol
      expect(res3.isSuccess, isFalse);
    });

    test('22. Cannot add waypoint to finalized plan', () {
      const finalized = FltPlanCreateState(name: 'PLAN1', isFinalized: true);
      final res = FltPlanCreateEngine.addWaypoint(finalized, 'DRK');
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, 'CANNOT MODIFY FINALIZED PLAN');
    });
  });

  group('FltPlanCreateEngine.finalize', () {
    test('23. Fails when origin is missing', () {
      final state = const FltPlanCreateState(name: 'PLAN1').copyWith(
        destinationIdent: 'KMSP',
        legs: const [FltPlanLeg(fixIdent: 'KMSP')],
      );
      final res = FltPlanCreateEngine.finalize(state, planId: 'p1');
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, 'ORIGIN REQUIRED');
    });

    test('24. Fails when destination is missing', () {
      final state = const FltPlanCreateState(name: 'PLAN1').copyWith(
        originIdent: 'KPHX',
        legs: const [FltPlanLeg(fixIdent: 'KMSP')],
      );
      final res = FltPlanCreateEngine.finalize(state, planId: 'p1');
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, 'DESTINATION REQUIRED');
    });

    test('25. Fails when legs list is empty', () {
      final state = const FltPlanCreateState(
        name: 'KPHX-KMSP',
        originIdent: 'KPHX',
        destinationIdent: 'KMSP',
        legs: [],
      );
      final res = FltPlanCreateEngine.finalize(state, planId: 'p1');
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, 'LEGS REQUIRED');
    });

    test('26. Fails when final leg is not equal to destination (Procedure 6-1 Step 8)', () {
      final state = const FltPlanCreateState(
        name: 'KPHX-KMSP',
        originIdent: 'KPHX',
        destinationIdent: 'KMSP',
        legs: [
          FltPlanLeg(fixIdent: 'DRK'),
          FltPlanLeg(fixIdent: 'INW'),
        ],
      );
      final res = FltPlanCreateEngine.finalize(state, planId: 'p1');
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, 'FINAL WAYPOINT MUST BE DESTINATION');
    });

    test('27. Fails when plan is already finalized', () {
      const state = FltPlanCreateState(
        name: 'KPHX-KMSP',
        originIdent: 'KPHX',
        destinationIdent: 'KMSP',
        legs: [FltPlanLeg(fixIdent: 'KMSP')],
        isFinalized: true,
      );
      final res = FltPlanCreateEngine.finalize(state, planId: 'p1');
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, 'PLAN ALREADY FINALIZED');
    });

    test('28. Successfully finalizes complete plan and returns StoredFltPlan', () {
      final state = const FltPlanCreateState(
        name: 'KPHX-KMSP',
        originIdent: 'KPHX',
        destinationIdent: 'KMSP',
        groundspeed: 135,
        legs: [
          FltPlanLeg(fixIdent: 'DRK'),
          FltPlanLeg(fixIdent: 'INW'),
          FltPlanLeg(fixIdent: 'KMSP'),
        ],
      );

      final res = FltPlanCreateEngine.finalize(state, planId: 'stored_001');
      expect(res.isSuccess, isTrue);
      expect(res.state.isFinalized, isTrue);
      expect(res.finalizedPlan, isNotNull);

      final stored = res.finalizedPlan!;
      expect(stored.id, 'stored_001');
      expect(stored.name, 'KPHX-KMSP');
      expect(stored.storageDevice, FltPlanStorageDevice.internal);
      expect(stored.originIdent, 'KPHX');
      expect(stored.destinationIdent, 'KMSP');
      expect(stored.legs.length, 3);
      expect(stored.legs[0].fixIdent, 'DRK');
      expect(stored.legs[1].fixIdent, 'INW');
      expect(stored.legs[2].fixIdent, 'KMSP');
    });

    test('29. Full Procedure 6-1 end-to-end simulation: standard name', () {
      // Step 1-2: User types KPHX-KMSP
      final r1 = FltPlanCreateEngine.createInitialState('KPHX-KMSP');
      expect(r1.isSuccess, isTrue);
      var current = r1.state;
      expect(current.originIdent, 'KPHX');
      expect(current.destinationIdent, 'KMSP');

      // Step 5: Groundspeed (kept at 120 or modified to 140)
      final r2 = FltPlanCreateEngine.setGroundspeed(current, 140);
      expect(r2.isSuccess, isTrue);
      current = r2.state;

      // Step 6-7: Waypoints
      final r3 = FltPlanCreateEngine.addWaypoint(current, 'DRK');
      final r4 = FltPlanCreateEngine.addWaypoint(r3.state, 'INW');
      final r5 = FltPlanCreateEngine.addWaypoint(r4.state, 'CNY');
      current = r5.state;
      expect(current.legs.map((l) => l.fixIdent).toList(), ['DRK', 'INW', 'CNY']);

      // Attempt premature finalize: fails
      final failFin = FltPlanCreateEngine.finalize(current, planId: 'id1');
      expect(failFin.isSuccess, isFalse);
      expect(failFin.errorMessage, 'FINAL WAYPOINT MUST BE DESTINATION');

      // Step 8: Enter destination waypoint KMSP
      final r6 = FltPlanCreateEngine.addWaypoint(current, 'KMSP');
      current = r6.state;

      // Finalize: succeeds
      final finalRes = FltPlanCreateEngine.finalize(current, planId: 'plan_kphx_kmsp');
      expect(finalRes.isSuccess, isTrue);
      expect(finalRes.finalizedPlan!.name, 'KPHX-KMSP');
      expect(finalRes.finalizedPlan!.originIdent, 'KPHX');
      expect(finalRes.finalizedPlan!.destinationIdent, 'KMSP');
      expect(finalRes.finalizedPlan!.legs.length, 4);
      expect(finalRes.finalizedPlan!.legs.last.fixIdent, 'KMSP');
    });

    test('30. Full Procedure 6-1 end-to-end simulation: non-standard name', () {
      // Step 1-2: User types PATROL01
      final r1 = FltPlanCreateEngine.createInitialState('PATROL01');
      var current = r1.state;
      expect(current.originIdent, isNull);
      expect(current.destinationIdent, isNull);

      // Step 3: Enter Origin VTBD
      final r2 = FltPlanCreateEngine.setOrigin(current, 'VTBD');
      current = r2.state;

      // Step 4: Enter Destination VTBK
      final r3 = FltPlanCreateEngine.setDestination(current, 'VTBK');
      current = r3.state;

      // Step 6: Enter intermediate waypoint WP01
      final r4 = FltPlanCreateEngine.addWaypoint(current, 'WP01');
      current = r4.state;

      // Step 8: Enter destination VTBK
      final r5 = FltPlanCreateEngine.addWaypoint(current, 'VTBK');
      current = r5.state;

      // Finalize
      final finalRes = FltPlanCreateEngine.finalize(current, planId: 'patrol_01');
      expect(finalRes.isSuccess, isTrue);
      expect(finalRes.finalizedPlan!.name, 'PATROL01');
      expect(finalRes.finalizedPlan!.originIdent, 'VTBD');
      expect(finalRes.finalizedPlan!.destinationIdent, 'VTBK');
      expect(finalRes.finalizedPlan!.legs.length, 2);
    });
  });
}
