// lib/features/training/domain/training_scenarios.dart
// Catalog of supported training scenarios.
import 'training_scenario.dart';
import 'training_step.dart';

class TrainingScenarios {
  /// Scenario 1: Basic MCDU Flow
  static final TrainingScenario basicMCDUFlow = TrainingScenario(
    scenarioId: 'basic_mcdu_flow',
    title: 'Basic MCDU Flow',
    description: 'Practice basic MCDU key flow',
    steps: const [
      TrainingStep(stepId: 'step_1', expectedKeyId: 'MENU', description: 'Press MENU key'),
      TrainingStep(stepId: 'step_2', expectedKeyId: 'FPL', description: 'Press FPL key or LSK 1L'),
      TrainingStep(stepId: 'step_3', expectedKeyId: 'V', description: 'Type V'),
      TrainingStep(stepId: 'step_4', expectedKeyId: 'T', description: 'Type T'),
      TrainingStep(stepId: 'step_5', expectedKeyId: 'B', description: 'Type B'),
      TrainingStep(stepId: 'step_6', expectedKeyId: 'D', description: 'Type D'),
      TrainingStep(stepId: 'step_7', expectedKeyId: '1L', description: 'Transfer to 1L'),
      TrainingStep(stepId: 'step_8', expectedKeyId: 'CLR', description: 'Press CLR'),
    ],
  );

  /// Scenario 2: Scratchpad Input
  static final TrainingScenario scratchpadInput = TrainingScenario(
    scenarioId: 'scratchpad_input',
    title: 'Scratchpad Input',
    description: 'Practice entering and editing scratchpad text',
    steps: const [
      TrainingStep(stepId: 'sp_1', expectedKeyId: 'A', expectedText: 'A', description: 'Type A'),
      TrainingStep(stepId: 'sp_2', expectedKeyId: 'B', expectedText: 'AB', description: 'Type B'),
      TrainingStep(stepId: 'sp_3', expectedKeyId: 'C', expectedText: 'ABC', description: 'Type C'),
      TrainingStep(stepId: 'sp_4', expectedKeyId: '1', expectedText: 'ABC1', description: 'Type 1'),
      TrainingStep(stepId: 'sp_5', expectedKeyId: '2', expectedText: 'ABC12', description: 'Type 2'),
      TrainingStep(stepId: 'sp_6', expectedKeyId: '3', expectedText: 'ABC123', description: 'Type 3'),
      TrainingStep(stepId: 'sp_7', expectedKeyId: 'CLR', expectedText: 'ABC12', description: 'Press CLR to delete last character'),
    ],
  );

  /// Scenario 3: LSK Data Entry
  static final TrainingScenario lskDataEntry = TrainingScenario(
    scenarioId: 'lsk_data_entry',
    title: 'LSK Data Entry',
    description: 'Practice entering data and transferring it to an LSK',
    steps: const [
      TrainingStep(stepId: 'lsk_1', expectedKeyId: 'M', expectedText: 'M', description: 'Type M'),
      TrainingStep(stepId: 'lsk_2', expectedKeyId: 'O', expectedText: 'MO', description: 'Type O'),
      TrainingStep(stepId: 'lsk_3', expectedKeyId: 'D', expectedText: 'MOD', description: 'Type D'),
      TrainingStep(stepId: 'lsk_4', expectedKeyId: '1', expectedText: 'MOD1', description: 'Type 1'),
      TrainingStep(stepId: 'lsk_5', expectedKeyId: 'L', expectedText: 'MOD1L', description: 'Type L'),
      TrainingStep(stepId: 'lsk_6', expectedKeyId: '1L', expectedText: 'MOD1L', description: 'Transfer to LSK 1L'),
    ],
  );

  /// Scenario 4: Page Navigation
  static final TrainingScenario pageNavigation = TrainingScenario(
    scenarioId: 'page_navigation',
    title: 'Page Navigation',
    description: 'Practice navigating MCDU pages',
    steps: const [
      TrainingStep(stepId: 'nav_1', expectedKeyId: 'MENU', description: 'Press MENU key'),
      TrainingStep(stepId: 'nav_2', expectedKeyId: 'FPL', description: 'Press FPL key'),
      TrainingStep(stepId: 'nav_3', expectedKeyId: 'PREV', description: 'Press PREV key'),
      TrainingStep(stepId: 'nav_4', expectedKeyId: 'NEXT', description: 'Press NEXT key'),
      TrainingStep(stepId: 'nav_5', expectedKeyId: 'DIR', description: 'Press DIR key'),
      TrainingStep(stepId: 'nav_6', expectedKeyId: 'PROG', description: 'Press PROG key'),
      TrainingStep(stepId: 'nav_7', expectedKeyId: 'NAV', description: 'Press NAV key'),
      TrainingStep(stepId: 'nav_8', expectedKeyId: 'RADIO', description: 'Press RADIO key'),
      TrainingStep(stepId: 'nav_9', expectedKeyId: 'DATA', description: 'Press LSK 3R for DATA page'),
    ],
  );

  /// All registered scenarios in the catalog.
  static final List<TrainingScenario> all = [
    basicMCDUFlow,
    scratchpadInput,
    lskDataEntry,
    pageNavigation,
  ];

  /// Find scenario by ID, returns null if not found.
  static TrainingScenario? findById(String id) {
    try {
      return all.firstWhere((scenario) => scenario.scenarioId == id);
    } catch (_) {
      return null;
    }
  }
}
