// TC-DIO-001 ~ TC-DIO-010
// 대상: lib/core/network/dio_client.dart (S2에서 구현)
// 레이어: Unit — HTTP 클라이언트, 재시도 로직, 에러 매핑

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:imjang_app/core/network/dio_client.dart';
import 'package:imjang_app/core/error/exceptions.dart';

import 'dio_client_test.mocks.dart';

@GenerateMocks([Dio, HttpClientAdapter])
void main() {
  late MockDio mockDio;
  late DioClient dioClient;

  const baseUrl = 'https://apis.data.go.kr';
  const testPath = '/1613000/RTMSDataSvcAptTradeDev';
  const testServiceKey = 'test-service-key';

  setUp(() {
    mockDio = MockDio();
    dioClient = DioClient(dio: mockDio);
  });

  group('GET 요청 — 성공 케이스', () {
    test(
      'TC-DIO-001: 정상 200 응답 → XML 문자열 반환',
      () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<response><header><resultCode>00</resultCode></header><body><items/></body></response>''';

        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(
              data: xmlResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: testPath),
            ));

        final result = await dioClient.get(
          testPath,
          queryParameters: {'serviceKey': testServiceKey},
        );

        expect(result, equals(xmlResponse));
      },
    );
  });

  group('재시도 로직 — 지수 백오프 (3회)', () {
    test(
      'TC-DIO-002: 첫 번째 요청 실패 후 재시도 성공 → 응답 반환 (총 2회 호출)',
      () async {
        const xmlResponse = '<response><header><resultCode>00</resultCode></header></response>';
        var callCount = 0;

        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            throw DioException(
              requestOptions: RequestOptions(path: testPath),
              type: DioExceptionType.connectionTimeout,
            );
          }
          return Response(
            data: xmlResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: testPath),
          );
        });

        // DioClient는 재시도를 내부적으로 처리함
        // 이 테스트는 DioClient의 retry interceptor가 구현된 후 통과
        final result = await dioClient.get(
          testPath,
          queryParameters: {'serviceKey': testServiceKey},
        );

        expect(result, equals(xmlResponse));
        expect(callCount, equals(2));
      },
    );

    test(
      'TC-DIO-003: 3회 모두 실패 → NetworkException throw',
      () async {
        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: testPath),
          type: DioExceptionType.connectionTimeout,
        ));

        expect(
          () => dioClient.get(
            testPath,
            queryParameters: {'serviceKey': testServiceKey},
          ),
          throwsA(isA<NetworkException>()),
        );
      },
    );

    test(
      'TC-DIO-004: 지수 백오프 — 재시도 간격이 1s → 2s → 4s 순서로 증가',
      () async {
        // 재시도 딜레이 간격 검증: DioClient의 retryDelays getter 확인
        final delays = dioClient.retryDelays;

        expect(delays.length, equals(3));
        expect(delays[0], equals(const Duration(seconds: 1)));
        expect(delays[1], equals(const Duration(seconds: 2)));
        expect(delays[2], equals(const Duration(seconds: 4)));
      },
    );
  });

  group('에러 매핑', () {
    test(
      'TC-DIO-005: HTTP 401 응답 → UnauthorizedException throw',
      () async {
        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: testPath),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: testPath),
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dioClient.get(testPath),
          throwsA(isA<UnauthorizedException>()),
        );
      },
    );

    test(
      'TC-DIO-006: HTTP 429 응답 (Too Many Requests) → RateLimitException throw',
      () async {
        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: testPath),
          response: Response(
            statusCode: 429,
            requestOptions: RequestOptions(path: testPath),
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dioClient.get(testPath),
          throwsA(isA<RateLimitException>()),
        );
      },
    );

    test(
      'TC-DIO-007: HTTP 500 응답 → ServerException throw',
      () async {
        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: testPath),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: testPath),
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => dioClient.get(testPath),
          throwsA(isA<ServerAppException>()),
        );
      },
    );

    test(
      'TC-DIO-008: 연결 타임아웃 → NetworkException throw',
      () async {
        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: testPath),
          type: DioExceptionType.connectionTimeout,
        ));

        expect(
          () => dioClient.get(testPath),
          throwsA(isA<NetworkException>()),
        );
      },
    );

    test(
      'TC-DIO-009: 수신 타임아웃 → NetworkException throw',
      () async {
        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: testPath),
          type: DioExceptionType.receiveTimeout,
        ));

        expect(
          () => dioClient.get(testPath),
          throwsA(isA<NetworkException>()),
        );
      },
    );
  });

  group('쿼리 파라미터 구성', () {
    test(
      'TC-DIO-010: queryParameters가 요청에 포함되어 전달됨',
      () async {
        const xmlResponse = '<response><header><resultCode>00</resultCode></header></response>';
        final queryParams = {
          'serviceKey': testServiceKey,
          'LAWD_CD': '11680',
          'DEAL_YMD': '202401',
          'numOfRows': '100',
          'pageNo': '1',
        };

        when(mockDio.get(
          testPath,
          queryParameters: queryParams,
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(
              data: xmlResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: testPath),
            ));

        final result = await dioClient.get(
          testPath,
          queryParameters: queryParams,
        );

        expect(result, equals(xmlResponse));
        verify(mockDio.get(
          testPath,
          queryParameters: queryParams,
          options: anyNamed('options'),
        )).called(1);
      },
    );
  });
}
