// lib/features/game/typing_test/presentation/typing_test_status_panel.dart
// Status panel widget for Typing Test showing prompt, targets, typed text, live time, accuracy, score, and completion results.

import 'package:flutter/material.dart';
import '../../domain/game_state.dart';
import '../domain/typing_test_session.dart';

class TypingTestStatusPanel extends StatelessWidget {
  final TypingTestSession session;
  final VoidCallback onStart;
  final VoidCallback onReset;

  const TypingTestStatusPanel({
    super.key,
    required this.session,
    required this.onStart,
    required this.onReset,
  });

  /// Format duration as SS.CC (e.g. 04.82s)
  String _formatTime(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hundredths = (duration.inMilliseconds % 1000) ~/ 10;
    final secondsStr = totalSeconds.toString().padLeft(2, '0');
    final hundredthsStr = hundredths.toString().padLeft(2, '0');
    return '$secondsStr.${hundredthsStr}s';
  }

  @override
  Widget build(BuildContext context) {
    // State display mapping
    String stateLabel;
    Color stateColor;

    switch (session.state) {
      case GameState.idle:
        stateLabel = 'READY';
        stateColor = Colors.grey;
        break;
      case GameState.playing:
        stateLabel = 'PLAYING';
        stateColor = Colors.cyanAccent;
        break;
      case GameState.completed:
        stateLabel = 'COMPLETE';
        stateColor = Colors.greenAccent;
        break;
    }

    final targetText = session.prompt.targetText;
    final typedText = session.typedText;
    final progressFraction = session.progress;
    final progressPercent = (progressFraction * 100).toInt();
    final accuracyStr = '${session.accuracy.toStringAsFixed(1)}%';
    final timeStr = _formatTime(session.elapsedTime);

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header / Title & State Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TYPING TEST',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: stateColor.withValues(alpha: 0.6)),
                ),
                child: Text(
                  stateLabel,
                  style: TextStyle(
                    color: stateColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Completion Result Banner when COMPLETE
          if (session.isCompleted) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.6)),
              ),
              child: Column(
                children: [
                  const Text(
                    'TEST COMPLETE',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'SCORE: ',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${session.score}',
                        key: const Key('completion_score_display'),
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Prompt Name
          Text(
            'Prompt: ${session.prompt.promptId.toUpperCase()}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),

          // Target Display
          Row(
            children: [
              const Text(
                'Target: ',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              Text(
                targetText,
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Typed Display
          Row(
            children: [
              const Text(
                'Typed:  ',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              Text(
                typedText.isEmpty ? '-' : typedText,
                key: const Key('typed_text_display'),
                style: TextStyle(
                  color: typedText.isEmpty ? Colors.white30 : Colors.greenAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Progress', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  Text('$progressPercent%', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: 5,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Metrics row 1: TIME & ACCURACY
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('Time', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  Text(
                    timeStr,
                    key: const Key('timer_display'),
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text('Accuracy', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  Text(
                    accuracyStr,
                    key: const Key('accuracy_display'),
                    style: const TextStyle(
                      color: Colors.purpleAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Metrics row 2: Correct and Errors
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('Correct', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  Text(
                    '${session.correctCount}',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text('Errors', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  Text(
                    '${session.errorCount}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Action Buttons: START / RESTART / RESET
          Row(
            children: [
              if (session.isIdle)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('START', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                )
              else if (session.isCompleted)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.replay, size: 16),
                    label: const Text('RESTART', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                )
              else
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('START', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white30,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('RESET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
