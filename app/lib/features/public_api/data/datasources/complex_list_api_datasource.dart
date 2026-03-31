import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:imjang_app/core/network/dio_client.dart';
import 'package:imjang_app/core/utils/xml_parser.dart';
import 'package:imjang_app/features/public_api/data/datasources/api_cache_datasource.dart';
import 'package:imjang_app/features/public_api/data/models/apt_list_response.dart';
import 'package:imjang_app/features/public_api/domain/entities/apt_list_item.dart';

/// 공동주택 단지 목록 API 데이터소스 (API-03)
/// - 공공데이터 API 호출 + Firestore 캐싱 (7일 TTL)
/// - 검색 자동완성 로직
class ComplexListApiDatasource {
  final DioClient dioClient;
  final ApiCacheDatasource cacheDatasource;

  static const String _endpoint = '/B552584/ArptList/getAprtList';
  static const int _ttlDays = 7;

  ComplexListApiDatasource({
    required this.dioClient,
    required this.cacheDatasource,
  });

  /// 단지 목록 조회 (캐시 우선)
  Future<List<AptListItem>> getComplexList({
    required String regionCode,
    int pageNo = 1,
    int numOfRows = 100,
  }) async {
    final cacheKey = ApiCacheDatasource.complexListKey(regionCode);

    // 1. 캐시 확인
    final cached = await cacheDatasource.getCachedData(cacheKey);
    if (cached != null) {
      return AptListResponse.fromCacheData(cached).items;
    }

    // 2. API 호출
    final serviceKey = dotenv.env['PUBLIC_DATA_API_KEY'] ?? '';
    final xmlString = await dioClient.get(
      _endpoint,
      queryParameters: {
        'ServiceKey': serviceKey,
        'bjdCode': regionCode,
        'pageNo': pageNo.toString(),
        'numOfRows': numOfRows.toString(),
      },
    );

    // 3. XML 파싱
    final xmlItems = XmlParser.parseResponse(xmlString);
    final response = AptListResponse.fromXmlItems(xmlItems);

    // 4. 캐시 저장
    if (response.items.isNotEmpty) {
      await cacheDatasource.setCachedData(
        cacheKey: cacheKey,
        apiType: 'complexList',
        params: {'regionCode': regionCode},
        data: response.toCacheData(),
        ttlDays: _ttlDays,
      );
    }

    return response.items;
  }

  /// 검색 자동완성 — 로컬 캐시 데이터에서 필터링
  List<AptListItem> searchAutoComplete(
    List<AptListItem> items,
    String query,
  ) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return items
        .where((item) =>
            item.complexName.toLowerCase().contains(lowerQuery) ||
            (item.address?.toLowerCase().contains(lowerQuery) ?? false) ||
            (item.dongName?.toLowerCase().contains(lowerQuery) ?? false))
        .toList();
  }
}
