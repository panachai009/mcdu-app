// lib/features/simulation/flt_plan/presentation/fpl_list_display_adapter.dart
// AW139 FMS MCDU Manual Reference:
// Flight Plan List / FPL LIST Page — Section 3/4 (NAV INDEX 1/2 1L -> FPL LIST, ACTIVE FLT PLAN 6L -> FPL LIST)
//
// Pure stateless adapter that converts FltPlanListState and scratchpad into an MCDUState.

import '../../../mcdu_core/domain/mcdu_page.dart';
import '../../../mcdu_core/domain/mcdu_state.dart';
import '../domain/flt_plan_list_state.dart';

class FplListDisplayAdapter {
  const FplListDisplayAdapter();

  /// Converts [FltPlanListState] and current [scratchpad] into an [MCDUState]
  /// adhering to the 14x24 MCDU display conventions.
  static MCDUState toMCDUState(
    FltPlanListState state, {
    required String scratchpad,
    String? lastKeyId,
    String? lastAction,
  }) {
    final leftLabels = List<String>.filled(6, '');
    final rightLabels = List<String>.filled(6, '');

    // Title line layout: FPL LIST (with page indication, e.g. 1/1)
    final title = 'FPL LIST       ${state.pageIndex}/${state.totalPages}';

    // Populate up to 5 plan items across LSK 1L - 5L
    // LSK 6L is reserved for return navigation prompt: ◄FPL or ◄ACTIVE FPL
    for (int i = 0; i < 5; i++) {
      if (i < state.plans.length) {
        final plan = state.plans[i];
        final isSelected = state.selectedIndex == i;
        // Selection indicator if selected: '*' prefix or highlighted marker
        final prefix = isSelected ? '* ' : '';
        leftLabels[i] = '$prefix${plan.name}';
      } else {
        leftLabels[i] = '';
      }
    }

    // 1R: SHOW FPL► prompt (AW139 manual p41 Figure 6-3, p42 Procedure 6-1)
    rightLabels[0] = 'SHOW FPL►';

    // 6L: Return prompt to flight plan
    leftLabels[5] = '◄FPL';

    // 6R: Prompt to FLT PLAN SELECT (AW139 manual p41 Figure 6-3/6-4)
    rightLabels[5] = 'FPL SEL►';

    final centerLines = <String>[];

    final page = const MCDUPage(
      pageId: 'FPL_LIST',
      title: 'FPL LIST',
      leftLabels: [],
      rightLabels: [],
      lines: [],
      scratchpadVisible: true,
    ).copyWith(
      pageId: 'FPL_LIST',
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
