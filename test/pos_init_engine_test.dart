// test/pos_init_engine_test.dart
// Unit tests for PosInitEngine and PosInitState domain logic.

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/simulation/pos_init/domain/pos_init_state.dart';
import 'package:mcdu_app/features/simulation/pos_init/engine/pos_init_engine.dart';

void main() {
  const engine = PosInitEngine();

  group('PosInitState Domain Tests', () {
    test('1. Initial state has no loaded position', () {
      final state = PosInitState.initial();
      expect(state.isPositionLoaded, isFalse);
      expect(state.loadedPosLatLon, isNull);
    });

    test('2. Initial loadedSource == none', () {
      final state = PosInitState.initial();
      expect(state.loadedSource, PositionLoadSource.none);
    });

    test('3. Initial example values match manual defaults', () {
      final state = PosInitState.initial();
      expect(state.lastPosLatLon, 'N14°53.2 E100°39.7');
      expect(state.gpsPosLatLon, 'N14°53.2 E100°39.7');
      expect(state.refWptIdent, 'VTBL');
      expect(state.refWptLatLon, 'N14°52.5 E100°39.8');
    });
  });

  group('LAST POS Loading Tests', () {
    test('4. loadLastPos succeeds', () {
      final state = PosInitState.initial();
      final result = engine.loadLastPos(state);
      expect(result.isSuccess, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('5. Loaded position equals last position', () {
      final state = PosInitState.initial();
      final result = engine.loadLastPos(state);
      expect(result.state.loadedPosLatLon, state.lastPosLatLon);
    });

    test('6. loadedSource == last', () {
      final state = PosInitState.initial();
      final result = engine.loadLastPos(state);
      expect(result.state.loadedSource, PositionLoadSource.last);
    });

    test('7. isPositionLoaded == true', () {
      final state = PosInitState.initial();
      final result = engine.loadLastPos(state);
      expect(result.state.isPositionLoaded, isTrue);
    });

    test('8. Original state remains unchanged (immutability)', () {
      final state = PosInitState.initial();
      final result = engine.loadLastPos(state);
      expect(state.isPositionLoaded, isFalse);
      expect(state.loadedPosLatLon, isNull);
      expect(state.loadedSource, PositionLoadSource.none);
      expect(result.state, isNot(equals(state)));
    });
  });

  group('GPS POS Loading Tests', () {
    test('9. loadGpsPos succeeds', () {
      final state = PosInitState.initial();
      final result = engine.loadGpsPos(state);
      expect(result.isSuccess, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('10. Loaded position equals GPS position', () {
      final state = PosInitState.initial();
      final result = engine.loadGpsPos(state);
      expect(result.state.loadedPosLatLon, state.gpsPosLatLon);
    });

    test('11. loadedSource == gps', () {
      final state = PosInitState.initial();
      final result = engine.loadGpsPos(state);
      expect(result.state.loadedSource, PositionLoadSource.gps);
      expect(result.state.isPositionLoaded, isTrue);
    });

    test('12. Original state remains unchanged on GPS load', () {
      final state = PosInitState.initial();
      engine.loadGpsPos(state);
      expect(state.isPositionLoaded, isFalse);
      expect(state.loadedPosLatLon, isNull);
    });
  });

  group('REF WPT Tests', () {
    test('13. Valid REF WPT can be stored', () {
      final state = PosInitState.initial();
      final result = engine.setRefWpt(
        state,
        ident: 'KPHX',
        latLon: 'N33°26.8 W112°01.5',
      );
      expect(result.isSuccess, isTrue);
      expect(result.state.refWptIdent, 'KPHX');
      expect(result.state.refWptLatLon, 'N33°26.8 W112°01.5');
    });

    test('14. loadRefWptPos succeeds after valid REF WPT', () {
      final state = PosInitState.initial();
      final result = engine.loadRefWptPos(state);
      expect(result.isSuccess, isTrue);
      expect(result.state.loadedPosLatLon, 'N14°52.5 E100°39.8');
    });

    test('15. loadedSource == refWpt', () {
      final state = PosInitState.initial();
      final result = engine.loadRefWptPos(state);
      expect(result.state.loadedSource, PositionLoadSource.refWpt);
      expect(result.state.isPositionLoaded, isTrue);
    });

    test('16. Missing REF WPT fails', () {
      const state = PosInitState(
        lastPosLatLon: 'N14°53.2 E100°39.7',
        gpsPosLatLon: 'N14°53.2 E100°39.7',
        refWptIdent: null,
        refWptLatLon: null,
      );
      final result = engine.loadRefWptPos(state);
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'INVALID ENTRY');
      expect(result.state.isPositionLoaded, isFalse);
    });

    test('17. Invalid REF WPT identifier fails (too long, spaces, symbols)', () {
      final state = PosInitState.initial();
      final res1 = engine.setRefWpt(state, ident: 'TOOLONG', latLon: 'N14°52.5 E100°39.8');
      expect(res1.isSuccess, isFalse);
      expect(res1.errorMessage, 'INVALID ENTRY');

      final res2 = engine.setRefWpt(state, ident: 'VT BL', latLon: 'N14°52.5 E100°39.8');
      expect(res2.isSuccess, isFalse);

      final res3 = engine.setRefWpt(state, ident: '', latLon: 'N14°52.5 E100°39.8');
      expect(res3.isSuccess, isFalse);
    });

    test('18. Invalid REF WPT coordinate fails', () {
      final state = PosInitState.initial();
      final res = engine.setRefWpt(state, ident: 'VTBD', latLon: 'INVALID_COORDS');
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, 'INVALID ENTRY');
    });

    test('19. Failed operation leaves state unchanged', () {
      final state = PosInitState.initial();
      final res = engine.setRefWpt(state, ident: '123456', latLon: 'INVALID');
      expect(res.state, equals(state));
    });
  });

  group('Coordinate Parsing & Validation Tests', () {
    test('20. Valid N/E coordinate accepted', () {
      final formatted = engine.validateAndFormatCoordinates('N14°53.2 E100°39.7');
      expect(formatted, 'N14°53.2 E100°39.7');
    });

    test('21. Valid S/W coordinate accepted (and compact format)', () {
      final formatted1 = engine.validateAndFormatCoordinates('S33°26.8 W112°01.5');
      expect(formatted1, 'S33°26.8 W112°01.5');

      final formatted2 = engine.validateAndFormatCoordinates('N3320.77W11152.58');
      expect(formatted2, 'N33°20.8 W111°52.6');
    });

    test('22. Invalid latitude rejected (> 90 deg)', () {
      expect(engine.validateAndFormatCoordinates('N95°00.0 E100°00.0'), isNull);
      expect(engine.validateAndFormatCoordinates('N90°00.1 E100°00.0'), isNull);
    });

    test('23. Invalid longitude rejected (> 180 deg)', () {
      expect(engine.validateAndFormatCoordinates('N14°00.0 E185°00.0'), isNull);
      expect(engine.validateAndFormatCoordinates('N14°00.0 E180°00.1'), isNull);
    });

    test('24. Invalid minutes rejected (>= 60 min)', () {
      expect(engine.validateAndFormatCoordinates('N14°60.0 E100°39.7'), isNull);
      expect(engine.validateAndFormatCoordinates('N14°53.2 E100°65.0'), isNull);
    });

    test('25. Invalid hemisphere rejected', () {
      expect(engine.validateAndFormatCoordinates('X14°53.2 E100°39.7'), isNull);
      expect(engine.validateAndFormatCoordinates('N14°53.2 Z100°39.7'), isNull);
    });
  });

  group('Result & Contract Tests', () {
    test('26. Failures return INVALID ENTRY', () {
      final state = PosInitState.initial().copyWith(clearRefWpt: true);
      final res = engine.loadRefWptPos(state);
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, 'INVALID ENTRY');
    });

    test('27. Successful operations return isSuccess true and null error', () {
      final state = PosInitState.initial();
      final res = engine.loadLastPos(state);
      expect(res.isSuccess, isTrue);
      expect(res.errorMessage, isNull);
    });
  });
}
