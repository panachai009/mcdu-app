// lib/features/training/domain/training_step.dart
// Immutable model representing a single step in a training flow.

class TrainingStep {
  final String stepId;
  final String expectedKeyId;
  final String? expectedText;
  final String description;

  const TrainingStep({
    required this.stepId,
    required this.expectedKeyId,
    this.expectedText,
    this.description = '',
  });

  TrainingStep copyWith({
    String? stepId,
    String? expectedKeyId,
    String? expectedText,
    String? description,
  }) {
    return TrainingStep(
      stepId: stepId ?? this.stepId,
      expectedKeyId: expectedKeyId ?? this.expectedKeyId,
      expectedText: expectedText ?? this.expectedText,
      description: description ?? this.description,
    );
  }
}
