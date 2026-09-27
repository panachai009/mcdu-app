// lib/features/mcdu_core/engine/mcdu_page_engine.dart
// Independent Page Engine managing demo pages, navigation transitions, and PREV/NEXT history.
import '../domain/mcdu_page.dart';

class MCDUPageEngine {
  // Catalog of standard demo pages
  static final Map<String, MCDUPage> catalog = {
    'MENU': const MCDUPage(
      pageId: 'MENU',
      title: 'MCDU MENU',
      leftLabels: ['<FPL', '<DIR', '<PROG', '<GAMES', '<REALISTIC', ''],
      rightLabels: ['NAV>', 'RADIO>', 'DATA>', '', '', ''],
      lines: ['MCDU DEMO MENU'],
      scratchpadVisible: true,
    ),
    'GAME': const MCDUPage(
      pageId: 'GAME',
      title: 'MCDU GAME MENU',
      leftLabels: ['<TYPING TEST', '<FALLING CODE', '<MEMORY', '<SPEED RUN', '<MCDU FLOW', '<RETURN'],
      rightLabels: ['', '', '', '', '', ''],
      lines: ['SELECT GAME MODE'],
      scratchpadVisible: false,
    ),
    'FPL': const MCDUPage(
      pageId: 'FPL',
      title: 'MCDU FPL',
      leftLabels: ['1L', '2L', '3L', '4L', '5L', '<MENU'],
      rightLabels: ['1R', '2R', '3R', '4R', '5R', 'SEC>'],
      lines: ['FPL PAGE', 'DEMO ONLY'],
      scratchpadVisible: true,
    ),
    'DIR': const MCDUPage(
      pageId: 'DIR',
      title: 'MCDU DIR',
      leftLabels: ['1L', '2L', '3L', '4L', '5L', '<MENU'],
      rightLabels: ['1R', '2R', '3R', '4R', '5R', ''],
      lines: ['DIR TO PAGE', 'DEMO ONLY'],
      scratchpadVisible: true,
    ),
    'PROG': const MCDUPage(
      pageId: 'PROG',
      title: 'MCDU PROG',
      leftLabels: ['1L', '2L', '3L', '4L', '5L', '<MENU'],
      rightLabels: ['1R', '2R', '3R', '4R', '5R', ''],
      lines: ['PROGRESS PAGE', 'DEMO ONLY'],
      scratchpadVisible: true,
    ),
    'NAV': const MCDUPage(
      pageId: 'NAV',
      title: 'MCDU NAV',
      leftLabels: ['1L', '2L', '3L', '4L', '5L', '<MENU'],
      rightLabels: ['1R', '2R', '3R', '4R', '5R', ''],
      lines: ['NAV PAGE', 'DEMO ONLY'],
      scratchpadVisible: true,
    ),
    'RADIO': const MCDUPage(
      pageId: 'RADIO',
      title: 'MCDU RADIO',
      leftLabels: ['1L', '2L', '3L', '4L', '5L', '<MENU'],
      rightLabels: ['1R', '2R', '3R', '4R', '5R', ''],
      lines: ['RADIO TUNING', 'DEMO ONLY'],
      scratchpadVisible: true,
    ),
    'DATA': const MCDUPage(
      pageId: 'DATA',
      title: 'MCDU DATA',
      leftLabels: ['1L', '2L', '3L', '4L', '5L', '<MENU'],
      rightLabels: ['1R', '2R', '3R', '4R', '5R', ''],
      lines: ['DATA INDEX', 'DEMO ONLY'],
      scratchpadVisible: true,
    ),
    'REALISTIC': const MCDUPage(
      pageId: 'REALISTIC',
      title: 'REALISTIC MCDU',
      leftLabels: ['', '', '', '', '', '<MENU'],
      rightLabels: ['', '', '', '', '', ''],
      lines: [
        'AW139 FMS SIMULATION',
        'PLACEHOLDER MODE',
        'READY FOR PHASE 19C',
      ],
      scratchpadVisible: true,
    ),
  };

  MCDUPage _currentPage;
  final List<MCDUPage> _backHistory = [];
  final List<MCDUPage> _forwardHistory = [];

  MCDUPageEngine({MCDUPage? initialPage})
      : _currentPage = initialPage ?? catalog['MENU']!;

  /// Current page active in the engine.
  MCDUPage get currentPage => _currentPage;

  /// Whether backward history exists.
  bool get canGoBack => _backHistory.isNotEmpty;

  /// Whether forward history exists.
  bool get canGoForward => _forwardHistory.isNotEmpty;

  /// Directly navigates to a specific pageId, updating back history and clearing forward history.
  bool navigateTo(String pageId) {
    final targetPage = catalog[pageId];
    if (targetPage == null || targetPage.pageId == _currentPage.pageId) {
      return false;
    }
    _backHistory.add(_currentPage);
    _forwardHistory.clear();
    _currentPage = targetPage;
    return true;
  }

  /// Sets a modified copy of the current page (e.g. after an LSK transfer on that page).
  void updateCurrentPage(MCDUPage updatedPage) {
    _currentPage = updatedPage;
  }

  /// Go back to previous page in history.
  bool goBack() {
    if (_backHistory.isEmpty) return false;
    _forwardHistory.add(_currentPage);
    _currentPage = _backHistory.removeLast();
    return true;
  }

  /// Go forward to next page in history.
  bool goForward() {
    if (_forwardHistory.isEmpty) return false;
    _backHistory.add(_currentPage);
    _currentPage = _forwardHistory.removeLast();
    return true;
  }

  /// Checks if a key event triggers a page navigation action.
  /// Returns target pageId if navigation occurred, or null if key does not navigate.
  String? handleNavigationKey(String keyId) {
    // 1. Dedicated Hardware Function Keys for Direct Navigation
    if (keyId == 'MENU') {
      if (navigateTo('MENU')) return 'MENU';
      return null;
    }
    if (keyId == 'FPL') {
      if (navigateTo('FPL')) return 'FPL';
      return null;
    }
    if (keyId == 'DIR') {
      if (navigateTo('DIR')) return 'DIR';
      return null;
    }
    if (keyId == 'PROG') {
      if (navigateTo('PROG')) return 'PROG';
      return null;
    }
    if (keyId == 'NAV') {
      if (navigateTo('NAV')) return 'NAV';
      return null;
    }
    if (keyId == 'RADIO') {
      if (navigateTo('RADIO')) return 'RADIO';
      return null;
    }

    // 2. PREV and NEXT History Keys
    if (keyId == 'PREV') {
      if (goBack()) return _currentPage.pageId;
      return null;
    }
    if (keyId == 'NEXT') {
      if (goForward()) return _currentPage.pageId;
      return null;
    }

    // 3. LSK Navigation Rules based on Current Page
    if (_currentPage.pageId == 'MENU') {
      switch (keyId) {
        case '1L':
          if (navigateTo('FPL')) return 'FPL';
          break;
        case '2L':
          if (navigateTo('DIR')) return 'DIR';
          break;
        case '3L':
          if (navigateTo('PROG')) return 'PROG';
          break;
        case '4L':
          if (navigateTo('GAME')) return 'GAME';
          break;
        case '5L':
          if (navigateTo('REALISTIC')) return 'REALISTIC';
          break;
        case '1R':
          if (navigateTo('NAV')) return 'NAV';
          break;
        case '2R':
          if (navigateTo('RADIO')) return 'RADIO';
          break;
        case '3R':
          if (navigateTo('DATA')) return 'DATA';
          break;
      }
    } else {
      // On subpages, 6L is `<MENU` return shortcut
      if (keyId == '6L') {
        if (navigateTo('MENU')) return 'MENU';
      }
    }

    return null;
  }
}
