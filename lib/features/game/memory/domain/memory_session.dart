// lib/features/game/memory/domain/memory_session.dart

enum MemoryStatus {
  ready,
  memorizing,
  recalling,
  paused,
  gameOver,
  completed,
}

class MemorySession {
  final MemoryStatus status;
  final int level;
  final String targetSequence;
  final String inputBuffer;
  final int lives;
  final int score;
  final int combo;
  final int completedRounds;
  final Duration elapsedTime;
  final MemoryStatus? previousStatus;

  const MemorySession({
    this.status = MemoryStatus.ready,
    this.level = 1,
    this.targetSequence = '',
    this.inputBuffer = '',
    this.lives = 3,
    this.score = 0,
    this.combo = 0,
    this.completedRounds = 0,
    this.elapsedTime = Duration.zero,
    this.previousStatus,
  });

  bool get isReady => status == MemoryStatus.ready;
  bool get isMemorizing => status == MemoryStatus.memorizing;
  bool get isRecalling => status == MemoryStatus.recalling;
  bool get isPaused => status == MemoryStatus.paused;
  bool get isGameOver => status == MemoryStatus.gameOver;
  bool get isCompleted => status == MemoryStatus.completed;

  MemorySession copyWith({
    MemoryStatus? status,
    int? level,
    String? targetSequence,
    String? inputBuffer,
    int? lives,
    int? score,
    int? combo,
    int? completedRounds,
    Duration? elapsedTime,
    MemoryStatus? previousStatus,
  }) {
    return MemorySession(
      status: status ?? this.status,
      level: level ?? this.level,
      targetSequence: targetSequence ?? this.targetSequence,
      inputBuffer: inputBuffer ?? this.inputBuffer,
      lives: lives ?? this.lives,
      score: score ?? this.score,
      combo: combo ?? this.combo,
      completedRounds: completedRounds ?? this.completedRounds,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      previousStatus: previousStatus ?? this.previousStatus,
    );
  }

  MemorySession reset() {
    return const MemorySession();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemorySession &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          level == other.level &&
          targetSequence == other.targetSequence &&
          inputBuffer == other.inputBuffer &&
          lives == other.lives &&
          score == other.score &&
          combo == other.combo &&
          completedRounds == other.completedRounds &&
          elapsedTime == other.elapsedTime &&
          previousStatus == other.previousStatus;

  @override
  int get hashCode => Object.hash(
        status,
        level,
        targetSequence,
        inputBuffer,
        lives,
        score,
        combo,
        completedRounds,
        elapsedTime,
        previousStatus,
      );

  @override
  String toString() =>
      'MemorySession(status: $status, level: $level, target: $targetSequence, input: $inputBuffer, lives: $lives, score: $score, combo: $combo, rounds: $completedRounds, elapsed: $elapsedTime)';
}
