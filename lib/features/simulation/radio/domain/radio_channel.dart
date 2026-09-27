// lib/features/simulation/radio/domain/radio_channel.dart
// Immutable representation of a dual-frequency radio channel (Active / Standby).

class RadioChannel {
  const RadioChannel({
    required this.active,
    required this.standby,
  });

  final String active;
  final String standby;

  RadioChannel copyWith({
    String? active,
    String? standby,
  }) {
    return RadioChannel(
      active: active ?? this.active,
      standby: standby ?? this.standby,
    );
  }

  RadioChannel swap() {
    return RadioChannel(
      active: standby,
      standby: active,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadioChannel &&
          runtimeType == other.runtimeType &&
          active == other.active &&
          standby == other.standby;

  @override
  int get hashCode => active.hashCode ^ standby.hashCode;

  @override
  String toString() => 'RadioChannel(active: $active, standby: $standby)';
}
