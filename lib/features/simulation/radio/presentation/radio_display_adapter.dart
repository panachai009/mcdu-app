// lib/features/simulation/radio/presentation/radio_display_adapter.dart
// Pure stateless adapter that converts RadioState and scratchpad into an MCDUState
// for dynamic display rendering inside MCDUScreen.

import '../../../mcdu_core/domain/mcdu_page.dart';
import '../../../mcdu_core/domain/mcdu_state.dart';
import '../domain/radio_state.dart';

class RadioDisplayAdapter {
  const RadioDisplayAdapter();

  /// Converts [RadioState] and current scratchpad into [MCDUState] for the MCDU dynamic display.
  static MCDUState toMCDUState(
    RadioState radioState, {
    required String scratchpad,
    String? lastKeyId,
    String? lastAction,
  }) {
    if (radioState.pageIndex == 2) {
      return _buildPage2(
        radioState,
        scratchpad: scratchpad,
        lastKeyId: lastKeyId,
        lastAction: lastAction,
      );
    }
    return _buildPage1(
      radioState,
      scratchpad: scratchpad,
      lastKeyId: lastKeyId,
      lastAction: lastAction,
    );
  }

  static MCDUState _buildPage1(
    RadioState radioState, {
    required String scratchpad,
    String? lastKeyId,
    String? lastAction,
  }) {
    final leftLabels = List<String>.filled(6, '');
    final rightLabels = List<String>.filled(6, '');

    // Row 1: COM1 Active / COM2 Active
    leftLabels[0] = '<${radioState.com1.active}';
    rightLabels[0] = '${radioState.com2.active}>';

    // Row 2: COM1 Standby / COM2 Standby
    leftLabels[1] = '<${radioState.com1.standby}';
    rightLabels[1] = '${radioState.com2.standby}>';

    // Row 3: NAV1 Active / NAV2 Active
    leftLabels[2] = '<${radioState.nav1.active}';
    rightLabels[2] = '${radioState.nav2.active}>';

    // Row 4: NAV1 Standby / NAV2 Standby
    leftLabels[3] = '<${radioState.nav1.standby}';
    rightLabels[3] = '${radioState.nav2.standby}>';

    // Row 5: TCAS/XPDR prompt / XPDR Code
    leftLabels[4] = '<TCAS/XPDR';
    rightLabels[4] = '${radioState.xpdrCode}>';

    // Row 6: XPDR Mode (STBY / ALT-ON) / IDENT
    final xpdrModeLabel = radioState.xpdrMode == XpdrMode.stby ? 'STBY' : 'ALT-ON';
    leftLabels[5] = '<$xpdrModeLabel';
    rightLabels[5] = radioState.isIdentActive ? '*IDENT*' : 'IDENT*';

    // Center lines for header / section indicators
    final List<String> centerLines = [
      'COM1 / COM2',
      'NAV1 / NAV2',
      'FMS AUTO',
      'XPDR',
    ];

    final page = MCDUPage(
      pageId: 'RADIO',
      title: 'RADIO        1/2',
      leftLabels: leftLabels,
      rightLabels: rightLabels,
      lines: centerLines,
      scratchpadVisible: true,
    );

    return MCDUState(
      currentPage: page,
      scratchpad: scratchpad,
      lastKeyId: lastKeyId,
      lastAction: lastAction,
    );
  }

  static MCDUState _buildPage2(
    RadioState radioState, {
    required String scratchpad,
    String? lastKeyId,
    String? lastAction,
  }) {
    final leftLabels = List<String>.filled(6, '');
    final rightLabels = List<String>.filled(6, '');

    // Row 1: Right is ADF2 Active
    rightLabels[0] = '${radioState.adf2.active}>';

    // Row 2: Right is ADF2 Standby
    rightLabels[1] = '${radioState.adf2.standby}>';

    // Row 6: Return shortcut or menu
    leftLabels[5] = '<MENU';

    final List<String> centerLines = [
      'ADF2',
    ];

    final page = MCDUPage(
      pageId: 'RADIO',
      title: 'RADIO        2/2',
      leftLabels: leftLabels,
      rightLabels: rightLabels,
      lines: centerLines,
      scratchpadVisible: true,
    );

    return MCDUState(
      currentPage: page,
      scratchpad: scratchpad,
      lastKeyId: lastKeyId,
      lastAction: lastAction,
    );
  }
}
