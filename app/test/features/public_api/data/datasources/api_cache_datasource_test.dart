// TC-CACHE-001 ~ TC-CACHE-005
// 대상: public_api/data/datasources/api_cache_datasource.dart
// 레이어: Unit — 캐시 키 생성 패턴 + 응답 모델 캐시 변환

import 'package:flutter_test/flutter_test.dart';
import 'package:imjang_app/features/public_api/data/datasources/api_cache_datasource.dart';
import 'package:imjang_app/features/public_api/data/models/apt_info_response.dart';
import 'package:imjang_app/features/public_api/data/models/building_ledger_response.dart';

void main() {
  group('ApiCacheDatasource — 캐시 키 생성 패턴', () {
    test('TC-CACHE-001: complexListKey — "complexList_{regionCode}" 형식', () {
      expect(
        ApiCacheDatasource.complexListKey('1168010100'),
        'complexList_1168010100',
      );
    });

    test('TC-CACHE-002: complexInfoKey — "complexInfo_{publicApiCode}" 형식', () {
      expect(
        ApiCacheDatasource.complexInfoKey('A12345'),
        'complexInfo_A12345',
      );
    });

    test('TC-CACHE-003: realPriceKey — "realPrice_{regionCode}_{yearMonth}" 형식', () {
      expect(
        ApiCacheDatasource.realPriceKey('11680', '202401'),
        'realPrice_11680_202401',
      );
    });

    test('TC-CACHE-004: buildingLedgerKey — "buildingLedger_{sigunguCode}_{번}_{지}" 형식', () {
      expect(
        ApiCacheDatasource.buildingLedgerKey('11680', '0123', '0004'),
        'buildingLedger_11680_0123_0004',
      );
    });
  });

  group('AptInfoResponse 캐시 라운드트립 (API-04)', () {
    test('TC-CACHE-005: toCacheData → fromCacheData 라운드트립 보존', () {
      final xmlItems = [
        {
          '단지코드': 'A12345',
          '단지명': '래미안역삼',
          '세대수': '1200',
          '동수': '15',
          '최저층': '5',
          '최고층': '35',
          '난방방식': '지역난방',
          '사용승인일': '20100315',
          '건설사': '삼성물산',
          '용적률': '249.5',
          '건폐율': '18.3',
        },
      ];

      final response = AptInfoResponse.fromXmlItems(xmlItems);
      expect(response.info, isNotNull);
      expect(response.info!.complexCode, 'A12345');
      expect(response.info!.totalHouseholds, 1200);
      expect(response.info!.heatingType, '지역난방');
      expect(response.info!.floorAreaRatio, 249.5);

      final cacheData = response.toCacheData();
      final restored = AptInfoResponse.fromCacheData(cacheData);

      expect(restored.info!.complexCode, 'A12345');
      expect(restored.info!.complexName, '래미안역삼');
      expect(restored.info!.totalHouseholds, 1200);
      expect(restored.info!.totalBuildings, 15);
      expect(restored.info!.minFloor, 5);
      expect(restored.info!.maxFloor, 35);
      expect(restored.info!.floorAreaRatio, 249.5);
      expect(restored.info!.buildingCoverageRatio, 18.3);
    });
  });

  group('BuildingLedgerResponse 캐시 라운드트립 (API-06)', () {
    test('TC-CACHE-006: fromXmlItems + toCacheData → fromCacheData 라운드트립', () {
      final xmlItems = [
        {
          'bldNm': '래미안 101동',
          'mainPurpsCdNm': '공동주택',
          'vlRat': '249.5',
          'bcRat': '18.3',
          'strctCdNm': '철근콘크리트구조',
          'grndFlrCnt': '35',
          'ugrndFlrCnt': '3',
          'totArea': '12500.50',
          'useAprDay': '20100315',
          'sigunguCd': '11680',
          'bjdongCd': '10100',
          'bun': '0123',
          'ji': '0004',
        },
      ];

      final response = BuildingLedgerResponse.fromXmlItems(xmlItems);
      expect(response.items.length, 1);
      expect(response.items[0].buildingName, '래미안 101동');
      expect(response.items[0].groundFloors, 35);
      expect(response.items[0].totalArea, 12500.50);

      final cacheData = response.toCacheData();
      final restored = BuildingLedgerResponse.fromCacheData(cacheData);

      expect(restored.items.length, 1);
      expect(restored.items[0].buildingName, '래미안 101동');
      expect(restored.items[0].mainPurpose, '공동주택');
      expect(restored.items[0].floorAreaRatio, 249.5);
      expect(restored.items[0].buildingCoverageRatio, 18.3);
      expect(restored.items[0].structure, '철근콘크리트구조');
      expect(restored.items[0].groundFloors, 35);
      expect(restored.items[0].undergroundFloors, 3);
      expect(restored.items[0].bun, '0123');
      expect(restored.items[0].ji, '0004');
    });
  });
}
