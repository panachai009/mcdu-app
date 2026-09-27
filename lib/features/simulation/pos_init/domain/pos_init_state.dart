// lib/features/simulation/pos_init/domain/pos_init_state.dart
// Immutable representation of POSITION INIT state for realistic Honeywell / AW139 MCDU simulation.

enum PositionLoadSource {
  none,
  last,
  refWpt,
  gps,
}

class PosInitState {
  const PosInitState({
    required this.lastPosLatLon,
    this.refWptIdent,
    this.refWptLatLon,
    required this.gpsPosLatLon,
    this.loadedPosLatLon,
    this.loadedSource = PositionLoadSource.none,
    this.isPositionLoaded = false,
  });

  /// Canonical initial state derived from Honeywell Primus Epic / AW139 MCDU manual.
  /// (25 NAV(MCDU).pdf p. 65, 73)
  factory PosInitState.initial() {
    return const PosInitState(
      lastPosLatLon: 'N14°53.2 E100°39.7',
      refWptIdent: 'VTBL',
      refWptLatLon: 'N14°52.5 E100°39.8',
      gpsPosLatLon: 'N14°53.2 E100°39.7',
      loadedPosLatLon: null,
      loadedSource: PositionLoadSource.none,
      isPositionLoaded: false,
    );
  }

  final String lastPosLatLon;
  final String? refWptIdent;
  final String? refWptLatLon;
  final String gpsPosLatLon;
  final String? loadedPosLatLon;
  final PositionLoadSource loadedSource;
  final bool isPositionLoaded;

  PosInitState copyWith({
    String? lastPosLatLon,
    String? refWptIdent,
    String? refWptLatLon,
    String? gpsPosLatLon,
    String? loadedPosLatLon,
    PositionLoadSource? loadedSource,
    bool? isPositionLoaded,
    bool clearRefWpt = false,
  }) {
    return PosInitState(
      lastPosLatLon: lastPosLatLon ?? this.lastPosLatLon,
      refWptIdent: clearRefWpt ? null : (refWptIdent ?? this.refWptIdent),
      refWptLatLon: clearRefWpt ? null : (refWptLatLon ?? this.refWptLatLon),
      gpsPosLatLon: gpsPosLatLon ?? this.gpsPosLatLon,
      loadedPosLatLon: loadedPosLatLon ?? this.loadedPosLatLon,
      loadedSource: loadedSource ?? this.loadedSource,
      isPositionLoaded: isPositionLoaded ?? this.isPositionLoaded,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosInitState &&
          runtimeType == other.runtimeType &&
          lastPosLatLon == other.lastPosLatLon &&
          refWptIdent == other.refWptIdent &&
          refWptLatLon == other.refWptLatLon &&
          gpsPosLatLon == other.gpsPosLatLon &&
          loadedPosLatLon == other.loadedPosLatLon &&
          loadedSource == other.loadedSource &&
          isPositionLoaded == other.isPositionLoaded;

  @override
  int get hashCode =>
      lastPosLatLon.hashCode ^
      refWptIdent.hashCode ^
      refWptLatLon.hashCode ^
      gpsPosLatLon.hashCode ^
      loadedPosLatLon.hashCode ^
      loadedSource.hashCode ^
      isPositionLoaded.hashCode;

  @override
  String toString() =>
      'PosInitState(lastPos: $lastPosLatLon, refWpt: $refWptIdent $refWptLatLon, gpsPos: $gpsPosLatLon, loaded: $loadedPosLatLon, source: $loadedSource, isLoaded: $isPositionLoaded)';
}
