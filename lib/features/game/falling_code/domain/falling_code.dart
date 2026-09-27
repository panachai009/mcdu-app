import 'reporting_point.dart';

enum FallingCodeState {
  active,
  hit,
  missed,
}

class FallingCode {
  final String id;
  final String code;
  final ReportingPoint reportingPoint;
  final double progress; // 0.0 (top) to 1.0 (bottom)
  final double speed;    // progress units per second (e.g. 0.1 = 10s from top to bottom)
  final FallingCodeState state;
  final int typedLength; // number of characters correctly typed so far

  const FallingCode({
    required this.id,
    required this.code,
    required this.reportingPoint,
    this.progress = 0.0,
    this.speed = 0.1,
    this.state = FallingCodeState.active,
    this.typedLength = 0,
  });

  bool get isActive => state == FallingCodeState.active;
  bool get isHit => state == FallingCodeState.hit;
  bool get isMissed => state == FallingCodeState.missed;

  /// Next character expected to be typed, or null if already fully typed.
  String? get nextChar {
    if (typedLength < code.length) {
      return code[typedLength];
    }
    return null;
  }

  /// Already typed substring.
  String get typedText => code.substring(0, typedLength);

  /// Remaining untyped substring.
  String get remainingText => code.substring(typedLength);

  FallingCode copyWith({
    String? id,
    String? code,
    ReportingPoint? reportingPoint,
    double? progress,
    double? speed,
    FallingCodeState? state,
    int? typedLength,
  }) {
    return FallingCode(
      id: id ?? this.id,
      code: code ?? this.code,
      reportingPoint: reportingPoint ?? this.reportingPoint,
      progress: progress ?? this.progress,
      speed: speed ?? this.speed,
      state: state ?? this.state,
      typedLength: typedLength ?? this.typedLength,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FallingCode &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          reportingPoint == other.reportingPoint &&
          progress == other.progress &&
          speed == other.speed &&
          state == other.state &&
          typedLength == other.typedLength;

  @override
  int get hashCode =>
      id.hashCode ^
      code.hashCode ^
      reportingPoint.hashCode ^
      progress.hashCode ^
      speed.hashCode ^
      state.hashCode ^
      typedLength.hashCode;

  @override
  String toString() =>
      'FallingCode(id: $id, code: $code, progress: $progress, speed: $speed, state: $state, typed: $typedLength/${code.length})';
}
