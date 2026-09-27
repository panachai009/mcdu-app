// lib/features/simulation/nav/presentation/nav_display_adapter.dart
// Pure stateless adapter that converts NavState and scratchpad into an MCDUState
// for dynamic display rendering inside MCDUScreen.

import '../../../mcdu_core/domain/mcdu_page.dart';
import '../../../mcdu_core/domain/mcdu_state.dart';
import '../domain/nav_state.dart';

class NavDisplayAdapter {
  const NavDisplayAdapter();

  /// Converts [NavState] and current scratchpad into [MCDUState] for the MCDU dynamic display.
  static MCDUState toMCDUState(
    NavState navState, {
    required String scratchpad,
    String? lastKeyId,
    String? lastAction,
  }) {
    switch (navState.page) {
      case NavPage.index1:
        return _buildIndex1(
          scratchpad: scratchpad,
          lastKeyId: lastKeyId,
          lastAction: lastAction,
        );
      case NavPage.index2:
        return _buildIndex2(
          scratchpad: scratchpad,
          lastKeyId: lastKeyId,
          lastAction: lastAction,
        );
      case NavPage.ident:
        return _buildIdent(
          navState,
          scratchpad: scratchpad,
          lastKeyId: lastKeyId,
          lastAction: lastAction,
        );
    }
  }

  static MCDUState _buildIndex1({
    required String scratchpad,
    String? lastKeyId,
    String? lastAction,
  }) {
    final leftLabels = List<String>.filled(6, '');
    final rightLabels = List<String>.filled(6, '');

    leftLabels[0] = '◄FPL LIST';
    rightLabels[0] = 'FPL SEL►';

    leftLabels[1] = '◄WPT LIST';
    rightLabels[1] = 'DATA BASE►';

    leftLabels[2] = '◄NAV IDENT';
    rightLabels[2] = 'FLT SUM►';

    leftLabels[3] = '◄POS SENSORS';
    rightLabels[3] = '';

    leftLabels[4] = '◄CROSS PTS';
    rightLabels[4] = 'PATTERNS►';

    leftLabels[5] = '◄DEPARTURE';
    rightLabels[5] = 'ARRIVAL►';

    final page = const MCDUPage(
      pageId: 'NAV',
      title: 'NAV INDEX      1/2',
      leftLabels: [],
      rightLabels: [],
      lines: [],
      scratchpadVisible: true,
    ).copyWith(
      leftLabels: leftLabels,
      rightLabels: rightLabels,
      lines: [''],
    );

    return MCDUState(
      currentPage: page,
      scratchpad: scratchpad,
      lastKeyId: lastKeyId,
      lastAction: lastAction,
    );
  }

  static MCDUState _buildIndex2({
    required String scratchpad,
    String? lastKeyId,
    String? lastAction,
  }) {
    final leftLabels = List<String>.filled(6, '');
    final rightLabels = List<String>.filled(6, '');

    leftLabels[0] = '◄POS INIT';
    rightLabels[0] = 'CONVERSION►';

    leftLabels[1] = '◄DATA LOAD';
    rightLabels[1] = 'MAINTENANCE►';

    final page = const MCDUPage(
      pageId: 'NAV',
      title: 'NAV INDEX      2/2',
      leftLabels: [],
      rightLabels: [],
      lines: [],
      scratchpadVisible: true,
    ).copyWith(
      leftLabels: leftLabels,
      rightLabels: rightLabels,
      lines: [''],
    );

    return MCDUState(
      currentPage: page,
      scratchpad: scratchpad,
      lastKeyId: lastKeyId,
      lastAction: lastAction,
    );
  }

  static MCDUState _buildIdent(
    NavState state, {
    required String scratchpad,
    String? lastKeyId,
    String? lastAction,
  }) {
    final leftLabels = List<String>.filled(6, '');
    final rightLabels = List<String>.filled(6, '');

    leftLabels[0] = state.date;
    rightLabels[0] = state.activeNdb;

    leftLabels[1] = state.utc;
    rightLabels[1] = state.nonActiveNdb;

    leftLabels[2] = state.softwareVersion;
    rightLabels[2] = state.databasePartNumber;

    leftLabels[5] = '◄MAINTENANCE';
    rightLabels[5] = 'POS INIT►';

    final lines = [
      'DATE',
      'ACTIVE NDB',
      'UTC',
      'NON-ACTIVE NDB',
      'SW',
      'NDB V3.01 16M',
    ];

    final page = const MCDUPage(
      pageId: 'NAV',
      title: 'NAV IDENT      1/1',
      leftLabels: [],
      rightLabels: [],
      lines: [],
      scratchpadVisible: true,
    ).copyWith(
      leftLabels: leftLabels,
      rightLabels: rightLabels,
      lines: lines,
    );

    return MCDUState(
      currentPage: page,
      scratchpad: scratchpad,
      lastKeyId: lastKeyId,
      lastAction: lastAction,
    );
  }
}
