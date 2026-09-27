import 'dart:async';
import 'package:flutter/material.dart';
import '../../game/falling_code/presentation/falling_code_controller.dart';
import '../../game/falling_code/presentation/falling_code_display_view.dart';
import '../../game/mcdu_game/typing_test_mcdu_adapter.dart';
import '../../game/memory/presentation/memory_controller.dart';
import '../../game/memory/presentation/memory_display_view.dart';
import '../../game/speed_run/presentation/speed_run_controller.dart';
import '../../game/speed_run/presentation/speed_run_display_view.dart';
import '../../game/typing_test/domain/typing_test_prompts.dart';
import '../../game/typing_test/engine/typing_test_engine.dart';
import '../../simulation/flt_plan/domain/flt_plan_create_state.dart';
import '../../simulation/flt_plan/domain/flt_plan_list_state.dart';
import '../../simulation/flt_plan/domain/flt_plan_state.dart';
import '../../simulation/flt_plan/domain/stored_flt_plan.dart';
import '../../simulation/flt_plan/engine/flt_plan_create_engine.dart';
import '../../simulation/flt_plan/engine/flt_plan_engine.dart';
import '../../simulation/flt_plan/engine/flt_plan_list_engine.dart';
import '../../simulation/flt_plan/presentation/active_flt_plan_display_adapter.dart';
import '../../simulation/flt_plan/presentation/flt_plan_select_display_adapter.dart';
import '../../simulation/flt_plan/presentation/fpl_create_display_adapter.dart';
import '../../simulation/flt_plan/presentation/fpl_list_display_adapter.dart';
import '../../simulation/flt_plan/presentation/fpl_show_display_adapter.dart';
import '../../simulation/nav/domain/nav_state.dart';
import '../../simulation/nav/engine/nav_engine.dart';
import '../../simulation/nav/presentation/nav_display_adapter.dart';
import '../../simulation/pos_init/domain/pos_init_state.dart';
import '../../simulation/pos_init/engine/pos_init_engine.dart';
import '../../simulation/pos_init/presentation/pos_init_display_adapter.dart';
import '../../simulation/radio/domain/radio_state.dart';
import '../../simulation/radio/engine/radio_engine.dart';
import '../../simulation/radio/presentation/radio_display_adapter.dart';
import '../domain/mcdu_operating_mode.dart';
import '../domain/mcdu_state.dart';
import '../engine/mcdu_input_engine.dart';
import 'mcdu_keypad_overlay.dart';

class MCDUScreen extends StatefulWidget {
  final MCDUState? initialState;
  final MCDUInputEngine? inputEngine;
  final ValueChanged<MCDUKeyEvent>? onKeyInput;

  const MCDUScreen({
    super.key,
    this.initialState,
    this.inputEngine,
    this.onKeyInput,
  });

  @override
  State<MCDUScreen> createState() => MCDUScreenState();
}

class MCDUScreenState extends State<MCDUScreen> with TickerProviderStateMixin {
  late final MCDUInputEngine _engine;
  bool _ownsEngine = false;

  // Operating mode (realistic vs game)
  MCDUOperatingMode _operatingMode = MCDUOperatingMode.realistic;
  MCDUOperatingMode get operatingMode => _operatingMode;

  // Active game mode state (within game operating mode)
  String? _activeGameMode; // null = game menu / idle, 'typing_test', 'falling_code', etc.
  String? get activeGameMode => _activeGameMode;
  TypingTestEngine? _typingEngine;
  Timer? _gameUiTimer;
  StreamSubscription? _typingSubscription;
  String? _gameLastKeyId;

  // Falling Code state
  FallingCodeController? _fallingCodeController;
  StreamSubscription? _fallingCodeSubscription;

  // Memory Game state
  MemoryController? _memoryController;
  StreamSubscription? _memorySubscription;

  // Speed Run state
  SpeedRunController? _speedRunController;
  StreamSubscription? _speedRunSubscription;

  // Realistic Radio Simulation state
  final RadioEngine _radioEngine = const RadioEngine();
  RadioState _radioState = RadioState.initial();

  // Realistic NAV & POS INIT Simulation state
  final NavEngine _navEngine = const NavEngine();
  NavState _navState = NavState.initial();
  final PosInitEngine _posInitEngine = const PosInitEngine();
  PosInitState _posInitState = PosInitState.initial();
  bool _isPosInitActive = false;

  // Realistic ACTIVE FLT PLAN Simulation state
  final FltPlanEngine _fltPlanEngine = const FltPlanEngine();
  FltPlanState _fltPlanState = FltPlanState.initial();

  // Realistic FPL LIST Simulation state
  final FltPlanListEngine _fltPlanListEngine = const FltPlanListEngine();
  FltPlanListState _fltPlanListState = FltPlanListState.initial();
  bool _isFplListActive = false;

  // Realistic FLT PLAN SELECT & CONFIRMATION Subsystem state (AW139 manual p46-48)
  bool _isFplSelectActive = false;
  bool _isFplConfirmActive = false;
  String? _selectedFplPlanName;
  bool _pendingInvertActivation = false;

  // Realistic SHOW FPL & DELETE mode state (AW139 manual p42-45)
  bool _isFplShowActive = false;
  bool _isFplDeleteMode = false;

  // Realistic CREATE STORED FLIGHT PLAN state (AW139 manual p41-44 Procedure 6-1)
  FltPlanCreateState? _createState;
  bool _isFplCreateActive = false;

  // Scratchpad override for special non-alphanumeric tokens (e.g. *DELETE*)
  String? _scratchpadOverride;

  String get _effectiveScratchpad =>
      _scratchpadOverride ?? _engine.state.scratchpad.replaceAll('±', '-');

  @visibleForTesting
  void loadStoredPlansForTesting(List<StoredFltPlan> plans) {
    _fltPlanListState = _fltPlanListEngine.loadPlans(_fltPlanListState, plans);
    if (mounted) setState(() {});
  }

  @visibleForTesting
  void setFltPlanStateForTesting(FltPlanState state) {
    _fltPlanState = state;
    if (mounted) setState(() {});
  }

  @visibleForTesting
  FltPlanState get fltPlanStateForTesting => _fltPlanState;

  @visibleForTesting
  List<StoredFltPlan> get storedPlansForTesting => _fltPlanListState.plans;

  @visibleForTesting
  String get currentScratchpad => _effectiveScratchpad;

  @visibleForTesting
  bool get isFplCreateActiveForTesting => _isFplCreateActive;

  @visibleForTesting
  FltPlanCreateState? get fltPlanCreateStateForTesting => _createState;

  @visibleForTesting
  void setScratchpadForTesting(String text) {
    _setMCDUScratchpad(text);
    if (mounted) setState(() {});
  }


  @override
  void initState() {
    super.initState();
    if (widget.inputEngine != null) {
      _engine = widget.inputEngine!;
      _ownsEngine = false;
    } else {
      _engine = MCDUInputEngine(initialState: widget.initialState);
      _ownsEngine = true;
    }

    _engine.stateStream.listen((state) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _startTypingGame() {
    _stopGameUiTimer();
    _typingSubscription?.cancel();
    _typingEngine?.dispose();

    _typingEngine = TypingTestEngine(prompt: TypingTestPrompts.abc123);
    _operatingMode = MCDUOperatingMode.game;
    _activeGameMode = 'typing_test';
    _gameLastKeyId = '1L';

    _typingSubscription = _typingEngine!.sessionStream.listen((session) {
      if (session.isPlaying && _gameUiTimer == null) {
        _startGameUiTimer();
      } else if (!session.isPlaying && _gameUiTimer != null) {
        _stopGameUiTimer();
      }
      if (mounted) setState(() {});
    });

    setState(() {});
  }

  void _startFallingCodeGame() {
    _stopGameUiTimer();
    _typingSubscription?.cancel();
    _typingEngine?.dispose();
    _typingEngine = null;

    _fallingCodeSubscription?.cancel();
    _fallingCodeController?.dispose();

    _fallingCodeController = FallingCodeController(vsync: this);
    _operatingMode = MCDUOperatingMode.game;
    _activeGameMode = 'falling_code';
    _gameLastKeyId = '2L';

    _fallingCodeSubscription = _fallingCodeController!.changes.listen((_) {
      if (mounted) setState(() {});
    });

    _fallingCodeController!.startCountdown();
    setState(() {});
  }

  void _startMemoryGame() {
    _stopGameUiTimer();
    _typingSubscription?.cancel();
    _typingEngine?.dispose();
    _typingEngine = null;

    _fallingCodeSubscription?.cancel();
    _fallingCodeController?.dispose();
    _fallingCodeController = null;

    _memorySubscription?.cancel();
    _memoryController?.dispose();

    _memoryController = MemoryController(vsync: this);
    _operatingMode = MCDUOperatingMode.game;
    _activeGameMode = 'memory';
    _gameLastKeyId = '3L';

    _memorySubscription = _memoryController!.changes.listen((_) {
      if (mounted) setState(() {});
    });

    // Game starts in READY state — do NOT call start() here
    setState(() {});
  }

  void _startSpeedRunGame() {
    _stopGameUiTimer();
    _typingSubscription?.cancel();
    _typingEngine?.dispose();
    _typingEngine = null;

    _fallingCodeSubscription?.cancel();
    _fallingCodeController?.dispose();
    _fallingCodeController = null;

    _memorySubscription?.cancel();
    _memoryController?.dispose();
    _memoryController = null;

    _speedRunSubscription?.cancel();
    _speedRunController?.dispose();

    _speedRunController = SpeedRunController(vsync: this);
    _operatingMode = MCDUOperatingMode.game;
    _activeGameMode = 'speed_run';
    _gameLastKeyId = '4L';

    _speedRunSubscription = _speedRunController!.changes.listen((_) {
      if (mounted) setState(() {});
    });

    // Speed Run starts in READY state — user presses 6R to start
    setState(() {});
  }

  void _startGameUiTimer() {
    _gameUiTimer?.cancel();
    _gameUiTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted && (_typingEngine?.session.isPlaying ?? false)) {
        setState(() {});
      }
    });
  }

  void _stopGameUiTimer() {
    _gameUiTimer?.cancel();
    _gameUiTimer = null;
  }

  void _exitGameToGameMenu() {
    _stopGameUiTimer();
    _typingSubscription?.cancel();
    _typingSubscription = null;
    _typingEngine?.dispose();
    _typingEngine = null;

    _fallingCodeSubscription?.cancel();
    _fallingCodeSubscription = null;
    _fallingCodeController?.dispose();
    _fallingCodeController = null;

    _memorySubscription?.cancel();
    _memorySubscription = null;
    _memoryController?.dispose();
    _memoryController = null;

    _speedRunSubscription?.cancel();
    _speedRunSubscription = null;
    _speedRunController?.dispose();
    _speedRunController = null;

    _activeGameMode = null;
    _gameLastKeyId = null;
    _operatingMode = MCDUOperatingMode.game;

    // Return to GAME page and ensure scratchpad is clean
    _engine.pageEngine.navigateTo('GAME');
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _stopGameUiTimer();
    _typingSubscription?.cancel();
    _typingEngine?.dispose();
    _fallingCodeSubscription?.cancel();
    _fallingCodeController?.dispose();
    _memorySubscription?.cancel();
    _memoryController?.dispose();
    _speedRunSubscription?.cancel();
    _speedRunController?.dispose();
    if (_ownsEngine) {
      _engine.dispose();
    }
    super.dispose();
  }

  void _handleKeyPressed(MCDUKeyEvent event) {
    // -------------------------------------------------------------
    // Active Falling Code Game Routing
    // -------------------------------------------------------------
    if (_activeGameMode == 'falling_code' && _fallingCodeController != null) {
      _gameLastKeyId = event.keyId;

      // 1. Control Keys: 6L = ABORT
      if (event.keyId == '6L') {
        _exitGameToGameMenu();
        widget.onKeyInput?.call(event);
        return;
      }

      // 2. Control Keys: 6R = PAUSE / RESUME / RETRY
      if (event.keyId == '6R') {
        if (_fallingCodeController!.isGameOver) {
          _fallingCodeController!.retry();
        } else if (_fallingCodeController!.isPaused) {
          _fallingCodeController!.resume();
        } else if (_fallingCodeController!.isPlaying) {
          _fallingCodeController!.pause();
        }
        if (mounted) setState(() {});
        widget.onKeyInput?.call(event);
        return;
      }

      // 3. Gameplay Keys: A-Z, 0-9
      _fallingCodeController!.handleKeyEvent(event);

      if (mounted) setState(() {});
      widget.onKeyInput?.call(event);
      return;
    }

    // -------------------------------------------------------------
    // Active Typing Test Game Routing
    // -------------------------------------------------------------
    if (_activeGameMode == 'typing_test' && _typingEngine != null) {
      _gameLastKeyId = event.keyId;

      // 1. Control Keys: 6L = ABORT
      if (event.keyId == '6L') {
        _exitGameToGameMenu();
        widget.onKeyInput?.call(event);
        return;
      }

      // 2. Control Keys: 6R = RETRY
      if (event.keyId == '6R') {
        _stopGameUiTimer();
        _typingEngine!.reset();
        if (mounted) setState(() {});
        widget.onKeyInput?.call(event);
        return;
      }

      // 3. Game Start trigger: If idle, first printable/input key starts game
      if (_typingEngine!.session.isIdle) {
        _typingEngine!.start();
        _startGameUiTimer();
      }

      // 4. Pass key to TypingTestEngine
      _typingEngine!.handleKeyEvent(event);

      if (mounted) setState(() {});
      widget.onKeyInput?.call(event);
      return;
    }

    // -------------------------------------------------------------
    // Active Memory Game Routing
    // -------------------------------------------------------------
    if (_activeGameMode == 'memory' && _memoryController != null) {
      _gameLastKeyId = event.keyId;

      // 1. Control Keys: 6L = ABORT
      if (event.keyId == '6L') {
        _exitGameToGameMenu();
        widget.onKeyInput?.call(event);
        return;
      }

      // 2. Control Keys: 6R = START / PAUSE / RESUME / RESET
      if (event.keyId == '6R') {
        if (_memoryController!.isReady) {
          _memoryController!.start();
        } else if (_memoryController!.isMemorizing || _memoryController!.isRecalling) {
          _memoryController!.pause();
        } else if (_memoryController!.isPaused) {
          _memoryController!.resume();
        } else if (_memoryController!.isGameOver || _memoryController!.isCompleted) {
          _memoryController!.reset();
        }
        if (mounted) setState(() {});
        widget.onKeyInput?.call(event);
        return;
      }

      // 3. Gameplay Keys: A-Z, 0-9 → MemoryController
      _memoryController!.handleKeyEvent(event);

      // 4. All other keys (MENU, FPL, DIR, PREV, NEXT, etc.) are consumed/blocked
      if (mounted) setState(() {});
      widget.onKeyInput?.call(event);
      return;
    }

    // -------------------------------------------------------------
    // Active Speed Run Game Routing
    // -------------------------------------------------------------
    if (_activeGameMode == 'speed_run' && _speedRunController != null) {
      _gameLastKeyId = event.keyId;

      // 1. Control Keys: 6L = ABORT
      if (event.keyId == '6L') {
        _exitGameToGameMenu();
        widget.onKeyInput?.call(event);
        return;
      }

      // 2. Control Keys: 6R = START / PAUSE / RESUME / RESET
      if (event.keyId == '6R') {
        if (_speedRunController!.isReady) {
          _speedRunController!.start();
        } else if (_speedRunController!.isPlaying) {
          _speedRunController!.pause();
        } else if (_speedRunController!.isPaused) {
          _speedRunController!.resume();
        } else if (_speedRunController!.isCompleted) {
          _speedRunController!.reset();
        }
        if (mounted) setState(() {});
        widget.onKeyInput?.call(event);
        return;
      }

      // 3. Gameplay Keys: Forward to SpeedRunController
      _speedRunController!.handleKeyEvent(event);

      // 4. All non-gameplay keys (BRT, DIM, etc.) or unconsumed keys are consumed/blocked
      if (mounted) setState(() {});
      widget.onKeyInput?.call(event);
      return;
    }

    // -------------------------------------------------------------
    // Normal MCDU Mode Routing
    // -------------------------------------------------------------
    // If on GAME page and user presses 1L -> Enter Typing Test
    if (_engine.state.currentPageId == 'GAME' && event.keyId == '1L') {
      _startTypingGame();
      widget.onKeyInput?.call(event);
      return;
    }

    // If on GAME page and user presses 2L -> Enter Falling Code
    if (_engine.state.currentPageId == 'GAME' && event.keyId == '2L') {
      _startFallingCodeGame();
      widget.onKeyInput?.call(event);
      return;
    }

    // If on GAME page and user presses 3L -> Enter Memory Game
    if (_engine.state.currentPageId == 'GAME' && event.keyId == '3L') {
      _startMemoryGame();
      widget.onKeyInput?.call(event);
      return;
    }

    // If on GAME page and user presses 4L -> Enter Speed Run
    if (_engine.state.currentPageId == 'GAME' && event.keyId == '4L') {
      _startSpeedRunGame();
      widget.onKeyInput?.call(event);
      return;
    }

    // -------------------------------------------------------------
    // Realistic Radio Subsystem Routing (when on RADIO page)
    // -------------------------------------------------------------
    if (_engine.state.currentPageId == 'RADIO') {
      if (_handleRadioKeyEvent(event)) {
        widget.onKeyInput?.call(event);
        return;
      }
    }

    // -------------------------------------------------------------
    // Realistic NAV & POS INIT Subsystem Routing (when on NAV page)
    // -------------------------------------------------------------
    if (event.keyId == 'NAV') {
      _navState = _navEngine.openNav(_navState).state;
      _isPosInitActive = false;
      _engine.handleKeyEvent(event);
      _operatingMode = MCDUOperatingMode.realistic;
      if (mounted) setState(() {});
      widget.onKeyInput?.call(event);
      return;
    }

    if (_engine.state.currentPageId == 'NAV') {
      if (_isPosInitActive) {
        if (_handlePosInitKeyEvent(event)) {
          widget.onKeyInput?.call(event);
          return;
        }
      } else {
        if (_handleNavKeyEvent(event)) {
          widget.onKeyInput?.call(event);
          return;
        }
      }
    }

    // -------------------------------------------------------------
    // Realistic ACTIVE FLT PLAN / FPL LIST Subsystem Routing
    // -------------------------------------------------------------
    if (event.keyId == 'FPL') {
      if (_posInitState.isPositionLoaded &&
          _posInitState.refWptIdent != null &&
          _posInitState.refWptIdent!.isNotEmpty &&
          !_fltPlanState.hasOrigin) {
        _fltPlanState = _fltPlanEngine.initializeOrigin(_fltPlanState, _posInitState.refWptIdent!).state;
      }
      _isPosInitActive = false;
      _isFplListActive = false;
      _isFplSelectActive = false;
      _isFplConfirmActive = false;
      _isFplShowActive = false;
      _isFplDeleteMode = false;
      _isFplCreateActive = false;
      _createState = null;
      _engine.handleKeyEvent(event);
      _operatingMode = MCDUOperatingMode.realistic;
      if (mounted) setState(() {});
      widget.onKeyInput?.call(event);
      return;
    }

    if (_engine.state.currentPageId == 'FPL') {
      if (_isFplConfirmActive) {
        if (_handleFplConfirmKeyEvent(event)) {
          widget.onKeyInput?.call(event);
          return;
        }
      } else if (_isFplShowActive) {
        if (_handleFplShowKeyEvent(event)) {
          widget.onKeyInput?.call(event);
          return;
        }
      } else if (_isFplCreateActive) {
        if (_handleFplCreateKeyEvent(event)) {
          widget.onKeyInput?.call(event);
          return;
        }
      } else if (_isFplSelectActive) {
        if (_handleFplSelectKeyEvent(event)) {
          widget.onKeyInput?.call(event);
          return;
        }
      } else if (_isFplListActive) {
        if (_handleFplListKeyEvent(event)) {
          widget.onKeyInput?.call(event);
          return;
        }
      } else {
        if (_handleFltPlanKeyEvent(event)) {
          widget.onKeyInput?.call(event);
          return;
        }
      }
    }

    if (_scratchpadOverride != null) {
      if (event.keyId == 'CLR') {
        _scratchpadOverride = null;
        if (mounted) setState(() {});
        widget.onKeyInput?.call(event);
        return;
      } else if (RegExp(r'^[A-Z0-9]$').hasMatch(event.keyId) || event.keyId == 'SP' || event.keyId == '.' || event.keyId == '+/-') {
        _scratchpadOverride = null;
      }
    }

    _engine.handleKeyEvent(event);

    // Update operating mode based on active page
    if (_engine.state.currentPageId == 'GAME') {
      _operatingMode = MCDUOperatingMode.game;
    } else {
      _operatingMode = MCDUOperatingMode.realistic;
    }

    widget.onKeyInput?.call(event);
  }



  /// Handles key inputs when active page is RADIO.
  /// Returns true if key was consumed by Radio subsystem, false to pass through to _engine.
  bool _handleRadioKeyEvent(MCDUKeyEvent event) {
    final keyId = event.keyId;

    // 1. PREV / NEXT Sub-Page Navigation
    if (keyId == 'NEXT') {
      if (_radioState.pageIndex == 1) {
        _radioState = _radioEngine.nextPage(_radioState).state;
        if (mounted) setState(() {});
      }
      return true;
    }

    if (keyId == 'PREV') {
      if (_radioState.pageIndex == 2) {
        _radioState = _radioEngine.previousPage(_radioState).state;
        if (mounted) setState(() {});
      }
      return true;
    }

    // 2. LSK Handling based on current sub-page
    final scratch = _engine.state.scratchpad;

    if (_radioState.pageIndex == 1) {
      // 2L: COM1 Standby / Swap
      if (keyId == '2L') {
        if (scratch.isEmpty) {
          _radioState = _radioEngine.swapCom1(_radioState).state;
        } else {
          final res = _radioEngine.tuneCom1Standby(_radioState, scratch);
          if (res.isSuccess) {
            _radioState = res.state;
            _clearMCDUScratchpad();
          } else {
            _setMCDUScratchpad('INVALID ENTRY');
          }
        }
        if (mounted) setState(() {});
        return true;
      }

      // 2R: COM2 Standby / Swap
      if (keyId == '2R') {
        if (scratch.isEmpty) {
          _radioState = _radioEngine.swapCom2(_radioState).state;
        } else {
          final res = _radioEngine.tuneCom2Standby(_radioState, scratch);
          if (res.isSuccess) {
            _radioState = res.state;
            _clearMCDUScratchpad();
          } else {
            _setMCDUScratchpad('INVALID ENTRY');
          }
        }
        if (mounted) setState(() {});
        return true;
      }

      // 4L: NAV1 Standby / Swap
      if (keyId == '4L') {
        if (scratch.isEmpty) {
          _radioState = _radioEngine.swapNav1(_radioState).state;
        } else {
          final res = _radioEngine.tuneNav1Standby(_radioState, scratch);
          if (res.isSuccess) {
            _radioState = res.state;
            _clearMCDUScratchpad();
          } else {
            _setMCDUScratchpad('INVALID ENTRY');
          }
        }
        if (mounted) setState(() {});
        return true;
      }

      // 4R: NAV2 Standby / Swap
      if (keyId == '4R') {
        if (scratch.isEmpty) {
          _radioState = _radioEngine.swapNav2(_radioState).state;
        } else {
          final res = _radioEngine.tuneNav2Standby(_radioState, scratch);
          if (res.isSuccess) {
            _radioState = res.state;
            _clearMCDUScratchpad();
          } else {
            _setMCDUScratchpad('INVALID ENTRY');
          }
        }
        if (mounted) setState(() {});
        return true;
      }

      // 5R: XPDR Code
      if (keyId == '5R') {
        if (scratch.isNotEmpty) {
          final res = _radioEngine.setXpdrCode(_radioState, scratch);
          if (res.isSuccess) {
            _radioState = res.state;
            _clearMCDUScratchpad();
          } else {
            _setMCDUScratchpad('INVALID ENTRY');
          }
        }
        if (mounted) setState(() {});
        return true;
      }

      // 6L: XPDR Mode Toggle (STBY <-> ALT-ON)
      if (keyId == '6L') {
        _radioState = _radioEngine.toggleXpdrMode(_radioState).state;
        if (mounted) setState(() {});
        return true;
      }

      // 6R: IDENT
      if (keyId == '6R') {
        _radioState = _radioEngine.triggerIdent(_radioState).state;
        if (mounted) setState(() {});
        return true;
      }

      // 1L, 1R, 3L, 3R, 5L are display/no-op on page 1
      if (keyId == '1L' || keyId == '1R' || keyId == '3L' || keyId == '3R' || keyId == '5L') {
        return true;
      }
    } else if (_radioState.pageIndex == 2) {
      // 2R: ADF2 Standby / Swap
      if (keyId == '2R') {
        if (scratch.isEmpty) {
          _radioState = _radioEngine.swapAdf2(_radioState).state;
        } else {
          final res = _radioEngine.tuneAdf2Standby(_radioState, scratch);
          if (res.isSuccess) {
            _radioState = res.state;
            _clearMCDUScratchpad();
          } else {
            _setMCDUScratchpad('INVALID ENTRY');
          }
        }
        if (mounted) setState(() {});
        return true;
      }

      // 1R: ADF2 Active display/no-op
      if (keyId == '1R') {
        return true;
      }

      // 6L: Return to MENU
      if (keyId == '6L') {
        _engine.pageEngine.navigateTo('MENU');
        _operatingMode = MCDUOperatingMode.realistic;
        if (mounted) setState(() {});
        return true;
      }

      // Other LSKs on page 2 are no-ops
      if (keyId == '1L' || keyId == '2L' || keyId == '3L' || keyId == '4L' || keyId == '5L' ||
          keyId == '3R' || keyId == '4R' || keyId == '5R' || keyId == '6R') {
        return true;
      }
    }

    return false;
  }

  /// Handles key inputs when active realistic page is NAV (INDEX or IDENT).
  /// Returns true if key was consumed by NAV subsystem, false to pass through.
  bool _handleNavKeyEvent(MCDUKeyEvent event) {
    final keyId = event.keyId;

    // 1. PREV / NEXT Sub-Page Navigation
    if (keyId == 'NEXT') {
      _navState = _navEngine.nextPage(_navState).state;
      if (mounted) setState(() {});
      return true;
    }

    if (keyId == 'PREV') {
      _navState = _navEngine.previousPage(_navState).state;
      if (mounted) setState(() {});
      return true;
    }

    // 1L on NAV INDEX 1/2 navigates to FLIGHT PLAN LIST (AW139 manual p40 Figure 6-1)
    if (keyId == '1L' && _navState.page == NavPage.index1) {
      _engine.handleKeyEvent(MCDUKeyEvent(keyId: 'FPL'));
      _isFplListActive = true;
      _isFplSelectActive = false;
      _isFplConfirmActive = false;
      _operatingMode = MCDUOperatingMode.realistic;
      if (mounted) setState(() {});
      return true;
    }

    // 2. LSK Transitions
    final result = _navEngine.handleLsk(_navState, keyId);
    _navState = result.state;

    if (result.target == NavNavigationTarget.posInit) {
      _isPosInitActive = true;
      if (mounted) setState(() {});
      return true;
    }

    if (result.target == NavNavigationTarget.navIdent || result.target == NavNavigationTarget.navIndex) {
      if (mounted) setState(() {});
      return true;
    }

    // 6L on NAV INDEX pages returns to MENU
    if (keyId == '6L' && (_navState.page == NavPage.index1 || _navState.page == NavPage.index2)) {
      _engine.pageEngine.navigateTo('MENU');
      _operatingMode = MCDUOperatingMode.realistic;
      if (mounted) setState(() {});
      return true;
    }

    // Any other LSK is a no-op within NAV
    if (RegExp(r'^[1-6][LR]$').hasMatch(keyId)) {
      return true;
    }

    return false;
  }

  /// Handles key inputs when active realistic page is POSITION INIT.
  /// Returns true if key was consumed by POS INIT subsystem, false to pass through.
  bool _handlePosInitKeyEvent(MCDUKeyEvent event) {
    final keyId = event.keyId;

    // 1. PREV / NEXT: 1/1 page, no-op
    if (keyId == 'NEXT' || keyId == 'PREV') {
      return true;
    }

    // 2. LSK Actions
    final scratch = _engine.state.scratchpad;

    // 1R: LOAD LAST POS
    if (keyId == '1R') {
      if (scratch.isEmpty) {
        _posInitState = _posInitEngine.loadLastPos(_posInitState).state;
        if (mounted) setState(() {});
      }
      return true;
    }

    // 2R: LOAD REF WPT
    if (keyId == '2R') {
      if (scratch.isEmpty) {
        final res = _posInitEngine.loadRefWptPos(_posInitState);
        if (res.isSuccess) {
          _posInitState = res.state;
        } else {
          _setMCDUScratchpad('INVALID ENTRY');
        }
        if (mounted) setState(() {});
      }
      return true;
    }

    // 3R: LOAD GPS 1 POS
    if (keyId == '3R') {
      if (scratch.isEmpty) {
        _posInitState = _posInitEngine.loadGpsPos(_posInitState).state;
        if (mounted) setState(() {});
      }
      return true;
    }

    // 6L: POS SENSORS display-only prompt in this phase
    if (keyId == '6L') {
      return true;
    }

    // 6R: FLT PLAN► (navigate to ACTIVE FLT PLAN when position loaded)
    if (keyId == '6R') {
      if (_posInitState.isPositionLoaded) {
        if (_posInitState.refWptIdent != null && _posInitState.refWptIdent!.isNotEmpty) {
          _fltPlanState = _fltPlanEngine.initializeOrigin(_fltPlanState, _posInitState.refWptIdent!).state;
        }
        _isPosInitActive = false;
        _engine.handleKeyEvent(MCDUKeyEvent(keyId: 'FPL'));
        _operatingMode = MCDUOperatingMode.realistic;
        if (mounted) setState(() {});
      }
      return true;
    }

    // 1L, 2L, 3L, 4L, 5L, 4R, 5R: Display-only rows on 1/1
    if (keyId == '1L' || keyId == '2L' || keyId == '3L' || keyId == '4L' || keyId == '5L' ||
        keyId == '4R' || keyId == '5R') {
      return true;
    }

    return false;
  }

  /// Handles key inputs when active realistic page is ACTIVE FLT PLAN.
  /// Returns true if key was consumed by FPL subsystem, false to pass through.
  bool _handleFltPlanKeyEvent(MCDUKeyEvent event) {
    final keyId = event.keyId;

    // 0. DEL Key Handling (AW139 manual p13):
    // Pushing DEL populates *DELETE* in the scratchpad.
    if (keyId == 'DEL') {
      _setMCDUScratchpad('*DELETE*');
      if (mounted) setState(() {});
      return true;
    }

    // 1. PREV / NEXT: navigates pages within totalPages
    if (keyId == 'NEXT') {
      _fltPlanState = _fltPlanEngine.nextPage(_fltPlanState);
      if (mounted) setState(() {});
      return true;
    }
    if (keyId == 'PREV') {
      _fltPlanState = _fltPlanEngine.previousPage(_fltPlanState);
      if (mounted) setState(() {});
      return true;
    }

    // 2. LSK Actions
    final rawScratch = _effectiveScratchpad.trim();
    final scratch = rawScratch;

    // 1R: Destination Entry / Update
    if (keyId == '1R') {
      if (scratch.isNotEmpty && scratch != '*DELETE*') {
        final res = _fltPlanEngine.setDestination(_fltPlanState, scratch);
        if (res.isSuccess) {
          _fltPlanState = res.state;
          _clearMCDUScratchpad();
        } else {
          _setMCDUScratchpad('INVALID ENTRY');
        }
        if (mounted) setState(() {});
      }
      return true;
    }

    // 6L: Return to MENU (or DEPARTURE / FPL LIST prompt)
    if (keyId == '6L') {
      if (_fltPlanState.page == FltPlanPage.init) {
        // Navigate to FPL LIST (◄FPL LIST prompt on 1/1)
        _isFplListActive = true;
        if (mounted) setState(() {});
        return true;
      }
      // On 1/2, 6L is ◄DEPARTURE (deferred/unimplemented sub-function)
      return true;
    }

    // 5R: SAVE ACTIVE FLT PLAN TO ---------- (AW139 manual p76-77, ACTIVE FLT PLAN 1/2)
    if (keyId == '5R' && _fltPlanState.page == FltPlanPage.route) {
      if (scratch.isEmpty || scratch == '*DELETE*') {
        _setMCDUScratchpad('INVALID ENTRY');
      } else {
        final planId = 'plan-${DateTime.now().millisecondsSinceEpoch}';
        final newPlan = _fltPlanEngine.createStoredPlanFromActiveState(
          state: _fltPlanState,
          name: scratch,
          id: planId,
        );

        if (newPlan != null) {
          _fltPlanListState = _fltPlanListEngine.addPlan(_fltPlanListState, newPlan);
          _clearMCDUScratchpad();
        } else {
          _setMCDUScratchpad('INVALID ENTRY');
        }
      }
      if (mounted) setState(() {});
      return true;
    }

    // 6R: PERF INIT► display-only prompt in this phase
    if (keyId == '6R') {
      return true;
    }

    // 3. Route LSKs: 2L, 3L, 4L, 5L on populated route page
    final routeMatch = RegExp(r'^([2-5])L$').firstMatch(keyId);
    if (routeMatch != null && _fltPlanState.page == FltPlanPage.route) {
      final slotIndex = int.parse(routeMatch.group(1)!) - 2; // 2L -> 0, 3L -> 1, 4L -> 2, 5L -> 3

      // Case A: Deletion via *DELETE*
      if (scratch == '*DELETE*') {
        if (slotIndex < _fltPlanState.legs.length) {
          final res = _fltPlanEngine.deleteWaypoint(_fltPlanState, slotIndex);
          if (res.isSuccess) {
            _fltPlanState = res.state;
            _clearMCDUScratchpad();
          } else {
            _setMCDUScratchpad('INVALID ENTRY');
          }
        } else {
          _setMCDUScratchpad('INVALID ENTRY');
        }
        if (mounted) setState(() {});
        return true;
      }

      // Case B: Waypoint entry/insertion from scratchpad
      if (scratch.isNotEmpty) {
        if (slotIndex >= _fltPlanState.legs.length) {
          // Append to end of route
          final res = _fltPlanEngine.addWaypoint(_fltPlanState, scratch);
          if (res.isSuccess) {
            _fltPlanState = res.state;
            _clearMCDUScratchpad();
          } else {
            _setMCDUScratchpad('INVALID ENTRY');
          }
        } else {
          // Insert at slot index
          final res = _fltPlanEngine.insertWaypoint(_fltPlanState, slotIndex, scratch);
          if (res.isSuccess) {
            _fltPlanState = res.state;
            _clearMCDUScratchpad();
          } else {
            _setMCDUScratchpad('INVALID ENTRY');
          }
        }
        if (mounted) setState(() {});
        return true;
      }
    }

    // Display-only LSKs
    if (RegExp(r'^[1-6][LR]$').hasMatch(keyId)) {
      return true;
    }

    return false;
  }

  /// Handles key inputs when active realistic page is FPL LIST.
  /// Returns true if key was consumed by FPL LIST subsystem, false to pass through.
  bool _handleFplListKeyEvent(MCDUKeyEvent event) {
    final keyId = event.keyId;

    // 0. DEL Key Handling (AW139 manual p45 Procedure 6-2):
    // "Push DEL key. DEL is displayed in the scratchpad."
    // Toggle/arm deletion mode on FPL LIST
    if (keyId == 'DEL') {
      _isFplDeleteMode = true;
      _setMCDUScratchpad('DEL');
      if (mounted) setState(() {});
      return true;
    }

    // CLR key clears delete mode if armed
    if (keyId == 'CLR') {
      _isFplDeleteMode = false;
      _clearMCDUScratchpad();
      if (mounted) setState(() {});
      return true;
    }

    // 1. Return prompt: 6L (◄FPL) returns to ACTIVE FLT PLAN
    if (keyId == '6L') {
      _isFplDeleteMode = false;
      _isFplListActive = false;
      if (mounted) setState(() {});
      return true;
    }

    // 2. Hardware PREV / NEXT keys: navigate through plans via engine
    if (keyId == 'NEXT') {
      _fltPlanListState = _fltPlanListEngine.next(_fltPlanListState);
      if (mounted) setState(() {});
      return true;
    }
    if (keyId == 'PREV') {
      _fltPlanListState = _fltPlanListEngine.previous(_fltPlanListState);
      if (mounted) setState(() {});
      return true;
    }

    // 3. Selection / Deletion LSKs: 1L - 5L
    final match = RegExp(r'^([1-5])L$').firstMatch(keyId);
    if (match != null) {
      final index = int.parse(match.group(1)!) - 1;

      // If DELETE mode is active (AW139 manual p45 Procedure 6-2 Step 2):
      // "Push adjacent LSK (1L–5L). The flight plan is deleted from the database."
      if (_isFplDeleteMode) {
        if (index >= 0 && index < _fltPlanListState.plans.length) {
          final planToDelete = _fltPlanListState.plans[index];
          _fltPlanListState = _fltPlanListEngine.deletePlanById(_fltPlanListState, planToDelete.id);
          _isFplDeleteMode = false;
          _clearMCDUScratchpad();
        }
        if (mounted) setState(() {});
        return true;
      }

      // Normal selection / CREATE on 1L (Procedure 6-1 Steps 2-3):
      // If 1L is pressed and scratchpad has text entered by user (not just auto-filled from previously selecting a plan):
      final rawScratch = _engine.state.scratchpad.trim();
      final scratch = rawScratch.replaceAll('±', '-');
      final isScratchpadAutofilledSelection = _selectedFplPlanName != null &&
          _selectedFplPlanName!.toUpperCase() == scratch.toUpperCase();
      if (keyId == '1L' && scratch.isNotEmpty && !isScratchpadAutofilledSelection) {
        final normalizedName = scratch.toUpperCase();
        final existingPlanIndex = _fltPlanListState.plans.indexWhere((p) => p.name.toUpperCase() == normalizedName);
        if (existingPlanIndex != -1) {
          // Existing plan: SHOW FPL review flow
          _fltPlanListState = _fltPlanListEngine.selectIndex(_fltPlanListState, existingPlanIndex);
          _selectedFplPlanName = _fltPlanListState.plans[existingPlanIndex].name;
          _isFplListActive = false;
          _isFplShowActive = true;
          _isFplSelectActive = false;
          _isFplConfirmActive = false;
          _isFplCreateActive = false;
        } else {
          // New plan: initiate CREATE workflow
          final createResult = FltPlanCreateEngine.createInitialState(scratch);
          if (createResult.isSuccess) {
            _createState = createResult.state;
            _isFplCreateActive = true;
            _isFplListActive = false;
            _isFplShowActive = false;
            _isFplSelectActive = false;
            _isFplConfirmActive = false;
            _clearMCDUScratchpad();
          } else {
            _setMCDUScratchpad('INVALID ENTRY');
          }
        }
        if (mounted) setState(() {});
        return true;
      }

      // Normal selection:
      _fltPlanListState = _fltPlanListEngine.selectIndex(_fltPlanListState, index);
      if (index >= 0 && index < _fltPlanListState.plans.length) {
        final plan = _fltPlanListState.plans[index];
        _selectedFplPlanName = plan.name;
        // AW139 manual p46 Procedure 6-3 Step 2:
        // "The name is displayed in the scratchpad."
        _setMCDUScratchpad(plan.name);
      }
      if (mounted) setState(() {});
      return true;
    }

    // 4. 1R: SHOW FPL► (AW139 manual p41 Figure 6-3, p42 Procedure 6-1)
    if (keyId == '1R') {
      _isFplDeleteMode = false;
      // Enter SHOW FPL review mode if a plan is selected
      if (_fltPlanListState.selectedPlan != null || (_selectedFplPlanName != null && _selectedFplPlanName!.isNotEmpty)) {
        _isFplListActive = false;
        _isFplShowActive = true;
        _isFplSelectActive = false;
        _isFplConfirmActive = false;
        if (mounted) setState(() {});
      }
      return true;
    }

    // 5. 6R: FPL SEL► enters FLT PLAN SELECT 1/1 (AW139 manual p46 Step 3)
    if (keyId == '6R') {
      _isFplDeleteMode = false;
      _isFplListActive = false;
      _isFplSelectActive = true;
      _isFplConfirmActive = false;
      _isFplShowActive = false;
      if (mounted) setState(() {});
      return true;
    }

    // Other LSKs (2R-5R): no-op / consumed
    if (RegExp(r'^[1-6][LR]$').hasMatch(keyId)) {
      return true;
    }

    return false;
  }

  /// Handles key inputs when active realistic page is SHOW FPL (AW139 manual p42-44 Procedure 6-1).
  /// Review-only: MUST NOT activate or mutate FltPlanState or StoredFltPlan.
  bool _handleFplShowKeyEvent(MCDUKeyEvent event) {
    final keyId = event.keyId;

    // 1. 6L: ◄FPL LIST returns to FPL LIST without activating
    if (keyId == '6L') {
      _isFplShowActive = false;
      _isFplListActive = true;
      if (mounted) setState(() {});
      return true;
    }

    // Hardware PREV / NEXT keys: no-op in single review page (or future paging)
    if (keyId == 'NEXT' || keyId == 'PREV') {
      return true;
    }

    // All other LSKs consumed/no-op in review mode
    if (RegExp(r'^[1-6][LR]$').hasMatch(keyId)) {
      return true;
    }

    return false;
  }

  /// Handles key inputs when active realistic page is CREATE STORED FLIGHT PLAN (AW139 manual p43-44 Procedure 6-1, Figure 6-6).
  /// Pure definition workflow: MUST NOT activate or mutate FltPlanState.
  bool _handleFplCreateKeyEvent(MCDUKeyEvent event) {
    if (_createState == null) return false;

    final keyId = event.keyId;
    final scratch = _engine.state.scratchpad.trim();

    // 1. 1L: Origin entry (Procedure 6-1 Step 3)
    if (keyId == '1L') {
      if (scratch.isNotEmpty) {
        final res = FltPlanCreateEngine.setOrigin(_createState!, scratch);
        if (res.isSuccess) {
          _createState = res.state;
          _clearMCDUScratchpad();
        } else {
          _setMCDUScratchpad('INVALID ENTRY');
        }
        if (mounted) setState(() {});
      }
      return true;
    }

    // 2. 1R: Groundspeed entry (Procedure 6-1 Step 5, default 120 kt)
    if (keyId == '1R') {
      if (scratch.isNotEmpty) {
        final res = FltPlanCreateEngine.setGroundspeed(_createState!, scratch);
        if (res.isSuccess) {
          _createState = res.state;
          _clearMCDUScratchpad();
        } else {
          _setMCDUScratchpad('INVALID ENTRY');
        }
        if (mounted) setState(() {});
      }
      return true;
    }

    // 3. 2R: Destination entry / transfer (Procedure 6-1 Step 4 & Step 8)
    if (keyId == '2R') {
      if (scratch.isNotEmpty) {
        // Sets destination IDENT on plan definition
        final res = FltPlanCreateEngine.setDestination(_createState!, scratch);
        if (res.isSuccess) {
          _createState = res.state;
          _clearMCDUScratchpad();
        } else {
          _setMCDUScratchpad('INVALID ENTRY');
        }
      } else {
        // Step 8 right-to-left transfer: line selecting destination from right side of the page into scratchpad
        if (_createState!.destinationIdent != null && _createState!.destinationIdent!.isNotEmpty) {
          _setMCDUScratchpad(_createState!.destinationIdent!);
        }
      }
      if (mounted) setState(() {});
      return true;
    }

    // 4. 2L, 3L, 4L, 5L: Route Waypoint entries (Procedure 6-1 Steps 6-8)
    if (keyId == '2L' || keyId == '3L' || keyId == '4L' || keyId == '5L') {
      if (scratch.isNotEmpty) {
        // Respect existing display model: maximum 4 displayed sequential legs (2L..5L)
        if (_createState!.legs.length >= 4) {
          _setMCDUScratchpad('INVALID ENTRY');
        } else {
          final res = FltPlanCreateEngine.addWaypoint(_createState!, scratch);
          if (res.isSuccess) {
            _createState = res.state;
            _clearMCDUScratchpad();
          } else {
            _setMCDUScratchpad('INVALID ENTRY');
          }
        }
        if (mounted) setState(() {});
      }
      return true;
    }

    // 5. 6L: ◄PATTERN (Figure 6-6 p43) - consumed / no-op in this phase
    if (keyId == '6L') {
      return true;
    }

    // 6. 6R: FPL SEL► (Figure 6-6 p43) - Triggers explicit finalization of completed plan definition
    if (keyId == '6R') {
      final planId = 'plan-${DateTime.now().millisecondsSinceEpoch}';
      final res = FltPlanCreateEngine.finalize(
        _createState!,
        planId: planId,
      );

      if (res.isSuccess && res.finalizedPlan != null) {
        // Add immutable StoredFltPlan to FltPlanListState
        _fltPlanListState = _fltPlanListEngine.addPlan(
          _fltPlanListState,
          res.finalizedPlan!,
        );
        _createState = null;
        _isFplCreateActive = false;
        _isFplListActive = true;
        _clearMCDUScratchpad();
      } else {
        _setMCDUScratchpad('INVALID ENTRY');
      }
      if (mounted) setState(() {});
      return true;
    }

    // Hardware PREV / NEXT keys: no-op in single definition page
    if (keyId == 'NEXT' || keyId == 'PREV') {
      return true;
    }

    // Other LSKs (3R, 4R, 5R) consumed
    if (RegExp(r'^[1-6][LR]$').hasMatch(keyId)) {
      return true;
    }

    return false;
  }

  /// Handles key inputs when active realistic page is FLT PLAN SELECT.
  /// AW139 manual p46-48 (Procedure 6-3, Figures 6-7, 6-8, 6-9)
  bool _handleFplSelectKeyEvent(MCDUKeyEvent event) {
    final keyId = event.keyId;

    // 1. 6L: ◄FPL LIST returns to FLIGHT PLAN LIST (Figure 6-7/6-8)
    if (keyId == '6L') {
      _isFplSelectActive = false;
      _isFplListActive = true;
      _isFplConfirmActive = false;
      if (mounted) setState(() {});
      return true;
    }

    // 2. 1L: FLT PLAN prompt (insert plan name from scratchpad)
    if (keyId == '1L') {
      final scratch = _engine.state.scratchpad.trim();
      if (scratch.isNotEmpty) {
        _selectedFplPlanName = scratch;
        _fltPlanListState = _fltPlanListEngine.selectById(_fltPlanListState, scratch);
        if (_fltPlanListState.selectedPlan == null) {
          final foundIdx = _fltPlanListState.plans.indexWhere((p) => p.name.toUpperCase() == scratch.toUpperCase());
          if (foundIdx != -1) {
            _fltPlanListState = _fltPlanListEngine.selectIndex(_fltPlanListState, foundIdx);
          }
        }
        if (mounted) setState(() {});
      }
      return true;
    }

    // 3. 1R: ACTIVATE►
    if (keyId == '1R') {
      _initiateFplActivation(invert: false);
      return true;
    }

    // 4. 2R: INVERT/ACTIVATE►
    if (keyId == '2R') {
      _initiateFplActivation(invert: true);
      return true;
    }

    // Other LSKs consumed
    if (RegExp(r'^[1-6][LR]$').hasMatch(keyId)) {
      return true;
    }

    return false;
  }

  /// Initiates activation of the selected plan.
  /// If active flight plan already exists, shows confirmation screen.
  void _initiateFplActivation({required bool invert}) {
    StoredFltPlan? planToActivate = _fltPlanListState.selectedPlan;
    if (planToActivate == null && _selectedFplPlanName != null && _selectedFplPlanName!.isNotEmpty) {
      final name = _selectedFplPlanName!.toUpperCase();
      final idx = _fltPlanListState.plans.indexWhere((p) => p.name.toUpperCase() == name);
      if (idx != -1) {
        planToActivate = _fltPlanListState.plans[idx];
      }
    }

    if (planToActivate == null) {
      // No valid plan selected: deterministic no-op
      return;
    }

    _pendingInvertActivation = invert;

    // Check if active flight plan already exists (AW139 manual p48 Step 6)
    final bool hasExistingActiveFpl = _fltPlanState.isRouteActive ||
        (_fltPlanState.originIdent != null && _fltPlanState.originIdent!.isNotEmpty && _fltPlanState.destinationIdent != null && _fltPlanState.destinationIdent!.isNotEmpty);

    if (hasExistingActiveFpl) {
      // Enter confirmation page (Figure 6-9)
      _isFplConfirmActive = true;
      if (mounted) setState(() {});
    } else {
      // Immediate activation without confirmation
      _commitFplActivation(planToActivate, invert: invert);
    }
  }

  /// Commits activation of a stored flight plan into _fltPlanState.
  void _commitFplActivation(StoredFltPlan plan, {required bool invert}) {
    final res = _fltPlanEngine.activatePlan(_fltPlanState, plan, invert: invert);
    if (res.isSuccess) {
      _fltPlanState = res.state;
      _isFplConfirmActive = false;
      _isFplSelectActive = false;
      _isFplListActive = false;
      if (mounted) setState(() {});
    }
  }

  /// Handles key inputs on CONFIRM REPLACING ACTIVE FLIGHT PLAN page.
  /// AW139 manual p48 Figure 6-9: 6L ◄NO, 6R YES►
  bool _handleFplConfirmKeyEvent(MCDUKeyEvent event) {
    final keyId = event.keyId;

    // 6L: ◄NO - cancels replacement, returns to FLT PLAN SELECT without mutating active plan
    if (keyId == '6L') {
      _isFplConfirmActive = false;
      _isFplSelectActive = true;
      if (mounted) setState(() {});
      return true;
    }

    // 6R: YES► - commits replacement and navigates to ACTIVE FLT PLAN
    if (keyId == '6R') {
      StoredFltPlan? planToActivate = _fltPlanListState.selectedPlan;
      if (planToActivate == null && _selectedFplPlanName != null && _selectedFplPlanName!.isNotEmpty) {
        final name = _selectedFplPlanName!.toUpperCase();
        final idx = _fltPlanListState.plans.indexWhere((p) => p.name.toUpperCase() == name);
        if (idx != -1) {
          planToActivate = _fltPlanListState.plans[idx];
        }
      }

      if (planToActivate != null) {
        _commitFplActivation(planToActivate, invert: _pendingInvertActivation);
      } else {
        _isFplConfirmActive = false;
        _isFplSelectActive = true;
        if (mounted) setState(() {});
      }
      return true;
    }

    // Other LSKs consumed
    if (RegExp(r'^[1-6][LR]$').hasMatch(keyId)) {
      return true;
    }

    return false;
  }

  void _clearMCDUScratchpad() {
    _scratchpadOverride = null;
    _engine.handleKeyEvent(MCDUKeyEvent(keyId: 'CLR'));
    while (_engine.state.scratchpad.isNotEmpty) {
      _engine.handleKeyEvent(MCDUKeyEvent(keyId: 'CLR'));
    }
  }

  void _setMCDUScratchpad(String text) {
    _clearMCDUScratchpad();
    if (text.contains('*')) {
      _scratchpadOverride = text;
      return;
    }
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == ' ') {
        _engine.handleKeyEvent(MCDUKeyEvent(keyId: 'SP'));
      } else if (char == '-') {
        // Alphanumeric keypad mapping for dash/hyphen (+/- key)
        _engine.handleKeyEvent(MCDUKeyEvent(keyId: '+/-'));
      } else {
        _engine.handleKeyEvent(MCDUKeyEvent(keyId: char.toUpperCase()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _activeGameMode == 'typing_test' && _typingEngine != null
        ? TypingTestMCDUAdapter.toMCDUState(_typingEngine!.session, lastKeyId: _gameLastKeyId)
        : _engine.state.currentPageId == 'RADIO'
            ? RadioDisplayAdapter.toMCDUState(
                _radioState,
                scratchpad: _engine.state.scratchpad,
                lastKeyId: _engine.lastKeyId,
                lastAction: _engine.lastAction,
              )
            : _engine.state.currentPageId == 'NAV'
                ? (_isPosInitActive
                    ? PosInitDisplayAdapter.toMCDUState(
                        _posInitState,
                        scratchpad: _engine.state.scratchpad,
                        lastKeyId: _engine.lastKeyId,
                        lastAction: _engine.lastAction,
                      )
                    : NavDisplayAdapter.toMCDUState(
                        _navState,
                        scratchpad: _engine.state.scratchpad,
                        lastKeyId: _engine.lastKeyId,
                        lastAction: _engine.lastAction,
                      ))
            : _engine.state.currentPageId == 'FPL'
                ? (_isFplConfirmActive
                    ? FltPlanSelectDisplayAdapter.toConfirmMCDUState(
                        scratchpad: _effectiveScratchpad,
                        lastKeyId: _engine.lastKeyId,
                        lastAction: _engine.lastAction,
                      )
                    : _isFplShowActive
                        ? (_fltPlanListState.selectedPlan != null
                            ? FplShowDisplayAdapter.toMCDUState(
                                _fltPlanListState.selectedPlan!,
                                scratchpad: _effectiveScratchpad,
                                lastKeyId: _engine.lastKeyId,
                                lastAction: _engine.lastAction,
                              )
                            : FplListDisplayAdapter.toMCDUState(
                                _fltPlanListState,
                                scratchpad: _effectiveScratchpad,
                                lastKeyId: _engine.lastKeyId,
                                lastAction: _engine.lastAction,
                              ))
                        : (_isFplCreateActive && _createState != null)
                            ? FplCreateDisplayAdapter.toMCDUState(
                                _createState!,
                                scratchpad: _effectiveScratchpad,
                                lastKeyId: _engine.lastKeyId,
                                lastAction: _engine.lastAction,
                              )
                            : _isFplSelectActive
                                ? FltPlanSelectDisplayAdapter.toSelectMCDUState(
                                    _fltPlanListState,
                                    fallbackPlanName: _selectedFplPlanName,
                                    scratchpad: _effectiveScratchpad,
                                    lastKeyId: _engine.lastKeyId,
                                    lastAction: _engine.lastAction,
                                  )
                            : _isFplListActive
                                ? FplListDisplayAdapter.toMCDUState(
                                    _fltPlanListState,
                                    scratchpad: _effectiveScratchpad,
                                    lastKeyId: _engine.lastKeyId,
                                    lastAction: _engine.lastAction,
                                  )
                                : ActiveFltPlanDisplayAdapter.toMCDUState(
                                    _fltPlanState,
                                    scratchpad: _effectiveScratchpad,
                                    lastKeyId: _engine.lastKeyId,
                                    lastAction: _engine.lastAction,
                                  ))
                : _engine.state.copyWith(scratchpad: _effectiveScratchpad);
    final displayLastKeyId = _activeGameMode != null ? _gameLastKeyId : _engine.lastKeyId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: AspectRatio(
                // Preserves strictly the original image aspect ratio (707:961)
                aspectRatio: 707 / 961,
                child: LayoutBuilder(
                  builder: (context, frameConstraints) {
                    final frameWidth = frameConstraints.maxWidth;
                    final frameHeight = frameConstraints.maxHeight;

                    // Display screen boundaries
                    final screenLeft = frameWidth * 0.175;
                    final screenTop = frameHeight * 0.088;
                    final screenWidth = frameWidth * 0.650;
                    final screenHeight = frameHeight * 0.405;

                    return Stack(
                      children: [
                        // Layer 1: Visual Base MCDU Frame Image
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/MCDU UI.jpg',
                            fit: BoxFit.contain,
                          ),
                        ),

                        // Layer 2: Dynamic Display Layer
                        Positioned(
                          left: screenLeft,
                          top: screenTop,
                          width: screenWidth,
                          height: screenHeight,
                          child: _activeGameMode == 'falling_code' && _fallingCodeController != null
                              ? FallingCodeDisplayView(
                                  controller: _fallingCodeController!,
                                  width: screenWidth,
                                  height: screenHeight,
                                )
                              : _activeGameMode == 'memory' && _memoryController != null
                                  ? MemoryDisplayView(
                                      controller: _memoryController!,
                                      width: screenWidth,
                                      height: screenHeight,
                                    )
                              : _activeGameMode == 'speed_run' && _speedRunController != null
                                  ? SpeedRunDisplayView(
                                      controller: _speedRunController!,
                                      width: screenWidth,
                                      height: screenHeight,
                                    )
                                  : _buildDynamicDisplay(state, screenWidth, screenHeight),
                        ),

                        // Layer 3: Interactive Touch Hitbox Layer
                        Positioned.fill(
                          child: MCDUKeypadOverlay(
                            containerWidth: frameWidth,
                            containerHeight: frameHeight,
                            onKeyPressed: _handleKeyPressed,
                          ),
                        ),

                        // Layer 4: Debug Indicator (Displays last key pressed and last action from engine)
                        Positioned(
                          top: 10,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.greenAccent.withValues(alpha: 0.6),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'KEY: ',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                Text(
                                  displayLastKeyId ?? 'NONE',
                                  style: TextStyle(
                                    color: displayLastKeyId != null
                                        ? Colors.greenAccent
                                        : Colors.white38,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the dynamic display content including Page Title, Center Lines, 1L-6L, 1R-6R, and Scratchpad.
  Widget _buildDynamicDisplay(MCDUState state, double width, double height) {
    final titleText = state.title;
    final centerLines = state.lines;
    final fontSize = (height * 0.040).clamp(10.0, 18.0);
    final headerFontSize = (height * 0.048).clamp(11.0, 20.0);
    final scratchpadFontSize = (height * 0.048).clamp(11.0, 20.0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.03,
        vertical: height * 0.03,
      ),
      color: Colors.black,
      child: Column(
        children: [
          // Page Title Header Area
          SizedBox(
            height: height * 0.09,
            child: Center(
              child: Text(
                titleText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: headerFontSize,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 1.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Main Screen Content Area (LSK rows + optional center lines)
          Expanded(
            child: Stack(
              children: [
                // Center / Body Lines (if any)
                if (centerLines.isNotEmpty)
                  Positioned.fill(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: centerLines.map((line) => Text(
                          line,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: fontSize * 0.9,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        )).toList(),
                      ),
                    ),
                  ),

                // LSK Labels Area (6 rows: 1L..6L on left, 1R..6R on right)
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    final leftText = index < state.leftLabels.length ? state.leftLabels[index] : '';
                    final rightText = index < state.rightLabels.length ? state.rightLabels[index] : '';

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left LSK Label
                        Text(
                          leftText,
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                        // Right LSK Label
                        Text(
                          rightText,
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),

          // Scratchpad Area at bottom of display
          Container(
            height: height * 0.11,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: width * 0.02),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 0.8,
                ),
              ),
            ),
            child: Text(
              state.scratchpadVisible ? state.scratchpad : '',
              style: TextStyle(
                color: Colors.amberAccent,
                fontSize: scratchpadFontSize,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
