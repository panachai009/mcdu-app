// lib/features/game/typing_test/domain/typing_test_prompt.dart
// Immutable value object representing a typing test prompt.

class TypingTestPrompt {
  final String promptId;
  final String targetText;

  const TypingTestPrompt({
    required this.promptId,
    required this.targetText,
  }) : assert(promptId.length > 0, 'promptId cannot be empty'),
       assert(targetText.length > 0, 'targetText cannot be empty');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypingTestPrompt &&
          runtimeType == other.runtimeType &&
          promptId == other.promptId &&
          targetText == other.targetText;

  @override
  int get hashCode => Object.hash(promptId, targetText);

  @override
  String toString() => 'TypingTestPrompt(promptId: $promptId, targetText: $targetText)';
}
