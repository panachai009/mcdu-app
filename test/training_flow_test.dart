import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';
import 'package:mcdu_app/features/training/domain/training_scenario.dart';
import 'package:mcdu_app/features/training/domain/training_scenarios.dart';
import 'package:mcdu_app/features/training/domain/training_step.dart';
import 'package:mcdu_app/features/training/engine/training_flow_engine.dart';

void main() {
  group('TrainingScenario Domain & Catalog Tests', () {
    test('1. TrainingScenario initializes correctly and protects steps', () {
      final mutableList = [
        const TrainingStep(stepId: 's1', expectedKeyId: 'MENU'),
      ];
      final scenario = TrainingScenario(
        scenarioId: 'test_scenario',
        title: 'Test Flow',
        description: 'Testing scenario',
        steps: mutableList,
      );

      expect(scenario.scenarioId, 'test_scenario');
      expect(scenario.title, 'Test Flow');
      expect(scenario.description, 'Testing scenario');
      expect(scenario.steps.length, 1);

      mutableList.add(const TrainingStep(stepId: 's2', expectedKeyId: 'FPL'));
      expect(scenario.steps.length, 1);
      expect(() => scenario.steps.add(const TrainingStep(stepId: 's3', expectedKeyId: 'DIR')),
          throwsUnsupportedError);
    });

    // 1. Catalog มี 4 scenarios
    test('Catalog contains exactly 4 scenarios', () {
      expect(TrainingScenarios.all.length, 4);
    });

    // 2. Basic MCDU Flow ยังมี 8 steps
    test('Scenario 1: Basic MCDU Flow has 8 steps with exact sequence', () {
      final basic = TrainingScenarios.findById('basic_mcdu_flow');
      expect(basic, isNotNull);
      expect(basic!.title, 'Basic MCDU Flow');
      expect(basic.steps.length, 8);

      final expectedSequence = ['MENU', 'FPL', 'V', 'T', 'B', 'D', '1L', 'CLR'];
      for (int i = 0; i < expectedSequence.length; i++) {
        expect(basic.steps[i].expectedKeyId, expectedSequence[i]);
      }
    });

    // 3. Scratchpad Input มี 7 steps
    test('Scenario 2: Scratchpad Input has 7 steps with exact sequence and metadata', () {
      final sp = TrainingScenarios.findById('scratchpad_input');
      expect(sp, isNotNull);
      expect(sp!.title, 'Scratchpad Input');
      expect(sp.steps.length, 7);

      final expectedSequence = ['A', 'B', 'C', '1', '2', '3', 'CLR'];
      final expectedTextMeta = ['A', 'AB', 'ABC', 'ABC1', 'ABC12', 'ABC123', 'ABC12'];
      for (int i = 0; i < expectedSequence.length; i++) {
        expect(sp.steps[i].expectedKeyId, expectedSequence[i]);
        expect(sp.steps[i].expectedText, expectedTextMeta[i]);
      }
    });

    // 4. LSK Data Entry มี 6 steps
    test('Scenario 3: LSK Data Entry has 6 steps with exact sequence and metadata', () {
      final lsk = TrainingScenarios.findById('lsk_data_entry');
      expect(lsk, isNotNull);
      expect(lsk!.title, 'LSK Data Entry');
      expect(lsk.steps.length, 6);

      final expectedSequence = ['M', 'O', 'D', '1', 'L', '1L'];
      final expectedTextMeta = ['M', 'MO', 'MOD', 'MOD1', 'MOD1L', 'MOD1L'];
      for (int i = 0; i < expectedSequence.length; i++) {
        expect(lsk.steps[i].expectedKeyId, expectedSequence[i]);
        expect(lsk.steps[i].expectedText, expectedTextMeta[i]);
      }
    });

    // 5. Page Navigation มี 9 steps
    test('Scenario 4: Page Navigation has 9 steps with exact sequence', () {
      final nav = TrainingScenarios.findById('page_navigation');
      expect(nav, isNotNull);
      expect(nav!.title, 'Page Navigation');
      expect(nav.steps.length, 9);

      final expectedSequence = ['MENU', 'FPL', 'PREV', 'NEXT', 'DIR', 'PROG', 'NAV', 'RADIO', 'DATA'];
      for (int i = 0; i < expectedSequence.length; i++) {
        expect(nav.steps[i].expectedKeyId, expectedSequence[i]);
      }
    });

    // 6. findById() หา Scenario ทั้ง 4 ได้
    test('findById() finds all 4 scenarios and returns null for unknown id', () {
      expect(TrainingScenarios.findById('basic_mcdu_flow'), isNotNull);
      expect(TrainingScenarios.findById('scratchpad_input'), isNotNull);
      expect(TrainingScenarios.findById('lsk_data_entry'), isNotNull);
      expect(TrainingScenarios.findById('page_navigation'), isNotNull);
      expect(TrainingScenarios.findById('unknown_scenario'), isNull);
    });
  });

  group('TrainingFlowEngine Universal Scenario Execution Tests', () {
    // Engine execution test helper
    void testScenarioExecution(TrainingScenario scenario) {
      final engine = TrainingFlowEngine.fromScenario(scenario);

      // Begins at step 1
      expect(engine.session.currentStepIndex, 0);
      expect(engine.session.currentStep, isNotNull);
      expect(engine.session.completed, isFalse);
      expect(engine.session.correctCount, 0);
      expect(engine.session.errorCount, 0);

      // Wrong key does not advance and increments error
      final wrongRes = engine.processKeyEvent(MCDUKeyEvent(keyId: 'UNEXPECTED_KEY_XYZ'));
      expect(wrongRes.correct, isFalse);
      expect(wrongRes.incorrect, isTrue);
      expect(engine.session.errorCount, 1);
      expect(engine.session.currentStepIndex, 0);

      // Execute sequence
      for (int i = 0; i < scenario.steps.length; i++) {
        final expectedKey = scenario.steps[i].expectedKeyId;
        final res = engine.processKeyEvent(MCDUKeyEvent(keyId: expectedKey));
        expect(res.correct, isTrue);
        expect(res.incorrect, isFalse);

        if (i == scenario.steps.length - 1) {
          expect(res.completed, isTrue);
        } else {
          expect(res.completed, isFalse);
        }
      }

      // Verified completed
      expect(engine.session.completed, isTrue);
      expect(engine.session.correctCount, scenario.steps.length);
      expect(engine.session.remainingStepsCount, 0);

      // Subsequent input ignored
      final postRes = engine.processKeyEvent(MCDUKeyEvent(keyId: 'MENU'));
      expect(postRes.correct, isFalse);
      expect(postRes.completed, isTrue);

      // Reset
      engine.reset();
      expect(engine.session.currentStepIndex, 0);
      expect(engine.session.completed, isFalse);
      expect(engine.session.correctCount, 0);
      expect(engine.session.errorCount, 0);

      engine.dispose();
    }

    test('Engine runs Basic MCDU Flow to completion', () {
      testScenarioExecution(TrainingScenarios.basicMCDUFlow);
    });

    test('Engine runs Scratchpad Input scenario to completion', () {
      testScenarioExecution(TrainingScenarios.scratchpadInput);
    });

    test('Engine runs LSK Data Entry scenario to completion', () {
      testScenarioExecution(TrainingScenarios.lskDataEntry);
    });

    test('Engine runs Page Navigation scenario to completion', () {
      testScenarioExecution(TrainingScenarios.pageNavigation);
    });

    test('Empty scenario initializes as completed without error', () {
      final emptyScenario = TrainingScenario(
        scenarioId: 'empty',
        title: 'Empty Scenario',
        steps: const [],
      );
      final emptyEngine = TrainingFlowEngine.fromScenario(emptyScenario);

      expect(emptyEngine.session.completed, isTrue);
      expect(emptyEngine.session.currentStep, isNull);
      expect(emptyEngine.session.remainingStepsCount, 0);

      final result = emptyEngine.processKeyEvent(MCDUKeyEvent(keyId: 'MENU'));
      expect(result.completed, isTrue);
      expect(result.correct, isFalse);

      emptyEngine.dispose();
    });
  });
}
