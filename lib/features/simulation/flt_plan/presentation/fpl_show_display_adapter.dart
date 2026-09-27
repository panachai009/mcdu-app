// lib/features/simulation/flt_plan/presentation/fpl_show_display_adapter.dart
// AW139 FMS MCDU Manual Reference:
// Flight Plan Review / SHOW FPL — p42–44 Procedure 6-1
//
// Pure stateless adapter that converts StoredFltPlan into an MCDUState for review-only display.
// Does NOT mutate StoredFltPlan. Does NOT instantiate or mutate FltPlanState.

import '../../../mcdu_core/domain/mcdu_page.dart';
import '../../../mcdu_core/domain/mcdu_state.dart';
import '../domain/stored_flt_plan.dart';

class FplShowDisplayAdapter {
  const FplShowDisplayAdapter();

  /// Converts [StoredFltPlan] and current [scratchpad] into [MCDUState] for the SHOW FPL review display.
  static MCDUState toMCDUState(
    StoredFltPlan plan, {
    int pageIndex = 1,
    int totalPages = 1,
    required String scratchpad,
    String? lastKeyId,
    String? lastAction,
  }) {
    final leftLabels = List<String>.filled(6, '');
    final rightLabels = List<String>.filled(6, '');

    // Title line: e.g. "SHOW FPL       1/1"
    final title = 'SHOW FPL       $pageIndex/$totalPages';

    // 1L: Origin (or blank if null)
    leftLabels[0] = plan.originIdent ?? '';

    // 1R: Destination (or '----' if null)
    rightLabels[0] = plan.destinationIdent ?? '----';

    // Route legs rendering: up to 3 intermediate legs displayed on rows 2, 3, 4
    if (plan.legs.isNotEmpty) {
      for (int i = 0; i < plan.legs.length && i < 3; i++) {
        final leg = plan.legs[i];
        leftLabels[i + 1] = leg.fixIdent;
        if (leg.altitudeSpd != null) {
          rightLabels[i + 1] = leg.altitudeSpd!;
        }
      }
    }

    // 6L: Return prompt to FPL LIST (◄FPL LIST)
    leftLabels[5] = '◄FPL LIST';

    final centerLines = [
      'ORIGIN/ETD',
      'DEST',
      'PLAN: ${plan.name}',
    ];

    final page = const MCDUPage(
      pageId: 'FPL_SHOW',
      title: 'SHOW FPL',
      leftLabels: [],
      rightLabels: [],
      lines: [],
      scratchpadVisible: true,
    ).copyWith(
      pageId: 'FPL_SHOW',
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
