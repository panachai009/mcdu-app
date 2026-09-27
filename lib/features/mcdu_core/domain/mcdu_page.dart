// lib/features/mcdu_core/domain/mcdu_page.dart
// Immutable model representing a single MCDU page layout and definition.

class MCDUPage {
  final String pageId;
  final String title;
  final List<String> leftLabels; // 6 LSK labels, indexed 0..5 (1L-6L)
  final List<String> rightLabels; // 6 LSK labels, indexed 0..5 (1R-6R)
  final List<String> lines; // Up to 6 center/body display lines
  final bool scratchpadVisible;

  const MCDUPage({
    required this.pageId,
    required this.title,
    this.leftLabels = const ['', '', '', '', '', ''],
    this.rightLabels = const ['', '', '', '', '', ''],
    this.lines = const [],
    this.scratchpadVisible = true,
  });

  MCDUPage copyWith({
    String? pageId,
    String? title,
    List<String>? leftLabels,
    List<String>? rightLabels,
    List<String>? lines,
    bool? scratchpadVisible,
  }) {
    return MCDUPage(
      pageId: pageId ?? this.pageId,
      title: title ?? this.title,
      leftLabels: leftLabels ?? this.leftLabels,
      rightLabels: rightLabels ?? this.rightLabels,
      lines: lines ?? this.lines,
      scratchpadVisible: scratchpadVisible ?? this.scratchpadVisible,
    );
  }
}
