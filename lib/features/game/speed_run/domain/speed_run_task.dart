// lib/features/game/speed_run/domain/speed_run_task.dart
// Immutable model representing a complete Speed Run procedural task.

import 'speed_run_step.dart';

class SpeedRunTask {
  final String taskId;
  final String title;
  final String category;
  final Duration parTime;
  final List<SpeedRunStep> _steps;

  SpeedRunTask({
    required this.taskId,
    required this.title,
    required this.category,
    required this.parTime,
    required List<SpeedRunStep> steps,
  }) : _steps = List.unmodifiable(steps);

  /// Unmodifiable view of steps
  List<SpeedRunStep> get steps => _steps;

  int get totalSteps => _steps.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpeedRunTask &&
          runtimeType == other.runtimeType &&
          taskId == other.taskId;

  @override
  int get hashCode => taskId.hashCode;

  @override
  String toString() => 'SpeedRunTask(taskId: , title: , steps: )';
}
