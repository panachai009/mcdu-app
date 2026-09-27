// lib/features/simulation/flt_plan/domain/stored_flt_plan.dart
// AW139 FMS MCDU Manual Reference:
// Flight Plan Storage & List — Section 3/4 FPL LIST

import 'flt_plan_state.dart' show FltPlanLeg;

/// Storage device media representation for stored flight plans.
/// According to AW139 FMS architectures, storage can be internal memory or data cards.
enum FltPlanStorageDevice {
  internal,
  card,
}

/// Immutable domain model representing a stored flight plan in FPL LIST.
class StoredFltPlan {
  final String id;
  final String name;
  final FltPlanStorageDevice storageDevice;
  final String? originIdent;
  final String? destinationIdent;
  final List<FltPlanLeg> legs;

  const StoredFltPlan({
    required this.id,
    required this.name,
    this.storageDevice = FltPlanStorageDevice.internal,
    this.originIdent,
    this.destinationIdent,
    this.legs = const [],
  });

  StoredFltPlan copyWith({
    String? id,
    String? name,
    FltPlanStorageDevice? storageDevice,
    String? originIdent,
    String? destinationIdent,
    List<FltPlanLeg>? legs,
  }) {
    return StoredFltPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      storageDevice: storageDevice ?? this.storageDevice,
      originIdent: originIdent ?? this.originIdent,
      destinationIdent: destinationIdent ?? this.destinationIdent,
      legs: legs != null ? List.unmodifiable(legs) : this.legs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoredFltPlan &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          storageDevice == other.storageDevice &&
          originIdent == other.originIdent &&
          destinationIdent == other.destinationIdent &&
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
        id,
        name,
        storageDevice,
        originIdent,
        destinationIdent,
        Object.hashAll(legs),
      );

  @override
  String toString() =>
      'StoredFltPlan(id: $id, name: $name, dev: $storageDevice, orig: $originIdent, dest: $destinationIdent, legs: ${legs.length})';
}
