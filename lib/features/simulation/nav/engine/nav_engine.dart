// lib/features/simulation/nav/engine/nav_engine.dart
// AW139 FMS MCDU Manual Reference:
// NAV INDEX — p17 / p40
// Page access (NEXT/PREV) — p18
// NAV IDENT / POS INIT transition — p71 / p73

import '../domain/nav_state.dart';

/// Pure, deterministic simulation engine for the AW139 NAV subsystem.
class NavEngine {
  const NavEngine();

  /// Handles hardware NAV key press or opening NAV subsystem.
  /// AW139 FMS manual p17: Pushing NAV function key displays NAV INDEX 1/2.
  NavNavigationResult openNav(NavState state) {
    return NavNavigationResult(
      state: state.copyWith(page: NavPage.index1),
      target: NavNavigationTarget.navIndex,
    );
  }

  /// Handles NEXT page key.
  /// AW139 FMS manual p18: INDEX 1/2 -> INDEX 2/2. On INDEX 2/2 or IDENT -> no-op.
  NavNavigationResult nextPage(NavState state) {
    if (state.page == NavPage.index1) {
      return NavNavigationResult(
        state: state.copyWith(page: NavPage.index2),
        target: NavNavigationTarget.none,
      );
    }
    return NavNavigationResult(
      state: state,
      target: NavNavigationTarget.none,
    );
  }

  /// Handles PREV page key.
  /// AW139 FMS manual p18: INDEX 2/2 -> INDEX 1/2. On INDEX 1/2 or IDENT -> no-op.
  NavNavigationResult previousPage(NavState state) {
    if (state.page == NavPage.index2) {
      return NavNavigationResult(
        state: state.copyWith(page: NavPage.index1),
        target: NavNavigationTarget.none,
      );
    }
    return NavNavigationResult(
      state: state,
      target: NavNavigationTarget.none,
    );
  }

  /// Direct transition to NAV IDENT 1/1.
  /// AW139 FMS manual p17 & p71: 3L on NAV INDEX 1/2 transitions to NAV IDENT 1/1.
  NavNavigationResult openNavIdent(NavState state) {
    return NavNavigationResult(
      state: state.copyWith(page: NavPage.ident),
      target: NavNavigationTarget.navIdent,
    );
  }

  /// Direct transition intent to POSITION INIT 1/1.
  /// AW139 FMS manual p17 & p73: 1L on INDEX 2/2 or 6R on NAV IDENT transitions to POS INIT.
  NavNavigationResult openPosInit(NavState state) {
    return NavNavigationResult(
      state: state,
      target: NavNavigationTarget.posInit,
    );
  }

  /// Dispatches LSK actions according to the current page.
  /// Supported transitions:
  /// - NAV INDEX 1/2: 3L -> NAV IDENT
  /// - NAV INDEX 2/2: 1L -> POS INIT
  /// - NAV IDENT 1/1: 6R -> POS INIT
  /// All other LSKs are no-op.
  NavNavigationResult handleLsk(NavState state, String lsk) {
    switch (state.page) {
      case NavPage.index1:
        if (lsk == '3L') {
          return openNavIdent(state);
        }
        break;
      case NavPage.index2:
        if (lsk == '1L') {
          return openPosInit(state);
        }
        break;
      case NavPage.ident:
        if (lsk == '6R') {
          return openPosInit(state);
        }
        break;
    }

    return NavNavigationResult(
      state: state,
      target: NavNavigationTarget.none,
    );
  }
}
