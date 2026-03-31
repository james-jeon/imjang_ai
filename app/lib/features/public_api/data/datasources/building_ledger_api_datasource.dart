import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:imjang_app/core/network/dio_client.dart';
import 'package:imjang_app/core/utils/xml_parser.dart';
import 'package:imjang_app/features/public_api/data/datasources/api_cache_datasource.dart';
import 'package:imjang_app/features/public_api/data/models/building_ledger_response.dart';
import 'package:imjang_app/features/public_api/domain/entities/building_ledger_info.dart';

/// 건축물대장 API 데이터소스 (API-06)
/// - 공공데이터 API 호출 + Firestore 영구 캐싱 (365일 TTL)
class BuildingLedgerApiDatasource {
  final DioClient dioClient;
  final ApiCacheDatasource cacheDatasource;

  static const String _endpoint =
      '/1613000/BldRgstHubService/getBrTitleInfo';
  static const int _ttlDays = 365;

  BuildingLedgerApiDatasource({
    required this.dioClient,
    required this.cacheDatasource,
  });

  /// 건축물대장 조회 (캐시 우선)
  Future<List<BuildingLedgerInfo>> getBuildingLedger({
    required String sigunguCode,
    required String bjdongCode,
    required String bun,
    required String ji,
    int pageNo = 1,
    int numOfRows = 100,
  }) async {
    final cacheKey =
        ApiCacheDatasource.buildingLedgerKey(sigunguCode, bun, ji);

    // 1. 캐시 확인
    final cached = await cacheDatasource.getCachedData(cacheKey);
    if (cached != null) {
      return BuildingLedgerResponse.fromCacheData(cached).items;
    }

    // 2. API 호출
    final serviceKey = dotenv.env['PUBLIC_DATA_API_KEY'] ?? '';
    final xmlString = await dioClient.get(
      _endpoint,
      queryParameters: {
        'ServiceKey': serviceKey,
        'sigunguCd': sigunguCode,
        'bjdongCd': bjdongCode,
        'bun': bun,
        'ji': ji,
        'pageNo': pageNo.toString(),
        'numOfRows': numOfRows.toString(),
      },
    );

    // 3. XML 파싱
    final xmlItems = XmlParser.parseResponse(xmlString);
    final response = BuildingLedgerResponse.fromXmlItems(xmlItems);

    // 4. 캐시 저장
    if (response.items.isNotEmpty) {
      await cacheDatasource.setCachedData(
        cacheKey: cacheKey,
        apiType: 'buildingLedger',
        params: {
          'sigunguCode': sigunguCode,
          'bjdongCode': bjdongCode,
          'bun': bun,
          'ji': ji,
        },
        data: response.toCacheData(),
        ttlDays: _ttlDays,
      );
    }

    return response.items;
  }
}
