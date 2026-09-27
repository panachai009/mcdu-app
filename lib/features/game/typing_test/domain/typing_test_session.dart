// lib/features/game/typing_test/domain/typing_test_session.dart
// Immutable session model for Typing Test with Timer, Accuracy, and Score calculations.

import 'dart:math' as math;
import '../../domain/game_state.dart';
import 'typing_test_prompt.dart';

class TypingTestSession {
  final TypingTestPrompt prompt;
  final GameState state;
  final String typedText;
  final int correctCount;
  final int errorCount;
  final Duration elapsedTime;

  const TypingTestSession({
    required this.prompt,
    this.state = GameState.idle,
    this.typedText = '',
    this.correctCount = 0,
    this.errorCount = 0,
    this.elapsedTime = Duration.zero,
  });

  bool get isIdle => state == GameState.idle;
  bool get isPlaying => state == GameState.playing;
  bool get isCompleted => state == GameState.completed;
  bool get isComplete => isCompleted;

  /// Progress from 0.0 to 1.0 based on target text length.
  double get progress {
    final targetLen = prompt.targetText.length;
    if (targetLen == 0) return 1.0;
    return (typedText.length / targetLen).clamp(0.0, 1.0);
  }

  /// Substring of the prompt's targetText that still needs to be typed.
  String get remainingText {
    if (typedText.length >= prompt.targetText.length) {
      return '';
    }
    return prompt.targetText.substring(typedText.length);
  }

  /// Accuracy calculation formula:
  /// accuracy = correctCount / (correctCount + errorCount) * 100
  /// When correct + error = 0, accuracy = 0.0
  double get accuracy {
    final total = correctCount + errorCount;
    if (total == 0) return 0.0;
    return (correctCount / total) * 100.0;
  }

  /// Score calculation formula:
  /// score = max(0, correctCount * 100 - errorCount * 25 - elapsedSeconds * 5)
  int get score {
    final elapsedSeconds = elapsedTime.inSeconds;
    final raw = (correctCount * 100) - (errorCount * 25) - (elapsedSeconds * 5);
    return math.max(0, raw);
  }

  TypingTestSession copyWith({
    TypingTestPrompt? prompt,
    GameState? state,
    String? typedText,
    int? correctCount,
    int? errorCount,
    Duration? elapsedTime,
  }) {
    return TypingTestSession(
      prompt: prompt ?? this.prompt,
      state: state ?? this.state,
      typedText: typedText ?? this.typedText,
      correctCount: correctCount ?? this.correctCount,
      errorCount: errorCount ?? this.errorCount,
      elapsedTime: elapsedTime ?? this.elapsedTime,
    );
  }

  TypingTestSession reset() {
    return TypingTestSession(
      prompt: prompt,
      state: GameState.idle,
      typedText: '',
      correctCount: 0,
      errorCount: 0,
      elapsedTime: Duration.zero,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypingTestSession &&
          runtimeType == other.runtimeType &&
          prompt == other.prompt &&
          state == other.state &&
          typedText == other.typedText &&
          correctCount == other.correctCount &&
          errorCount == other.errorCount &&
          elapsedTime == other.elapsedTime;

  @override
  int get hashCode => Object.hash(
        prompt,
        state,
        typedText,
        correctCount,
        errorCount,
        elapsedTime,
      );

  @override
  String toString() =>
      'TypingTestSession(prompt: ${prompt.promptId}, state: $state, typed: "$typedText", correct: $correctCount, errors: $errorCount, elapsed: ${elapsedTime.inMilliseconds}ms, acc: $accuracy%, score: $score)';
}
