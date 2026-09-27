// test/fpl_create_display_test.dart
// AW139 FMS MCDU Manual Reference:
// Flight Plan Creation Display Adapter Tests — Procedure 6-1 (p43–44, Figure 6-6)

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/flt_plan_create_state.dart';
import 'package:mcdu_app/features/simulation/flt_plan/domain/flt_plan_state.dart'
    show FltPlanLeg;
import 'package:mcdu_app/features/simulation/flt_plan/presentation/fpl_create_display_adapter.dart';

void main() {
  group('FplCreateDisplayAdapter Tests', () {
    const standardState = FltPlanCreateState(
      name: 'KPHX-KMSP',
      originIdent: 'KPHX',
      destinationIdent: 'KMSP',
      groundspeed: 120,
      legs: [
        FltPlanLeg(fixIdent: 'DRK'),
        FltPlanLeg(fixIdent: 'INW'),
        FltPlanLeg(fixIdent: 'CNY'),
        FltPlanLeg(fixIdent: 'KMSP'),
      ],
    );

    const nonStandardState = FltPlanCreateState(
      name: 'PATROL01',
      originIdent: 'VTBD',
      destinationIdent: 'VTBK',
      groundspeed: 250,
      legs: [
        FltPlanLeg(fixIdent: 'WP01'),
        FltPlanLeg(fixIdent: 'VTBK'),
      ],
    );

    const unpopulatedState = FltPlanCreateState(
      name: 'NEWPLAN',
      originIdent: null,
      destinationIdent: null,
      groundspeed: 120,
      legs: [],
    );

    // 1. Title <NAME> FPL 1/1
    test('1. title formats as <NAME> FPL 1/1', () {
      final mcdu = FplCreateDisplayAdapter.toMCDUState(standardState, scratchpad: '');
      expect(mcdu.title, 'KPHX-KMSP FPL 1/1');
    });

    // 2. Standard name formatting in title
    test('2. standard name displays correctly in title', () {
      const state = FltPlanCreateState(name: 'KPHX-KMSP1');
      final mcdu = FplCreateDisplayAdapter.toMCDUState(state, scratchpad: '');
      expect(mcdu.title, 'KPHX-KMSP1 FPL 1/1');
    });

    // 3. Non-standard name formatting in title
    test('3. non-standard name displays correctly in title', () {
      final mcdu = FplCreateDisplayAdapter.toMCDUState(nonStandardState, scratchpad: '');
      expect(mcdu.title, 'PATROL01 FPL 1/1');
    });

    // 4. Origin displayed at 1L
    test('4. origin displayed at 1L', () {
      final mcdu = FplCreateDisplayAdapter.toMCDUState(standardState, scratchpad: '');
      expect(mcdu.leftLabels[0], 'KPHX');
    });

    // 5. Destination displayed at 2R
    test('5. destination displayed at 2R', () {
      final mcdu = FplCreateDisplayAdapter.toMCDUState(standardState, scratchpad: '');
      expect(mcdu.rightLabels[1], 'KMSP');
    });

    // 6. Missing origin displays dashes
    test('6. missing origin displays placeholder dashes', () {
      final mcdu = FplCreateDisplayAdapter.toMCDUState(unpopulatedState, scratchpad: '');
      expect(mcdu.leftLabels[0], '----');
    });

    // 7. Missing destination displays dashes
    test('7. missing destination displays placeholder dashes', () {
      final mcdu = FplCreateDisplayAdapter.toMCDUState(unpopulatedState, scratchpad: '');
      expect(mcdu.rightLabels[1], '----');
    });

    // 8. Default groundspeed 120 displayed at 1R
    test('8. default 120 groundspeed displayed at 1R', () {
      final mcdu = FplCreateDisplayAdapter.toMCDUState(standardState, scratchpad: '');
      expect(mcdu.rightLabels[0], '120');
    });

    // 9. Changed groundspeed displayed at 1R
    test('9. changed groundspeed (e.g. 250) displayed at 1R without hardcoding 120', () {
      final mcdu = FplCreateDisplayAdapter.toMCDUState(nonStandardState, scratchpad: '');
      expect(mcdu.rightLabels[0], '250');
    });

    // 10. Empty route displays VIA.TO prompt dashes
    test('10. empty route displays VIA.TO dashes at 2L', () {
      final mcdu = FplCreateDisplayAdapter.toMCDUState(unpopulatedState, scratchpad: '');
      expect(mcdu.leftLabels[1], '-----');
      expect(mcdu.leftLabels[2], '');
      expect(mcdu.leftLabels[3], '');
      expect(mcdu.leftLabels[4], '');
    });

    // 11. One waypoint displayed at 2L
    test('11. one waypoint displayed at 2L', () {
      final state = unpopulatedState.copyWith(
        legs: const [FltPlanLeg(fixIdent: 'DRK')],
      );
      final mcdu = FplCreateDisplayAdapter.toMCDUState(state, scratchpad: '');
      expect(mcdu.leftLabels[1], 'DRK');
      expect(mcdu.leftLabels[2], '');
    });

    // 12. Multiple waypoints displayed sequentially on left labels
    test('12. multiple waypoints displayed sequentially', () {
      final mcdu = FplCreateDisplayAdapter.toMCDUState(standardState, scratchpad: '');
      expect(mcdu.leftLabels[1], 'DRK');
      expect(mcdu.leftLabels[2], 'INW');
      expect(mcdu.leftLabels[3], 'CNY');
      expect(mcdu.leftLabels[4], 'KMSP');
    });

    // 13. Route order strictly preserved from state
    test('13. route order strictly preserved from state legs', () {
      final mcdu = FplCreateDisplayAdapter.toMCDUState(standardState, scratchpad: '');
      final renderedWaypoints = [
        mcdu.leftLabels[1],
        mcdu.leftLabels[2],
        mcdu.leftLabels[3],
        mcdu.leftLabels[4],
      ];
      expect(renderedWaypoints, ['DRK', 'INW', 'CNY', 'KMSP']);
    });

    // 14. Destination displayed separately on 2R regardless of legs
    test('14. destination displayed separately from intermediate legs at 2R', () {
      final mcdu = FplCreateDisplayAdapter.toMCDUState(standardState, scratchpad: '');
      expect(mcdu.rightLabels[1], 'KMSP');
      expect(mcdu.leftLabels[4], 'KMSP'); // final leg is explicit last waypoint per Procedure 6-1 Step 8
    });

    // 15. Scratchpad preserved exactly
    test('15. scratchpad preserved with custom value', () {
      final mcdu = FplCreateDisplayAdapter.toMCDUState(
        standardState,
        scratchpad: 'VTBH',
      );
      expect(mcdu.scratchpad, 'VTBH');
    });

    // 16. Empty scratchpad remains empty
    test('16. empty scratchpad remains empty', () {
      final mcdu = FplCreateDisplayAdapter.toMCDUState(
        standardState,
        scratchpad: '',
      );
      expect(mcdu.scratchpad, '');
    });

    // 17. Verify required labels and positions from PDF Figure 6-6
    test('17. verify required labels and positions from PDF Figure 6-6', () {
      final mcdu = FplCreateDisplayAdapter.toMCDUState(standardState, scratchpad: '');
      // 1L: Origin
      expect(mcdu.leftLabels[0], 'KPHX');
      // 1R: GS
      expect(mcdu.rightLabels[0], '120');
      // 2R: DEST
      expect(mcdu.rightLabels[1], 'KMSP');
      // 6L: ◄PATTERN
      expect(mcdu.leftLabels[5], '◄PATTERN');
      // 6R: FPL SEL►
      expect(mcdu.rightLabels[5], 'FPL SEL►');
      // Center lines: headers
      expect(mcdu.lines, contains('ORIGIN          GS'));
      expect(mcdu.lines, contains('VIA.TO        DEST'));
    });

    // 18. No unsupported/invented labels on inactive positions
    test('18. no unsupported or invented labels on 3R, 4R, 5R', () {
      final mcdu = FplCreateDisplayAdapter.toMCDUState(standardState, scratchpad: '');
      expect(mcdu.rightLabels[2], '');
      expect(mcdu.rightLabels[3], '');
      expect(mcdu.rightLabels[4], '');
    });

    // 19. Immutability: input state is completely unchanged
    test('19. input state is completely unchanged by adapter call', () {
      final originalName = standardState.name;
      final originalOrigin = standardState.originIdent;
      final originalDest = standardState.destinationIdent;
      final originalGs = standardState.groundspeed;
      final originalLegsCount = standardState.legs.length;

      FplCreateDisplayAdapter.toMCDUState(standardState, scratchpad: 'INPUT');

      expect(standardState.name, originalName);
      expect(standardState.originIdent, originalOrigin);
      expect(standardState.destinationIdent, originalDest);
      expect(standardState.groundspeed, originalGs);
      expect(standardState.legs.length, originalLegsCount);
    });

    // 20. Deterministic rendering
    test('20. repeated rendering with identical state yields identical MCDUState', () {
      final run1 = FplCreateDisplayAdapter.toMCDUState(standardState, scratchpad: 'TEST');
      final run2 = FplCreateDisplayAdapter.toMCDUState(standardState, scratchpad: 'TEST');

      expect(run1.title, run2.title);
      expect(run1.leftLabels, run2.leftLabels);
      expect(run1.rightLabels, run2.rightLabels);
      expect(run1.lines, run2.lines);
      expect(run1.scratchpad, run2.scratchpad);
      expect(run1.currentPage.pageId, 'FPL_CREATE');
    });

    // 21. MCDU 14x24 dimensional conventions
    test('21. adheres to 6 leftLabels, 6 rightLabels, and title length constraints', () {
      final mcdu = FplCreateDisplayAdapter.toMCDUState(standardState, scratchpad: '');
      expect(mcdu.leftLabels.length, 6);
      expect(mcdu.rightLabels.length, 6);
      expect(mcdu.title.length, lessThanOrEqualTo(24));
      for (final line in mcdu.lines) {
        expect(line.length, lessThanOrEqualTo(24));
      }
    });
  });
}
