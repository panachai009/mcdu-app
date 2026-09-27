// lib/features/simulation/radio/engine/radio_engine.dart
// Deterministic state transition engine for MCDU Radio subsystem.

import '../domain/radio_state.dart';

class RadioTuneResult {
  const RadioTuneResult({
    required this.state,
    required this.isSuccess,
    this.errorMessage,
  });

  final RadioState state;
  final bool isSuccess;
  final String? errorMessage;
}

class RadioEngine {
  const RadioEngine();

  // Swapping Active <-> Standby
  RadioTuneResult swapCom1(RadioState state) {
    return RadioTuneResult(
      state: state.copyWith(com1: state.com1.swap()),
      isSuccess: true,
    );
  }

  RadioTuneResult swapCom2(RadioState state) {
    return RadioTuneResult(
      state: state.copyWith(com2: state.com2.swap()),
      isSuccess: true,
    );
  }

  RadioTuneResult swapNav1(RadioState state) {
    return RadioTuneResult(
      state: state.copyWith(nav1: state.nav1.swap()),
      isSuccess: true,
    );
  }

  RadioTuneResult swapNav2(RadioState state) {
    return RadioTuneResult(
      state: state.copyWith(nav2: state.nav2.swap()),
      isSuccess: true,
    );
  }

  RadioTuneResult swapAdf2(RadioState state) {
    return RadioTuneResult(
      state: state.copyWith(adf2: state.adf2.swap()),
      isSuccess: true,
    );
  }

  // Standby Frequency Tuning
  RadioTuneResult tuneCom1Standby(RadioState state, String input) {
    final formatted = _validateAndFormatVhfCom(input);
    if (formatted == null) {
      return RadioTuneResult(
        state: state,
        isSuccess: false,
        errorMessage: 'INVALID ENTRY',
      );
    }
    return RadioTuneResult(
      state: state.copyWith(com1: state.com1.copyWith(standby: formatted)),
      isSuccess: true,
    );
  }

  RadioTuneResult tuneCom2Standby(RadioState state, String input) {
    final formatted = _validateAndFormatVhfCom(input);
    if (formatted == null) {
      return RadioTuneResult(
        state: state,
        isSuccess: false,
        errorMessage: 'INVALID ENTRY',
      );
    }
    return RadioTuneResult(
      state: state.copyWith(com2: state.com2.copyWith(standby: formatted)),
      isSuccess: true,
    );
  }

  RadioTuneResult tuneNav1Standby(RadioState state, String input) {
    final formatted = _validateAndFormatVhfNav(input);
    if (formatted == null) {
      return RadioTuneResult(
        state: state,
        isSuccess: false,
        errorMessage: 'INVALID ENTRY',
      );
    }
    return RadioTuneResult(
      state: state.copyWith(nav1: state.nav1.copyWith(standby: formatted)),
      isSuccess: true,
    );
  }

  RadioTuneResult tuneNav2Standby(RadioState state, String input) {
    final formatted = _validateAndFormatVhfNav(input);
    if (formatted == null) {
      return RadioTuneResult(
        state: state,
        isSuccess: false,
        errorMessage: 'INVALID ENTRY',
      );
    }
    return RadioTuneResult(
      state: state.copyWith(nav2: state.nav2.copyWith(standby: formatted)),
      isSuccess: true,
    );
  }

  RadioTuneResult tuneAdf2Standby(RadioState state, String input) {
    final formatted = _validateAndFormatAdf(input);
    if (formatted == null) {
      return RadioTuneResult(
        state: state,
        isSuccess: false,
        errorMessage: 'INVALID ENTRY',
      );
    }
    return RadioTuneResult(
      state: state.copyWith(adf2: state.adf2.copyWith(standby: formatted)),
      isSuccess: true,
    );
  }

  // Transponder (XPDR)
  RadioTuneResult setXpdrCode(RadioState state, String input) {
    final trimmed = input.trim();
    if (trimmed.length != 4) {
      return RadioTuneResult(
        state: state,
        isSuccess: false,
        errorMessage: 'INVALID ENTRY',
      );
    }

    // Must be octal digits 0 to 7
    for (int i = 0; i < trimmed.length; i++) {
      final char = trimmed[i];
      if (char.compareTo('0') < 0 || char.compareTo('7') > 0) {
        return RadioTuneResult(
          state: state,
          isSuccess: false,
          errorMessage: 'INVALID ENTRY',
        );
      }
    }

    return RadioTuneResult(
      state: state.copyWith(xpdrCode: trimmed),
      isSuccess: true,
    );
  }

  RadioTuneResult toggleXpdrMode(RadioState state) {
    final newMode =
        state.xpdrMode == XpdrMode.stby ? XpdrMode.altOn : XpdrMode.stby;
    return RadioTuneResult(
      state: state.copyWith(xpdrMode: newMode),
      isSuccess: true,
    );
  }

  RadioTuneResult triggerIdent(RadioState state) {
    return RadioTuneResult(
      state: state.copyWith(isIdentActive: true),
      isSuccess: true,
    );
  }

  RadioTuneResult clearIdent(RadioState state) {
    return RadioTuneResult(
      state: state.copyWith(isIdentActive: false),
      isSuccess: true,
    );
  }

  // Paging
  RadioTuneResult nextPage(RadioState state) {
    final next = state.pageIndex == 1 ? 2 : 1;
    return RadioTuneResult(
      state: state.copyWith(pageIndex: next),
      isSuccess: true,
    );
  }

  RadioTuneResult previousPage(RadioState state) {
    final prev = state.pageIndex == 2 ? 1 : 2;
    return RadioTuneResult(
      state: state.copyWith(pageIndex: prev),
      isSuccess: true,
    );
  }

  // Validation & Formatting Helpers

  /// VHF COM: Range 118.000 - 136.975 MHz
  /// Valid spacing: standard 25 kHz / 8.33 kHz channels (3 decimals displayed)
  String? _validateAndFormatVhfCom(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final parts = trimmed.split('.');
    if (parts.length > 2) return null;

    final mhz = int.tryParse(parts[0]);
    if (mhz == null) return null;

    int khz = 0;
    if (parts.length == 2) {
      final fracStr = parts[1];
      if (fracStr.length > 3) return null;
      final parsedFrac = int.tryParse(fracStr);
      if (parsedFrac == null) return null;

      if (fracStr.length == 1) {
        khz = parsedFrac * 100;
      } else if (fracStr.length == 2) {
        khz = parsedFrac * 10;
      } else {
        khz = parsedFrac;
      }
    }

    final totalKhz = (mhz * 1000) + khz;
    if (totalKhz < 118000 || totalKhz > 136975) {
      return null;
    }

    // Format to 3 decimals: e.g. 122.600
    final paddedKhz = (totalKhz % 1000).toString().padLeft(3, '0');
    return '$mhz.$paddedKhz';
  }

  /// VHF NAV: Range 108.00 - 117.95 MHz (50 kHz spacing, 2 decimals displayed)
  String? _validateAndFormatVhfNav(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final parts = trimmed.split('.');
    if (parts.length > 2) return null;

    final mhz = int.tryParse(parts[0]);
    if (mhz == null) return null;

    int hundredths = 0;
    if (parts.length == 2) {
      final fracStr = parts[1];
      if (fracStr.length > 2) return null;
      final parsedFrac = int.tryParse(fracStr);
      if (parsedFrac == null) return null;

      if (fracStr.length == 1) {
        hundredths = parsedFrac * 10;
      } else {
        hundredths = parsedFrac;
      }
    }

    // 50 kHz spacing means hundredths must be multiple of 5 (.00, .05, .10, .15, ..., .95)
    if (hundredths % 5 != 0) {
      return null;
    }

    final totalHundredths = (mhz * 100) + hundredths;
    if (totalHundredths < 10800 || totalHundredths > 11795) {
      return null;
    }

    final paddedHundredths = (hundredths).toString().padLeft(2, '0');
    return '$mhz.$paddedHundredths';
  }

  /// ADF: Range 190.0 - 1799.5 kHz (0.5 kHz spacing, 1 decimal displayed)
  String? _validateAndFormatAdf(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final parts = trimmed.split('.');
    if (parts.length > 2) return null;

    final baseKhz = int.tryParse(parts[0]);
    if (baseKhz == null) return null;

    int tenths = 0;
    if (parts.length == 2) {
      final fracStr = parts[1];
      if (fracStr.length != 1) return null;
      final parsedTenth = int.tryParse(fracStr);
      if (parsedTenth == null) return null;
      tenths = parsedTenth;
    }

    if (tenths != 0 && tenths != 5) {
      return null;
    }

    final totalTenths = (baseKhz * 10) + tenths;
    if (totalTenths < 1900 || totalTenths > 17995) {
      return null;
    }

    return '$baseKhz.$tenths';
  }
}
