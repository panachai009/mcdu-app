// lib/features/simulation/flt_plan/presentation/fpl_create_display_adapter.dart
// AW139 FMS MCDU Manual Reference:
// Flight Plan Creation / Definition Display — Section 3/4 Navigation Index / Procedure 6-1 (p43-44, Figure 6-6)
//
// Pure stateless adapter that converts FltPlanCreateState and scratchpad into MCDUState.
// Does NOT mutate FltPlanCreateState. Does NOT execute business logic or call engines.

import '../../../mcdu_core/domain/mcdu_page.dart';
import '../../../mcdu_core/domain/mcdu_state.dart';
import '../domain/flt_plan_create_state.dart';

class FplCreateDisplayAdapter {
  const FplCreateDisplayAdapter();

  /// Converts [FltPlanCreateState] and current [scratchpad] into [MCDUState]
  /// for the CREATE STORED FLIGHT PLAN definition display (p43 Figure 6-6).
  static MCDUState toMCDUState(
    FltPlanCreateState state, {
    int pageIndex = 1,
    int totalPages = 1,
    required String scratchpad,
    String? lastKeyId,
    String? lastAction,
  }) {
    final leftLabels = List<String>.filled(6, '');
    final rightLabels = List<String>.filled(6, '');

    // Title line: "<NAME> FPL <pageIndex>/<totalPages>"
    // AW139 MCDU manual p43 Figure 6-6: "KPHX-KMSP FPL   1/1"
    final title = '${state.name.toUpperCase()} FPL $pageIndex/$totalPages';

    // 1L: Origin (or dashes '----' if not yet defined)
    leftLabels[0] = state.originIdent ?? '----';

    // 1R: Groundspeed (kt) from state.groundspeed (default 120 kt, or user-entered)
    rightLabels[0] = '${state.groundspeed}';

    // 2R: Destination (or dashes '----' if not yet defined)
    rightLabels[1] = state.destinationIdent ?? '----';

    // Route legs rendering:
    // Sequential route waypoints (Procedure 6-1 Steps 6-8)
    // Displayed on intermediate left labels (2L..5L).
    // If no route legs have been added yet, 2L shows '-----' placeholder prompt for VIA.TO entry.
    if (state.legs.isEmpty) {
      leftLabels[1] = '-----';
    } else {
      for (int i = 0; i < state.legs.length && i < 4; i++) {
        leftLabels[i + 1] = state.legs[i].fixIdent;
      }
    }

    // 6L: ◄PATTERN (Figure 6-6 p43)
    leftLabels[5] = '◄PATTERN';

    // 6R: FPL SEL► (Figure 6-6 p43)
    rightLabels[5] = 'FPL SEL►';

    // Center header lines corresponding to column headers in Figure 6-6:
    // Line 1: ORIGIN     GS
    // Line 2: VIA.TO     DEST
    final centerLines = [
      'ORIGIN          GS',
      'VIA.TO        DEST',
    ];

    final page = const MCDUPage(
      pageId: 'FPL_CREATE',
      title: 'FPL CREATE',
      leftLabels: [],
      rightLabels: [],
      lines: [],
      scratchpadVisible: true,
    ).copyWith(
      pageId: 'FPL_CREATE',
      title: title,
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
