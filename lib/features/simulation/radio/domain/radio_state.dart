// lib/features/simulation/radio/domain/radio_state.dart
// Immutable Radio subsystem state for realistic Honeywell / AW139 MCDU simulation.

import 'radio_channel.dart';

enum XpdrMode {
  stby,
  altOn,
}

class RadioState {
  const RadioState({
    required this.pageIndex,
    required this.com1,
    required this.com2,
    required this.nav1,
    required this.nav2,
    required this.adf2,
    required this.xpdrCode,
    required this.xpdrMode,
    required this.isIdentActive,
  });

  /// Factory creating the canonical initial state derived from Honeywell Primus Epic / AW139 MCDU manual.
  /// (Page 22, 96, 97 of 25 NAV(MCDU).pdf)
  factory RadioState.initial() {
    return const RadioState(
      pageIndex: 1,
      com1: RadioChannel(active: '122.600', standby: '127.000'),
      com2: RadioChannel(active: '122.100', standby: '127.000'),
      nav1: RadioChannel(active: '117.30', standby: '113.80'),
      nav2: RadioChannel(active: '116.80', standby: '111.10'),
      adf2: RadioChannel(active: '242.0', standby: '1570.0'),
      xpdrCode: '1102',
      xpdrMode: XpdrMode.stby,
      isIdentActive: false,
    );
  }

  final int pageIndex;
  final RadioChannel com1;
  final RadioChannel com2;
  final RadioChannel nav1;
  final RadioChannel nav2;
  final RadioChannel adf2;
  final String xpdrCode;
  final XpdrMode xpdrMode;
  final bool isIdentActive;

  RadioState copyWith({
    int? pageIndex,
    RadioChannel? com1,
    RadioChannel? com2,
    RadioChannel? nav1,
    RadioChannel? nav2,
    RadioChannel? adf2,
    String? xpdrCode,
    XpdrMode? xpdrMode,
    bool? isIdentActive,
  }) {
    return RadioState(
      pageIndex: pageIndex ?? this.pageIndex,
      com1: com1 ?? this.com1,
      com2: com2 ?? this.com2,
      nav1: nav1 ?? this.nav1,
      nav2: nav2 ?? this.nav2,
      adf2: adf2 ?? this.adf2,
      xpdrCode: xpdrCode ?? this.xpdrCode,
      xpdrMode: xpdrMode ?? this.xpdrMode,
      isIdentActive: isIdentActive ?? this.isIdentActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadioState &&
          runtimeType == other.runtimeType &&
          pageIndex == other.pageIndex &&
          com1 == other.com1 &&
          com2 == other.com2 &&
          nav1 == other.nav1 &&
          nav2 == other.nav2 &&
          adf2 == other.adf2 &&
          xpdrCode == other.xpdrCode &&
          xpdrMode == other.xpdrMode &&
          isIdentActive == other.isIdentActive;

  @override
  int get hashCode =>
      pageIndex.hashCode ^
      com1.hashCode ^
      com2.hashCode ^
      nav1.hashCode ^
      nav2.hashCode ^
      adf2.hashCode ^
      xpdrCode.hashCode ^
      xpdrMode.hashCode ^
      isIdentActive.hashCode;

  @override
  String toString() =>
      'RadioState(pageIndex: $pageIndex, com1: $com1, com2: $com2, nav1: $nav1, nav2: $nav2, adf2: $adf2, xpdrCode: $xpdrCode, xpdrMode: $xpdrMode, isIdentActive: $isIdentActive)';
}
