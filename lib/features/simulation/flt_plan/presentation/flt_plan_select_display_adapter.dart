// lib/features/simulation/flt_plan/presentation/flt_plan_select_display_adapter.dart
// AW139 FMS MCDU Manual Reference:
// FLT PLAN SELECT 1/1 & CONFIRM REPLACING ACTIVE FLIGHT PLAN — p46–48 Figures 6-7, 6-8, 6-9
//
// Pure stateless adapter that converts flight plan selection state into MCDUState.

import '../../../mcdu_core/domain/mcdu_page.dart';
import '../../../mcdu_core/domain/mcdu_state.dart';
import '../domain/flt_plan_list_state.dart';

class FltPlanSelectDisplayAdapter {
  const FltPlanSelectDisplayAdapter();

  /// Builds MCDUState for FLT PLAN SELECT 1/1 page (AW139 manual p46-48 Figures 6-7, 6-8).
  static MCDUState toSelectMCDUState(
    FltPlanListState listState, {
    String? fallbackPlanName,
    required String scratchpad,
    String? lastKeyId,
    String? lastAction,
  }) {
    final leftLabels = List<String>.filled(6, '');
    final rightLabels = List<String>.filled(6, '');

    final selectedPlan = listState.selectedPlan;
    final planName = selectedPlan?.name ?? fallbackPlanName ?? '';

    // 1L: FLT PLAN prompt, display plan name if selected
    leftLabels[0] = planName.isNotEmpty ? planName : 'FLT PLAN';

    // 1R: ACTIVATE►
    rightLabels[0] = 'ACTIVATE►';
    // 2R: INVERT/ACTIVATE►
    rightLabels[1] = 'INVERT/ACTIVATE►';
    // 6L: ◄FPL LIST
    leftLabels[5] = '◄FPL LIST';

    final page = const MCDUPage(
      pageId: 'FPL_SELECT',
      title: 'FLT PLAN SELECT 1/1',
      leftLabels: [],
      rightLabels: [],
      lines: [],
      scratchpadVisible: true,
    ).copyWith(
      pageId: 'FPL_SELECT',
      title: 'FLT PLAN SELECT 1/1',
      leftLabels: leftLabels,
      rightLabels: rightLabels,
      lines: const [],
    );

    return MCDUState(
      currentPage: page,
      scratchpad: scratchpad,
      lastKeyId: lastKeyId,
      lastAction: lastAction,
    );
  }

  /// Builds MCDUState for CONFIRM REPLACING ACTIVE FLIGHT PLAN page (AW139 manual p48 Figure 6-9).
  static MCDUState toConfirmMCDUState({
    required String scratchpad,
    String? lastKeyId,
    String? lastAction,
  }) {
    final leftLabels = List<String>.filled(6, '');
    final rightLabels = List<String>.filled(6, '');

    // 6L: ◄NO
    leftLabels[5] = '◄NO';
    // 6R: YES►
    rightLabels[5] = 'YES►';

    final centerLines = [
      '',
      '',
      'CONFIRM REPLACING',
      'ACTIVE FLIGHT PLAN',
    ];

    final page = const MCDUPage(
      pageId: 'FPL_CONFIRM',
      title: 'FLT PLAN SELECT 1/1',
      leftLabels: [],
      rightLabels: [],
      lines: [],
      scratchpadVisible: true,
    ).copyWith(
      pageId: 'FPL_CONFIRM',
      title: 'FLT PLAN SELECT 1/1',
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
