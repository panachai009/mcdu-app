import 'package:flutter/material.dart';
import '../../mcdu_core/domain/mcdu_state.dart';
import '../../mcdu_core/engine/mcdu_input_engine.dart';
import '../../mcdu_core/presentation/mcdu_keypad_overlay.dart';
import '../../mcdu_core/presentation/mcdu_screen.dart';
import '../domain/training_scenario.dart';
import '../domain/training_scenarios.dart';
import '../engine/training_flow_engine.dart';
import 'training_status_panel.dart';

class TrainingScreen extends StatefulWidget {
  final TrainingScenario? initialScenario;
  final TrainingFlowEngine? trainingEngine;
  final MCDUInputEngine? inputEngine;

  const TrainingScreen({
    super.key,
    this.initialScenario,
    this.trainingEngine,
    this.inputEngine,
  });

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  late TrainingFlowEngine _trainingEngine;
  late final MCDUInputEngine _inputEngine;
  late TrainingScenario _currentScenario;
  bool _ownsTrainingEngine = false;
  bool _ownsInputEngine = false;

  TrainingStepResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _currentScenario = widget.initialScenario ?? TrainingScenarios.basicMCDUFlow;

    if (widget.trainingEngine != null) {
      _trainingEngine = widget.trainingEngine!;
      _ownsTrainingEngine = false;
    } else {
      _trainingEngine = TrainingFlowEngine.fromScenario(_currentScenario);
      _ownsTrainingEngine = true;
    }

    if (widget.inputEngine != null) {
      _inputEngine = widget.inputEngine!;
      _ownsInputEngine = false;
    } else {
      _inputEngine = MCDUInputEngine(initialState: MCDUState.initial());
      _ownsInputEngine = true;
    }

    _subscribeTrainingEngine();
  }

  void _subscribeTrainingEngine() {
    _trainingEngine.sessionStream.listen((_) {
      if (mounted) setState(() {});
    });

    _trainingEngine.resultStream.listen((result) {
      if (mounted) {
        setState(() {
          _lastResult = result;
        });
      }
    });
  }

  /// Scenario Switching with strict reset order:
  /// 1. Update current scenario
  /// 2. Create/reset new TrainingFlowEngine for that scenario
  /// 3. Reset MCDU state (MCDU returns to MENU, scratchpad is cleared)
  /// 4. Training UI resets to Step 1 and feedback becomes READY
  void switchScenario(TrainingScenario newScenario) {
    if (_ownsTrainingEngine) {
      _trainingEngine.dispose();
    }
    setState(() {
      _currentScenario = newScenario;
      _trainingEngine = TrainingFlowEngine.fromScenario(newScenario);
      _ownsTrainingEngine = true;
      _lastResult = null;
      _inputEngine.reset();
    });
    _subscribeTrainingEngine();
  }

  @override
  void dispose() {
    if (_ownsTrainingEngine) {
      _trainingEngine.dispose();
    }
    if (_ownsInputEngine) {
      _inputEngine.dispose();
    }
    super.dispose();
  }

  /// Process key event coming from the real MCDU keypad
  void _handleKeyInput(MCDUKeyEvent event) {
    _trainingEngine.processKeyEvent(event);
  }

  /// Full reset: resets training engine and resets MCDU core to MENU with empty scratchpad
  void _handleReset() {
    _trainingEngine.reset();
    _inputEngine.reset();
    setState(() {
      _lastResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;

            if (isLandscape) {
              // Landscape layout: 50/50 proportion with scrollable panel
              return Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 707 / 961,
                        child: MCDUScreen(
                          inputEngine: _inputEngine,
                          onKeyInput: _handleKeyInput,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Center(
                        child: SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: TrainingStatusPanel(
                              session: _trainingEngine.session,
                              currentScenario: _currentScenario,
                              lastResult: _lastResult,
                              onScenarioSelected: switchScenario,
                              onReset: _handleReset,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // Portrait layout: Training Status Panel on top, MCDU Frame below
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: TrainingStatusPanel(
                        session: _trainingEngine.session,
                        currentScenario: _currentScenario,
                        lastResult: _lastResult,
                        onScenarioSelected: switchScenario,
                        onReset: _handleReset,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 707 / 961,
                        child: MCDUScreen(
                          inputEngine: _inputEngine,
                          onKeyInput: _handleKeyInput,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
