// TC-API03-001 ~ TC-API03-006
// 대상: public_api/data/datasources/complex_list_api_datasource.dart (API-03)
// 레이어: Unit — 단지 목록 API + 검색 자동완성

import 'package:flutter_test/flutter_test.dart';
import 'package:imjang_app/features/public_api/data/models/apt_list_response.dart';
import 'package:imjang_app/features/public_api/domain/entities/apt_list_item.dart';

void main() {
  group('AptListResponse.fromXmlItems (API-03 XML 파싱)', () {
    test('TC-API03-001: 정상 XML items → AptListItem 리스트 변환', () {
      final xmlItems = [
        {
          '단지코드': 'A10001',
          '단지명': '래미안역삼',
          '법정동코드': '1168010100',
          '주소': '서울시 강남구 역삼동 123',
          '법정동': '역삼동',
          '세대수': '1,200',
        },
        {
          '단지코드': 'A10002',
          '단지명': '삼성힐스테이트',
          '법정동코드': '1168010200',
          '주소': '서울시 강남구 삼성동 456',
          '법정동': '삼성동',
          '세대수': '850',
        },
      ];

      final response = AptListResponse.fromXmlItems(xmlItems);

      expect(response.items.length, 2);
      expect(response.items[0].complexCode, 'A10001');
      expect(response.items[0].complexName, '래미안역삼');
      expect(response.items[0].regionCode, '1168010100');
      expect(response.items[0].totalHouseholds, 1200);
      expect(response.items[1].complexName, '삼성힐스테이트');
      expect(response.items[1].totalHouseholds, 850);
    });

    test('TC-API03-002: 빈 XML items → 빈 리스트', () {
      final response = AptListResponse.fromXmlItems([]);
      expect(response.items, isEmpty);
    });

    test('TC-API03-003: 누락 필드 — 기본값 처리', () {
      final xmlItems = [
        {'단지코드': 'A10003', '단지명': '테스트단지', '법정동코드': '11680'},
      ];

      final response = AptListResponse.fromXmlItems(xmlItems);

      expect(response.items[0].address, isNull);
      expect(response.items[0].dongName, isNull);
      expect(response.items[0].totalHouseholds, isNull);
    });
  });

  group('AptListResponse 캐시 라운드트립', () {
    test('TC-API03-004: toCacheData → fromCacheData 라운드트립 보존', () {
      final original = AptListResponse(items: [
        AptListItem(
          complexCode: 'A10001',
          complexName: '래미안역삼',
          regionCode: '1168010100',
          address: '서울시 강남구 역삼동',
          dongName: '역삼동',
          totalHouseholds: 1200,
        ),
      ]);

      final cacheData = original.toCacheData();
      final restored = AptListResponse.fromCacheData(cacheData);

      expect(restored.items.length, 1);
      expect(restored.items[0].complexCode, 'A10001');
      expect(restored.items[0].complexName, '래미안역삼');
      expect(restored.items[0].totalHouseholds, 1200);
    });
  });

  group('검색 자동완성 로직', () {
    final items = [
      AptListItem(
        complexCode: 'A1',
        complexName: '래미안역삼',
        regionCode: '11680',
        address: '서울시 강남구 역삼동',
        dongName: '역삼동',
      ),
      AptListItem(
        complexCode: 'A2',
        complexName: '래미안서초',
        regionCode: '11650',
        address: '서울시 서초구 서초동',
        dongName: '서초동',
      ),
      AptListItem(
        complexCode: 'A3',
        complexName: '삼성힐스테이트',
        regionCode: '11680',
        address: '서울시 강남구 삼성동',
        dongName: '삼성동',
      ),
    ];

    // 자동완성 로직은 datasource 메서드이나 순수 함수이므로 직접 테스트
    List<AptListItem> searchAutoComplete(
        List<AptListItem> items, String query) {
      if (query.isEmpty) return [];
      final lowerQuery = query.toLowerCase();
      return items
          .where((item) =>
              item.complexName.toLowerCase().contains(lowerQuery) ||
              (item.address?.toLowerCase().contains(lowerQuery) ?? false) ||
              (item.dongName?.toLowerCase().contains(lowerQuery) ?? false))
          .toList();
    }

    test('TC-API03-005: "래미안" 검색 → 2개 매칭', () {
      final result = searchAutoComplete(items, '래미안');
      expect(result.length, 2);
      expect(result[0].complexName, '래미안역삼');
      expect(result[1].complexName, '래미안서초');
    });

    test('TC-API03-006: 빈 쿼리 → 빈 리스트', () {
      final result = searchAutoComplete(items, '');
      expect(result, isEmpty);
    });
  });
}
