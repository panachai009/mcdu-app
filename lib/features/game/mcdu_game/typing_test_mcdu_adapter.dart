// lib/features/game/mcdu_game/typing_test_mcdu_adapter.dart
// Pure stateless adapter that converts a TypingTestSession into an MCDUState
// for dynamic display rendering inside MCDUScreen.

import '../../mcdu_core/domain/mcdu_page.dart';
import '../../mcdu_core/domain/mcdu_state.dart';
import '../typing_test/domain/typing_test_session.dart';

class TypingTestMCDUAdapter {
  const TypingTestMCDUAdapter();

  /// Maps [TypingTestSession] into an [MCDUState] configured for the MCDU Dynamic Display.
  static MCDUState toMCDUState(TypingTestSession session, {String? lastKeyId}) {
    final isComplete = session.isCompleted;
    final elapsedSec = (session.elapsedTime.inMilliseconds / 1000.0).toStringAsFixed(2);
    final accFormatted = '${session.accuracy.toStringAsFixed(1)}%';

    final title = isComplete ? 'TEST COMPLETE' : 'TYPING TEST';

    // Left and right LSK labels (6 rows: 0..5 for 1L-6L and 1R-6R)
    final leftLabels = List<String>.filled(6, '');
    final rightLabels = List<String>.filled(6, '');

    // 1L: Target display
    leftLabels[0] = '<TARGET ${session.prompt.targetText}';

    // 3L: Elapsed time
    leftLabels[2] = 'TIME $elapsedSec';

    // 4L: Accuracy
    leftLabels[3] = 'ACC $accFormatted';

    // 5L: Score
    leftLabels[4] = 'SCORE ${session.score}';

    // Completion stats on right side
    if (isComplete) {
      rightLabels[2] = 'CORRECT ${session.correctCount}';
      rightLabels[3] = 'ERRORS ${session.errorCount}';
    }

    // 6L: ABORT, 6R: RETRY
    leftLabels[5] = '<ABORT';
    rightLabels[5] = 'RETRY>';

    // Center display lines
    final List<String> centerLines = [];
    if (session.isIdle) {
      centerLines.add('TYPE THE CODE');
    } else if (isComplete) {
      centerLines.add('TEST COMPLETE');
    }

    final page = MCDUPage(
      pageId: 'TYPING_TEST',
      title: title,
      leftLabels: leftLabels,
      rightLabels: rightLabels,
      lines: centerLines,
      scratchpadVisible: true,
    );

    return MCDUState(
      currentPage: page,
      scratchpad: session.typedText,
      lastKeyId: lastKeyId,
      lastAction: isComplete ? 'TYPING_COMPLETE' : 'TYPING_PLAYING',
    );
  }
}
