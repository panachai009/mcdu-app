// lib/features/simulation/flt_plan/domain/flt_plan_list_state.dart
// AW139 FMS MCDU Manual Reference:
// FPL LIST state representation — Section 3/4 FPL LIST

import 'stored_flt_plan.dart';

/// Immutable state representing the FPL LIST subsystem.
class FltPlanListState {
  final List<StoredFltPlan> plans;
  final int? selectedIndex;
  final int pageIndex;
  final int totalPages;

  const FltPlanListState({
    required this.plans,
    this.selectedIndex,
    this.pageIndex = 1,
    this.totalPages = 1,
  });

  /// Factory for a completely empty initial state.
  factory FltPlanListState.initial() {
    return const FltPlanListState(
      plans: [],
      selectedIndex: null,
      pageIndex: 1,
      totalPages: 1,
    );
  }

  /// True if there are no stored plans.
  bool get isEmpty => plans.isEmpty;

  /// True if there is at least one stored plan.
  bool get isNotEmpty => plans.isNotEmpty;

  /// Total count of stored flight plans.
  int get count => plans.length;

  /// Gets the currently selected stored flight plan, if any.
  StoredFltPlan? get selectedPlan {
    if (selectedIndex == null || selectedIndex! < 0 || selectedIndex! >= plans.length) {
      return null;
    }
    return plans[selectedIndex!];
  }

  FltPlanListState copyWith({
    List<StoredFltPlan>? plans,
    int? selectedIndex,
    bool clearSelection = false,
    int? pageIndex,
    int? totalPages,
  }) {
    return FltPlanListState(
      plans: plans != null ? List.unmodifiable(plans) : this.plans,
      selectedIndex: clearSelection ? null : (selectedIndex ?? this.selectedIndex),
      pageIndex: pageIndex ?? this.pageIndex,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FltPlanListState &&
          runtimeType == other.runtimeType &&
          selectedIndex == other.selectedIndex &&
          pageIndex == other.pageIndex &&
          totalPages == other.totalPages &&
          _arePlansEqual(plans, other.plans);

  static bool _arePlansEqual(List<StoredFltPlan> a, List<StoredFltPlan> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        selectedIndex,
        pageIndex,
        totalPages,
        Object.hashAll(plans),
      );

  @override
  String toString() =>
      'FltPlanListState(plans: ${plans.length}, selectedIndex: $selectedIndex, page: $pageIndex/$totalPages)';
}
