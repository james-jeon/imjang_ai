/// 공동주택 단지 목록 항목 (API-03)
class AptListItem {
  final String complexCode;
  final String complexName;
  final String regionCode;
  final String? address;
  final String? dongName;
  final int? totalHouseholds;

  AptListItem({
    required this.complexCode,
    required this.complexName,
    required this.regionCode,
    this.address,
    this.dongName,
    this.totalHouseholds,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AptListItem &&
          runtimeType == other.runtimeType &&
          complexCode == other.complexCode;

  @override
  int get hashCode => complexCode.hashCode;

  @override
  String toString() =>
      'AptListItem(code: $complexCode, name: $complexName)';
}
