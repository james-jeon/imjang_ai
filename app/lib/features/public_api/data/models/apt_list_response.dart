import 'package:imjang_app/features/public_api/domain/entities/apt_list_item.dart';

/// 공동주택 단지 목록 API 응답 모델 (API-03)
/// XML 파싱된 Map을 AptListItem으로 변환
class AptListResponse {
  final List<AptListItem> items;

  AptListResponse({required this.items});

  factory AptListResponse.fromXmlItems(List<Map<String, String>> xmlItems) {
    final items = xmlItems.map((map) {
      return AptListItem(
        complexCode: map['단지코드'] ?? map['kaptCode'] ?? '',
        complexName: map['단지명'] ?? map['kaptName'] ?? '',
        regionCode: map['법정동코드'] ?? map['bjdCode'] ?? '',
        address: map['주소'] ?? map['kaptAddr'] ?? map['doroJuso'],
        dongName: map['법정동'] ?? map['bjdongName'],
        totalHouseholds: _parseInt(map['세대수'] ?? map['kaptDaCnt']),
      );
    }).toList();
    return AptListResponse(items: items);
  }

  /// Firestore 캐시에서 복원
  factory AptListResponse.fromCacheData(List<dynamic> data) {
    final items = data.map((item) {
      final map = item as Map<String, dynamic>;
      return AptListItem(
        complexCode: map['complexCode'] as String? ?? '',
        complexName: map['complexName'] as String? ?? '',
        regionCode: map['regionCode'] as String? ?? '',
        address: map['address'] as String?,
        dongName: map['dongName'] as String?,
        totalHouseholds: (map['totalHouseholds'] as num?)?.toInt(),
      );
    }).toList();
    return AptListResponse(items: items);
  }

  /// Firestore 캐시 저장용
  List<Map<String, dynamic>> toCacheData() {
    return items.map((item) {
      return {
        'complexCode': item.complexCode,
        'complexName': item.complexName,
        'regionCode': item.regionCode,
        'address': item.address,
        'dongName': item.dongName,
        'totalHouseholds': item.totalHouseholds,
      };
    }).toList();
  }

  static int? _parseInt(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value.replaceAll(',', '').trim());
  }
}
