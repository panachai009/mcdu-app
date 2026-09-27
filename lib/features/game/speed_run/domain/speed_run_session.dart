// lib/features/game/speed_run/domain/speed_run_session.dart
// Immutable runtime session state for Speed Run.

import 'speed_run_step.dart';
import 'speed_run_task.dart';

enum SpeedRunStatus {
  ready,
  playing,
  taskComplete,
  paused,
  completed,
}

class SpeedRunSession {
  final SpeedRunStatus status;
  final List<SpeedRunTask> tasks;
  final int currentTaskIndex;
  final int currentStepIndex;
  final String scratchpadBuffer;
  final Duration elapsedTime;
  final Duration penaltyTime;
  final int score;
  final int errors;
  final int combo;
  final int completedTasks;
  final int difficultyLevel;
  final SpeedRunStatus? previousStatus;

  SpeedRunSession({
    this.status = SpeedRunStatus.ready,
    List<SpeedRunTask>? tasks,
    this.currentTaskIndex = 0,
    this.currentStepIndex = 0,
    this.scratchpadBuffer = '',
    this.elapsedTime = Duration.zero,
    this.penaltyTime = Duration.zero,
    this.score = 0,
    this.errors = 0,
    this.combo = 0,
    this.completedTasks = 0,
    this.difficultyLevel = 1,
    this.previousStatus,
  }) : tasks = List.unmodifiable(tasks ?? const []);

  bool get isReady => status == SpeedRunStatus.ready;
  bool get isPlaying => status == SpeedRunStatus.playing;
  bool get isTaskComplete => status == SpeedRunStatus.taskComplete;
  bool get isPaused => status == SpeedRunStatus.paused;
  bool get isCompleted => status == SpeedRunStatus.completed;

  /// Current active task, or null if no tasks or index out of bounds
  SpeedRunTask? get currentTask {
    if (tasks.isEmpty || currentTaskIndex >= tasks.length) return null;
    return tasks[currentTaskIndex];
  }

  /// Current active step within current task
  SpeedRunStep? get currentStep {
    final task = currentTask;
    if (task == null || currentStepIndex >= task.steps.length) return null;
    return task.steps[currentStepIndex];
  }

  /// Total effective time including penalties
  Duration get totalEffectiveTime => elapsedTime + penaltyTime;

  SpeedRunSession copyWith({
    SpeedRunStatus? status,
    List<SpeedRunTask>? tasks,
    int? currentTaskIndex,
    int? currentStepIndex,
    String? scratchpadBuffer,
    Duration? elapsedTime,
    Duration? penaltyTime,
    int? score,
    int? errors,
    int? combo,
    int? completedTasks,
    int? difficultyLevel,
    SpeedRunStatus? previousStatus,
  }) {
    return SpeedRunSession(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      currentTaskIndex: currentTaskIndex ?? this.currentTaskIndex,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      scratchpadBuffer: scratchpadBuffer ?? this.scratchpadBuffer,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      penaltyTime: penaltyTime ?? this.penaltyTime,
      score: score ?? this.score,
      errors: errors ?? this.errors,
      combo: combo ?? this.combo,
      completedTasks: completedTasks ?? this.completedTasks,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      previousStatus: previousStatus ?? this.previousStatus,
    );
  }
}
