import 'package:imjang_app/features/public_api/domain/entities/building_ledger_info.dart';

/// 건축물대장 API 응답 모델 (API-06)
class BuildingLedgerResponse {
  final List<BuildingLedgerInfo> items;

  BuildingLedgerResponse({required this.items});

  factory BuildingLedgerResponse.fromXmlItems(
      List<Map<String, String>> xmlItems) {
    final items = xmlItems.map((map) {
      return BuildingLedgerInfo(
        buildingName: map['bldNm'] ?? map['건물명'] ?? '',
        mainPurpose: map['mainPurpsCdNm'] ?? map['주용도'],
        floorAreaRatio: _parseDouble(map['vlRat'] ?? map['용적률']),
        buildingCoverageRatio: _parseDouble(map['bcRat'] ?? map['건폐율']),
        structure: map['strctCdNm'] ?? map['구조'],
        groundFloors: _parseInt(map['grndFlrCnt'] ?? map['지상층수']),
        undergroundFloors: _parseInt(map['ugrndFlrCnt'] ?? map['지하층수']),
        totalArea: _parseDouble(map['totArea'] ?? map['연면적']),
        approvalDate: map['useAprDay'] ?? map['사용승인일'],
        sigunguCode: map['sigunguCd'] ?? map['시군구코드'],
        bjdongCode: map['bjdongCd'] ?? map['법정동코드'],
        bun: map['bun'] ?? map['번'],
        ji: map['ji'] ?? map['지'],
      );
    }).toList();
    return BuildingLedgerResponse(items: items);
  }

  /// Firestore 캐시에서 복원
  factory BuildingLedgerResponse.fromCacheData(List<dynamic> data) {
    final items = data.map((item) {
      final map = item as Map<String, dynamic>;
      return BuildingLedgerInfo(
        buildingName: map['buildingName'] as String? ?? '',
        mainPurpose: map['mainPurpose'] as String?,
        floorAreaRatio: (map['floorAreaRatio'] as num?)?.toDouble(),
        buildingCoverageRatio:
            (map['buildingCoverageRatio'] as num?)?.toDouble(),
        structure: map['structure'] as String?,
        groundFloors: (map['groundFloors'] as num?)?.toInt(),
        undergroundFloors: (map['undergroundFloors'] as num?)?.toInt(),
        totalArea: (map['totalArea'] as num?)?.toDouble(),
        approvalDate: map['approvalDate'] as String?,
        sigunguCode: map['sigunguCode'] as String?,
        bjdongCode: map['bjdongCode'] as String?,
        bun: map['bun'] as String?,
        ji: map['ji'] as String?,
      );
    }).toList();
    return BuildingLedgerResponse(items: items);
  }

  /// Firestore 캐시 저장용
  List<Map<String, dynamic>> toCacheData() {
    return items.map((item) {
      return {
        'buildingName': item.buildingName,
        'mainPurpose': item.mainPurpose,
        'floorAreaRatio': item.floorAreaRatio,
        'buildingCoverageRatio': item.buildingCoverageRatio,
        'structure': item.structure,
        'groundFloors': item.groundFloors,
        'undergroundFloors': item.undergroundFloors,
        'totalArea': item.totalArea,
        'approvalDate': item.approvalDate,
        'sigunguCode': item.sigunguCode,
        'bjdongCode': item.bjdongCode,
        'bun': item.bun,
        'ji': item.ji,
      };
    }).toList();
  }

  static int? _parseInt(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value.replaceAll(',', '').trim());
  }

  static double? _parseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '').trim());
  }
}
