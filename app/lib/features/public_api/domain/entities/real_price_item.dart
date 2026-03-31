/// 아파트 매매 실거래가 항목 (API-05)
class RealPriceItem {
  final String aptName;
  final String dealAmount;
  final double exclusiveArea;
  final int floor;
  final int dealYear;
  final int dealMonth;
  final int dealDay;
  final String dongName;
  final String? jibun;
  final int? buildYear;
  final String? regionCode;

  RealPriceItem({
    required this.aptName,
    required this.dealAmount,
    required this.exclusiveArea,
    required this.floor,
    required this.dealYear,
    required this.dealMonth,
    required this.dealDay,
    required this.dongName,
    this.jibun,
    this.buildYear,
    this.regionCode,
  });

  /// 거래금액을 int로 변환 (만원 단위, 쉼표 제거)
  int get dealAmountInt {
    final cleaned = dealAmount.replaceAll(',', '').trim();
    return int.tryParse(cleaned) ?? 0;
  }

  /// 거래일 DateTime
  DateTime get dealDate => DateTime(dealYear, dealMonth, dealDay);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RealPriceItem &&
          runtimeType == other.runtimeType &&
          aptName == other.aptName &&
          dealAmount == other.dealAmount &&
          dealYear == other.dealYear &&
          dealMonth == other.dealMonth &&
          dealDay == other.dealDay &&
          floor == other.floor;

  @override
  int get hashCode =>
      aptName.hashCode ^
      dealAmount.hashCode ^
      dealYear.hashCode ^
      dealMonth.hashCode ^
      dealDay.hashCode ^
      floor.hashCode;

  @override
  String toString() =>
      'RealPriceItem(apt: $aptName, amount: $dealAmount, area: $exclusiveArea, floor: $floor)';
}
