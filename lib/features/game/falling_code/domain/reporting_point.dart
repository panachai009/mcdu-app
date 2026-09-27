enum ReportingPointCategory {
  bangkokZone,
  militaryProvincial,
}

class ReportingPoint {
  final String code;
  final String name;
  final ReportingPointCategory category;
  final String? rawCoordinates;

  const ReportingPoint({
    required this.code,
    required this.name,
    required this.category,
    this.rawCoordinates,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportingPoint &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          name == other.name &&
          category == other.category &&
          rawCoordinates == other.rawCoordinates;

  @override
  int get hashCode =>
      code.hashCode ^
      name.hashCode ^
      category.hashCode ^
      (rawCoordinates?.hashCode ?? 0);

  @override
  String toString() =>
      'ReportingPoint(code: $code, name: $name, category: $category, rawCoordinates: $rawCoordinates)';
}
