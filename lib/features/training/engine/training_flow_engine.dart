// lib/features/training/engine/training_flow_engine.dart
// Training Flow Engine for evaluating user keypress sequences against a TrainingScenario.
import 'dart:async';
import '../../mcdu_core/presentation/mcdu_keypad_overlay.dart';
import '../domain/training_scenario.dart';
import '../domain/training_scenarios.dart';
import '../domain/training_session.dart';

/// Result report for a processed training step key event.
class TrainingStepResult {
  final bool correct;
  final bool incorrect;
  final bool completed;
  final String? expectedKeyId;
  final String actualKeyId;
  final int currentStepIndex;

  const TrainingStepResult({
    required this.correct,
    required this.incorrect,
    required this.completed,
    required this.expectedKeyId,
    required this.actualKeyId,
    required this.currentStepIndex,
  });
}

/// Pure domain/application engine for evaluating training flows.
class TrainingFlowEngine {
  final TrainingScenario scenario;
  TrainingSession _session;

  final _sessionController = StreamController<TrainingSession>.broadcast();
  final _resultController = StreamController<TrainingStepResult>.broadcast();

  TrainingFlowEngine({
    TrainingScenario? scenario,
    TrainingSession? session,
  })  : scenario = scenario ??
            TrainingScenario(
              scenarioId: session?.sessionId ?? 'custom_scenario',
              title: 'Custom Flow',
              steps: session?.steps ?? const [],
            ),
        _session = session ??
            TrainingSession(
              sessionId: scenario?.scenarioId ?? 'basic_mcdu_flow',
              steps: scenario?.steps ?? const [],
              completed: (scenario?.steps.isEmpty ?? true),
            ) {
    if (_session.steps.isEmpty && !_session.completed) {
      _session = _session.copyWith(completed: true);
    }
  }

  /// Factory creating an engine from a specific TrainingScenario.
  factory TrainingFlowEngine.fromScenario(TrainingScenario scenario) {
    return TrainingFlowEngine(
      scenario: scenario,
      session: TrainingSession(
        sessionId: scenario.scenarioId,
        steps: scenario.steps,
        completed: scenario.steps.isEmpty,
      ),
    );
  }

  /// Stream of session state updates.
  Stream<TrainingSession> get sessionStream => _sessionController.stream;

  /// Stream of step evaluation results.
  Stream<TrainingStepResult> get resultStream => _resultController.stream;

  /// Current training session snapshot.
  TrainingSession get session => _session;

  /// Whether the session is finished.
  bool get isCompleted => _session.completed;

  /// Process an incoming MCDU key event against the current step.
  TrainingStepResult processKeyEvent(MCDUKeyEvent event) {
    final actualKeyId = event.keyId;

    // If session is already completed or empty, ignore input.
    if (_session.completed || _session.steps.isEmpty) {
      final result = TrainingStepResult(
        correct: false,
        incorrect: false,
        completed: _session.completed,
        expectedKeyId: null,
        actualKeyId: actualKeyId,
        currentStepIndex: _session.currentStepIndex,
      );
      _resultController.add(result);
      return result;
    }

    final currentStep = _session.currentStep!;
    final expectedKeyId = currentStep.expectedKeyId;

    if (actualKeyId == expectedKeyId) {
      // Correct input
      final nextIndex = _session.currentStepIndex + 1;
      final isFinished = nextIndex >= _session.steps.length;

      _session = _session.copyWith(
        currentStepIndex: isFinished ? _session.currentStepIndex : nextIndex,
        completed: isFinished,
        correctCount: _session.correctCount + 1,
      );

      final result = TrainingStepResult(
        correct: true,
        incorrect: false,
        completed: isFinished,
        expectedKeyId: expectedKeyId,
        actualKeyId: actualKeyId,
        currentStepIndex: _session.currentStepIndex,
      );

      _sessionController.add(_session);
      _resultController.add(result);
      return result;
    } else {
      // Incorrect input
      _session = _session.copyWith(
        errorCount: _session.errorCount + 1,
      );

      final result = TrainingStepResult(
        correct: false,
        incorrect: true,
        completed: false,
        expectedKeyId: expectedKeyId,
        actualKeyId: actualKeyId,
        currentStepIndex: _session.currentStepIndex,
      );

      _sessionController.add(_session);
      _resultController.add(result);
      return result;
    }
  }

  /// Resets the engine back to Step 1 with counts cleared.
  void reset() {
    _session = _session.reset();
    _sessionController.add(_session);
  }

  /// Dispose stream controllers.
  void dispose() {
    _sessionController.close();
    _resultController.close();
  }

  /// Backward-compatible factory for tests.
  static TrainingSession createBasicMCDUFlowSession() {
    return TrainingScenarios.basicMCDUFlow.steps.isNotEmpty
        ? TrainingSession(
            sessionId: TrainingScenarios.basicMCDUFlow.scenarioId,
            steps: TrainingScenarios.basicMCDUFlow.steps,
          )
        : const TrainingSession(sessionId: 'basic_mcdu_flow', steps: []);
  }
}
