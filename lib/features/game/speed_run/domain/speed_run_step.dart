// lib/features/game/speed_run/domain/speed_run_step.dart
// Immutable model representing a single step within a Speed Run task.

class SpeedRunStep {
  final String stepId;
  final String prompt;
  final String expectedKeyId;
  final bool isScratchpadChar;
  final String targetFieldLabel;

  const SpeedRunStep({
    required this.stepId,
    required this.prompt,
    required this.expectedKeyId,
    this.isScratchpadChar = false,
    this.targetFieldLabel = '',
  });

  SpeedRunStep copyWith({
    String? stepId,
    String? prompt,
    String? expectedKeyId,
    bool? isScratchpadChar,
    String? targetFieldLabel,
  }) {
    return SpeedRunStep(
      stepId: stepId ?? this.stepId,
      prompt: prompt ?? this.prompt,
      expectedKeyId: expectedKeyId ?? this.expectedKeyId,
      isScratchpadChar: isScratchpadChar ?? this.isScratchpadChar,
      targetFieldLabel: targetFieldLabel ?? this.targetFieldLabel,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpeedRunStep &&
          runtimeType == other.runtimeType &&
          stepId == other.stepId &&
          prompt == other.prompt &&
          expectedKeyId == other.expectedKeyId &&
          isScratchpadChar == other.isScratchpadChar &&
          targetFieldLabel == other.targetFieldLabel;

  @override
  int get hashCode =>
      stepId.hashCode ^
      prompt.hashCode ^
      expectedKeyId.hashCode ^
      isScratchpadChar.hashCode ^
      targetFieldLabel.hashCode;

  @override
  String toString() =>
      'SpeedRunStep(stepId: , expectedKeyId: , isScratchpadChar: )';
}
