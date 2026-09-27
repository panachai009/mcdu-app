// lib/features/simulation/nav/domain/nav_state.dart
// AW139 FMS MCDU Manual Reference:
// NAV INDEX pages — p17 / p40
// NAV IDENT page — p71 / p73

/// Active logical page within the NAV subsystem.
enum NavPage {
  index1,
  index2,
  ident,
}

/// External navigation target intent emitted by the NavEngine.
enum NavNavigationTarget {
  none,
  navIndex,
  navIdent,
  posInit,
}

/// Result returned from operations on [NavEngine].
class NavNavigationResult {
  final NavState state;
  final NavNavigationTarget target;
  final bool isSuccess;

  const NavNavigationResult({
    required this.state,
    this.target = NavNavigationTarget.none,
    this.isSuccess = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavNavigationResult &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          target == other.target &&
          isSuccess == other.isSuccess;

  @override
  int get hashCode => Object.hash(state, target, isSuccess);

  @override
  String toString() =>
      'NavNavigationResult(state: $state, target: $target, isSuccess: $isSuccess)';
}

/// Immutable state representing the AW139 MCDU NAV subsystem.
class NavState {
  final NavPage page;

  // NAV IDENT 1/1 parameters (AW139 FMS manual p71/p73)
  final String date;
  final String utc;
  final String softwareVersion;
  final String activeNdb;
  final String nonActiveNdb;
  final String databaseVersion;
  final String databasePartNumber;

  const NavState({
    required this.page,
    required this.date,
    required this.utc,
    required this.softwareVersion,
    required this.activeNdb,
    required this.nonActiveNdb,
    required this.databaseVersion,
    required this.databasePartNumber,
  });

  /// Factory for the default initial state grounded in AW139 FMS manual p71/p73.
  factory NavState.initial() {
    return const NavState(
      page: NavPage.index1,
      date: '24JAN17',
      utc: '0755z',
      softwareVersion: 'NZ7.1.2',
      activeNdb: '10NOV 07DEC/16',
      nonActiveNdb: '13OCT 09NOV/16',
      databaseVersion: 'NDB V3.01 16M',
      databasePartNumber: 'AW139-5-312',
    );
  }

  NavState copyWith({
    NavPage? page,
    String? date,
    String? utc,
    String? softwareVersion,
    String? activeNdb,
    String? nonActiveNdb,
    String? databaseVersion,
    String? databasePartNumber,
  }) {
    return NavState(
      page: page ?? this.page,
      date: date ?? this.date,
      utc: utc ?? this.utc,
      softwareVersion: softwareVersion ?? this.softwareVersion,
      activeNdb: activeNdb ?? this.activeNdb,
      nonActiveNdb: nonActiveNdb ?? this.nonActiveNdb,
      databaseVersion: databaseVersion ?? this.databaseVersion,
      databasePartNumber: databasePartNumber ?? this.databasePartNumber,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavState &&
          runtimeType == other.runtimeType &&
          page == other.page &&
          date == other.date &&
          utc == other.utc &&
          softwareVersion == other.softwareVersion &&
          activeNdb == other.activeNdb &&
          nonActiveNdb == other.nonActiveNdb &&
          databaseVersion == other.databaseVersion &&
          databasePartNumber == other.databasePartNumber;

  @override
  int get hashCode => Object.hash(
        page,
        date,
        utc,
        softwareVersion,
        activeNdb,
        nonActiveNdb,
        databaseVersion,
        databasePartNumber,
      );

  @override
  String toString() =>
      'NavState(page: $page, date: $date, utc: $utc, sw: $softwareVersion, activeNdb: $activeNdb, nonActiveNdb: $nonActiveNdb, dbVer: $databaseVersion, dbPart: $databasePartNumber)';
}
