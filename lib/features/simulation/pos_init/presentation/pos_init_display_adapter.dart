// lib/features/simulation/pos_init/presentation/pos_init_display_adapter.dart
// Pure stateless adapter that converts PosInitState and scratchpad into an MCDUState
// for dynamic display rendering inside MCDUScreen.

import '../../../mcdu_core/domain/mcdu_page.dart';
import '../../../mcdu_core/domain/mcdu_state.dart';
import '../domain/pos_init_state.dart';

class PosInitDisplayAdapter {
  const PosInitDisplayAdapter();

  /// Converts [PosInitState] and current scratchpad into [MCDUState] for the MCDU dynamic display.
  static MCDUState toMCDUState(
    PosInitState state, {
    required String scratchpad,
    String? lastKeyId,
    String? lastAction,
  }) {
    final leftLabels = List<String>.filled(6, '');
    final rightLabels = List<String>.filled(6, '');

    // Row 1: LAST POS (1L) / LOAD► (1R)
    leftLabels[0] = state.lastPosLatLon;
    rightLabels[0] = 'LOAD►';

    // Row 2: REF WPT (2L) / LOAD► (2R)
    if (state.refWptIdent != null && state.refWptLatLon != null) {
      leftLabels[1] = state.refWptLatLon!;
      rightLabels[1] = 'LOAD►';
    } else {
      leftLabels[1] = '---° --.- ----° --.-';
      rightLabels[1] = '';
    }

    // Row 3: GPS 1 POS (3L) / LOAD► (3R)
    leftLabels[2] = state.gpsPosLatLon;
    rightLabels[2] = 'LOAD►';

    // Row 6: ◄POS SENSORS (6L) / FLT PLAN► (6R) if loaded
    leftLabels[5] = '◄POS SENSORS';
    rightLabels[5] = state.isPositionLoaded ? 'FLT PLAN►' : '';

    // Center header / sub-labels
    final refWptHeader = state.refWptIdent != null ? '${state.refWptIdent} REF WPT' : '--- REF WPT OR';
    final List<String> centerLines = [
      'LAST POS',
      refWptHeader,
      'GPS 1 POS',
    ];

    final page = const MCDUPage(
      pageId: 'POS_INIT',
      title: 'POSITION INIT   1/1',
      leftLabels: [],
      rightLabels: [],
      lines: [],
      scratchpadVisible: true,
    ).copyWith(
      leftLabels: leftLabels,
      rightLabels: rightLabels,
      lines: centerLines,
    );

    return MCDUState(
      currentPage: page,
      scratchpad: scratchpad,
      lastKeyId: lastKeyId,
      lastAction: lastAction,
    );
  }
}
