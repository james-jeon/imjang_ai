import 'package:imjang_app/features/public_api/domain/entities/apt_detail_info.dart';

/// 공동주택 단지 상세 정보 API 응답 모델 (API-04)
class AptInfoResponse {
  final AptDetailInfo? info;

  AptInfoResponse({this.info});

  factory AptInfoResponse.fromXmlItems(List<Map<String, String>> xmlItems) {
    if (xmlItems.isEmpty) {
      return AptInfoResponse(info: null);
    }
    final map = xmlItems.first;
    return AptInfoResponse(
      info: AptDetailInfo(
        complexCode: map['단지코드'] ?? map['kaptCode'] ?? '',
        complexName: map['단지명'] ?? map['kaptName'] ?? '',
        totalHouseholds: _parseInt(map['세대수'] ?? map['kaptDaCnt']),
        totalBuildings: _parseInt(map['동수'] ?? map['kaptDongCnt']),
        minFloor: _parseInt(map['최저층'] ?? map['kaptMparea_60']),
        maxFloor: _parseInt(map['최고층'] ?? map['kaptMparea_85']),
        heatingType: map['난방방식'] ?? map['kaptHeatType'],
        approvalDate: map['사용승인일'] ?? map['kaptUsedate'],
        constructor: map['건설사'] ?? map['kaptBcompany'],
        floorAreaRatio: _parseDouble(map['용적률'] ?? map['kaptFar']),
        buildingCoverageRatio: _parseDouble(map['건폐율'] ?? map['kaptBcr']),
      ),
    );
  }

  /// Firestore 캐시에서 복원
  factory AptInfoResponse.fromCacheData(List<dynamic> data) {
    if (data.isEmpty) return AptInfoResponse(info: null);
    final map = data.first as Map<String, dynamic>;
    return AptInfoResponse(
      info: AptDetailInfo(
        complexCode: map['complexCode'] as String? ?? '',
        complexName: map['complexName'] as String? ?? '',
        totalHouseholds: (map['totalHouseholds'] as num?)?.toInt(),
        totalBuildings: (map['totalBuildings'] as num?)?.toInt(),
        minFloor: (map['minFloor'] as num?)?.toInt(),
        maxFloor: (map['maxFloor'] as num?)?.toInt(),
        heatingType: map['heatingType'] as String?,
        approvalDate: map['approvalDate'] as String?,
        constructor: map['constructor'] as String?,
        floorAreaRatio: (map['floorAreaRatio'] as num?)?.toDouble(),
        buildingCoverageRatio: (map['buildingCoverageRatio'] as num?)?.toDouble(),
      ),
    );
  }

  /// Firestore 캐시 저장용
  List<Map<String, dynamic>> toCacheData() {
    if (info == null) return [];
    return [
      {
        'complexCode': info!.complexCode,
        'complexName': info!.complexName,
        'totalHouseholds': info!.totalHouseholds,
        'totalBuildings': info!.totalBuildings,
        'minFloor': info!.minFloor,
        'maxFloor': info!.maxFloor,
        'heatingType': info!.heatingType,
        'approvalDate': info!.approvalDate,
        'constructor': info!.constructor,
        'floorAreaRatio': info!.floorAreaRatio,
        'buildingCoverageRatio': info!.buildingCoverageRatio,
      }
    ];
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
