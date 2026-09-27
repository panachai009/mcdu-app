// test/flt_plan_route_engine_test.dart
// Phase 19E-G-B — Pure Deterministic Engine Tests for ACTIVE FLT PLAN Route Management

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/flt_plan_state.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/stored_flt_plan.dart';
import 'package:mcdu_app/features/simulation/flt_plan/engine/flt_plan_engine.dart';

void main() {
  group('Phase 19E-G-B ACTIVE FLT PLAN Route Engine Tests', () {
    const engine = FltPlanEngine();

    // -------------------------------------------------------------------------
    // 1. ADD WAYPOINT
    // -------------------------------------------------------------------------
    test('1. add waypoint to empty route', () {
      final s0 = FltPlanState.initial();
      final res = engine.addWaypoint(s0, 'DRK');

      expect(res.isSuccess, isTrue);
      expect(res.errorMessage, isNull);
      expect(res.state.legs.length, 1);
      expect(res.state.legs.first.fixIdent, 'DRK');
    });

    test('2. add waypoint to existing route appends to end', () {
      final s0 = const FltPlanState(
        originIdent: 'KPHX',
        destinationIdent: 'KMSP',
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [
          FltPlanLeg(fixIdent: 'DRK'),
        ],
      );

      final res = engine.addWaypoint(s0, 'INW');

      expect(res.isSuccess, isTrue);
      expect(res.state.legs.length, 2);
      expect(res.state.legs[0].fixIdent, 'DRK');
      expect(res.state.legs[1].fixIdent, 'INW');
      expect(res.state.originIdent, 'KPHX');
      expect(res.state.destinationIdent, 'KMSP');
    });

    test('3. normalize lowercase ident', () {
      final s0 = FltPlanState.initial();
      final res = engine.addWaypoint(s0, 'cny');

      expect(res.isSuccess, isTrue);
      expect(res.state.legs.first.fixIdent, 'CNY');
    });

    test('4. trim whitespace from ident', () {
      final s0 = FltPlanState.initial();
      final res = engine.addWaypoint(s0, '  drk  ');

      expect(res.isSuccess, isTrue);
      expect(res.state.legs.first.fixIdent, 'DRK');
    });

    test('5. reject invalid ident (empty, too short, too long, special characters)', () {
      final s0 = FltPlanState.initial();

      expect(engine.addWaypoint(s0, '').isSuccess, isFalse);
      expect(engine.addWaypoint(s0, '   ').isSuccess, isFalse);
      expect(engine.addWaypoint(s0, 'A').isSuccess, isFalse); // < 2 chars
      expect(engine.addWaypoint(s0, 'TOOLONG1').isSuccess, isFalse); // > 5 chars
      expect(engine.addWaypoint(s0, 'DR-K').isSuccess, isFalse); // non-alphanumeric

      final res = engine.addWaypoint(s0, '');
      expect(res.errorMessage, 'INVALID ENTRY');
      expect(res.state, equals(s0));
    });

    test('6. original state unchanged after add waypoint', () {
      const original = FltPlanState(
        originIdent: 'KPHX',
        destinationIdent: 'KMSP',
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [FltPlanLeg(fixIdent: 'DRK')],
      );

      final res = engine.addWaypoint(original, 'INW');

      expect(res.isSuccess, isTrue);
      expect(original.legs.length, 1);
      expect(original.legs.first.fixIdent, 'DRK');
    });

    // -------------------------------------------------------------------------
    // 2. INSERT WAYPOINT
    // -------------------------------------------------------------------------
    test('7. insert at beginning (index 0)', () {
      const s0 = FltPlanState(
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [
          FltPlanLeg(fixIdent: 'WPTB'),
          FltPlanLeg(fixIdent: 'WPTC'),
        ],
      );

      final res = engine.insertWaypoint(s0, 0, 'WPTA');

      expect(res.isSuccess, isTrue);
      expect(res.state.legs.length, 3);
      expect(res.state.legs.map((l) => l.fixIdent).toList(), ['WPTA', 'WPTB', 'WPTC']);
    });

    test('8. insert in middle', () {
      const s0 = FltPlanState(
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [
          FltPlanLeg(fixIdent: 'DRK'),
          FltPlanLeg(fixIdent: 'CNY'),
        ],
      );

      final res = engine.insertWaypoint(s0, 1, 'INW');

      expect(res.isSuccess, isTrue);
      expect(res.state.legs.length, 3);
      expect(res.state.legs.map((l) => l.fixIdent).toList(), ['DRK', 'INW', 'CNY']);
    });

    test('9. insert at end (index == legs.length)', () {
      const s0 = FltPlanState(
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [
          FltPlanLeg(fixIdent: 'WPTA'),
          FltPlanLeg(fixIdent: 'WPTB'),
        ],
      );

      final res = engine.insertWaypoint(s0, 2, 'WPTC');

      expect(res.isSuccess, isTrue);
      expect(res.state.legs.length, 3);
      expect(res.state.legs.map((l) => l.fixIdent).toList(), ['WPTA', 'WPTB', 'WPTC']);
    });

    test('10. invalid index returns failure and preserves state', () {
      const s0 = FltPlanState(
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [FltPlanLeg(fixIdent: 'WPTA')],
      );

      // Negative index
      final resNeg = engine.insertWaypoint(s0, -1, 'WPTX');
      expect(resNeg.isSuccess, isFalse);
      expect(resNeg.errorMessage, 'INVALID ENTRY');
      expect(resNeg.state, equals(s0));

      // Out of bounds (> length)
      final resHigh = engine.insertWaypoint(s0, 5, 'WPTX');
      expect(resHigh.isSuccess, isFalse);
      expect(resHigh.errorMessage, 'INVALID ENTRY');
      expect(resHigh.state, equals(s0));
    });

    test('11. original state unchanged after insert waypoint', () {
      const original = FltPlanState(
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [FltPlanLeg(fixIdent: 'WPTA'), FltPlanLeg(fixIdent: 'WPTC')],
      );

      final res = engine.insertWaypoint(original, 1, 'WPTB');

      expect(res.isSuccess, isTrue);
      expect(original.legs.length, 2);
      expect(original.legs[0].fixIdent, 'WPTA');
      expect(original.legs[1].fixIdent, 'WPTC');
    });

    // -------------------------------------------------------------------------
    // 3. DELETE WAYPOINT
    // -------------------------------------------------------------------------
    test('12. delete first route leg (index 0)', () {
      const s0 = FltPlanState(
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [
          FltPlanLeg(fixIdent: 'A'),
          FltPlanLeg(fixIdent: 'B'),
          FltPlanLeg(fixIdent: 'C'),
        ],
      );

      final res = engine.deleteWaypoint(s0, 0);

      expect(res.isSuccess, isTrue);
      expect(res.state.legs.length, 2);
      expect(res.state.legs.map((l) => l.fixIdent).toList(), ['B', 'C']);
    });

    test('13. delete intermediate leg', () {
      const s0 = FltPlanState(
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [
          FltPlanLeg(fixIdent: 'A'),
          FltPlanLeg(fixIdent: 'B'),
          FltPlanLeg(fixIdent: 'C'),
        ],
      );

      final res = engine.deleteWaypoint(s0, 1);

      expect(res.isSuccess, isTrue);
      expect(res.state.legs.length, 2);
      expect(res.state.legs.map((l) => l.fixIdent).toList(), ['A', 'C']);
    });

    test('14. delete last route leg', () {
      const s0 = FltPlanState(
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [
          FltPlanLeg(fixIdent: 'A'),
          FltPlanLeg(fixIdent: 'B'),
        ],
      );

      final res = engine.deleteWaypoint(s0, 1);

      expect(res.isSuccess, isTrue);
      expect(res.state.legs.length, 1);
      expect(res.state.legs.first.fixIdent, 'A');
    });

    test('15. invalid negative index returns failure and preserves state', () {
      const s0 = FltPlanState(
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [FltPlanLeg(fixIdent: 'A')],
      );

      final res = engine.deleteWaypoint(s0, -1);

      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, 'INVALID ENTRY');
      expect(res.state, equals(s0));
    });

    test('16. invalid out-of-range index returns failure and preserves state', () {
      const s0 = FltPlanState(
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [FltPlanLeg(fixIdent: 'A')],
      );

      final res = engine.deleteWaypoint(s0, 1); // length is 1, max index is 0
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, 'INVALID ENTRY');
      expect(res.state, equals(s0));

      final resEmpty = engine.deleteWaypoint(FltPlanState.initial(), 0);
      expect(resEmpty.isSuccess, isFalse);
      expect(resEmpty.errorMessage, 'INVALID ENTRY');
    });

    test('17. original state unchanged after delete waypoint', () {
      const original = FltPlanState(
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 2,
        legs: [FltPlanLeg(fixIdent: 'A'), FltPlanLeg(fixIdent: 'B')],
      );

      final res = engine.deleteWaypoint(original, 0);

      expect(res.isSuccess, isTrue);
      expect(original.legs.length, 2);
      expect(original.legs[0].fixIdent, 'A');
      expect(original.legs[1].fixIdent, 'B');
    });

    // -------------------------------------------------------------------------
    // 4. PAGINATION
    // -------------------------------------------------------------------------
    test('18. next page advances pageIndex within totalPages', () {
      const s0 = FltPlanState(
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 3,
        legs: [],
      );

      final s1 = engine.nextPage(s0);
      expect(s1.pageIndex, 2);
      expect(s1.totalPages, 3);

      final s2 = engine.nextPage(s1);
      expect(s2.pageIndex, 3);
      expect(s2.totalPages, 3);
    });

    test('19. next page clamps at totalPages boundary', () {
      const s0 = FltPlanState(
        page: FltPlanPage.route,
        pageIndex: 3,
        totalPages: 3,
        legs: [],
      );

      final s1 = engine.nextPage(s0);
      expect(s1.pageIndex, 3);
      expect(s1, equals(s0));
    });

    test('20. previous page decrements pageIndex', () {
      const s0 = FltPlanState(
        page: FltPlanPage.route,
        pageIndex: 3,
        totalPages: 3,
        legs: [],
      );

      final s1 = engine.previousPage(s0);
      expect(s1.pageIndex, 2);

      final s2 = engine.previousPage(s1);
      expect(s2.pageIndex, 1);
    });

    test('21. previous page clamps at first page (1) boundary', () {
      const s0 = FltPlanState(
        page: FltPlanPage.route,
        pageIndex: 1,
        totalPages: 3,
        legs: [],
      );

      final s1 = engine.previousPage(s0);
      expect(s1.pageIndex, 1);
      expect(s1, equals(s0));
    });

    test('22. page state remains valid after route mutation', () {
      const s0 = FltPlanState(
        originIdent: 'VTBD',
        destinationIdent: 'VTBS',
        page: FltPlanPage.route,
        pageIndex: 2,
        totalPages: 3,
        legs: [FltPlanLeg(fixIdent: 'W1')],
      );

      final res = engine.addWaypoint(s0, 'W2');
      expect(res.state.pageIndex, 2);
      expect(res.state.totalPages, 3);
      expect(res.state.page, FltPlanPage.route);
    });

    // -------------------------------------------------------------------------
    // 5. ISOLATION & COMPATIBILITY
    // -------------------------------------------------------------------------
    test('23. StoredFltPlan is completely untouched by route operations', () {
      const stored = StoredFltPlan(
        id: 'plan-01',
        name: 'VFR01',
        originIdent: 'VTBD',
        destinationIdent: 'VTBS',
        legs: [FltPlanLeg(fixIdent: 'VTBS')],
      );

      final active = engine.activatePlan(FltPlanState.initial(), stored).state;
      expect(active.legs.length, 1);

      // Perform route mutations on active plan
      final modified = engine.addWaypoint(active, 'WAYP2').state;
      expect(modified.legs.length, 2);

      // Stored plan remains 100% untouched
      expect(stored.legs.length, 1);
      expect(stored.legs.first.fixIdent, 'VTBS');
    });

    test('24. resulting legs list is deep unmodifiable', () {
      final s0 = FltPlanState.initial();
      final res = engine.addWaypoint(s0, 'DRK');

      expect(() => res.state.legs.add(const FltPlanLeg(fixIdent: 'HACK')), throwsUnsupportedError);
    });

    test('25. existing activatePlan behavior remains compatible', () {
      const stored = StoredFltPlan(
        id: 'plan-02',
        name: 'KPHX-KMSP',
        originIdent: 'KPHX',
        destinationIdent: 'KMSP',
        legs: [
          FltPlanLeg(fixIdent: 'DRK'),
          FltPlanLeg(fixIdent: 'KMSP'),
        ],
      );

      final s0 = FltPlanState.initial();
      final res = engine.activatePlan(s0, stored);

      expect(res.isSuccess, isTrue);
      expect(res.state.originIdent, 'KPHX');
      expect(res.state.destinationIdent, 'KMSP');
      expect(res.state.legs.length, 2);
      expect(res.state.page, FltPlanPage.route);
    });

    test('26. existing save-active behavior remains compatible with modified routes', () {
      var state = FltPlanState.initial();
      state = engine.initializeOrigin(state, 'VTBL').state;
      state = engine.setDestination(state, 'VTBH').state;

      // Add a route waypoint
      state = engine.addWaypoint(state, 'MIDPT').state;
      expect(state.legs.length, 2);

      final savedPlan = engine.createStoredPlanFromActiveState(
        state: state,
        name: 'SAVED01',
        id: 'plan-999',
      );

      expect(savedPlan, isNotNull);
      expect(savedPlan!.name, 'SAVED01');
      expect(savedPlan.originIdent, 'VTBL');
      expect(savedPlan.destinationIdent, 'VTBH');
      expect(savedPlan.legs.length, 2);
      expect(savedPlan.legs.map((l) => l.fixIdent).toList(), ['VTBH', 'MIDPT']);
    });
  });
}
