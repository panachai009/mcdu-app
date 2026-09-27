import 'package:flutter/material.dart';
import '../domain/falling_code.dart';
import 'falling_code_controller.dart';

class FallingCodeDisplayView extends StatelessWidget {
  final FallingCodeController controller;
  final double width;
  final double height;

  const FallingCodeDisplayView({
    super.key,
    required this.controller,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final session = controller.session;
    final fontSize = (height * 0.038).clamp(9.0, 16.0);
    final hudFontSize = (height * 0.038).clamp(9.0, 15.0);

    // Identify current nearest-to-bottom active target for emphasis
    final active = session.activeCodes.where((c) => c.isActive && c.progress < 1.0).toList();
    FallingCode? nearestTarget;
    if (active.isNotEmpty) {
      active.sort((a, b) => b.progress.compareTo(a.progress));
      nearestTarget = active.first;
    }

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
                  // Thin divider below HUD
                  SizedBox(height: height * 0.006),
                  Container(
                    height: 0.8,
                    color: Colors.white24,
                  ),
                ],
              ),
            ),

            // 2. Danger line (around 76% height) with tactical label
            Positioned(
              left: width * 0.02,
              right: width * 0.02,
              top: height * 0.76,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    color: Colors.redAccent.withValues(alpha: 0.25),
                    child: Text(
                      'LIMIT',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: fontSize * 0.65,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 1.2,
                      color: Colors.redAccent.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Falling Objects Area
            if (controller.isPlaying || controller.isPaused)
              ...session.activeCodes.map((code) => _buildFallingObject(
                    code,
                    fontSize,
                    isTarget: code.id == nearestTarget?.id,
                  )),

            // 4. Target Readout Area (Below danger line)
            Positioned(
              left: width * 0.03,
              right: width * 0.03,
              top: height * 0.78,
              child: _buildTargetReadout(fontSize, nearestTarget),
            ),

            // 5. Bottom Controls (6L / 6R)
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
                    controller.isPaused ? 'RESUME>' : (controller.isGameOver ? 'RETRY>' : 'PAUSE>'),
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

            // 6. Overlay: Ready / Countdown
            if (controller.isReady || controller.isCountingDown)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.88),
                  child: Center(
                    child: _buildCountdownMessage(fontSize),
                  ),
                ),
              ),

            // 7. Overlay: Paused
            if (controller.isPaused)
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
                      ),
                    ),
                  ),
                ),
              ),

            // 8. Overlay: Game Over
            if (controller.isGameOver)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.94),
                  child: Center(
                    child: _buildGameOverScreen(fontSize),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallingObject(FallingCode code, double fontSize, {required bool isTarget}) {
    // Normalized mapping:
    // progress: 0.0 -> displayTop (14% of height)
    // progress: 1.0 -> danger line (72% of height)
    final topBound = height * 0.14;
    final bottomBound = height * 0.72;
    final y = topBound + (code.progress.clamp(0.0, 1.0) * (bottomBound - topBound));

    // Horizontal lane (1..4)
    final lane = controller.getLaneFor(code);
    final laneFractions = [0.08, 0.32, 0.56, 0.78];
    final x = width * laneFractions[(lane - 1).clamp(0, 3)];

    final isDanger = code.progress >= 0.85;

    return Positioned(
      left: x,
      top: y,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          border: isTarget
              ? Border.all(
                  color: isDanger ? Colors.redAccent : Colors.cyanAccent.withValues(alpha: 0.8),
                  width: 1.0,
                )
              : null,
          color: isTarget ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Code with typed / remaining split
            RichText(
              text: TextSpan(
                children: [
                  // Bracket for target indicator
                  if (isTarget)
                    TextSpan(
                      text: '[',
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: fontSize * 1.1,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  // Typed prefix (Phosphor Green)
                  TextSpan(
                    text: code.typedText,
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: fontSize * 1.1,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  // Remaining suffix (White / Red warning)
                  TextSpan(
                    text: code.remainingText,
                    style: TextStyle(
                      color: isDanger ? Colors.redAccent : Colors.white,
                      fontSize: fontSize * 1.1,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (isTarget)
                    TextSpan(
                      text: ']',
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: fontSize * 1.1,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                ],
              ),
            ),
            // Reporting point name subtitle
            if (code.reportingPoint.name.isNotEmpty)
              Text(
                code.reportingPoint.name,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: fontSize * 0.58,
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            // Vector indicator
            Text(
              '|',
              style: TextStyle(
                color: isDanger ? Colors.redAccent : Colors.white24,
                fontSize: fontSize * 0.7,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetReadout(double fontSize, FallingCode? target) {
    if (target == null) {
      return Text(
        'TARGET: NONE',
        style: TextStyle(
          color: Colors.white54,
          fontSize: fontSize * 0.9,
          fontFamily: 'monospace',
        ),
      );
    }

    final isPartiallyTyped = target.typedLength > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'TARGET: ',
              style: TextStyle(
                color: Colors.white70,
                fontSize: fontSize * 0.95,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              target.code,
              style: TextStyle(
                color: Colors.amberAccent,
                fontSize: fontSize * 1.05,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              ' (${target.typedLength}/${target.code.length})',
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: fontSize * 0.9,
                fontFamily: 'monospace',
              ),
            ),
            const Spacer(),
            if (isPartiallyTyped)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                color: Colors.greenAccent.withValues(alpha: 0.2),
                child: Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: fontSize * 0.7,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
          ],
        ),
        if (target.reportingPoint.name.isNotEmpty)
          Text(
            target.reportingPoint.name,
            style: TextStyle(
              color: Colors.cyanAccent.withValues(alpha: 0.7),
              fontSize: fontSize * 0.75,
              fontFamily: 'monospace',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildCountdownMessage(double fontSize) {
    String text;
    Color color = Colors.white;

    switch (controller.countdownState) {
      case CountdownState.ready:
        text = 'FALLING CODE\nTRAINING MODE\n\nGET READY';
        color = Colors.cyanAccent;
        break;
      case CountdownState.count3:
        text = '3';
        color = Colors.amberAccent;
        break;
      case CountdownState.count2:
        text = '2';
        color = Colors.amberAccent;
        break;
      case CountdownState.count1:
        text = '1';
        color = Colors.amberAccent;
        break;
      case CountdownState.go:
        text = 'GO!';
        color = Colors.greenAccent;
        break;
      case CountdownState.finished:
        text = '';
        break;
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontSize: fontSize * 1.5,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildGameOverScreen(double fontSize) {
    final session = controller.session;
    final totalAttempts = session.correctCount + session.errorCount;
    final accuracy = totalAttempts > 0
        ? ((session.correctCount / totalAttempts) * 100.0).toStringAsFixed(1)
        : '100.0';
    final elapsedSec = (session.elapsedTime.inMilliseconds / 1000.0).toStringAsFixed(1);

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
          'ACCURACY: $accuracy%',
          style: TextStyle(
            color: Colors.cyanAccent,
            fontSize: fontSize,
            fontFamily: 'monospace',
          ),
        ),
        SizedBox(height: height * 0.01),
        Text(
          'MAX COMBO: X${session.maxCombo}',
          style: TextStyle(
            color: Colors.amberAccent,
            fontSize: fontSize,
            fontFamily: 'monospace',
          ),
        ),
        SizedBox(height: height * 0.01),
        Text(
          'TIME: ${elapsedSec}s',
          style: TextStyle(
            color: Colors.white70,
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
