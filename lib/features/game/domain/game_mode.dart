// lib/features/game/domain/game_mode.dart
// Immutable model representing a game mode in MCDU App.

class GameMode {
  final String gameModeId;
  final String title;
  final String description;

  const GameMode({
    required this.gameModeId,
    required this.title,
    required this.description,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameMode &&
          runtimeType == other.runtimeType &&
          gameModeId == other.gameModeId &&
          title == other.title &&
          description == other.description;

  @override
  int get hashCode => Object.hash(gameModeId, title, description);

  @override
  String toString() => 'GameMode(gameModeId: $gameModeId, title: $title)';
}
