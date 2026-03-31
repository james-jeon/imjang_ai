import 'package:imjang_app/features/public_api/domain/entities/real_price_item.dart';

/// 아파트 매매 실거래가 API 응답 모델 (API-05)
class RealPriceResponse {
  final List<RealPriceItem> items;

  RealPriceResponse({required this.items});

  factory RealPriceResponse.fromXmlItems(List<Map<String, String>> xmlItems) {
    final items = xmlItems.map((map) {
      return RealPriceItem(
        aptName: map['아파트'] ?? map['aptNm'] ?? '',
        dealAmount: (map['거래금액'] ?? map['dealAmount'] ?? '0').trim(),
        exclusiveArea:
            double.tryParse(map['전용면적'] ?? map['excluUseAr'] ?? '0') ?? 0.0,
        floor: int.tryParse(map['층'] ?? map['floor'] ?? '0') ?? 0,
        dealYear: int.tryParse(map['년'] ?? map['dealYear'] ?? '0') ?? 0,
        dealMonth: int.tryParse(map['월'] ?? map['dealMonth'] ?? '0') ?? 0,
        dealDay: int.tryParse(map['일'] ?? map['dealDay'] ?? '0') ?? 0,
        dongName: map['법정동'] ?? map['umdNm'] ?? '',
        jibun: map['지번'] ?? map['jibun'],
        buildYear: int.tryParse(map['건축년도'] ?? map['buildYear'] ?? ''),
        regionCode: map['지역코드'] ?? map['dealingGbn'],
      );
    }).toList();
    return RealPriceResponse(items: items);
  }

  /// Firestore 캐시에서 복원
  factory RealPriceResponse.fromCacheData(List<dynamic> data) {
    final items = data.map((item) {
      final map = item as Map<String, dynamic>;
      return RealPriceItem(
        aptName: map['aptName'] as String? ?? '',
        dealAmount: map['dealAmount'] as String? ?? '0',
        exclusiveArea: (map['exclusiveArea'] as num?)?.toDouble() ?? 0.0,
        floor: (map['floor'] as num?)?.toInt() ?? 0,
        dealYear: (map['dealYear'] as num?)?.toInt() ?? 0,
        dealMonth: (map['dealMonth'] as num?)?.toInt() ?? 0,
        dealDay: (map['dealDay'] as num?)?.toInt() ?? 0,
        dongName: map['dongName'] as String? ?? '',
        jibun: map['jibun'] as String?,
        buildYear: (map['buildYear'] as num?)?.toInt(),
        regionCode: map['regionCode'] as String?,
      );
    }).toList();
    return RealPriceResponse(items: items);
  }

  /// Firestore 캐시 저장용
  List<Map<String, dynamic>> toCacheData() {
    return items.map((item) {
      return {
        'aptName': item.aptName,
        'dealAmount': item.dealAmount,
        'exclusiveArea': item.exclusiveArea,
        'floor': item.floor,
        'dealYear': item.dealYear,
        'dealMonth': item.dealMonth,
        'dealDay': item.dealDay,
        'dongName': item.dongName,
        'jibun': item.jibun,
        'buildYear': item.buildYear,
        'regionCode': item.regionCode,
      };
    }).toList();
  }
}
