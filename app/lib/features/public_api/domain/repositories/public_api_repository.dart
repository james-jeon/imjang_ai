import 'package:imjang_app/features/public_api/domain/entities/apt_detail_info.dart';
import 'package:imjang_app/features/public_api/domain/entities/apt_list_item.dart';
import 'package:imjang_app/features/public_api/domain/entities/building_ledger_info.dart';
import 'package:imjang_app/features/public_api/domain/entities/real_price_item.dart';

/// 공공데이터 API Repository 인터페이스
abstract class PublicApiRepository {
  /// API-03: 단지 목록 조회
  Future<List<AptListItem>> getComplexList({
    required String regionCode,
    int pageNo = 1,
    int numOfRows = 100,
  });

  /// API-03: 검색 자동완성
  List<AptListItem> searchAutoComplete(
    List<AptListItem> items,
    String query,
  );

  /// API-04: 단지 상세 정보 조회
  Future<AptDetailInfo?> getComplexInfo({
    required String publicApiCode,
  });

  /// API-05: 실거래가 조회
  Future<List<RealPriceItem>> getRealPriceList({
    required String regionCode,
    required String yearMonth,
    int pageNo = 1,
    int numOfRows = 100,
  });

  /// API-06: 건축물대장 조회
  Future<List<BuildingLedgerInfo>> getBuildingLedger({
    required String sigunguCode,
    required String bjdongCode,
    required String bun,
    required String ji,
  });
}
