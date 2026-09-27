// lib/features/game/speed_run/domain/speed_run_tasks_catalog.dart
// Static immutable catalog of supported procedural Speed Run tasks.

import 'speed_run_step.dart';
import 'speed_run_task.dart';

class SpeedRunTasksCatalog {
  const SpeedRunTasksCatalog._();

  /// Task 1: Direct To Waypoint (DIR -> B -> K -> K -> 1L)
  static final SpeedRunTask directToBkk = SpeedRunTask(
    taskId: 'SR-01',
    title: 'DIRECT TO BKK',
    category: 'NAVIGATION',
    parTime: const Duration(seconds: 4),
    steps: const [
      SpeedRunStep(stepId: 's1', prompt: 'OPEN DIR PAGE', expectedKeyId: 'DIR'),
      SpeedRunStep(stepId: 's2', prompt: 'TYPE B', expectedKeyId: 'B', isScratchpadChar: true),
      SpeedRunStep(stepId: 's3', prompt: 'TYPE K', expectedKeyId: 'K', isScratchpadChar: true),
      SpeedRunStep(stepId: 's4', prompt: 'TYPE K', expectedKeyId: 'K', isScratchpadChar: true),
      SpeedRunStep(stepId: 's5', prompt: 'INSERT AT 1L', expectedKeyId: '1L', targetFieldLabel: 'DIR TO'),
    ],
  );

  /// Task 2: Flight Number Entry (FPL -> T -> H -> A -> 1L)
  static final SpeedRunTask flightIdTha = SpeedRunTask(
    taskId: 'SR-02',
    title: 'FLIGHT ID THA',
    category: 'FLIGHT PLAN',
    parTime: const Duration(milliseconds: 3500),
    steps: const [
      SpeedRunStep(stepId: 's1', prompt: 'OPEN FPL PAGE', expectedKeyId: 'FPL'),
      SpeedRunStep(stepId: 's2', prompt: 'TYPE T', expectedKeyId: 'T', isScratchpadChar: true),
      SpeedRunStep(stepId: 's3', prompt: 'TYPE H', expectedKeyId: 'H', isScratchpadChar: true),
      SpeedRunStep(stepId: 's4', prompt: 'TYPE A', expectedKeyId: 'A', isScratchpadChar: true),
      SpeedRunStep(stepId: 's5', prompt: 'INSERT AT 1L', expectedKeyId: '1L', targetFieldLabel: 'FLT NBR'),
    ],
  );

  /// Task 3: Radio Tuning (RADIO -> 1 -> 1 -> 8 -> DOT -> 1 -> 2L)
  static final SpeedRunTask radioCom1 = SpeedRunTask(
    taskId: 'SR-03',
    title: 'TOWER COM 118.1',
    category: 'COMMUNICATION',
    parTime: const Duration(seconds: 5),
    steps: const [
      SpeedRunStep(stepId: 's1', prompt: 'OPEN RADIO PAGE', expectedKeyId: 'RADIO'),
      SpeedRunStep(stepId: 's2', prompt: 'TYPE 1', expectedKeyId: '1', isScratchpadChar: true),
      SpeedRunStep(stepId: 's3', prompt: 'TYPE 1', expectedKeyId: '1', isScratchpadChar: true),
      SpeedRunStep(stepId: 's4', prompt: 'TYPE 8', expectedKeyId: '8', isScratchpadChar: true),
      SpeedRunStep(stepId: 's5', prompt: 'TYPE .', expectedKeyId: 'DOT', isScratchpadChar: true),
      SpeedRunStep(stepId: 's6', prompt: 'TYPE 1', expectedKeyId: '1', isScratchpadChar: true),
      SpeedRunStep(stepId: 's7', prompt: 'INSERT STANDBY 2L', expectedKeyId: '2L', targetFieldLabel: 'STBY'),
    ],
  );

  /// Task 4: Cruise Altitude (PROG -> 3 -> 5 -> 0 -> 1R)
  static final SpeedRunTask crzAltFl350 = SpeedRunTask(
    taskId: 'SR-04',
    title: 'CRZ ALT FL350',
    category: 'PERFORMANCE',
    parTime: const Duration(seconds: 4),
    steps: const [
      SpeedRunStep(stepId: 's1', prompt: 'OPEN PROG PAGE', expectedKeyId: 'PROG'),
      SpeedRunStep(stepId: 's2', prompt: 'TYPE 3', expectedKeyId: '3', isScratchpadChar: true),
      SpeedRunStep(stepId: 's3', prompt: 'TYPE 5', expectedKeyId: '5', isScratchpadChar: true),
      SpeedRunStep(stepId: 's4', prompt: 'TYPE 0', expectedKeyId: '0', isScratchpadChar: true),
      SpeedRunStep(stepId: 's5', prompt: 'INSERT CRZ 1R', expectedKeyId: '1R', targetFieldLabel: 'CRZ ALT'),
    ],
  );

  /// Task 5: NAV Fix Check (NAV -> V -> O -> R -> 1L)
  static final SpeedRunTask navVorCheck = SpeedRunTask(
    taskId: 'SR-05',
    title: 'NAV VOR IDENT',
    category: 'NAVIGATION',
    parTime: const Duration(milliseconds: 3500),
    steps: const [
      SpeedRunStep(stepId: 's1', prompt: 'OPEN NAV PAGE', expectedKeyId: 'NAV'),
      SpeedRunStep(stepId: 's2', prompt: 'TYPE V', expectedKeyId: 'V', isScratchpadChar: true),
      SpeedRunStep(stepId: 's3', prompt: 'TYPE O', expectedKeyId: 'O', isScratchpadChar: true),
      SpeedRunStep(stepId: 's4', prompt: 'TYPE R', expectedKeyId: 'R', isScratchpadChar: true),
      SpeedRunStep(stepId: 's5', prompt: 'CHECK VOR 1L', expectedKeyId: '1L', targetFieldLabel: 'VOR IDENT'),
    ],
  );

  /// Standard default task sequence for Speed Run session (5 curated tasks)
  static final List<SpeedRunTask> defaultTasks = [
    directToBkk,
    flightIdTha,
    radioCom1,
    crzAltFl350,
    navVorCheck,
  ];
}
