// lib/features/simulation/flt_plan/domain/flt_plan_state.dart
// AW139 FMS MCDU Manual Reference:
// Pre-departure procedures & ACTIVE FLT PLAN — p71-77 (Im123, Im130-Im133)
// Page access — p18, p19 (Figure 3-5)

/// Logical page representation for the ACTIVE FLT PLAN subsystem.
enum FltPlanPage {
  /// Unpopulated plan awaiting destination entry: "ACTIVE FLT PLAN 1/1" (p74 Im130)
  init,

  /// Populated plan with active origin and destination legs: "ACTIVE FLT PLAN 1/2" (p76 Im132)
  route,
}

/// Represents an immutable route leg within an active flight plan.
class FltPlanLeg {
  final String fixIdent;
  final String? bearingTrack; // e.g. "344T"
  final String? distanceNm;   // e.g. "3.9NM"
  final String? ete;          // e.g. "00+02"
  final String? altitudeSpd;  // e.g. "---/0100"

  const FltPlanLeg({
    required this.fixIdent,
    this.bearingTrack,
    this.distanceNm,
    this.ete,
    this.altitudeSpd,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FltPlanLeg &&
          runtimeType == other.runtimeType &&
          fixIdent == other.fixIdent &&
          bearingTrack == other.bearingTrack &&
          distanceNm == other.distanceNm &&
          ete == other.ete &&
          altitudeSpd == other.altitudeSpd;

  @override
  int get hashCode => Object.hash(
        fixIdent,
        bearingTrack,
        distanceNm,
        ete,
        altitudeSpd,
      );

  @override
  String toString() =>
      'FltPlanLeg(fix: $fixIdent, track: $bearingTrack, dist: $distanceNm, ete: $ete, altSpd: $altitudeSpd)';
}

/// Immutable state for AW139 ACTIVE FLT PLAN simulation.
class FltPlanState {
  final String? originIdent;
  final String? destinationIdent;
  final FltPlanPage page;
  final int pageIndex;
  final int totalPages;
  final List<FltPlanLeg> legs;

  const FltPlanState({
    this.originIdent,
    this.destinationIdent,
    required this.page,
    required this.pageIndex,
    required this.totalPages,
    required this.legs,
  });

  /// Factory for a completely empty initial state.
  factory FltPlanState.initial() {
    return const FltPlanState(
      originIdent: null,
      destinationIdent: null,
      page: FltPlanPage.init,
      pageIndex: 1,
      totalPages: 1,
      legs: [],
    );
  }

  bool get hasOrigin => originIdent != null && originIdent!.isNotEmpty;
  bool get hasDestination => destinationIdent != null && destinationIdent!.isNotEmpty;
  bool get isRouteActive => hasOrigin && hasDestination;

  FltPlanState copyWith({
    String? originIdent,
    String? destinationIdent,
    FltPlanPage? page,
    int? pageIndex,
    int? totalPages,
    List<FltPlanLeg>? legs,
    bool clearDestination = false,
  }) {
    return FltPlanState(
      originIdent: originIdent ?? this.originIdent,
      destinationIdent: clearDestination ? null : (destinationIdent ?? this.destinationIdent),
      page: page ?? this.page,
      pageIndex: pageIndex ?? this.pageIndex,
      totalPages: totalPages ?? this.totalPages,
      legs: legs ?? this.legs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FltPlanState &&
          runtimeType == other.runtimeType &&
          originIdent == other.originIdent &&
          destinationIdent == other.destinationIdent &&
          page == other.page &&
          pageIndex == other.pageIndex &&
          totalPages == other.totalPages &&
          _areListsEqual(legs, other.legs);

  static bool _areListsEqual(List<FltPlanLeg> a, List<FltPlanLeg> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        originIdent,
        destinationIdent,
        page,
        pageIndex,
        totalPages,
        Object.hashAll(legs),
      );

  @override
  String toString() =>
      'FltPlanState(origin: $originIdent, dest: $destinationIdent, page: $page ($pageIndex/$totalPages), legs: ${legs.length})';
}
