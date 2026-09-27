// lib/features/game/speed_run/presentation/speed_run_display_view.dart
// Presentation display view for Speed Run, strictly contained within the MCDU aperture.

import 'package:flutter/material.dart';
import '../domain/speed_run_session.dart';
import 'speed_run_controller.dart';

class SpeedRunDisplayView extends StatelessWidget {
  final SpeedRunController controller;
  final double width;
  final double height;

  const SpeedRunDisplayView({
    super.key,
    required this.controller,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SpeedRunSession>(
      stream: controller.changes,
      initialData: controller.session,
      builder: (context, snapshot) {
        final session = snapshot.data ?? controller.session;
        final hudFontSize = (height * 0.035).clamp(8.0, 13.5);
        final baseFontSize = (height * 0.038).clamp(9.0, 16.0);

        final currentTaskNumber = (session.currentTaskIndex + 1)
            .clamp(1, session.tasks.isEmpty ? 1 : session.tasks.length)
            .toString()
            .padLeft(2, '0');
        final totalTasksNumber = (session.tasks.isEmpty ? 1 : session.tasks.length)
            .toString()
            .padLeft(2, '0');

        return Container(
          width: width,
          height: height,
          color: Colors.black,
          child: ClipRect(
            child: Stack(
              children: [
                // 1. Top HUD Area
                Positioned(
                  top: height * 0.015,
                  left: width * 0.03,
                  right: width * 0.03,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'LV ${session.difficultyLevel.toString().padLeft(2, '0')} ',
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: hudFontSize,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text(
                                'TASK $currentTaskNumber/$totalTasksNumber',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: hudFontSize,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'TIME ${_formatDuration(session.totalEffectiveTime)}',
                            style: TextStyle(
                              color: (session.isPlaying &&
                                      session.currentTask != null &&
                                      session.totalEffectiveTime > session.currentTask!.parTime)
                                  ? Colors.amberAccent
                                  : Colors.greenAccent,
                              fontSize: hudFontSize,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: height * 0.005),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PAR ${_formatDuration(session.currentTask?.parTime ?? Duration.zero)}',
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontSize: hudFontSize,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (session.combo > 0)
                            Text(
                              'x${session.combo}',
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: hudFontSize,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            )
                          else if (session.errors > 0)
                            Text(
                              'E:${session.errors}',
                              style: TextStyle(
                                color: Colors.redAccent,
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
                      Container(height: 0.8, color: Colors.white24),
                    ],
                  ),
                ),

                // 2. Center Content Area (Playing Flow)
                if (session.isPlaying)
                  Positioned(
                    top: height * 0.20,
                    left: width * 0.03,
                    right: width * 0.03,
                    bottom: height * 0.12,
                    child: ClipRect(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Task Title
                          Text(
                            session.currentTask?.title ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontSize: baseFontSize * 1.1,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: height * 0.02),

                          // Step Flow Representation
                          _buildStepFlow(session, baseFontSize),

                          SizedBox(height: height * 0.02),

                          // Active Step Prompt
                          Text(
                            session.currentStep?.prompt ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: baseFontSize * 0.9,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          SizedBox(height: height * 0.015),

                          // Scratchpad Line
                          _buildScratchpadLine(session, baseFontSize),
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
                          fontSize: baseFontSize,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        session.isReady
                            ? 'START>'
                            : session.isPaused
                                ? 'RESUME>'
                                : session.isCompleted
                                    ? 'RETRY>'
                                    : 'PAUSE>',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: baseFontSize,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Overlay: READY
                if (session.isReady)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.88),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'SPEED RUN\nPROCEDURAL FLOW',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: baseFontSize * 1.2,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                letterSpacing: 1.5,
                              ),
                            ),
                            SizedBox(height: height * 0.03),
                            Text(
                              '${session.tasks.length} FLIGHT TASKS\n\nPRESS START TO BEGIN',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: baseFontSize * 0.95,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 5. Overlay: PAUSED
                if (session.isPaused)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.88),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'PAUSED',
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontSize: baseFontSize * 1.4,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                letterSpacing: 2.0,
                              ),
                            ),
                            SizedBox(height: height * 0.02),
                            Text(
                              'TASK ${(session.currentTaskIndex + 1).toString().padLeft(2, '0')}/${session.tasks.length.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: baseFontSize,
                                fontFamily: 'monospace',
                              ),
                            ),
                            SizedBox(height: height * 0.01),
                            Text(
                              'TIME: ${_formatDuration(session.totalEffectiveTime)}',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: baseFontSize,
                                fontFamily: 'monospace',
                              ),
                            ),
                            SizedBox(height: height * 0.01),
                            Text(
                              'SCORE: ${session.score.toString().padLeft(6, '0')}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: baseFontSize,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 6. Overlay: COMPLETED
                if (session.isCompleted)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.92),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'SPEED RUN COMPLETE',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: baseFontSize * 1.3,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                letterSpacing: 1.5,
                              ),
                            ),
                            SizedBox(height: height * 0.015),
                            Text(
                              'LV ${session.difficultyLevel.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontSize: baseFontSize * 1.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            SizedBox(height: height * 0.008),
                            Text(
                              'TASKS: ${session.completedTasks}/${session.tasks.length}',
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: baseFontSize * 0.95,
                                fontFamily: 'monospace',
                              ),
                            ),
                            SizedBox(height: height * 0.008),
                            Text(
                              'TIME: ${_formatDuration(session.totalEffectiveTime)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: baseFontSize * 0.95,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            SizedBox(height: height * 0.008),
                            Text(
                              'ERRORS: ${session.errors.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: session.errors > 0 ? Colors.redAccent : Colors.cyanAccent,
                                fontSize: baseFontSize * 0.95,
                                fontFamily: 'monospace',
                              ),
                            ),
                            SizedBox(height: height * 0.008),
                            Text(
                              'SCORE: ${session.score.toString().padLeft(6, '0')}',
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontSize: baseFontSize * 1.05,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
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

  Widget _buildStepFlow(SpeedRunSession session, double fontSize) {
    final task = session.currentTask;
    if (task == null) return const SizedBox.shrink();

    final children = <Widget>[];
    for (int i = 0; i < task.steps.length; i++) {
      final step = task.steps[i];
      final isDone = i < session.currentStepIndex;
      final isActive = i == session.currentStepIndex;

      final label = step.expectedKeyId;
      children.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.cyanAccent.withValues(alpha: 0.2)
                : isDone
                    ? Colors.greenAccent.withValues(alpha: 0.15)
                    : Colors.transparent,
            border: Border.all(
              color: isActive
                  ? Colors.cyanAccent
                  : isDone
                      ? Colors.greenAccent.withValues(alpha: 0.7)
                      : Colors.white24,
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive
                  ? Colors.cyanAccent
                  : isDone
                      ? Colors.greenAccent
                      : Colors.white54,
              fontSize: fontSize * 0.8,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
      );

      if (i < task.steps.length - 1) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              '>',
              style: TextStyle(
                color: Colors.white24,
                fontSize: fontSize * 0.75,
                fontFamily: 'monospace',
              ),
            ),
          ),
        );
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildScratchpadLine(SpeedRunSession session, double fontSize) {
    final buffer = session.scratchpadBuffer;
    final padded = buffer.padRight(12, '_');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white24, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SP: ',
            style: TextStyle(
              color: Colors.white38,
              fontSize: fontSize * 0.8,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            '[ $padded ]',
            style: TextStyle(
              color: buffer.isNotEmpty ? Colors.greenAccent : Colors.white38,
              fontSize: fontSize * 0.9,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final tenths = ((duration.inMilliseconds % 1000) ~/ 100).toString();
    return '$minutes:$seconds.$tenths';
  }
}
