/// 건축물대장 정보 (API-06)
class BuildingLedgerInfo {
  final String buildingName;
  final String? mainPurpose;
  final double? floorAreaRatio;
  final double? buildingCoverageRatio;
  final String? structure;
  final int? groundFloors;
  final int? undergroundFloors;
  final double? totalArea;
  final String? approvalDate;
  final String? sigunguCode;
  final String? bjdongCode;
  final String? bun;
  final String? ji;

  BuildingLedgerInfo({
    required this.buildingName,
    this.mainPurpose,
    this.floorAreaRatio,
    this.buildingCoverageRatio,
    this.structure,
    this.groundFloors,
    this.undergroundFloors,
    this.totalArea,
    this.approvalDate,
    this.sigunguCode,
    this.bjdongCode,
    this.bun,
    this.ji,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuildingLedgerInfo &&
          runtimeType == other.runtimeType &&
          buildingName == other.buildingName &&
          sigunguCode == other.sigunguCode &&
          bun == other.bun &&
          ji == other.ji;

  @override
  int get hashCode =>
      buildingName.hashCode ^
      sigunguCode.hashCode ^
      bun.hashCode ^
      ji.hashCode;

  @override
  String toString() =>
      'BuildingLedgerInfo(name: $buildingName, purpose: $mainPurpose)';
}
