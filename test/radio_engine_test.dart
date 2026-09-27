// test/radio_engine_test.dart
// Unit tests for RadioEngine and RadioState domain logic.

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/simulation/radio/domain/radio_channel.dart';
import 'package:mcdu_app/features/simulation/radio/domain/radio_state.dart';
import 'package:mcdu_app/features/simulation/radio/engine/radio_engine.dart';

void main() {
  const engine = RadioEngine();

  group('RadioState Domain Tests', () {
    test('1. Initial state has exact default values from manual', () {
      final state = RadioState.initial();
      expect(state.pageIndex, 1);
      expect(state.com1.active, '122.600');
      expect(state.com1.standby, '127.000');
      expect(state.com2.active, '122.100');
      expect(state.com2.standby, '127.000');
      expect(state.nav1.active, '117.30');
      expect(state.nav1.standby, '113.80');
      expect(state.nav2.active, '116.80');
      expect(state.nav2.standby, '111.10');
      expect(state.adf2.active, '242.0');
      expect(state.adf2.standby, '1570.0');
      expect(state.xpdrCode, '1102');
      expect(state.xpdrMode, XpdrMode.stby);
      expect(state.isIdentActive, isFalse);
    });

    test('2. RadioChannel swap produces swapped copy', () {
      const channel = RadioChannel(active: '118.000', standby: '136.975');
      final swapped = channel.swap();
      expect(swapped.active, '136.975');
      expect(swapped.standby, '118.000');
      // Original unchanged
      expect(channel.active, '118.000');
    });

    test('3. RadioChannel equality and hashCode', () {
      const ch1 = RadioChannel(active: '122.600', standby: '127.000');
      const ch2 = RadioChannel(active: '122.600', standby: '127.000');
      const ch3 = RadioChannel(active: '122.100', standby: '127.000');
      expect(ch1, equals(ch2));
      expect(ch1.hashCode, equals(ch2.hashCode));
      expect(ch1, isNot(equals(ch3)));
    });

    test('4. RadioState equality and copyWith', () {
      final initial = RadioState.initial();
      final copied = initial.copyWith(xpdrCode: '7700');
      expect(copied.xpdrCode, '7700');
      expect(initial.xpdrCode, '1102');
      expect(copied, isNot(equals(initial)));
    });
  });

  group('Frequency Swapping Tests', () {
    test('5. swapCom1 swaps active and standby', () {
      final state = RadioState.initial();
      final result = engine.swapCom1(state);
      expect(result.isSuccess, isTrue);
      expect(result.state.com1.active, '127.000');
      expect(result.state.com1.standby, '122.600');
      expect(state.com1.active, '122.600'); // immutability check
    });

    test('6. swapCom2 swaps active and standby', () {
      final state = RadioState.initial();
      final result = engine.swapCom2(state);
      expect(result.isSuccess, isTrue);
      expect(result.state.com2.active, '127.000');
      expect(result.state.com2.standby, '122.100');
    });

    test('7. swapNav1 swaps active and standby', () {
      final state = RadioState.initial();
      final result = engine.swapNav1(state);
      expect(result.isSuccess, isTrue);
      expect(result.state.nav1.active, '113.80');
      expect(result.state.nav1.standby, '117.30');
    });

    test('8. swapNav2 swaps active and standby', () {
      final state = RadioState.initial();
      final result = engine.swapNav2(state);
      expect(result.isSuccess, isTrue);
      expect(result.state.nav2.active, '111.10');
      expect(result.state.nav2.standby, '116.80');
    });

    test('9. swapAdf2 swaps active and standby', () {
      final state = RadioState.initial();
      final result = engine.swapAdf2(state);
      expect(result.isSuccess, isTrue);
      expect(result.state.adf2.active, '1570.0');
      expect(result.state.adf2.standby, '242.0');
    });
  });

  group('VHF COM Tuning Tests', () {
    test('10. tuneCom1Standby accepts valid full 3-decimal string', () {
      final state = RadioState.initial();
      final res = engine.tuneCom1Standby(state, '121.500');
      expect(res.isSuccess, isTrue);
      expect(res.state.com1.standby, '121.500');
      expect(res.state.com1.active, '122.600');
    });

    test('11. tuneCom1Standby pads 1 decimal and 2 decimals', () {
      final state = RadioState.initial();
      final res1 = engine.tuneCom1Standby(state, '125.8');
      expect(res1.isSuccess, isTrue);
      expect(res1.state.com1.standby, '125.800');

      final res2 = engine.tuneCom1Standby(state, '125.85');
      expect(res2.isSuccess, isTrue);
      expect(res2.state.com1.standby, '125.850');
    });

    test('12. tuneCom1Standby accepts integer MHz without decimal', () {
      final state = RadioState.initial();
      final res = engine.tuneCom1Standby(state, '124');
      expect(res.isSuccess, isTrue);
      expect(res.state.com1.standby, '124.000');
    });

    test('13. tuneCom1Standby accepts lower boundary 118.000', () {
      final state = RadioState.initial();
      final res = engine.tuneCom1Standby(state, '118.000');
      expect(res.isSuccess, isTrue);
      expect(res.state.com1.standby, '118.000');
    });

    test('14. tuneCom1Standby accepts upper boundary 136.975', () {
      final state = RadioState.initial();
      final res = engine.tuneCom1Standby(state, '136.975');
      expect(res.isSuccess, isTrue);
      expect(res.state.com1.standby, '136.975');
    });

    test('15. tuneCom1Standby rejects below 118.000', () {
      final state = RadioState.initial();
      final res = engine.tuneCom1Standby(state, '117.975');
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, 'INVALID ENTRY');
      expect(res.state.com1.standby, '127.000');
    });

    test('16. tuneCom1Standby rejects above 136.975', () {
      final state = RadioState.initial();
      final res = engine.tuneCom1Standby(state, '137.000');
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, 'INVALID ENTRY');
    });

    test('17. tuneCom2Standby works identically', () {
      final state = RadioState.initial();
      final res = engine.tuneCom2Standby(state, '130.000');
      expect(res.isSuccess, isTrue);
      expect(res.state.com2.standby, '130.000');
    });

    test('18. tuneCom1Standby rejects malformed or alphabetic input', () {
      final state = RadioState.initial();
      expect(engine.tuneCom1Standby(state, 'ABC').isSuccess, isFalse);
      expect(engine.tuneCom1Standby(state, '122..5').isSuccess, isFalse);
      expect(engine.tuneCom1Standby(state, '').isSuccess, isFalse);
      expect(engine.tuneCom1Standby(state, '   ').isSuccess, isFalse);
    });
  });

  group('VHF NAV Tuning Tests', () {
    test('19. tuneNav1Standby accepts valid 2-decimal 50 kHz channel', () {
      final state = RadioState.initial();
      final res = engine.tuneNav1Standby(state, '110.50');
      expect(res.isSuccess, isTrue);
      expect(res.state.nav1.standby, '110.50');
    });

    test('20. tuneNav1Standby pads 1 decimal to 2 decimals', () {
      final state = RadioState.initial();
      final res = engine.tuneNav1Standby(state, '115.1');
      expect(res.isSuccess, isTrue);
      expect(res.state.nav1.standby, '115.10');
    });

    test('21. tuneNav1Standby accepts integer MHz without decimal', () {
      final state = RadioState.initial();
      final res = engine.tuneNav1Standby(state, '112');
      expect(res.isSuccess, isTrue);
      expect(res.state.nav1.standby, '112.00');
    });

    test('22. tuneNav1Standby accepts lower boundary 108.00', () {
      final state = RadioState.initial();
      final res = engine.tuneNav1Standby(state, '108.00');
      expect(res.isSuccess, isTrue);
      expect(res.state.nav1.standby, '108.00');
    });

    test('23. tuneNav1Standby accepts upper boundary 117.95', () {
      final state = RadioState.initial();
      final res = engine.tuneNav1Standby(state, '117.95');
      expect(res.isSuccess, isTrue);
      expect(res.state.nav1.standby, '117.95');
    });

    test('24. tuneNav1Standby rejects invalid spacing (not multiple of 50 kHz)', () {
      final state = RadioState.initial();
      final res = engine.tuneNav1Standby(state, '112.12');
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, 'INVALID ENTRY');
    });

    test('25. tuneNav1Standby rejects out of range (< 108.00 or > 117.95)', () {
      final state = RadioState.initial();
      expect(engine.tuneNav1Standby(state, '107.95').isSuccess, isFalse);
      expect(engine.tuneNav1Standby(state, '118.00').isSuccess, isFalse);
    });

    test('26. tuneNav2Standby updates nav2 correctly', () {
      final state = RadioState.initial();
      final res = engine.tuneNav2Standby(state, '114.25');
      expect(res.isSuccess, isTrue);
      expect(res.state.nav2.standby, '114.25');
    });
  });

  group('ADF Tuning Tests', () {
    test('27. tuneAdf2Standby accepts valid frequency with 1 decimal (.0 or .5)', () {
      final state = RadioState.initial();
      final res = engine.tuneAdf2Standby(state, '350.5');
      expect(res.isSuccess, isTrue);
      expect(res.state.adf2.standby, '350.5');
    });

    test('28. tuneAdf2Standby accepts integer frequency and pads .0', () {
      final state = RadioState.initial();
      final res = engine.tuneAdf2Standby(state, '410');
      expect(res.isSuccess, isTrue);
      expect(res.state.adf2.standby, '410.0');
    });

    test('29. tuneAdf2Standby accepts boundary values 190.0 and 1799.5', () {
      final state = RadioState.initial();
      expect(engine.tuneAdf2Standby(state, '190.0').isSuccess, isTrue);
      expect(engine.tuneAdf2Standby(state, '1799.5').isSuccess, isTrue);
    });

    test('30. tuneAdf2Standby rejects out of range and invalid decimals', () {
      final state = RadioState.initial();
      expect(engine.tuneAdf2Standby(state, '189.5').isSuccess, isFalse);
      expect(engine.tuneAdf2Standby(state, '1800.0').isSuccess, isFalse);
      expect(engine.tuneAdf2Standby(state, '350.2').isSuccess, isFalse);
      expect(engine.tuneAdf2Standby(state, '350.55').isSuccess, isFalse);
    });
  });

  group('Transponder & IDENT Tests', () {
    test('31. setXpdrCode accepts valid 4-digit octal string', () {
      final state = RadioState.initial();
      final res = engine.setXpdrCode(state, '7000');
      expect(res.isSuccess, isTrue);
      expect(res.state.xpdrCode, '7000');
    });

    test('32. setXpdrCode rejects non-octal digits (8 and 9)', () {
      final state = RadioState.initial();
      final res8 = engine.setXpdrCode(state, '1280');
      expect(res8.isSuccess, isFalse);
      expect(res8.errorMessage, 'INVALID ENTRY');

      final res9 = engine.setXpdrCode(state, '7900');
      expect(res9.isSuccess, isFalse);
      expect(res9.errorMessage, 'INVALID ENTRY');
    });

    test('33. setXpdrCode rejects lengths other than 4', () {
      final state = RadioState.initial();
      expect(engine.setXpdrCode(state, '123').isSuccess, isFalse);
      expect(engine.setXpdrCode(state, '12345').isSuccess, isFalse);
      expect(engine.setXpdrCode(state, '').isSuccess, isFalse);
    });

    test('34. toggleXpdrMode alternates between stby and altOn', () {
      final state = RadioState.initial();
      expect(state.xpdrMode, XpdrMode.stby);

      final toggled1 = engine.toggleXpdrMode(state);
      expect(toggled1.isSuccess, isTrue);
      expect(toggled1.state.xpdrMode, XpdrMode.altOn);

      final toggled2 = engine.toggleXpdrMode(toggled1.state);
      expect(toggled2.isSuccess, isTrue);
      expect(toggled2.state.xpdrMode, XpdrMode.stby);
    });

    test('35. triggerIdent and clearIdent manage ident state', () {
      final state = RadioState.initial();
      expect(state.isIdentActive, isFalse);

      final triggered = engine.triggerIdent(state);
      expect(triggered.isSuccess, isTrue);
      expect(triggered.state.isIdentActive, isTrue);

      final cleared = engine.clearIdent(triggered.state);
      expect(cleared.isSuccess, isTrue);
      expect(cleared.state.isIdentActive, isFalse);
    });
  });

  group('Paging Tests', () {
    test('36. nextPage and previousPage toggle between page 1 and 2', () {
      final state = RadioState.initial();
      expect(state.pageIndex, 1);

      final p2 = engine.nextPage(state);
      expect(p2.isSuccess, isTrue);
      expect(p2.state.pageIndex, 2);

      final p1 = engine.previousPage(p2.state);
      expect(p1.isSuccess, isTrue);
      expect(p1.state.pageIndex, 1);

      // Wrapping verification
      final wrappedNext = engine.nextPage(p2.state);
      expect(wrappedNext.state.pageIndex, 1);

      final wrappedPrev = engine.previousPage(state);
      expect(wrappedPrev.state.pageIndex, 2);
    });
  });
}
