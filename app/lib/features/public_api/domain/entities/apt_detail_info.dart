/// 공동주택 단지 상세 정보 (API-04)
class AptDetailInfo {
  final String complexCode;
  final String complexName;
  final int? totalHouseholds;
  final int? totalBuildings;
  final int? minFloor;
  final int? maxFloor;
  final String? heatingType;
  final String? approvalDate;
  final String? constructor;
  final double? floorAreaRatio;
  final double? buildingCoverageRatio;

  AptDetailInfo({
    required this.complexCode,
    required this.complexName,
    this.totalHouseholds,
    this.totalBuildings,
    this.minFloor,
    this.maxFloor,
    this.heatingType,
    this.approvalDate,
    this.constructor,
    this.floorAreaRatio,
    this.buildingCoverageRatio,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AptDetailInfo &&
          runtimeType == other.runtimeType &&
          complexCode == other.complexCode;

  @override
  int get hashCode => complexCode.hashCode;

  @override
  String toString() =>
      'AptDetailInfo(code: $complexCode, name: $complexName, households: $totalHouseholds)';
}
