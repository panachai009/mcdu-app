// test/fpl_show_display_test.dart
// Phase 19E-F1 — FplShowDisplayAdapter Unit Tests
// AW139 Manual Reference: p42-44 Procedure 6-1

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/flt_plan_state.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/stored_flt_plan.dart';
import 'package:mcdu_app/features/simulation/flt_plan/presentation/fpl_show_display_adapter.dart';

void main() {
  group('Phase 19E-F1 FplShowDisplayAdapter Tests', () {
    const planWithLegs = StoredFltPlan(
      id: 'plan-01',
      name: 'VFR01',
      originIdent: 'VTBD',
      destinationIdent: 'VTBS',
      legs: [
        FltPlanLeg(fixIdent: 'WAYP1', altitudeSpd: '030/0150'),
        FltPlanLeg(fixIdent: 'VTBS', altitudeSpd: '---/0100'),
      ],
    );

    const planNoLegs = StoredFltPlan(
      id: 'plan-02',
      name: 'DIRECT',
      originIdent: 'VTBD',
      destinationIdent: 'VTCC',
      legs: [],
    );

    // 1. renders stored plan name
    test('1. renders stored plan name in header or center lines', () {
      final state = FplShowDisplayAdapter.toMCDUState(planWithLegs, scratchpad: '');
      expect(state.currentPage.pageId, 'FPL_SHOW');
      expect(state.currentPage.lines, contains('PLAN: VFR01'));
    });

    // 2. renders origin
    test('2. renders origin at 1L', () {
      final state = FplShowDisplayAdapter.toMCDUState(planWithLegs, scratchpad: '');
      expect(state.currentPage.leftLabels[0], 'VTBD');
    });

    // 3. renders destination
    test('3. renders destination at 1R', () {
      final state = FplShowDisplayAdapter.toMCDUState(planWithLegs, scratchpad: '');
      expect(state.currentPage.rightLabels[0], 'VTBS');
    });

    // 4. renders actual stored legs
    test('4. renders actual stored legs on intermediate rows', () {
      final state = FplShowDisplayAdapter.toMCDUState(planWithLegs, scratchpad: '');
      expect(state.currentPage.leftLabels[1], 'WAYP1');
      expect(state.currentPage.rightLabels[1], '030/0150');
      expect(state.currentPage.leftLabels[2], 'VTBS');
      expect(state.currentPage.rightLabels[2], '---/0100');
    });

    // 5. does not mutate StoredFltPlan
    test('5. does not mutate input StoredFltPlan', () {
      final originalName = planWithLegs.name;
      final originalLegsCount = planWithLegs.legs.length;

      FplShowDisplayAdapter.toMCDUState(planWithLegs, scratchpad: 'TEST');

      expect(planWithLegs.name, originalName);
      expect(planWithLegs.legs.length, originalLegsCount);
    });

    // 6. does not create FltPlanState
    test('6. returns MCDUState without creating or returning FltPlanState', () {
      final state = FplShowDisplayAdapter.toMCDUState(planWithLegs, scratchpad: '');
      expect(state.currentPage.pageId, 'FPL_SHOW');
      expect(state.scratchpad, '');
    });

    // 7. handles empty route without fake data
    test('7. handles empty route without injecting fake data or waypoints', () {
      final state = FplShowDisplayAdapter.toMCDUState(planNoLegs, scratchpad: '');
      expect(state.currentPage.leftLabels[0], 'VTBD');
      expect(state.currentPage.rightLabels[0], 'VTCC');
      expect(state.currentPage.leftLabels[1], isEmpty);
      expect(state.currentPage.leftLabels[2], isEmpty);
      expect(state.currentPage.leftLabels[3], isEmpty);
      expect(state.currentPage.leftLabels[4], isEmpty);
      expect(state.currentPage.leftLabels[5], '◄FPL LIST');
    });

    // 8. preserves MCDU 14x24 layout conventions
    test('8. preserves MCDU 14x24 layout conventions and return prompt', () {
      final state = FplShowDisplayAdapter.toMCDUState(planWithLegs, scratchpad: 'SCRATCH');
      expect(state.currentPage.leftLabels.length, 6);
      expect(state.currentPage.rightLabels.length, 6);
      expect(state.currentPage.leftLabels[5], '◄FPL LIST');
      expect(state.scratchpad, 'SCRATCH');
    });
  });
}
