// lib/features/mcdu_core/domain/mcdu_state.dart
// Immutable state model for the MCDU dynamic display and input state.
import 'mcdu_page.dart';

class MCDUState {
  final MCDUPage currentPage;
  final String scratchpad;
  final String? lastKeyId;
  final String? lastAction;

  const MCDUState({
    required this.currentPage,
    required this.scratchpad,
    this.lastKeyId,
    this.lastAction,
  });

  // Convenience getters to access current page properties seamlessly
  String get currentPageId => currentPage.pageId;
  String get title => currentPage.title;
  List<String> get lines => currentPage.lines;
  List<String> get leftLabels => currentPage.leftLabels;
  List<String> get rightLabels => currentPage.rightLabels;
  bool get scratchpadVisible => currentPage.scratchpadVisible;

  // Default initial demo state starting on MENU page
  factory MCDUState.initial([MCDUPage? initialPage]) {
    final defaultMenuPage = const MCDUPage(
      pageId: 'MENU',
      title: 'MCDU MENU',
      leftLabels: ['<FPL', '<DIR', '<PROG', '', '', ''],
      rightLabels: ['NAV>', 'RADIO>', 'DATA>', '', '', ''],
      lines: ['MCDU DEMO MENU'],
      scratchpadVisible: true,
    );

    return MCDUState(
      currentPage: initialPage ?? defaultMenuPage,
      scratchpad: '',
      lastKeyId: null,
      lastAction: null,
    );
  }

  // Factory demo for backward-compatible tests if needed
  factory MCDUState.demo() => MCDUState.initial();

  MCDUState copyWith({
    MCDUPage? currentPage,
    String? scratchpad,
    String? lastKeyId,
    String? lastAction,
  }) {
    return MCDUState(
      currentPage: currentPage ?? this.currentPage,
      scratchpad: scratchpad ?? this.scratchpad,
      lastKeyId: lastKeyId ?? this.lastKeyId,
      lastAction: lastAction ?? this.lastAction,
    );
  }
}
