// lib/features/simulation/flt_plan/engine/flt_plan_create_engine.dart
// AW139 FMS MCDU Manual Reference:
// Flight Plan Creation Engine — Section 3/4 FPL LIST / Procedure 6-1 (p41-44)

import '../domain/flt_plan_create_state.dart';
import '../domain/flt_plan_state.dart' show FltPlanLeg;
import '../domain/stored_flt_plan.dart';

/// Result envelope for CREATE FPL domain operations.
class FltPlanCreateResult {
  final bool isSuccess;
  final FltPlanCreateState state;
  final String? errorMessage;
  final StoredFltPlan? finalizedPlan;

  const FltPlanCreateResult({
    required this.isSuccess,
    required this.state,
    this.errorMessage,
    this.finalizedPlan,
  });

  factory FltPlanCreateResult.success(
    FltPlanCreateState state, {
    StoredFltPlan? finalizedPlan,
  }) {
    return FltPlanCreateResult(
      isSuccess: true,
      state: state,
      finalizedPlan: finalizedPlan,
    );
  }

  factory FltPlanCreateResult.failure(
    FltPlanCreateState state,
    String errorMessage,
  ) {
    return FltPlanCreateResult(
      isSuccess: false,
      state: state,
      errorMessage: errorMessage,
    );
  }
}

/// Pure deterministic engine for the transient CREATE STORED FLIGHT PLAN workflow.
///
/// Follows AW139 FMS Procedure 6-1 (p41-44):
/// - Step 1-2: Plan name entry on FPL LIST (1L)
///   Standard format AAAA-BBBB or AAAA-BBBBx automatically sets origin and destination.
///   Non-standard name retains name with blank origin and destination.
/// - Step 3: Origin entry (if not pre-populated)
/// - Step 4: Destination entry (if not pre-populated)
/// - Step 5: Groundspeed entry (default 120 kt)
/// - Step 6-7: Sequential VIA.TO route legs
/// - Step 8: Final waypoint entered must be the destination, concluding the plan definition.
class FltPlanCreateEngine {
  /// Standard route pattern: e.g. KPHX-KMSP or KPHX-KMSP1
  static final RegExp _standardRoutePattern = RegExp(
    r'^([A-Z0-9]{4})-([A-Z0-9]{4})([A-Z0-9])?$',
  );

  /// Waypoint identifier validation: 2 to 5 alphanumeric characters.
  static final RegExp _identPattern = RegExp(r'^[A-Z0-9]{2,5}$');

  /// Creates initial [FltPlanCreateState] from user input scratchpad name.
  ///
  /// If [rawName] matches `AAAA-BBBB` or `AAAA-BBBBx`, origin is initialized to AAAA
  /// and destination is initialized to BBBB.
  /// Otherwise, name is retained and origin/destination remain null.
  static FltPlanCreateResult createInitialState(String rawName) {
    final trimmedName = rawName.trim().toUpperCase();
    if (trimmedName.isEmpty) {
      return const FltPlanCreateResult(
        isSuccess: false,
        state: FltPlanCreateState(name: ''),
        errorMessage: 'INVALID NAME',
      );
    }

    final match = _standardRoutePattern.firstMatch(trimmedName);
    if (match != null) {
      final origin = match.group(1)!;
      final destination = match.group(2)!;
      final state = FltPlanCreateState(
        name: trimmedName,
        originIdent: origin,
        destinationIdent: destination,
        groundspeed: 120,
        legs: const [],
        isFinalized: false,
      );
      return FltPlanCreateResult.success(state);
    } else {
      final state = FltPlanCreateState(
        name: trimmedName,
        originIdent: null,
        destinationIdent: null,
        groundspeed: 120,
        legs: const [],
        isFinalized: false,
      );
      return FltPlanCreateResult.success(state);
    }
  }

  /// Sets or updates the origin identifier.
  static FltPlanCreateResult setOrigin(
    FltPlanCreateState state,
    String rawIdent,
  ) {
    if (state.isFinalized) {
      return FltPlanCreateResult.failure(
        state,
        'CANNOT MODIFY FINALIZED PLAN',
      );
    }

    final trimmed = rawIdent.trim().toUpperCase();
    if (!_identPattern.hasMatch(trimmed)) {
      return FltPlanCreateResult.failure(state, 'INVALID ENTRY');
    }

    return FltPlanCreateResult.success(
      state.copyWith(originIdent: trimmed),
    );
  }

  /// Sets or updates the destination identifier.
  static FltPlanCreateResult setDestination(
    FltPlanCreateState state,
    String rawIdent,
  ) {
    if (state.isFinalized) {
      return FltPlanCreateResult.failure(
        state,
        'CANNOT MODIFY FINALIZED PLAN',
      );
    }

    final trimmed = rawIdent.trim().toUpperCase();
    if (!_identPattern.hasMatch(trimmed)) {
      return FltPlanCreateResult.failure(state, 'INVALID ENTRY');
    }

    return FltPlanCreateResult.success(
      state.copyWith(destinationIdent: trimmed),
    );
  }

  /// Sets planned groundspeed in knots.
  ///
  /// Must be an integer greater than 0.
  static FltPlanCreateResult setGroundspeed(
    FltPlanCreateState state,
    dynamic rawSpeed,
  ) {
    if (state.isFinalized) {
      return FltPlanCreateResult.failure(
        state,
        'CANNOT MODIFY FINALIZED PLAN',
      );
    }

    int? speed;
    if (rawSpeed is int) {
      speed = rawSpeed;
    } else if (rawSpeed is String) {
      speed = int.tryParse(rawSpeed.trim());
    }

    if (speed == null || speed <= 0) {
      return FltPlanCreateResult.failure(state, 'INVALID ENTRY');
    }

    return FltPlanCreateResult.success(
      state.copyWith(groundspeed: speed),
    );
  }

  /// Adds a sequential route waypoint leg to the plan.
  static FltPlanCreateResult addWaypoint(
    FltPlanCreateState state,
    String rawIdent, {
    String? bearingTrack,
    String? distanceNm,
    String? ete,
    String? altitudeSpd,
  }) {
    if (state.isFinalized) {
      return FltPlanCreateResult.failure(
        state,
        'CANNOT MODIFY FINALIZED PLAN',
      );
    }

    final trimmed = rawIdent.trim().toUpperCase();
    if (!_identPattern.hasMatch(trimmed)) {
      return FltPlanCreateResult.failure(state, 'INVALID ENTRY');
    }

    final newLeg = FltPlanLeg(
      fixIdent: trimmed,
      bearingTrack: bearingTrack,
      distanceNm: distanceNm,
      ete: ete,
      altitudeSpd: altitudeSpd,
    );

    final updatedLegs = List<FltPlanLeg>.from(state.legs)..add(newLeg);
    return FltPlanCreateResult.success(
      state.copyWith(legs: updatedLegs),
    );
  }

  /// Finalizes the definition into an immutable [StoredFltPlan].
  ///
  /// Preconditions (Procedure 6-1):
  /// - [state.name] must not be empty.
  /// - [state.originIdent] must not be null or empty.
  /// - [state.destinationIdent] must not be null or empty.
  /// - [state.legs] must not be empty.
  /// - The final leg in [state.legs] must equal [state.destinationIdent] (Procedure 6-1 Step 8:
  ///   "The flight plan definition is concluded by entering the destination waypoint.").
  static FltPlanCreateResult finalize(
    FltPlanCreateState state, {
    required String planId,
    FltPlanStorageDevice storageDevice = FltPlanStorageDevice.internal,
  }) {
    if (state.isFinalized) {
      return FltPlanCreateResult.failure(
        state,
        'PLAN ALREADY FINALIZED',
      );
    }

    if (state.name.trim().isEmpty) {
      return FltPlanCreateResult.failure(state, 'NAME REQUIRED');
    }

    if (state.originIdent == null || state.originIdent!.trim().isEmpty) {
      return FltPlanCreateResult.failure(state, 'ORIGIN REQUIRED');
    }

    if (state.destinationIdent == null ||
        state.destinationIdent!.trim().isEmpty) {
      return FltPlanCreateResult.failure(state, 'DESTINATION REQUIRED');
    }

    if (state.legs.isEmpty) {
      return FltPlanCreateResult.failure(state, 'LEGS REQUIRED');
    }

    if (state.legs.last.fixIdent != state.destinationIdent) {
      return FltPlanCreateResult.failure(
        state,
        'FINAL WAYPOINT MUST BE DESTINATION',
      );
    }

    final finalizedState = state.copyWith(isFinalized: true);
    final storedPlan = StoredFltPlan(
      id: planId,
      name: state.name,
      storageDevice: storageDevice,
      originIdent: state.originIdent,
      destinationIdent: state.destinationIdent,
      legs: List.unmodifiable(state.legs),
    );

    return FltPlanCreateResult.success(
      finalizedState,
      finalizedPlan: storedPlan,
    );
  }
}
