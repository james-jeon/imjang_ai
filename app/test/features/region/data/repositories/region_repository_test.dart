// TC-REGION-001 ~ TC-REGION-015
// 대상: lib/features/region/data/repositories/region_repository_impl.dart (S2에서 구현)
// 레이어: Unit — 법정동코드 drift/SQLite CRUD + 계층 검색
//
// AC 매핑:
//   FR-API-05: 법정동코드 로컬 캐시, 오프라인 검색, 시도→시군구→읍면동 계층 선택

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:imjang_app/features/region/data/repositories/region_repository_impl.dart';
import 'package:imjang_app/features/region/domain/entities/region_entity.dart';
import 'package:imjang_app/features/region/data/datasources/region_local_datasource.dart';

import 'region_repository_test.mocks.dart';

@GenerateMocks([RegionLocalDataSource])
void main() {
  late MockRegionLocalDataSource mockDataSource;
  late RegionRepositoryImpl repository;

  // 테스트 데이터
  final sidoSeoul = RegionEntity(
    code: '1100000000',
    sidoName: '서울특별시',
    sigunguName: null,
    dongName: null,
    level: 1,
  );
  final sidoBusan = RegionEntity(
    code: '2600000000',
    sidoName: '부산광역시',
    sigunguName: null,
    dongName: null,
    level: 1,
  );
  final sigunguGangnam = RegionEntity(
    code: '1168000000',
    sidoName: '서울특별시',
    sigunguName: '강남구',
    dongName: null,
    level: 2,
  );
  final sigunguSeocho = RegionEntity(
    code: '1165000000',
    sidoName: '서울특별시',
    sigunguName: '서초구',
    dongName: null,
    level: 2,
  );
  final dongYeoksam = RegionEntity(
    code: '1168010100',
    sidoName: '서울특별시',
    sigunguName: '강남구',
    dongName: '역삼동',
    level: 3,
  );
  final dongSamsung = RegionEntity(
    code: '1168010300',
    sidoName: '서울특별시',
    sigunguName: '강남구',
    dongName: '삼성동',
    level: 3,
  );

  setUp(() {
    mockDataSource = MockRegionLocalDataSource();
    repository = RegionRepositoryImpl(localDataSource: mockDataSource);
  });

  // ---------------------------------------------------------------------------
  // 시도 목록 조회
  // ---------------------------------------------------------------------------

  group('getSidoList — 시도(level=1) 전체 목록', () {
    test(
      'TC-REGION-001: 시도 목록 조회 → level=1 RegionEntity 리스트 반환',
      () async {
        when(mockDataSource.getSidoList())
            .thenAnswer((_) async => [sidoSeoul, sidoBusan]);

        final result = await repository.getSidoList();

        expect(result, isA<List<RegionEntity>>());
        expect(result.length, equals(2));
        expect(result.every((r) => r.level == 1), isTrue);
        verify(mockDataSource.getSidoList()).called(1);
      },
    );

    test(
      'TC-REGION-002: 시도 목록 — 모든 항목에 sidoName이 존재함',
      () async {
        when(mockDataSource.getSidoList())
            .thenAnswer((_) async => [sidoSeoul, sidoBusan]);

        final result = await repository.getSidoList();

        for (final region in result) {
          expect(region.sidoName, isNotEmpty);
          expect(region.sigunguName, isNull);
          expect(region.dongName, isNull);
        }
      },
    );

    test(
      'TC-REGION-003: DataSource 오류 발생 → RegionException throw',
      () async {
        when(mockDataSource.getSidoList()).thenThrow(Exception('DB error'));

        expect(
          () => repository.getSidoList(),
          throwsA(isA<RegionException>()),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // 시군구 목록 조회
  // ---------------------------------------------------------------------------

  group('getSigunguList — 특정 시도의 시군구(level=2) 목록', () {
    test(
      'TC-REGION-004: 서울특별시 시군구 목록 조회 → level=2, sidoName="서울특별시" 항목만 반환',
      () async {
        when(mockDataSource.getSigunguList(sidoCode: '11'))
            .thenAnswer((_) async => [sigunguGangnam, sigunguSeocho]);

        final result = await repository.getSigunguList(sidoCode: '11');

        expect(result.length, equals(2));
        expect(result.every((r) => r.level == 2), isTrue);
        expect(result.every((r) => r.sidoName == '서울특별시'), isTrue);
        verify(mockDataSource.getSigunguList(sidoCode: '11')).called(1);
      },
    );

    test(
      'TC-REGION-005: 시군구 목록 — 모든 항목에 sigunguName이 존재함',
      () async {
        when(mockDataSource.getSigunguList(sidoCode: '11'))
            .thenAnswer((_) async => [sigunguGangnam, sigunguSeocho]);

        final result = await repository.getSigunguList(sidoCode: '11');

        for (final region in result) {
          expect(region.sigunguName, isNotNull);
          expect(region.sigunguName, isNotEmpty);
        }
      },
    );

    test(
      'TC-REGION-006: 존재하지 않는 sidoCode → 빈 리스트 반환',
      () async {
        when(mockDataSource.getSigunguList(sidoCode: '99'))
            .thenAnswer((_) async => []);

        final result = await repository.getSigunguList(sidoCode: '99');

        expect(result, isEmpty);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // 읍면동 목록 조회
  // ---------------------------------------------------------------------------

  group('getDongList — 특정 시군구의 읍면동(level=3) 목록', () {
    test(
      'TC-REGION-007: 강남구 읍면동 목록 조회 → level=3 항목만 반환',
      () async {
        when(mockDataSource.getDongList(sigunguCode: '11680'))
            .thenAnswer((_) async => [dongYeoksam, dongSamsung]);

        final result = await repository.getDongList(sigunguCode: '11680');

        expect(result.length, equals(2));
        expect(result.every((r) => r.level == 3), isTrue);
        expect(result.every((r) => r.sigunguName == '강남구'), isTrue);
        verify(mockDataSource.getDongList(sigunguCode: '11680')).called(1);
      },
    );

    test(
      'TC-REGION-008: 읍면동 목록 — 모든 항목에 dongName이 존재함',
      () async {
        when(mockDataSource.getDongList(sigunguCode: '11680'))
            .thenAnswer((_) async => [dongYeoksam, dongSamsung]);

        final result = await repository.getDongList(sigunguCode: '11680');

        for (final region in result) {
          expect(region.dongName, isNotNull);
          expect(region.dongName, isNotEmpty);
        }
      },
    );
  });

  // ---------------------------------------------------------------------------
  // 법정동코드 검색 (이름 기반)
  // ---------------------------------------------------------------------------

  group('searchByName — 이름 검색', () {
    test(
      'TC-REGION-009: "강남" 검색 → 강남이 포함된 RegionEntity 리스트 반환',
      () async {
        when(mockDataSource.searchByName(query: '강남'))
            .thenAnswer((_) async => [sigunguGangnam, dongYeoksam]);

        final result = await repository.searchByName(query: '강남');

        expect(result, isNotEmpty);
        verify(mockDataSource.searchByName(query: '강남')).called(1);
      },
    );

    test(
      'TC-REGION-010: 빈 쿼리 검색 → 빈 리스트 반환 (DataSource 미호출)',
      () async {
        final result = await repository.searchByName(query: '');

        expect(result, isEmpty);
        verifyNever(mockDataSource.searchByName(query: anyNamed('query')));
      },
    );

    test(
      'TC-REGION-011: 1글자 쿼리 → 빈 리스트 반환 (최소 2글자 정책)',
      () async {
        final result = await repository.searchByName(query: '강');

        expect(result, isEmpty);
        verifyNever(mockDataSource.searchByName(query: anyNamed('query')));
      },
    );

    test(
      'TC-REGION-012: 일치하는 결과 없음 → 빈 리스트 반환',
      () async {
        when(mockDataSource.searchByName(query: '존재하지않는동네'))
            .thenAnswer((_) async => []);

        final result = await repository.searchByName(query: '존재하지않는동네');

        expect(result, isEmpty);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // 법정동코드로 조회
  // ---------------------------------------------------------------------------

  group('getByCode — 코드 직접 조회', () {
    test(
      'TC-REGION-013: 유효한 10자리 코드 조회 → RegionEntity 반환',
      () async {
        when(mockDataSource.getByCode('1168010100'))
            .thenAnswer((_) async => dongYeoksam);

        final result = await repository.getByCode('1168010100');

        expect(result, isNotNull);
        expect(result!.code, equals('1168010100'));
        expect(result.dongName, equals('역삼동'));
      },
    );

    test(
      'TC-REGION-014: 존재하지 않는 코드 조회 → null 반환',
      () async {
        when(mockDataSource.getByCode('9999999999'))
            .thenAnswer((_) async => null);

        final result = await repository.getByCode('9999999999');

        expect(result, isNull);
      },
    );

    test(
      'TC-REGION-015: 코드 형식 검증 — 10자리 숫자가 아닌 경우 → InvalidCodeException throw',
      () async {
        expect(
          () => repository.getByCode('invalid'),
          throwsA(isA<InvalidRegionCodeException>()),
        );
      },
    );
  });
}
