import 'dart:async';
import '../domain/mcdu_key.dart';
import '../domain/mcdu_page.dart';
import '../domain/mcdu_state.dart';
import '../presentation/mcdu_keypad_overlay.dart';
import 'mcdu_page_engine.dart';

/// Central input engine for MCDU.
/// Coordinates page navigation (via MCDUPageEngine), Alpha/Numeric input,
/// Scratchpad management (max 24 chars), CLR, DEL, and LSK transfers.
class MCDUInputEngine {
  final MCDUPageEngine pageEngine;
  MCDUState _state;

  // Broadcast stream of key events
  final _eventController = StreamController<MCDUKeyEvent>.broadcast();

  // Broadcast stream of state changes
  final _stateController = StreamController<MCDUState>.broadcast();

  MCDUInputEngine({MCDUPageEngine? pageEngine, MCDUState? initialState})
      : pageEngine = pageEngine ?? MCDUPageEngine(initialPage: initialState?.currentPage),
        _state = initialState ?? MCDUState.initial(pageEngine?.currentPage) {
    // Synchronize initial page with page engine
    if (_state.currentPage != this.pageEngine.currentPage) {
      _state = _state.copyWith(currentPage: this.pageEngine.currentPage);
    }
  }

  /// Stream of key events.
  Stream<MCDUKeyEvent> get events => _eventController.stream;

  /// Stream of updated states.
  Stream<MCDUState> get stateStream => _stateController.stream;

  /// Current state snapshot.
  MCDUState get state => _state;

  /// Identifier of the most recent key.
  String? get lastKeyId => _state.lastKeyId;

  /// Identifier of the most recent action.
  String? get lastAction => _state.lastAction;

  /// Process a key event coming from the UI.
  void handleKeyEvent(MCDUKeyEvent event) {
    _eventController.add(event);

    final keyId = event.keyId;
    _state = _reduceState(_state, keyId);
    _stateController.add(_state);
  }

  /// Resets the engine back to initial state (MENU page, empty scratchpad, no last key).
  void reset() {
    pageEngine.navigateTo('MENU');
    _state = MCDUState.initial(pageEngine.currentPage);
    _stateController.add(_state);
  }

  /// State transition reducer based on keyId.
  MCDUState _reduceState(MCDUState current, String keyId) {
    // -------------------------------------------------------------
    // 1. Page Engine Navigation Check (Precedence over Scratchpad/LSK)
    // -------------------------------------------------------------
    final navigatedPageId = pageEngine.handleNavigationKey(keyId);
    if (navigatedPageId != null) {
      return current.copyWith(
        currentPage: pageEngine.currentPage,
        lastKeyId: keyId,
        lastAction: 'NAVIGATE_$navigatedPageId',
      );
    }

    // If PREV or NEXT was pressed but no history was available
    if (keyId == MCDUKey.prev || keyId == MCDUKey.next) {
      return current.copyWith(
        lastKeyId: keyId,
        lastAction: 'NO_HISTORY',
      );
    }

    // -------------------------------------------------------------
    // 2. Line Select Keys (LSK) Handling (When not consumed by navigation)
    // -------------------------------------------------------------
    final lskMatch = RegExp(r'^([1-6])([LR])$').firstMatch(keyId);
    if (lskMatch != null) {
      final index = int.parse(lskMatch.group(1)!) - 1;
      final side = lskMatch.group(2)!;

      if (current.scratchpad.isNotEmpty) {
        final transferredText = current.scratchpad;
        MCDUPage updatedPage;

        if (side == 'L') {
          final newLeft = List<String>.from(current.leftLabels);
          newLeft[index] = transferredText;
          updatedPage = current.currentPage.copyWith(leftLabels: newLeft);
        } else {
          final newRight = List<String>.from(current.rightLabels);
          newRight[index] = transferredText;
          updatedPage = current.currentPage.copyWith(rightLabels: newRight);
        }

        pageEngine.updateCurrentPage(updatedPage);

        return current.copyWith(
          currentPage: updatedPage,
          scratchpad: '',
          lastKeyId: keyId,
          lastAction: 'LSK_TRANSFER_$keyId',
        );
      } else {
        return current.copyWith(
          lastKeyId: keyId,
          lastAction: 'LSK_PRESS_$keyId',
        );
      }
    }

    // -------------------------------------------------------------
    // 3. CLR Key Handling
    // -------------------------------------------------------------
    if (keyId == MCDUKey.clr) {
      if (current.scratchpad.isNotEmpty) {
        final updatedScratchpad = current.scratchpad.substring(0, current.scratchpad.length - 1);
        return current.copyWith(
          scratchpad: updatedScratchpad,
          lastKeyId: keyId,
          lastAction: 'CLR',
        );
      } else {
        return current.copyWith(
          lastKeyId: keyId,
          lastAction: 'CLR_EMPTY',
        );
      }
    }

    // -------------------------------------------------------------
    // 4. DEL Key Handling (Separate action/event from CLR)
    // -------------------------------------------------------------
    if (keyId == MCDUKey.del) {
      return current.copyWith(
        lastKeyId: keyId,
        lastAction: 'DEL',
      );
    }

    // -------------------------------------------------------------
    // 5. Printable Character Input into Scratchpad
    // -------------------------------------------------------------
    final char = _mapChar(keyId);
    if (char != null) {
      if (current.scratchpad.length < 24) {
        return current.copyWith(
          scratchpad: current.scratchpad + char,
          lastKeyId: keyId,
          lastAction: 'INPUT_CHAR_$char',
        );
      } else {
        return current.copyWith(
          lastKeyId: keyId,
          lastAction: 'SCRATCHPAD_FULL',
        );
      }
    }

    // Default: record key press for other keys (e.g. BRT/DIM)
    return current.copyWith(
      lastKeyId: keyId,
      lastAction: 'PRESS_$keyId',
    );
  }

  /// Maps a keyId to a printable character, or null if non-character.
  String? _mapChar(String keyId) {
    if (keyId.length == 1 &&
        ((keyId.codeUnitAt(0) >= 65 && keyId.codeUnitAt(0) <= 90) || // A-Z
         (keyId.codeUnitAt(0) >= 48 && keyId.codeUnitAt(0) <= 57))) {  // 0-9
      return keyId;
    }
    switch (keyId) {
      case MCDUKey.dot:
        return '.';
      case MCDUKey.space:
        return ' ';
      case MCDUKey.slash:
        return '/';
      case MCDUKey.plusMinus:
        return '±';
      default:
        return null;
    }
  }

  /// Dispose stream controllers.
  void dispose() {
    _eventController.close();
    _stateController.close();
  }
}
