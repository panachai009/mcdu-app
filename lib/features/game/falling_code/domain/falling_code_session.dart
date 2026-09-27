import 'falling_code.dart';

enum FallingCodeStatus {
  ready,
  playing,
  paused,
  gameOver,
  completed,
}

class FallingCodeSession {
  final FallingCodeStatus status;
  final List<FallingCode> activeCodes;
  final int score;
  final int combo;
  final int maxCombo;
  final int correctCount;
  final int errorCount;
  final int missedCount;
  final int lives;
  final Duration elapsedTime;
  final int level;
  final int completedTargets;

  const FallingCodeSession({
    this.status = FallingCodeStatus.ready,
    this.activeCodes = const [],
    this.score = 0,
    this.combo = 0,
    this.maxCombo = 0,
    this.correctCount = 0,
    this.errorCount = 0,
    this.missedCount = 0,
    this.lives = 3,
    this.elapsedTime = Duration.zero,
    this.level = 1,
    this.completedTargets = 0,
  });

  bool get isReady => status == FallingCodeStatus.ready;
  bool get isPlaying => status == FallingCodeStatus.playing;
  bool get isPaused => status == FallingCodeStatus.paused;
  bool get isGameOver => status == FallingCodeStatus.gameOver;
  bool get isCompleted => status == FallingCodeStatus.completed;

  FallingCodeSession copyWith({
    FallingCodeStatus? status,
    List<FallingCode>? activeCodes,
    int? score,
    int? combo,
    int? maxCombo,
    int? correctCount,
    int? errorCount,
    int? missedCount,
    int? lives,
    Duration? elapsedTime,
    int? level,
    int? completedTargets,
  }) {
    return FallingCodeSession(
      status: status ?? this.status,
      activeCodes: activeCodes ?? this.activeCodes,
      score: score ?? this.score,
      combo: combo ?? this.combo,
      maxCombo: maxCombo ?? this.maxCombo,
      correctCount: correctCount ?? this.correctCount,
      errorCount: errorCount ?? this.errorCount,
      missedCount: missedCount ?? this.missedCount,
      lives: lives ?? this.lives,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      level: level ?? this.level,
      completedTargets: completedTargets ?? this.completedTargets,
    );
  }

  FallingCodeSession reset() {
    return const FallingCodeSession();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FallingCodeSession &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          score == other.score &&
          combo == other.combo &&
          maxCombo == other.maxCombo &&
          correctCount == other.correctCount &&
          errorCount == other.errorCount &&
          missedCount == other.missedCount &&
          lives == other.lives &&
          elapsedTime == other.elapsedTime &&
          level == other.level &&
          completedTargets == other.completedTargets &&
          _listEquals(activeCodes, other.activeCodes);

  @override
  int get hashCode =>
      status.hashCode ^
      score.hashCode ^
      combo.hashCode ^
      maxCombo.hashCode ^
      correctCount.hashCode ^
      errorCount.hashCode ^
      missedCount.hashCode ^
      lives.hashCode ^
      elapsedTime.hashCode ^
      level.hashCode ^
      completedTargets.hashCode ^
      activeCodes.length.hashCode;

  static bool _listEquals(List<FallingCode> a, List<FallingCode> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'FallingCodeSession(status: $status, score: $score, combo: $combo, maxCombo: $maxCombo, lives: $lives, activeCodes: ${activeCodes.length}, elapsed: $elapsedTime)';
}
