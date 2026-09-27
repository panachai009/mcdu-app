// lib/features/game/typing_test/domain/typing_test_prompts.dart
// Catalog of predefined Typing Test prompts.

import 'typing_test_prompt.dart';

class TypingTestPrompts {
  static const TypingTestPrompt abc123 = TypingTestPrompt(
    promptId: 'abc123',
    targetText: 'ABC123',
  );

  static const TypingTestPrompt mod1l = TypingTestPrompt(
    promptId: 'mod1l',
    targetText: 'MOD1L',
  );

  static const TypingTestPrompt fpl = TypingTestPrompt(
    promptId: 'fpl',
    targetText: 'FPL',
  );

  static const TypingTestPrompt dir = TypingTestPrompt(
    promptId: 'dir',
    targetText: 'DIR',
  );

  static const TypingTestPrompt nav = TypingTestPrompt(
    promptId: 'nav',
    targetText: 'NAV',
  );

  static const List<TypingTestPrompt> all = [
    abc123,
    mod1l,
    fpl,
    dir,
    nav,
  ];

  static TypingTestPrompt? findById(String promptId) {
    for (final prompt in all) {
      if (prompt.promptId == promptId) {
        return prompt;
      }
    }
    return null;
  }
}
