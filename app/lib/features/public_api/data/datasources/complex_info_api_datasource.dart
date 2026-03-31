import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:imjang_app/core/network/dio_client.dart';
import 'package:imjang_app/core/utils/xml_parser.dart';
import 'package:imjang_app/features/public_api/data/datasources/api_cache_datasource.dart';
import 'package:imjang_app/features/public_api/data/models/apt_info_response.dart';
import 'package:imjang_app/features/public_api/domain/entities/apt_detail_info.dart';

/// 공동주택 단지 정보 API 데이터소스 (API-04)
/// - 공공데이터 API 호출 + Firestore 캐싱 (30일 TTL)
class ComplexInfoApiDatasource {
  final DioClient dioClient;
  final ApiCacheDatasource cacheDatasource;

  static const String _endpoint = '/B552584/AprtInfo/getAprtInfo';
  static const int _ttlDays = 30;

  ComplexInfoApiDatasource({
    required this.dioClient,
    required this.cacheDatasource,
  });

  /// 단지 상세 정보 조회 (캐시 우선)
  Future<AptDetailInfo?> getComplexInfo({
    required String publicApiCode,
  }) async {
    final cacheKey = ApiCacheDatasource.complexInfoKey(publicApiCode);

    // 1. 캐시 확인
    final cached = await cacheDatasource.getCachedData(cacheKey);
    if (cached != null) {
      return AptInfoResponse.fromCacheData(cached).info;
    }

    // 2. API 호출
    final serviceKey = dotenv.env['PUBLIC_DATA_API_KEY'] ?? '';
    final xmlString = await dioClient.get(
      _endpoint,
      queryParameters: {
        'ServiceKey': serviceKey,
        'kaptCode': publicApiCode,
      },
    );

    // 3. XML 파싱
    final xmlItems = XmlParser.parseResponse(xmlString);
    final response = AptInfoResponse.fromXmlItems(xmlItems);

    // 4. 캐시 저장
    if (response.info != null) {
      await cacheDatasource.setCachedData(
        cacheKey: cacheKey,
        apiType: 'complexInfo',
        params: {'publicApiCode': publicApiCode},
        data: response.toCacheData(),
        ttlDays: _ttlDays,
      );
    }

    return response.info;
  }
}
