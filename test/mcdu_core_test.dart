import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/mcdu_core/domain/mcdu_key.dart';
import 'package:mcdu_app/features/mcdu_core/domain/mcdu_state.dart';
import 'package:mcdu_app/features/mcdu_core/engine/mcdu_input_engine.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';

void main() {
  group('MCDUKey domain tests', () {
    test('contains all verified keys from image audit', () {
      expect(MCDUKey.alpha.length, 26);
      expect(MCDUKey.perf, 'PERF');
      expect(MCDUKey.nav, 'NAV');
      expect(MCDUKey.prev, 'PREV');
      expect(MCDUKey.fpl, 'FPL');
      expect(MCDUKey.prog, 'PROG');
      expect(MCDUKey.dir, 'DIR');
      expect(MCDUKey.menu, 'MENU');
      expect(MCDUKey.next, 'NEXT');
      expect(MCDUKey.radio, 'RADIO');
      expect(MCDUKey.brtDim, 'BRT/DIM');
      expect(MCDUKey.clr, 'CLR');
      expect(MCDUKey.del, 'DEL');
      expect(MCDUKey.dot, 'DOT');
      expect(MCDUKey.slash, 'SLASH');
      expect(MCDUKey.space, 'SP');
      expect(MCDUKey.plusMinus, '+/-');
    });
  });

  group('MCDUPage and MCDUState domain tests', () {
    test('1. Initial page = MENU', () {
      final state = MCDUState.initial();
      expect(state.currentPageId, 'MENU');
      expect(state.title, 'MCDU MENU');
      expect(state.leftLabels[0], '<FPL');
      expect(state.leftLabels[1], '<DIR');
      expect(state.leftLabels[2], '<PROG');
      expect(state.rightLabels[0], 'NAV>');
      expect(state.rightLabels[1], 'RADIO>');
      expect(state.rightLabels[2], 'DATA>');
      expect(state.scratchpad, '');
    });

    test('MCDUState copyWith updates state immutably', () {
      final state = MCDUState.initial();
      final updated = state.copyWith(scratchpad: 'ABC', lastKeyId: 'C');
      expect(state.scratchpad, '');
      expect(updated.scratchpad, 'ABC');
      expect(updated.lastKeyId, 'C');
    });
  });

  group('MCDUPageEngine Navigation Tests', () {
    // 2. MENU -> FPL
    test('2. MENU -> FPL navigation via 1L or FPL key', () {
      final engine = MCDUInputEngine();
      expect(engine.state.currentPageId, 'MENU');
      engine.handleKeyEvent(MCDUKeyEvent(keyId: '1L'));
      expect(engine.state.currentPageId, 'FPL');
      expect(engine.state.title, 'MCDU FPL');
    });

    // 3. MENU -> DIR
    test('3. MENU -> DIR navigation via 2L or DIR key', () {
      final engine = MCDUInputEngine();
      engine.handleKeyEvent(MCDUKeyEvent(keyId: '2L'));
      expect(engine.state.currentPageId, 'DIR');
      expect(engine.state.title, 'MCDU DIR');
    });

    // 4. MENU -> PROG
    test('4. MENU -> PROG navigation via 3L or PROG key', () {
      final engine = MCDUInputEngine();
      engine.handleKeyEvent(MCDUKeyEvent(keyId: '3L'));
      expect(engine.state.currentPageId, 'PROG');
      expect(engine.state.title, 'MCDU PROG');
    });

    // 5. MENU -> NAV
    test('5. MENU -> NAV navigation via 1R or NAV key', () {
      final engine = MCDUInputEngine();
      engine.handleKeyEvent(MCDUKeyEvent(keyId: '1R'));
      expect(engine.state.currentPageId, 'NAV');
      expect(engine.state.title, 'MCDU NAV');
    });

    // 6. MENU -> RADIO
    test('6. MENU -> RADIO navigation via 2R or RADIO key', () {
      final engine = MCDUInputEngine();
      engine.handleKeyEvent(MCDUKeyEvent(keyId: '2R'));
      expect(engine.state.currentPageId, 'RADIO');
      expect(engine.state.title, 'MCDU RADIO');
    });

    // 7. MENU -> DATA
    test('7. MENU -> DATA navigation via 3R', () {
      final engine = MCDUInputEngine();
      engine.handleKeyEvent(MCDUKeyEvent(keyId: '3R'));
      expect(engine.state.currentPageId, 'DATA');
      expect(engine.state.title, 'MCDU DATA');
    });

    // 8. PREV returns to previous page
    test('8. PREV returns to previous page', () {
      final engine = MCDUInputEngine();
      engine.handleKeyEvent(MCDUKeyEvent(keyId: '1L')); // MENU -> FPL
      expect(engine.state.currentPageId, 'FPL');

      engine.handleKeyEvent(MCDUKeyEvent(keyId: MCDUKey.prev));
      expect(engine.state.currentPageId, 'MENU');
    });

    // 9. NEXT returns to forward page when available
    test('9. NEXT returns to forward page when available', () {
      final engine = MCDUInputEngine();
      engine.handleKeyEvent(MCDUKeyEvent(keyId: '1L')); // MENU -> FPL
      engine.handleKeyEvent(MCDUKeyEvent(keyId: MCDUKey.prev)); // Back to MENU
      expect(engine.state.currentPageId, 'MENU');

      engine.handleKeyEvent(MCDUKeyEvent(keyId: MCDUKey.next)); // Forward to FPL
      expect(engine.state.currentPageId, 'FPL');
    });

    // 10. Page Engine does not crash when history is empty
    test('10. PREV / NEXT does not crash when history is empty', () {
      final engine = MCDUInputEngine();
      expect(engine.state.currentPageId, 'MENU');

      engine.handleKeyEvent(MCDUKeyEvent(keyId: MCDUKey.prev));
      expect(engine.state.currentPageId, 'MENU');
      expect(engine.lastAction, 'NO_HISTORY');

      engine.handleKeyEvent(MCDUKeyEvent(keyId: MCDUKey.next));
      expect(engine.state.currentPageId, 'MENU');
      expect(engine.lastAction, 'NO_HISTORY');
    });
  });

  group('MCDUInputEngine Phase 4 & 5 Core Behavior Tests', () {
    // 11. Scratchpad still works
    test('11. Scratchpad still works for alpha, numeric, symbols', () {
      final engine = MCDUInputEngine();
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'V'));
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'T'));
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'B'));
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'D'));
      engine.handleKeyEvent(MCDUKeyEvent(keyId: MCDUKey.space));
      engine.handleKeyEvent(MCDUKeyEvent(keyId: '1'));
      engine.handleKeyEvent(MCDUKeyEvent(keyId: MCDUKey.dot));
      engine.handleKeyEvent(MCDUKeyEvent(keyId: '2'));
      expect(engine.state.scratchpad, 'VTBD 1.2');
    });

    // 12. CLR still works
    test('12. CLR removes last char and does not corrupt empty scratchpad', () {
      final engine = MCDUInputEngine();
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'A'));
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'B'));
      expect(engine.state.scratchpad, 'AB');

      engine.handleKeyEvent(MCDUKeyEvent(keyId: MCDUKey.clr));
      expect(engine.state.scratchpad, 'A');

      engine.handleKeyEvent(MCDUKeyEvent(keyId: MCDUKey.clr));
      expect(engine.state.scratchpad, '');

      // CLR on empty
      engine.handleKeyEvent(MCDUKeyEvent(keyId: MCDUKey.clr));
      expect(engine.state.scratchpad, '');
      expect(engine.lastAction, 'CLR_EMPTY');
    });

    // 13. DEL still generates separate action
    test('13. DEL generates separate action without deleting scratchpad', () {
      final engine = MCDUInputEngine();
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'A'));
      engine.handleKeyEvent(MCDUKeyEvent(keyId: MCDUKey.del));
      expect(engine.lastKeyId, 'DEL');
      expect(engine.lastAction, 'DEL');
      expect(engine.state.scratchpad, 'A');
    });

    // 14. LSK transfer still works outside page-navigation actions
    test('14. LSK transfer still works on subpages (e.g. FPL page 1L)', () {
      final engine = MCDUInputEngine();
      // Go to FPL page
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'FPL'));
      expect(engine.state.currentPageId, 'FPL');

      // Type waypoint VTBD in scratchpad
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'V'));
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'T'));
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'B'));
      engine.handleKeyEvent(MCDUKeyEvent(keyId: 'D'));
      expect(engine.state.scratchpad, 'VTBD');

      // Transfer to 1L
      engine.handleKeyEvent(MCDUKeyEvent(keyId: '1L'));
      expect(engine.state.leftLabels[0], 'VTBD');
      expect(engine.state.scratchpad, '');
      expect(engine.lastAction, 'LSK_TRANSFER_1L');
    });

    // 15. MENU navigation LSK does not incorrectly transfer MENU label into scratchpad
    test('15. MENU navigation LSK triggers navigation and does not transfer into scratchpad', () {
      final engine = MCDUInputEngine();
      expect(engine.state.currentPageId, 'MENU');
      expect(engine.state.scratchpad, '');

      // Press 1L on MENU
      engine.handleKeyEvent(MCDUKeyEvent(keyId: '1L'));
      expect(engine.state.currentPageId, 'FPL');
      expect(engine.state.scratchpad, ''); // Scratchpad must remain empty!
    });
  });

  group('Hitbox and Bounds Integrity Tests', () {
    // 17. All hitboxes remain normalized [0.0, 1.0]
    test('17. all hitboxes remain normalized within [0.0, 1.0]', () {
      expect(MCDUKeypadOverlay.allHitboxes.isNotEmpty, isTrue);

      final keyIds = <String>{};
      for (final hitbox in MCDUKeypadOverlay.allHitboxes) {
        expect(hitbox.x, greaterThanOrEqualTo(0.0), reason: '${hitbox.keyId} x < 0.0');
        expect(hitbox.y, greaterThanOrEqualTo(0.0), reason: '${hitbox.keyId} y < 0.0');
        expect(hitbox.width, greaterThan(0.0), reason: '${hitbox.keyId} width <= 0.0');
        expect(hitbox.height, greaterThan(0.0), reason: '${hitbox.keyId} height <= 0.0');
        expect(hitbox.x + hitbox.width, lessThanOrEqualTo(1.0001), reason: '${hitbox.keyId} right edge > 1.0');
        expect(hitbox.y + hitbox.height, lessThanOrEqualTo(1.0001), reason: '${hitbox.keyId} bottom edge > 1.0');

        keyIds.add(hitbox.keyId);
      }

      // LSKs
      for (int i = 1; i <= 6; i++) {
        expect(keyIds.contains('${i}L'), isTrue);
        expect(keyIds.contains('${i}R'), isTrue);
      }

      // Function keys from physical image
      expect(keyIds.contains(MCDUKey.perf), isTrue);
      expect(keyIds.contains(MCDUKey.nav), isTrue);
      expect(keyIds.contains(MCDUKey.prev), isTrue);
      expect(keyIds.contains(MCDUKey.fpl), isTrue);
      expect(keyIds.contains(MCDUKey.prog), isTrue);
      expect(keyIds.contains(MCDUKey.dir), isTrue);
      expect(keyIds.contains(MCDUKey.menu), isTrue);
      expect(keyIds.contains(MCDUKey.next), isTrue);
      expect(keyIds.contains(MCDUKey.radio), isTrue);
      expect(keyIds.contains(MCDUKey.brtDim), isTrue);

      // Alpha A-Z
      for (final a in MCDUKey.alpha) {
        expect(keyIds.contains(a), isTrue);
      }

      // Numeric 0-9
      for (int i = 0; i <= 9; i++) {
        expect(keyIds.contains('$i'), isTrue);
      }

      // Action / Symbols
      expect(keyIds.contains(MCDUKey.clr), isTrue);
      expect(keyIds.contains(MCDUKey.del), isTrue);
      expect(keyIds.contains(MCDUKey.dot), isTrue);
      expect(keyIds.contains(MCDUKey.slash), isTrue);
      expect(keyIds.contains(MCDUKey.space), isTrue);
      expect(keyIds.contains(MCDUKey.plusMinus), isTrue);
    });
  });
}
