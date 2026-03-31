import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:imjang_app/core/network/dio_client.dart';
import 'package:imjang_app/core/utils/xml_parser.dart';
import 'package:imjang_app/features/public_api/data/datasources/api_cache_datasource.dart';
import 'package:imjang_app/features/public_api/data/models/real_price_response.dart';
import 'package:imjang_app/features/public_api/domain/entities/real_price_item.dart';

/// 아파트 매매 실거래가 API 데이터소스 (API-05)
/// - 공공데이터 API 호출 + Firestore 캐싱 (7일 TTL)
class RealPriceApiDatasource {
  final DioClient dioClient;
  final ApiCacheDatasource cacheDatasource;

  static const String _endpoint =
      '/OpenAPI_ToolInstall/service/rest/RTMSDataSvcAptTradeDev/getRTMSDataSvcAptTradeDev';
  static const int _ttlDays = 7;

  RealPriceApiDatasource({
    required this.dioClient,
    required this.cacheDatasource,
  });

  /// 실거래가 조회 (캐시 우선)
  /// [regionCode] 5자리 법정동코드 (LAWD_CD)
  /// [yearMonth] YYYYMM 형식
  Future<List<RealPriceItem>> getRealPriceList({
    required String regionCode,
    required String yearMonth,
    int pageNo = 1,
    int numOfRows = 100,
  }) async {
    final cacheKey = ApiCacheDatasource.realPriceKey(regionCode, yearMonth);

    // 1. 캐시 확인
    final cached = await cacheDatasource.getCachedData(cacheKey);
    if (cached != null) {
      return RealPriceResponse.fromCacheData(cached).items;
    }

    // 2. API 호출
    final serviceKey = dotenv.env['PUBLIC_DATA_API_KEY'] ?? '';
    final xmlString = await dioClient.get(
      _endpoint,
      queryParameters: {
        'ServiceKey': serviceKey,
        'LAWD_CD': regionCode,
        'DEAL_YMD': yearMonth,
        'pageNo': pageNo.toString(),
        'numOfRows': numOfRows.toString(),
      },
    );

    // 3. XML 파싱
    final xmlItems = XmlParser.parseResponse(xmlString);
    final response = RealPriceResponse.fromXmlItems(xmlItems);

    // 4. 캐시 저장
    if (response.items.isNotEmpty) {
      await cacheDatasource.setCachedData(
        cacheKey: cacheKey,
        apiType: 'realPrice',
        params: {'regionCode': regionCode, 'yearMonth': yearMonth},
        data: response.toCacheData(),
        ttlDays: _ttlDays,
      );
    }

    return response.items;
  }
}
