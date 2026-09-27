// lib/features/simulation/flt_plan/engine/flt_plan_engine.dart
// AW139 FMS MCDU Manual Reference:
// Pre-departure procedures & ACTIVE FLT PLAN — p71-77 (Im123, Im130-Im133)
// Page access — p18, p19 (Figure 3-5)

import '../domain/flt_plan_state.dart';
import '../domain/stored_flt_plan.dart';

/// Result object returned by [FltPlanEngine] operations.
class FltPlanResult {
  final FltPlanState state;
  final bool isSuccess;
  final String? errorMessage;

  const FltPlanResult({
    required this.state,
    this.isSuccess = true,
    this.errorMessage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FltPlanResult &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          isSuccess == other.isSuccess &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(state, isSuccess, errorMessage);

  @override
  String toString() =>
      'FltPlanResult(success: $isSuccess, error: $errorMessage, state: $state)';
}

/// Pure deterministic engine for AW139 ACTIVE FLT PLAN simulation.
class FltPlanEngine {
  const FltPlanEngine();

  /// Initializes origin waypoint (e.g. from POS INIT reference station like 'VTBL').
  /// AW139 FMS manual p74 Im130: Origin is populated, plan remains in init mode (1/1).
  FltPlanResult initializeOrigin(FltPlanState state, String rawIdent) {
    final clean = rawIdent.trim().toUpperCase();
    if (!_isValidIdent(clean)) {
      return FltPlanResult(
        state: state,
        isSuccess: false,
        errorMessage: 'INVALID ENTRY',
      );
    }

    final newLegs = _deriveLegs(clean, state.destinationIdent);
    final isRoute = clean.isNotEmpty && (state.destinationIdent != null && state.destinationIdent!.isNotEmpty);

    final newState = state.copyWith(
      originIdent: clean,
      page: isRoute ? FltPlanPage.route : FltPlanPage.init,
      pageIndex: 1,
      totalPages: isRoute ? 2 : 1,
      legs: newLegs,
    );

    return FltPlanResult(
      state: newState,
      isSuccess: true,
    );
  }

  /// Sets destination waypoint from scratchpad entry (e.g. 'VTBH' inserted at 1R).
  /// AW139 FMS manual p75-76 Im131-Im132: Destination is populated.
  /// If origin exists, transitions from 1/1 (init) to 1/2 (route).
  FltPlanResult setDestination(FltPlanState state, String rawIdent) {
    final clean = rawIdent.trim().toUpperCase();
    if (!_isValidIdent(clean)) {
      return FltPlanResult(
        state: state,
        isSuccess: false,
        errorMessage: 'INVALID ENTRY',
      );
    }

    final newLegs = _deriveLegs(state.originIdent, clean);
    final hasOrigin = state.hasOrigin;

    final newState = state.copyWith(
      destinationIdent: clean,
      page: hasOrigin ? FltPlanPage.route : FltPlanPage.init,
      pageIndex: 1,
      totalPages: hasOrigin ? 2 : 1,
      legs: newLegs,
    );

    return FltPlanResult(
      state: newState,
      isSuccess: true,
    );
  }

  /// Clears destination from active plan.
  FltPlanResult clearDestination(FltPlanState state) {
    final newState = state.copyWith(
      clearDestination: true,
      page: FltPlanPage.init,
      pageIndex: 1,
      totalPages: 1,
      legs: const [],
    );

    return FltPlanResult(
      state: newState,
      isSuccess: true,
    );
  }

  /// Adds (appends) a waypoint to the end of the active flight plan's route legs.
  /// Validates ident (2–5 alphanumeric characters).
  /// Preserves origin, destination, and does not mutate the original state.
  FltPlanResult addWaypoint(FltPlanState state, String rawIdent) {
    final clean = rawIdent.trim().toUpperCase();
    if (!_isValidIdent(clean)) {
      return FltPlanResult(
        state: state,
        isSuccess: false,
        errorMessage: 'INVALID ENTRY',
      );
    }

    final newLeg = FltPlanLeg(fixIdent: clean);
    final updatedLegs = List<FltPlanLeg>.unmodifiable([...state.legs, newLeg]);

    final newState = state.copyWith(
      legs: updatedLegs,
    );

    return FltPlanResult(
      state: newState,
      isSuccess: true,
    );
  }

  /// Inserts a waypoint at a specific 0-based index in the active flight plan legs.
  /// Validates ident and ensures [index] is within [0, state.legs.length].
  /// Returns a failure with state unchanged if [index] is out of bounds or ident is invalid.
  FltPlanResult insertWaypoint(FltPlanState state, int index, String rawIdent) {
    final clean = rawIdent.trim().toUpperCase();
    if (!_isValidIdent(clean)) {
      return FltPlanResult(
        state: state,
        isSuccess: false,
        errorMessage: 'INVALID ENTRY',
      );
    }

    if (index < 0 || index > state.legs.length) {
      return FltPlanResult(
        state: state,
        isSuccess: false,
        errorMessage: 'INVALID ENTRY',
      );
    }

    final newLeg = FltPlanLeg(fixIdent: clean);
    final list = List<FltPlanLeg>.from(state.legs);
    list.insert(index, newLeg);
    final updatedLegs = List<FltPlanLeg>.unmodifiable(list);

    final newState = state.copyWith(
      legs: updatedLegs,
    );

    return FltPlanResult(
      state: newState,
      isSuccess: true,
    );
  }

  /// Deletes a waypoint at a specific 0-based index from the active flight plan legs.
  /// Validates that [index] is within [0, state.legs.length - 1].
  /// Returns a failure with state unchanged if [index] is out of bounds or list is empty.
  FltPlanResult deleteWaypoint(FltPlanState state, int index) {
    if (index < 0 || index >= state.legs.length) {
      return FltPlanResult(
        state: state,
        isSuccess: false,
        errorMessage: 'INVALID ENTRY',
      );
    }

    final list = List<FltPlanLeg>.from(state.legs);
    list.removeAt(index);
    final updatedLegs = List<FltPlanLeg>.unmodifiable(list);

    final newState = state.copyWith(
      legs: updatedLegs,
    );

    return FltPlanResult(
      state: newState,
      isSuccess: true,
    );
  }

  /// Advances to the next page of the active flight plan.
  /// Deterministically clamps at [totalPages].
  FltPlanState nextPage(FltPlanState state) {
    if (state.pageIndex >= state.totalPages) {
      return state;
    }
    return state.copyWith(pageIndex: state.pageIndex + 1);
  }

  /// Returns to the previous page of the active flight plan.
  /// Deterministically clamps at first page (1).
  FltPlanState previousPage(FltPlanState state) {
    if (state.pageIndex <= 1) {
      return state;
    }
    return state.copyWith(pageIndex: state.pageIndex - 1);
  }

  /// Validates ICAO waypoint/station identifier: 2–5 alphanumeric characters without whitespace.
  bool _isValidIdent(String ident) {
    if (ident.length < 2 || ident.length > 5) return false;
    final regex = RegExp(r'^[A-Z0-9]{2,5}$');
    return regex.hasMatch(ident);
  }

  /// Derives route legs when both origin and destination are present.
  /// AW139 FMS manual p76 Im132: Shows origin fix and destination fix leg.
  List<FltPlanLeg> _deriveLegs(String? origin, String? destination) {
    if (origin == null || origin.isEmpty || destination == null || destination.isEmpty) {
      return const [];
    }

    // AW139 Flight deck reference example (VTBL -> VTBH leg on p76 Im132)
    final isVtblVtbh = origin == 'VTBL' && destination == 'VTBH';

    return [
      FltPlanLeg(
        fixIdent: destination,
        bearingTrack: isVtblVtbh ? '344T' : null,
        distanceNm: isVtblVtbh ? '3.9NM' : null,
        ete: isVtblVtbh ? '00+02' : null,
        altitudeSpd: isVtblVtbh ? '---/0100' : null,
      ),
    ];
  }

  /// Activates a [StoredFltPlan] into the active [FltPlanState].
  /// If [invert] is true, origin and destination are swapped, and any route legs
  /// are reversed according to AW139 FMS INVERT/ACTIVATE semantics (p46-48).
  FltPlanResult activatePlan(
    FltPlanState state,
    StoredFltPlan storedPlan, {
    bool invert = false,
  }) {
    final origin = invert ? storedPlan.destinationIdent : storedPlan.originIdent;
    final destination = invert ? storedPlan.originIdent : storedPlan.destinationIdent;

    List<FltPlanLeg> activeLegs;
    if (storedPlan.legs.isNotEmpty) {
      if (invert) {
        // Reverse legs order and set the final leg destination to the inverted destination (the original origin)
        final rev = storedPlan.legs.reversed.toList();
        if (destination != null && destination.isNotEmpty) {
          rev[rev.length - 1] = FltPlanLeg(fixIdent: destination);
        }
        activeLegs = List<FltPlanLeg>.unmodifiable(rev);
      } else {
        activeLegs = List<FltPlanLeg>.unmodifiable(storedPlan.legs);
      }
    } else {
      activeLegs = _deriveLegs(origin, destination);
    }

    final hasOrigin = origin != null && origin.isNotEmpty;
    final hasDestination = destination != null && destination.isNotEmpty;
    final isRoute = hasOrigin && hasDestination;

    final newState = state.copyWith(
      originIdent: origin,
      destinationIdent: destination,
      page: isRoute ? FltPlanPage.route : FltPlanPage.init,
      pageIndex: 1,
      totalPages: isRoute ? 2 : 1,
      legs: activeLegs,
    );

    return FltPlanResult(
      state: newState,
      isSuccess: true,
    );
  }

  /// Creates a new immutable [StoredFltPlan] by copying the route data from the active [FltPlanState].
  /// AW139 FMS MCDU Manual Reference: p76–77 (SAVE ACTIVE FLT PLAN TO ----------).
  ///
  /// Returns null if the plan name is empty or if active plan lacks origin or destination.
  /// Does NOT mutate [state].
  StoredFltPlan? createStoredPlanFromActiveState({
    required FltPlanState state,
    required String name,
    required String id,
    FltPlanStorageDevice storageDevice = FltPlanStorageDevice.internal,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return null;
    if (!state.isRouteActive) return null;

    return StoredFltPlan(
      id: id,
      name: cleanName,
      storageDevice: storageDevice,
      originIdent: state.originIdent,
      destinationIdent: state.destinationIdent,
      legs: List<FltPlanLeg>.unmodifiable(state.legs),
    );
  }
}

