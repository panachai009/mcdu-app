// lib/features/training/domain/training_scenario.dart
// Immutable domain model for a training scenario.
import 'training_step.dart';

class TrainingScenario {
  final String scenarioId;
  final String title;
  final String description;
  final List<TrainingStep> _steps;

  TrainingScenario({
    required this.scenarioId,
    required this.title,
    this.description = '',
    required List<TrainingStep> steps,
  }) : _steps = List.unmodifiable(steps);

  /// Unmodifiable view of steps to prevent external mutation.
  List<TrainingStep> get steps => _steps;
}
