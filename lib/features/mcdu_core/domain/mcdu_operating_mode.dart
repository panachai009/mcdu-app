// lib/features/mcdu_core/domain/mcdu_operating_mode.dart
// Operating mode domain definition for the MCDU application.

/// Represents the top-level operational mode of the MCDU application.
enum MCDUOperatingMode {
  /// Realistic aircraft simulation mode (Honeywell / AW139 FMS).
  realistic,

  /// Minigame suite mode (Typing Test, Falling Code, Memory, Speed Run, MCDU Flow).
  game,
}
