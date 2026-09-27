// lib/features/simulation/flt_plan/presentation/active_flt_plan_display_adapter.dart
// Pure stateless adapter that converts FltPlanState and scratchpad into an MCDUState
// for dynamic display rendering inside MCDUScreen.
//
// AW139 FMS MCDU Manual Reference:
// ACTIVE FLT PLAN 1/1 (unpopulated) — p74 Im130
// ACTIVE FLT PLAN 1/2 (populated) — p76 Im132

import '../../../mcdu_core/domain/mcdu_page.dart';
import '../../../mcdu_core/domain/mcdu_state.dart';
import '../domain/flt_plan_state.dart';

class ActiveFltPlanDisplayAdapter {
  const ActiveFltPlanDisplayAdapter();

  /// Converts [FltPlanState] and current scratchpad into [MCDUState] for dynamic display rendering.
  static MCDUState toMCDUState(
    FltPlanState state, {
    required String scratchpad,
    String? lastKeyId,
    String? lastAction,
  }) {
    switch (state.page) {
      case FltPlanPage.init:
        return _buildInitPage(
          state,
          scratchpad: scratchpad,
          lastKeyId: lastKeyId,
          lastAction: lastAction,
        );
      case FltPlanPage.route:
        return _buildRoutePage(
          state,
          scratchpad: scratchpad,
          lastKeyId: lastKeyId,
          lastAction: lastAction,
        );
    }
  }

  /// Builds ACTIVE FLT PLAN 1/1 (unpopulated / awaiting destination).
  /// AW139 FMS MCDU manual p74 Im130:
  /// 1L: ORIGIN/ETD / `origin`
  /// 1R: DEST / ----
  /// Center lines:
  ///   RECALL OR CREATE
  ///   FPL NAMED ----------
  ///   FPL STORAGE DEVICE
  ///   LAN
  /// 6L: ◄FPL LIST
  /// 6R: PERF INIT►
  static MCDUState _buildInitPage(
    FltPlanState state, {
    required String scratchpad,
    String? lastKeyId,
    String? lastAction,
  }) {
    final leftLabels = List<String>.filled(6, '');
    final rightLabels = List<String>.filled(6, '');

    // 1L: Origin (or blank if uninitialized)
    leftLabels[0] = state.originIdent ?? '';

    // 1R: Destination prompt (or '----' when empty)
    rightLabels[0] = state.destinationIdent ?? '----';

    // 6L: ◄FPL LIST
    leftLabels[5] = '◄FPL LIST';

    // 6R: PERF INIT►
    rightLabels[5] = 'PERF INIT►';

    final centerLines = [
      'ORIGIN/ETD',
      'DEST',
      'RECALL OR CREATE',
      'FPL NAMED ----------',
      'FPL STORAGE DEVICE',
      'LAN',
    ];

    final page = const MCDUPage(
      pageId: 'FPL',
      title: 'ACTIVE FLT PLAN 1/1',
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

  /// Builds ACTIVE FLT PLAN 1/2 (populated with origin and destination).
  /// AW139 FMS MCDU manual p76 Im132:
  /// 1L: ORIGIN/ETD / `origin`
  /// 2L: `destination` (or first leg fix) with tracking details
  /// 2R: DEST / `destination`
  /// Center lines:
  ///   SAVE ACTIVE FLT
  ///   PLAN TO ----------
  /// 6L: ◄DEPARTURE
  /// 6R: PERF INIT►
  static MCDUState _buildRoutePage(
    FltPlanState state, {
    required String scratchpad,
    String? lastKeyId,
    String? lastAction,
  }) {
    final leftLabels = List<String>.filled(6, '');
    final rightLabels = List<String>.filled(6, '');

    // 1L: Origin
    leftLabels[0] = state.originIdent ?? '';

    final title = 'ACTIVE FLT PLAN ${state.pageIndex}/${state.totalPages}';

    // If leg information exists in state, display it; otherwise display destination identifier directly.
    if (state.legs.isNotEmpty) {
      // If single leg with detailed flight deck tracking (AW139 p76 Im132 style)
      if (state.legs.length == 1) {
        final leg = state.legs.first;
        // 2L: Leg fix ident
        leftLabels[1] = leg.fixIdent;

        // Leg details if present
        final trackDist = [
          if (leg.bearingTrack != null) leg.bearingTrack,
          if (leg.distanceNm != null) leg.distanceNm,
        ].join(' ');

        // 2R: DEST
        rightLabels[1] = leg.altitudeSpd ?? '';
        rightLabels[2] = 'DEST';
        rightLabels[3] = leg.fixIdent;

        // Center header and leg tracking
        final centerLines = [
          'ORIGIN/ETD',
          trackDist,
          leg.ete ?? '',
          'SAVE ACTIVE FLT',
          'PLAN TO ----------',
        ];

        leftLabels[5] = '◄DEPARTURE';
        rightLabels[5] = 'PERF INIT►';

        final page = const MCDUPage(
          pageId: 'FPL',
          title: 'ACTIVE FLT PLAN',
          leftLabels: [],
          rightLabels: [],
          lines: [],
          scratchpadVisible: true,
        ).copyWith(
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
      } else {
        // Multi-leg route rendering (AW139 p19 Figure 3-5 style):
        // Up to 4 sequential legs displayed on rows 2L–5L
        for (int i = 0; i < state.legs.length && i < 4; i++) {
          final leg = state.legs[i];
          leftLabels[i + 1] = leg.fixIdent;
          if (leg.altitudeSpd != null) {
            rightLabels[i + 1] = leg.altitudeSpd!;
          }
        }

        leftLabels[5] = '◄DEPARTURE';
        rightLabels[5] = 'PERF INIT►';

        final centerLines = [
          'ORIGIN/ETD',
          'SAVE ACTIVE FLT',
          'PLAN TO ----------',
        ];

        final page = const MCDUPage(
          pageId: 'FPL',
          title: 'ACTIVE FLT PLAN',
          leftLabels: [],
          rightLabels: [],
          lines: [],
          scratchpadVisible: true,
        ).copyWith(
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
    } else {
      // Direct origin -> destination without detailed leg calculations
      leftLabels[1] = state.destinationIdent ?? '';
      rightLabels[1] = 'DEST';
      rightLabels[2] = state.destinationIdent ?? '';

      leftLabels[5] = '◄DEPARTURE';
      rightLabels[5] = 'PERF INIT►';

      final centerLines = [
        'ORIGIN/ETD',
        'SAVE ACTIVE FLT',
        'PLAN TO ----------',
      ];

      final page = const MCDUPage(
        pageId: 'FPL',
        title: 'ACTIVE FLT PLAN',
        leftLabels: [],
        rightLabels: [],
        lines: [],
        scratchpadVisible: true,
      ).copyWith(
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
}
