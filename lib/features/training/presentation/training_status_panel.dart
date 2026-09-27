import 'package:flutter/material.dart';
import '../domain/training_scenario.dart';
import '../domain/training_scenarios.dart';
import '../domain/training_session.dart';
import '../engine/training_flow_engine.dart';

class TrainingStatusPanel extends StatelessWidget {
  final TrainingSession session;
  final TrainingScenario currentScenario;
  final TrainingStepResult? lastResult;
  final ValueChanged<TrainingScenario>? onScenarioSelected;
  final VoidCallback onReset;

  const TrainingStatusPanel({
    super.key,
    required this.session,
    required this.currentScenario,
    required this.lastResult,
    this.onScenarioSelected,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final currentStep = session.currentStep;
    final totalSteps = session.totalStepsCount;
    final currentStepDisplay = session.completed ? totalSteps : session.currentStepIndex + 1;

    // Determine feedback string and color
    String feedbackText = 'READY';
    Color feedbackColor = Colors.grey;

    if (session.completed) {
      feedbackText = 'TRAINING COMPLETE';
      feedbackColor = Colors.greenAccent;
    } else if (lastResult != null) {
      if (lastResult!.correct) {
        feedbackText = 'CORRECT';
        feedbackColor = Colors.greenAccent;
      } else if (lastResult!.incorrect) {
        feedbackText = 'INCORRECT\nExpected: ${lastResult!.expectedKeyId} | Pressed: ${lastResult!.actualKeyId}';
        feedbackColor = Colors.redAccent;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          const Text(
            'BASIC MCDU TRAINING',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),

          // Scenario Selector Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentScenario.scenarioId,
                isDense: true,
                isExpanded: true,
                dropdownColor: const Color(0xFF262626),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
                items: TrainingScenarios.all.map((scenario) {
                  return DropdownMenuItem<String>(
                    value: scenario.scenarioId,
                    child: Text(
                      scenario.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (selectedId) {
                  if (selectedId != null && selectedId != currentScenario.scenarioId) {
                    final selectedScenario = TrainingScenarios.findById(selectedId);
                    if (selectedScenario != null) {
                      onScenarioSelected?.call(selectedScenario);
                    }
                  }
                },
              ),
            ),
          ),
          const Divider(color: Colors.white24, height: 16),

          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step $currentStepDisplay / $totalSteps',
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                session.completed ? 'COMPLETED' : 'IN PROGRESS',
                style: TextStyle(
                  color: session.completed ? Colors.greenAccent : Colors.cyanAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Current Instruction
          const Text(
            'Instruction:',
            style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            session.completed
                ? 'All steps completed successfully!'
                : (currentStep?.description ?? 'N/A'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),

          // Expected Key
          if (!session.completed) ...[
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                const Text(
                  'Expected Key: ',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.cyanAccent, width: 1),
                  ),
                  child: Text(
                    currentStep?.expectedKeyId ?? '',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Feedback Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: feedbackColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: feedbackColor.withValues(alpha: 0.6)),
            ),
            child: Text(
              feedbackText,
              style: TextStyle(
                color: feedbackColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),

          // Score / Counts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('Correct', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  Text(
                    '${session.correctCount}',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text('Errors', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  Text(
                    '${session.errorCount}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Reset Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('RESET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
