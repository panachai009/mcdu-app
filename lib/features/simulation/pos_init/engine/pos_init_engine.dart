// lib/features/simulation/pos_init/engine/pos_init_engine.dart
// Pure deterministic engine for POSITION INIT 1/1 subsystem.

import '../domain/pos_init_state.dart';

class PosInitResult {
  const PosInitResult({
    required this.state,
    required this.isSuccess,
    this.errorMessage,
  });

  final PosInitState state;
  final bool isSuccess;
  final String? errorMessage;
}

class PosInitEngine {
  const PosInitEngine();

  /// Loads LAST POS into active FMS position (1R).
  PosInitResult loadLastPos(PosInitState state) {
    return PosInitResult(
      state: state.copyWith(
        loadedPosLatLon: state.lastPosLatLon,
        loadedSource: PositionLoadSource.last,
        isPositionLoaded: true,
      ),
      isSuccess: true,
    );
  }

  /// Loads GPS 1 POS into active FMS position (3R).
  PosInitResult loadGpsPos(PosInitState state) {
    return PosInitResult(
      state: state.copyWith(
        loadedPosLatLon: state.gpsPosLatLon,
        loadedSource: PositionLoadSource.gps,
        isPositionLoaded: true,
      ),
      isSuccess: true,
    );
  }

  /// Loads REF WPT into active FMS position (2R).
  PosInitResult loadRefWptPos(PosInitState state) {
    if (state.refWptLatLon == null || state.refWptLatLon!.isEmpty) {
      return PosInitResult(
        state: state,
        isSuccess: false,
        errorMessage: 'INVALID ENTRY',
      );
    }

    return PosInitResult(
      state: state.copyWith(
        loadedPosLatLon: state.refWptLatLon,
        loadedSource: PositionLoadSource.refWpt,
        isPositionLoaded: true,
      ),
      isSuccess: true,
    );
  }

  /// Sets Reference Waypoint with an identifier and resolved coordinate string.
  PosInitResult setRefWpt(
    PosInitState state, {
    required String ident,
    required String latLon,
  }) {
    final cleanIdent = ident.trim().toUpperCase();
    if (!_isValidIdent(cleanIdent)) {
      return PosInitResult(
        state: state,
        isSuccess: false,
        errorMessage: 'INVALID ENTRY',
      );
    }

    final formattedLatLon = validateAndFormatCoordinates(latLon);
    if (formattedLatLon == null) {
      return PosInitResult(
        state: state,
        isSuccess: false,
        errorMessage: 'INVALID ENTRY',
      );
    }

    return PosInitResult(
      state: state.copyWith(
        refWptIdent: cleanIdent,
        refWptLatLon: formattedLatLon,
      ),
      isSuccess: true,
    );
  }

  /// Validates waypoint identifier: 1–5 alphanumeric characters without spaces.
  bool _isValidIdent(String ident) {
    if (ident.isEmpty || ident.length > 5) return false;
    final regex = RegExp(r'^[A-Z0-9]{1,5}$');
    return regex.hasMatch(ident);
  }

  /// Validates and normalizes geographic coordinate string.
  /// Supports:
  /// 1. Canonical display format: "N14°53.2 E100°39.7" or "N14 53.2 E100 39.7"
  /// 2. Compact entry format: "N1453.2E10039.7"
  String? validateAndFormatCoordinates(String raw) {
    final trimmed = raw.trim().toUpperCase();
    if (trimmed.isEmpty) return null;

    // Pattern 1: Canonical "N14°53.2 E100°39.7" or with space instead of degree symbol
    final canonicalRegex = RegExp(
      r'^([NS])\s*(\d{2})[°\s]?(\d{2}(?:\.\d+)?)\s+([EW])\s*(\d{3})[°\s]?(\d{2}(?:\.\d+)?)$',
    );
    final match = canonicalRegex.firstMatch(trimmed);
    if (match != null) {
      final latHemi = match.group(1)!;
      final latDeg = int.tryParse(match.group(2)!);
      final latMin = double.tryParse(match.group(3)!);

      final lonHemi = match.group(4)!;
      final lonDeg = int.tryParse(match.group(5)!);
      final lonMin = double.tryParse(match.group(6)!);

      if (latDeg == null || latMin == null || lonDeg == null || lonMin == null) {
        return null;
      }

      if (!_isValidLatRange(latDeg, latMin) || !_isValidLonRange(lonDeg, lonMin)) {
        return null;
      }

      final formattedLat = '$latHemi${latDeg.toString().padLeft(2, '0')}°${latMin.toStringAsFixed(1).padLeft(4, '0')}';
      final formattedLon = '$lonHemi${lonDeg.toString().padLeft(3, '0')}°${lonMin.toStringAsFixed(1).padLeft(4, '0')}';
      return '$formattedLat $formattedLon';
    }

    // Pattern 2: Compact entry format e.g. "N1453.2E10039.7" or "N3320.77W11152.58"
    final compactRegex = RegExp(
      r'^([NS])(\d{2})(\d{2}(?:\.\d+)?)([EW])(\d{3})(\d{2}(?:\.\d+)?)$',
    );
    final compactMatch = compactRegex.firstMatch(trimmed);
    if (compactMatch != null) {
      final latHemi = compactMatch.group(1)!;
      final latDeg = int.tryParse(compactMatch.group(2)!);
      final latMin = double.tryParse(compactMatch.group(3)!);

      final lonHemi = compactMatch.group(4)!;
      final lonDeg = int.tryParse(compactMatch.group(5)!);
      final lonMin = double.tryParse(compactMatch.group(6)!);

      if (latDeg == null || latMin == null || lonDeg == null || lonMin == null) {
        return null;
      }

      if (!_isValidLatRange(latDeg, latMin) || !_isValidLonRange(lonDeg, lonMin)) {
        return null;
      }

      final formattedLat = '$latHemi${latDeg.toString().padLeft(2, '0')}°${latMin.toStringAsFixed(1).padLeft(4, '0')}';
      final formattedLon = '$lonHemi${lonDeg.toString().padLeft(3, '0')}°${lonMin.toStringAsFixed(1).padLeft(4, '0')}';
      return '$formattedLat $formattedLon';
    }

    return null;
  }

  bool _isValidLatRange(int deg, double min) {
    if (deg < 0 || deg > 90) return false;
    if (min < 0.0 || min >= 60.0) return false;
    if (deg == 90 && min > 0.0) return false;
    return true;
  }

  bool _isValidLonRange(int deg, double min) {
    if (deg < 0 || deg > 180) return false;
    if (min < 0.0 || min >= 60.0) return false;
    if (deg == 180 && min > 0.0) return false;
    return true;
  }
}
