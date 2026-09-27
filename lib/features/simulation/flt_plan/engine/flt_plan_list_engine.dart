// lib/features/simulation/flt_plan/engine/flt_plan_list_engine.dart
// AW139 FMS MCDU Manual Reference:
// FPL LIST Pure Deterministic Engine — Section 3/4 FPL LIST

import '../domain/flt_plan_list_state.dart';
import '../domain/stored_flt_plan.dart';

/// Pure deterministic engine for managing stored flight plans in FPL LIST.
class FltPlanListEngine {
  const FltPlanListEngine();

  /// Creates initial state with an empty list.
  FltPlanListState createInitialState() {
    return FltPlanListState.initial();
  }

  /// Loads or replaces the stored plans list preserving explicit input order.
  /// If the current selection becomes invalid, selection is reset or cleared deterministically.
  FltPlanListState loadPlans(FltPlanListState current, List<StoredFltPlan> newPlans) {
    final unmodifiablePlans = List<StoredFltPlan>.unmodifiable(newPlans);
    int? newSelection;
    if (unmodifiablePlans.isEmpty) {
      newSelection = null;
    } else if (current.selectedIndex != null &&
        current.selectedIndex! >= 0 &&
        current.selectedIndex! < unmodifiablePlans.length) {
      newSelection = current.selectedIndex;
    } else {
      newSelection = null;
    }

    return current.copyWith(
      plans: unmodifiablePlans,
      selectedIndex: newSelection,
      clearSelection: newSelection == null,
    );
  }

  /// Selects a plan by index. If the index is out of bounds or list is empty,
  /// returns state unchanged or with selection unchanged (deterministic invalid selection).
  FltPlanListState selectIndex(FltPlanListState current, int index) {
    if (current.plans.isEmpty) {
      return current;
    }
    if (index < 0 || index >= current.plans.length) {
      // Invalid index: preserves current state deterministically
      return current;
    }
    return current.copyWith(selectedIndex: index);
  }

  /// Selects a plan by its unique domain ID.
  FltPlanListState selectById(FltPlanListState current, String id) {
    if (current.plans.isEmpty) {
      return current;
    }
    final index = current.plans.indexWhere((plan) => plan.id == id);
    if (index == -1) {
      return current;
    }
    return current.copyWith(selectedIndex: index);
  }

  /// Advances selection to the next plan.
  /// If at boundary (last item), clamps at the boundary (does not wrap or crash).
  /// If no item is selected and list is non-empty, selects index 0.
  /// If empty, returns current state unchanged.
  FltPlanListState next(FltPlanListState current) {
    if (current.plans.isEmpty) {
      return current;
    }
    if (current.selectedIndex == null) {
      return current.copyWith(selectedIndex: 0);
    }
    if (current.selectedIndex! >= current.plans.length - 1) {
      // Boundary reached: clamp to last
      return current;
    }
    return current.copyWith(selectedIndex: current.selectedIndex! + 1);
  }

  /// Moves selection to the previous plan.
  /// If at boundary (first item, index 0), clamps at 0.
  /// If no item is selected and list is non-empty, selects index 0.
  /// If empty, returns current state unchanged.
  FltPlanListState previous(FltPlanListState current) {
    if (current.plans.isEmpty) {
      return current;
    }
    if (current.selectedIndex == null) {
      return current.copyWith(selectedIndex: 0);
    }
    if (current.selectedIndex! <= 0) {
      // Boundary reached: clamp to 0
      return current;
    }
    return current.copyWith(selectedIndex: current.selectedIndex! - 1);
  }

  /// Adds a new plan to the list in a deterministic append order.
  /// Preserves current selection unless selection was null, in which case it remains null.
  FltPlanListState addPlan(FltPlanListState current, StoredFltPlan plan) {
    final updatedList = List<StoredFltPlan>.unmodifiable([...current.plans, plan]);
    return current.copyWith(
      plans: updatedList,
      selectedIndex: current.selectedIndex,
    );
  }

  /// Deletes a plan by ID.
  /// If plan not found, returns current state.
  /// If selected plan was deleted, adjusts selection deterministically.
  FltPlanListState deletePlanById(FltPlanListState current, String id) {
    final indexToDelete = current.plans.indexWhere((p) => p.id == id);
    if (indexToDelete == -1) {
      return current;
    }

    final updatedList = List<StoredFltPlan>.unmodifiable(
      current.plans.where((p) => p.id != id).toList(),
    );

    int? newSelection;
    if (updatedList.isEmpty) {
      newSelection = null;
    } else if (current.selectedIndex == null) {
      newSelection = null;
    } else if (current.selectedIndex == indexToDelete) {
      // Clamped to valid range
      newSelection = indexToDelete >= updatedList.length
          ? updatedList.length - 1
          : indexToDelete;
    } else if (current.selectedIndex! > indexToDelete) {
      newSelection = current.selectedIndex! - 1;
    } else {
      newSelection = current.selectedIndex;
    }

    return current.copyWith(
      plans: updatedList,
      selectedIndex: newSelection,
      clearSelection: newSelection == null,
    );
  }
}
