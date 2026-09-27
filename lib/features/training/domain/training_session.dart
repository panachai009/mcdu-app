// lib/features/training/domain/training_session.dart
// Immutable model representing a training session and its execution state.
import 'training_step.dart';

class TrainingSession {
  final String sessionId;
  final List<TrainingStep> steps;
  final int currentStepIndex;
  final bool completed;
  final int correctCount;
  final int errorCount;

  const TrainingSession({
    required this.sessionId,
    required this.steps,
    this.currentStepIndex = 0,
    this.completed = false,
    this.correctCount = 0,
    this.errorCount = 0,
  });

  /// The current step waiting to be executed, or null if session is completed / empty.
  TrainingStep? get currentStep {
    if (currentStepIndex >= 0 && currentStepIndex < steps.length) {
      return steps[currentStepIndex];
    }
    return null;
  }

  /// Number of steps remaining to complete.
  int get remainingStepsCount {
    if (completed || currentStepIndex >= steps.length) return 0;
    return steps.length - currentStepIndex;
  }

  /// Total steps count.
  int get totalStepsCount => steps.length;

  /// Returns a reset copy of this session back to Step 1 (index 0).
  TrainingSession reset() {
    return TrainingSession(
      sessionId: sessionId,
      steps: steps,
      currentStepIndex: 0,
      completed: steps.isEmpty,
      correctCount: 0,
      errorCount: 0,
    );
  }

  TrainingSession copyWith({
    String? sessionId,
    List<TrainingStep>? steps,
    int? currentStepIndex,
    bool? completed,
    int? correctCount,
    int? errorCount,
  }) {
    return TrainingSession(
      sessionId: sessionId ?? this.sessionId,
      steps: steps ?? this.steps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      completed: completed ?? this.completed,
      correctCount: correctCount ?? this.correctCount,
      errorCount: errorCount ?? this.errorCount,
    );
  }
}
