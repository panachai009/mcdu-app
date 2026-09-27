// test/nav_engine_test.dart
// Phase 19E-B — Pure NavEngine and NavState Domain Unit Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/simulation/nav/domain/nav_state.dart';
import 'package:mcdu_app/features/simulation/nav/engine/nav_engine.dart';

void main() {
  group('Phase 19E-B NavState & NavEngine Domain Tests', () {
    const engine = NavEngine();

    // -------------------------------------------------------------------------
    // 1. Initial State
    // -------------------------------------------------------------------------
    test('1. Default initial state has correct page and ground-truth defaults', () {
      final state = NavState.initial();
      expect(state.page, NavPage.index1);
      expect(state.date, '24JAN17');
      expect(state.utc, '0755z');
      expect(state.softwareVersion, 'NZ7.1.2');
      expect(state.activeNdb, '10NOV 07DEC/16');
      expect(state.nonActiveNdb, '13OCT 09NOV/16');
      expect(state.databaseVersion, 'NDB V3.01 16M');
      expect(state.databasePartNumber, 'AW139-5-312');
    });

    // -------------------------------------------------------------------------
    // 2. NAV Opening
    // -------------------------------------------------------------------------
    test('2. openNav transitions to INDEX 1/2 from any other page', () {
      final identState = NavState.initial().copyWith(page: NavPage.ident);
      final res = engine.openNav(identState);

      expect(res.isSuccess, isTrue);
      expect(res.state.page, NavPage.index1);
      expect(res.target, NavNavigationTarget.navIndex);
    });

    // -------------------------------------------------------------------------
    // 3. Page Cycling (NEXT / PREV)
    // -------------------------------------------------------------------------
    test('3. INDEX 1/2 -> NEXT -> INDEX 2/2', () {
      final s1 = NavState.initial();
      final res = engine.nextPage(s1);

      expect(res.isSuccess, isTrue);
      expect(res.state.page, NavPage.index2);
      expect(res.target, NavNavigationTarget.none);
    });

    test('4. INDEX 2/2 -> NEXT -> unchanged (no-op)', () {
      final s2 = NavState.initial().copyWith(page: NavPage.index2);
      final res = engine.nextPage(s2);

      expect(res.isSuccess, isTrue);
      expect(res.state.page, NavPage.index2);
      expect(res.target, NavNavigationTarget.none);
    });

    test('5. INDEX 2/2 -> PREV -> INDEX 1/2', () {
      final s2 = NavState.initial().copyWith(page: NavPage.index2);
      final res = engine.previousPage(s2);

      expect(res.isSuccess, isTrue);
      expect(res.state.page, NavPage.index1);
      expect(res.target, NavNavigationTarget.none);
    });

    test('6. INDEX 1/2 -> PREV -> unchanged (no-op)', () {
      final s1 = NavState.initial();
      final res = engine.previousPage(s1);

      expect(res.isSuccess, isTrue);
      expect(res.state.page, NavPage.index1);
      expect(res.target, NavNavigationTarget.none);
    });

    test('7. NAV IDENT + NEXT / PREV -> unchanged (no-op)', () {
      final sIdent = NavState.initial().copyWith(page: NavPage.ident);
      final resNext = engine.nextPage(sIdent);
      final resPrev = engine.previousPage(sIdent);

      expect(resNext.state.page, NavPage.ident);
      expect(resPrev.state.page, NavPage.ident);
    });

    // -------------------------------------------------------------------------
    // 4. NAV IDENT
    // -------------------------------------------------------------------------
    test('8. INDEX 1/2 + 3L -> NAV IDENT 1/1 via handleLsk', () {
      final s1 = NavState.initial();
      final res = engine.handleLsk(s1, '3L');

      expect(res.isSuccess, isTrue);
      expect(res.state.page, NavPage.ident);
      expect(res.target, NavNavigationTarget.navIdent);
    });

    test('9. openNavIdent method explicitly transitions to NAV IDENT', () {
      final s1 = NavState.initial();
      final res = engine.openNavIdent(s1);

      expect(res.isSuccess, isTrue);
      expect(res.state.page, NavPage.ident);
      expect(res.target, NavNavigationTarget.navIdent);
    });

    // -------------------------------------------------------------------------
    // 5. POS INIT Targets
    // -------------------------------------------------------------------------
    test('10. INDEX 2/2 + 1L -> posInit target without modifying NavState', () {
      final s2 = NavState.initial().copyWith(page: NavPage.index2);
      final res = engine.handleLsk(s2, '1L');

      expect(res.isSuccess, isTrue);
      expect(res.target, NavNavigationTarget.posInit);
      expect(res.state.page, NavPage.index2); // Engine state remains index2
    });

    test('11. NAV IDENT + 6R -> posInit target without modifying NavState', () {
      final sIdent = NavState.initial().copyWith(page: NavPage.ident);
      final res = engine.handleLsk(sIdent, '6R');

      expect(res.isSuccess, isTrue);
      expect(res.target, NavNavigationTarget.posInit);
      expect(res.state.page, NavPage.ident); // Engine state remains ident
    });

    test('12. openPosInit method produces posInit target intent', () {
      final s = NavState.initial();
      final res = engine.openPosInit(s);

      expect(res.isSuccess, isTrue);
      expect(res.target, NavNavigationTarget.posInit);
      expect(res.state, s);
    });

    // -------------------------------------------------------------------------
    // 6. Unsupported LSKs (No-ops)
    // -------------------------------------------------------------------------
    test('13. Unsupported LSKs on INDEX 1/2 do not alter state', () {
      final s1 = NavState.initial();
      final unhandled = ['1L', '2L', '4L', '5L', '6L', '1R', '2R', '3R', '4R', '5R', '6R'];

      for (final lsk in unhandled) {
        final res = engine.handleLsk(s1, lsk);
        expect(res.state, s1, reason: 'LSK $lsk on index1 must not alter state');
        expect(res.target, NavNavigationTarget.none);
      }
    });

    test('14. Unsupported LSKs on INDEX 2/2 do not alter state', () {
      final s2 = NavState.initial().copyWith(page: NavPage.index2);
      final unhandled = ['2L', '3L', '4L', '5L', '6L', '1R', '2R', '3R', '4R', '5R', '6R'];

      for (final lsk in unhandled) {
        final res = engine.handleLsk(s2, lsk);
        expect(res.state, s2, reason: 'LSK $lsk on index2 must not alter state');
        expect(res.target, NavNavigationTarget.none);
      }
    });

    test('15. Unsupported LSKs on NAV IDENT do not alter state', () {
      final sIdent = NavState.initial().copyWith(page: NavPage.ident);
      final unhandled = ['1L', '2L', '3L', '4L', '5L', '6L', '1R', '2R', '3R', '4R', '5R'];

      for (final lsk in unhandled) {
        final res = engine.handleLsk(sIdent, lsk);
        expect(res.state, sIdent, reason: 'LSK $lsk on ident must not alter state');
        expect(res.target, NavNavigationTarget.none);
      }
    });

    // -------------------------------------------------------------------------
    // 7. Immutability
    // -------------------------------------------------------------------------
    test('16. Original NavState remains immutable after engine operations', () {
      final original = NavState.initial();
      final nextRes = engine.nextPage(original);
      final identRes = engine.handleLsk(original, '3L');

      expect(original.page, NavPage.index1);
      expect(nextRes.state.page, NavPage.index2);
      expect(identRes.state.page, NavPage.ident);
      expect(original, NavState.initial());
    });

    test('17. NavState equality, hashCode, and toString work correctly', () {
      final s1 = NavState.initial();
      final s2 = NavState.initial();
      final s3 = s1.copyWith(utc: '0800z');

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1, isNot(equals(s3)));
      expect(s1.toString(), contains('NZ7.1.2'));
    });
  });
}
