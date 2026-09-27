// test/flt_plan_engine_test.dart
// Phase 19E-D-B — Pure FltPlanEngine and FltPlanState Domain Unit Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/flt_plan_state.dart';
import 'package:mcdu_app/features/simulation/flt_plan/engine/flt_plan_engine.dart';

void main() {
  group('Phase 19E-D-B FltPlanState & FltPlanEngine Domain Tests', () {
    const engine = FltPlanEngine();

    // -------------------------------------------------------------------------
    // A. Initial State
    // -------------------------------------------------------------------------
    test('A. Default initial state has no origin/destination, page 1/1, and empty legs', () {
      final state = FltPlanState.initial();
      expect(state.originIdent, isNull);
      expect(state.destinationIdent, isNull);
      expect(state.hasOrigin, isFalse);
      expect(state.hasDestination, isFalse);
      expect(state.isRouteActive, isFalse);
      expect(state.page, FltPlanPage.init);
      expect(state.pageIndex, 1);
      expect(state.totalPages, 1);
      expect(state.legs, isEmpty);
    });

    // -------------------------------------------------------------------------
    // B. Initialize Origin
    // -------------------------------------------------------------------------
    test('B. initializeOrigin sets origin, keeps destination empty and page 1/1', () {
      final s0 = FltPlanState.initial();
      final res = engine.initializeOrigin(s0, 'VTBL');

      expect(res.isSuccess, isTrue);
      expect(res.errorMessage, isNull);
      expect(res.state.originIdent, 'VTBL');
      expect(res.state.hasOrigin, isTrue);
      expect(res.state.destinationIdent, isNull);
      expect(res.state.hasDestination, isFalse);
      expect(res.state.isRouteActive, isFalse);
      expect(res.state.page, FltPlanPage.init);
      expect(res.state.pageIndex, 1);
      expect(res.state.totalPages, 1);
      expect(res.state.legs, isEmpty);
    });

    // -------------------------------------------------------------------------
    // C. Set Destination
    // -------------------------------------------------------------------------
    test('C. setDestination with existing origin transitions page from 1/1 to 1/2', () {
      final s0 = FltPlanState.initial();
      final s1 = engine.initializeOrigin(s0, 'VTBL').state;
      final res = engine.setDestination(s1, 'VTBH');

      expect(res.isSuccess, isTrue);
      expect(res.state.originIdent, 'VTBL');
      expect(res.state.destinationIdent, 'VTBH');
      expect(res.state.hasOrigin, isTrue);
      expect(res.state.hasDestination, isTrue);
      expect(res.state.isRouteActive, isTrue);
      expect(res.state.page, FltPlanPage.route);
      expect(res.state.pageIndex, 1);
      expect(res.state.totalPages, 2);
      expect(res.state.legs.length, 1);
      expect(res.state.legs.first.fixIdent, 'VTBH');
      expect(res.state.legs.first.bearingTrack, '344T');
      expect(res.state.legs.first.distanceNm, '3.9NM');
      expect(res.state.legs.first.ete, '00+02');
      expect(res.state.legs.first.altitudeSpd, '---/0100');
    });

    // -------------------------------------------------------------------------
    // D. Invalid Destination
    // -------------------------------------------------------------------------
    test('D. Invalid destination rejects empty, whitespace, too short, too long, symbols', () {
      final s1 = engine.initializeOrigin(FltPlanState.initial(), 'VTBL').state;

      final invalidEntries = ['', ' ', '   ', 'A', 'TOOLONGID', 'VT-BL', 'VT@1'];
      for (final entry in invalidEntries) {
        final res = engine.setDestination(s1, entry);
        expect(res.isSuccess, isFalse, reason: 'Entry "$entry" should be rejected');
        expect(res.errorMessage, 'INVALID ENTRY');
        expect(res.state, s1, reason: 'Rejected entry must leave state unchanged');
      }
    });

    // -------------------------------------------------------------------------
    // E. Immutability
    // -------------------------------------------------------------------------
    test('E. Original FltPlanState is never mutated by engine operations', () {
      final original = FltPlanState.initial();
      final res1 = engine.initializeOrigin(original, 'VTBL');
      final res2 = engine.setDestination(res1.state, 'VTBH');

      expect(original.originIdent, isNull);
      expect(original.page, FltPlanPage.init);
      expect(res1.state.originIdent, 'VTBL');
      expect(res1.state.destinationIdent, isNull);
      expect(res1.state.page, FltPlanPage.init);
      expect(res2.state.destinationIdent, 'VTBH');
      expect(res2.state.page, FltPlanPage.route);
    });

    // -------------------------------------------------------------------------
    // F. Deterministic Page Derivation
    // -------------------------------------------------------------------------
    test('F. Page derivation strictly follows origin/destination presence', () {
      final sEmpty = FltPlanState.initial();
      expect(sEmpty.totalPages, 1);
      expect(sEmpty.page, FltPlanPage.init);

      // Only destination without origin stays 1/1
      final sOnlyDest = engine.setDestination(sEmpty, 'VTBH').state;
      expect(sOnlyDest.totalPages, 1);
      expect(sOnlyDest.page, FltPlanPage.init);

      // Origin added -> becomes route (1/2)
      final sBoth = engine.initializeOrigin(sOnlyDest, 'VTBL').state;
      expect(sBoth.totalPages, 2);
      expect(sBoth.page, FltPlanPage.route);

      // Destination cleared -> returns to 1/1
      final sCleared = engine.clearDestination(sBoth).state;
      expect(sCleared.originIdent, 'VTBL');
      expect(sCleared.destinationIdent, isNull);
      expect(sCleared.totalPages, 1);
      expect(sCleared.page, FltPlanPage.init);
    });

    // -------------------------------------------------------------------------
    // G. Case Normalization
    // -------------------------------------------------------------------------
    test('G. Lowercase and leading/trailing whitespace inputs are trimmed and uppercased', () {
      final s0 = FltPlanState.initial();
      final resOrigin = engine.initializeOrigin(s0, '  vtbl  ');
      expect(resOrigin.isSuccess, isTrue);
      expect(resOrigin.state.originIdent, 'VTBL');

      final resDest = engine.setDestination(resOrigin.state, '  vtbh  ');
      expect(resDest.isSuccess, isTrue);
      expect(resDest.state.destinationIdent, 'VTBH');
    });

    // -------------------------------------------------------------------------
    // H. State Equality, HashCode, and ToString
    // -------------------------------------------------------------------------
    test('H. FltPlanState and FltPlanLeg equality, hashCode, and toString work correctly', () {
      const leg1 = FltPlanLeg(fixIdent: 'VTBH', bearingTrack: '344T');
      const leg2 = FltPlanLeg(fixIdent: 'VTBH', bearingTrack: '344T');
      const leg3 = FltPlanLeg(fixIdent: 'VTBD', bearingTrack: '180T');

      expect(leg1, equals(leg2));
      expect(leg1.hashCode, equals(leg2.hashCode));
      expect(leg1, isNot(equals(leg3)));
      expect(leg1.toString(), contains('VTBH'));

      final s1 = engine.setDestination(engine.initializeOrigin(FltPlanState.initial(), 'VTBL').state, 'VTBH').state;
      final s2 = engine.setDestination(engine.initializeOrigin(FltPlanState.initial(), 'VTBL').state, 'VTBH').state;

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1.toString(), contains('VTBL'));
      expect(s1.toString(), contains('VTBH'));
    });
  });
}
