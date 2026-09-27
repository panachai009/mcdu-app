// lib/features/simulation/flt_plan/domain/flt_plan_create_state.dart
// AW139 FMS MCDU Manual Reference:
// Flight Plan Creation Definition Workflow — Section 3/4 FPL LIST / Procedure 6-1 (p41-44)

import 'package:flutter/foundation.dart';
import 'flt_plan_state.dart' show FltPlanLeg;

/// Immutable transient domain state for the in-progress creation of a stored flight plan.
///
/// Models Procedure 6-1 (p41-44):
/// - Starts via prompt/name entry on FPL LIST (1L)
/// - Holds user-entered or auto-parsed origin, destination, sequential route legs, and groundspeed
/// - Tracks finalization status before being committed to StoredFltPlan
@immutable
class FltPlanCreateState {
  /// The raw identifier or user-given name for the stored plan (e.g. "KPHX-KMSP" or "PATROL01").
  final String name;

  /// Origin waypoint identifier (e.g. "KPHX").
  final String? originIdent;

  /// Destination waypoint identifier (e.g. "KMSP").
  final String? destinationIdent;

  /// Planned cruise groundspeed in knots (default 120 kt per AW139 FMS default).
  final int groundspeed;

  /// Sequential route legs added to the plan definition.
  final List<FltPlanLeg> legs;

  /// Flag indicating whether definition has met all preconditions and been finalized.
  final bool isFinalized;

  const FltPlanCreateState({
    required this.name,
    this.originIdent,
    this.destinationIdent,
    this.groundspeed = 120,
    this.legs = const [],
    this.isFinalized = false,
  });

  /// Creates a copy with the given fields replaced by the new values.
  FltPlanCreateState copyWith({
    String? name,
    String? originIdent,
    String? destinationIdent,
    int? groundspeed,
    List<FltPlanLeg>? legs,
    bool? isFinalized,
  }) {
    return FltPlanCreateState(
      name: name ?? this.name,
      originIdent: originIdent ?? this.originIdent,
      destinationIdent: destinationIdent ?? this.destinationIdent,
      groundspeed: groundspeed ?? this.groundspeed,
      legs: legs != null ? List.unmodifiable(legs) : this.legs,
      isFinalized: isFinalized ?? this.isFinalized,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FltPlanCreateState &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          originIdent == other.originIdent &&
          destinationIdent == other.destinationIdent &&
          groundspeed == other.groundspeed &&
          isFinalized == other.isFinalized &&
          _areLegsEqual(legs, other.legs);

  static bool _areLegsEqual(List<FltPlanLeg> a, List<FltPlanLeg> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        name,
        originIdent,
        destinationIdent,
        groundspeed,
        isFinalized,
        Object.hashAll(legs),
      );

  @override
  String toString() =>
      'FltPlanCreateState(name: $name, orig: $originIdent, dest: $destinationIdent, gs: $groundspeed, legs: ${legs.length}, finalized: $isFinalized)';
}
