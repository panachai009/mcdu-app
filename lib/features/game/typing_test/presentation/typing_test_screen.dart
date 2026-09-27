// lib/features/game/typing_test/presentation/typing_test_screen.dart
// Presentation screen integrating MCDU UI with TypingTestEngine, including UI ticker for running time.

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../mcdu_core/domain/mcdu_state.dart';
import '../../../mcdu_core/engine/mcdu_input_engine.dart';
import '../../../mcdu_core/presentation/mcdu_keypad_overlay.dart';
import '../../../mcdu_core/presentation/mcdu_screen.dart';
import '../domain/typing_test_prompt.dart';
import '../domain/typing_test_prompts.dart';
import '../engine/typing_test_engine.dart';
import 'typing_test_status_panel.dart';

class TypingTestScreen extends StatefulWidget {
  final TypingTestPrompt? initialPrompt;
  final TypingTestEngine? typingEngine;
  final MCDUInputEngine? inputEngine;

  const TypingTestScreen({
    super.key,
    this.initialPrompt,
    this.typingEngine,
    this.inputEngine,
  });

  @override
  State<TypingTestScreen> createState() => _TypingTestScreenState();
}

class _TypingTestScreenState extends State<TypingTestScreen> {
  late final TypingTestEngine _typingEngine;
  late final MCDUInputEngine _inputEngine;
  bool _ownsTypingEngine = false;
  bool _ownsInputEngine = false;
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    final prompt = widget.initialPrompt ?? TypingTestPrompts.abc123;

    if (widget.typingEngine != null) {
      _typingEngine = widget.typingEngine!;
      _ownsTypingEngine = false;
    } else {
      _typingEngine = TypingTestEngine(prompt: prompt);
      _ownsTypingEngine = true;
    }

    if (widget.inputEngine != null) {
      _inputEngine = widget.inputEngine!;
      _ownsInputEngine = false;
    } else {
      _inputEngine = MCDUInputEngine(initialState: MCDUState.initial());
      _ownsInputEngine = true;
    }

    _typingEngine.sessionStream.listen((session) {
      if (session.isPlaying && _uiTimer == null) {
        _startUiTicker();
      } else if (!session.isPlaying && _uiTimer != null) {
        _stopUiTicker();
      }
      if (mounted) setState(() {});
    });
  }

  void _startUiTicker() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted && _typingEngine.session.isPlaying) {
        setState(() {});
      }
    });
  }

  void _stopUiTicker() {
    _uiTimer?.cancel();
    _uiTimer = null;
  }

  @override
  void dispose() {
    _stopUiTicker();
    if (_ownsTypingEngine) {
      _typingEngine.dispose();
    }
    if (_ownsInputEngine) {
      _inputEngine.dispose();
    }
    super.dispose();
  }

  void _handleKeyInput(MCDUKeyEvent event) {
    _typingEngine.handleKeyEvent(event);
  }

  void _handleStart() {
    _typingEngine.start();
    _startUiTicker();
  }

  void _handleReset() {
    _stopUiTicker();
    _typingEngine.reset();
    _inputEngine.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;

            if (isLandscape) {
              // Landscape layout: 50/50 proportion with scrollable panel
              return Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 707 / 961,
                        child: MCDUScreen(
                          inputEngine: _inputEngine,
                          onKeyInput: _handleKeyInput,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Center(
                        child: SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: TypingTestStatusPanel(
                              session: _typingEngine.session,
                              onStart: _handleStart,
                              onReset: _handleReset,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // Portrait layout: Status panel on top, MCDU frame below
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: TypingTestStatusPanel(
                        session: _typingEngine.session,
                        onStart: _handleStart,
                        onReset: _handleReset,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 707 / 961,
                        child: MCDUScreen(
                          inputEngine: _inputEngine,
                          onKeyInput: _handleKeyInput,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
