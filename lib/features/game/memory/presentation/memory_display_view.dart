// lib/features/game/memory/presentation/memory_display_view.dart

import 'package:flutter/material.dart';
import 'memory_controller.dart';

class MemoryDisplayView extends StatelessWidget {
  final MemoryController controller;
  final double width;
  final double height;

  const MemoryDisplayView({
    super.key,
    required this.controller,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: controller.changes,
      builder: (context, _) {
        final session = controller.session;
        final fontSize = (height * 0.038).clamp(9.0, 16.0);
        final hudFontSize = (height * 0.038).clamp(9.0, 15.0);

        return Container(
          width: width,
          height: height,
          color: Colors.black,
          child: ClipRect(
            child: Stack(
              children: [
            // 1. Top HUD Area (Avionics Header: Row 1 & Row 2)
            Positioned(
              top: height * 0.015,
              left: width * 0.03,
              right: width * 0.03,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LV ${session.level.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: hudFontSize,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        'SCORE ${session.score.toString().padLeft(6, '0')}',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: hudFontSize,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.006),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'COMBO X${session.combo.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: session.combo >= 5 ? Colors.greenAccent : Colors.amberAccent,
                          fontSize: hudFontSize,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        'LIFE ${'O ' * session.lives}'.trim(),
                        style: TextStyle(
                          color: session.lives == 1 ? Colors.redAccent : Colors.cyanAccent,
                          fontSize: hudFontSize,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.006),
                  Container(
                    height: 0.8,
                    color: Colors.white24,
                  ),
                ],
              ),
            ),

            // 2. Main Center Content (Memorizing / Recalling / Feedback)
            if (session.isMemorizing || session.isRecalling)
              Positioned(
                top: height * 0.22,
                left: width * 0.05,
                right: width * 0.05,
                bottom: height * 0.14,
                child: ClipRect(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status Tag
                      Text(
                        session.isMemorizing ? 'MEMORIZE SEQUENCE' : 'RECALL & ENTER',
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          color: session.isMemorizing ? Colors.amberAccent : Colors.cyanAccent,
                          fontSize: fontSize * 0.85,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: height * 0.04),

                      // Sequence Display
                      _buildSequenceDisplay(fontSize),

                      SizedBox(height: height * 0.04),

                      // Progress or Input Indicator
                      if (session.isMemorizing)
                        _buildProgressBar(width, height)
                      else
                        _buildInputProgress(fontSize),
                    ],
                  ),
                ),
              ),

            // 3. Bottom Controls (6L / 6R)
            Positioned(
              left: width * 0.03,
              right: width * 0.03,
              bottom: height * 0.02,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '<ABORT',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    session.isReady
                        ? 'START>'
                        : session.isPaused
                            ? 'RESUME>'
                            : (session.isGameOver || session.isCompleted)
                                ? 'RETRY>'
                                : 'PAUSE>',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            // 4. Overlays: Ready
            if (session.isReady)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.88),
                  child: Center(
                    child: Text(
                      'MEMORY TRAINING\n\nPRESS START TO BEGIN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: fontSize * 1.2,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

            // 5. Overlays: Paused
            if (session.isPaused)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.80),
                  child: Center(
                    child: Text(
                      'PAUSED\n\nPRESS 6R TO RESUME',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontSize: fontSize * 1.2,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

            // 6. Overlays: Game Over
            if (session.isGameOver)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.94),
                  child: Center(
                    child: _buildGameOverScreen(fontSize),
                  ),
                ),
              ),

            // 7. Overlays: Completed (if triggered)
            if (session.isCompleted)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.94),
                  child: Center(
                    child: Text(
                      'COURSE COMPLETED\n\nALL SEQUENCES MASTERED',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: fontSize * 1.2,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildSequenceDisplay(double fontSize) {
    final session = controller.session;
    final target = session.targetSequence;
    final input = session.inputBuffer;

    if (session.isMemorizing) {
      // Show full sequence in crisp Phosphor Green
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.6), width: 1.5),
          color: Colors.greenAccent.withValues(alpha: 0.05),
        ),
        child: Text(
          target,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: TextStyle(
            color: Colors.greenAccent,
            fontSize: fontSize * 1.8,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 4.0,
          ),
        ),
      );
    } else {
      // Recalling: masked display [ V T _ _ ]
      final spans = <TextSpan>[];
      for (int i = 0; i < target.length; i++) {
        if (i < input.length) {
          spans.add(
            TextSpan(
              text: '${input[i]} ',
              style: const TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        } else {
          spans.add(
            const TextSpan(
              text: '_ ',
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6), width: 1.5),
          color: Colors.cyanAccent.withValues(alpha: 0.05),
        ),
        child: RichText(
          maxLines: 1,
          overflow: TextOverflow.clip,
          text: TextSpan(
            style: TextStyle(
              fontSize: fontSize * 1.8,
              fontFamily: 'monospace',
              letterSpacing: 2.0,
            ),
            children: [
              const TextSpan(
                text: '[ ',
                style: TextStyle(color: Colors.cyanAccent),
              ),
              ...spans,
              const TextSpan(
                text: ']',
                style: TextStyle(color: Colors.cyanAccent),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildProgressBar(double width, double height) {
    final progress = controller.presentationProgress;
    final remaining = (1.0 - progress).clamp(0.0, 1.0);

    return Column(
      children: [
        Container(
          width: width * 0.7,
          height: 4.0,
          color: Colors.white24,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: remaining,
            child: Container(
              color: Colors.amberAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputProgress(double fontSize) {
    final session = controller.session;
    return Text(
      'ENTERED: ${session.inputBuffer.length} / ${session.targetSequence.length}',
      style: TextStyle(
        color: Colors.white70,
        fontSize: fontSize * 0.85,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildGameOverScreen(double fontSize) {
    final session = controller.session;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'GAME OVER',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: fontSize * 1.4,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 2.0,
          ),
        ),
        SizedBox(height: height * 0.03),
        Text(
          'FINAL SCORE: ${session.score.toString().padLeft(6, '0')}',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize * 1.1,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        SizedBox(height: height * 0.01),
        Text(
          'LEVEL REACHED: LV ${session.level.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: Colors.cyanAccent,
            fontSize: fontSize,
            fontFamily: 'monospace',
          ),
        ),
        SizedBox(height: height * 0.01),
        Text(
          'ROUNDS CLEARED: ${session.completedRounds}',
          style: TextStyle(
            color: Colors.amberAccent,
            fontSize: fontSize,
            fontFamily: 'monospace',
          ),
        ),
        SizedBox(height: height * 0.03),
        Text(
          '<ABORT       RETRY>',
          style: TextStyle(
            color: Colors.cyanAccent,
            fontSize: fontSize * 0.95,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
