// lib/features/game/memory/domain/memory_sequence.dart

class MemorySequence {
  final String value;
  final int level;

  const MemorySequence({
    required this.value,
    required this.level,
  });

  int get length => value.length;

  String? characterAt(int index) {
    if (index < 0 || index >= value.length) return null;
    return value[index];
  }

  bool isComplete(String input) => input == value;

  bool matchesInput(String input) {
    if (input.length > value.length) return false;
    return value.startsWith(input);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemorySequence &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          level == other.level;

  @override
  int get hashCode => Object.hash(value, level);

  @override
  String toString() => 'MemorySequence(value: $value, level: $level)';
}
