// TC-API05-001 ~ TC-API05-006
// 대상: public_api/data/models/real_price_response.dart (API-05)
// 레이어: Unit — 실거래가 API 응답 파싱 + 캐시 라운드트립

import 'package:flutter_test/flutter_test.dart';
import 'package:imjang_app/features/public_api/data/models/real_price_response.dart';
import 'package:imjang_app/features/public_api/domain/entities/real_price_item.dart';

void main() {
  group('RealPriceResponse.fromXmlItems (API-05 XML 파싱)', () {
    test('TC-API05-001: 정상 XML items → RealPriceItem 리스트 변환', () {
      final xmlItems = [
        {
          '아파트': '래미안역삼',
          '거래금액': ' 85,000',
          '전용면적': '84.98',
          '층': '12',
          '년': '2024',
          '월': '1',
          '일': '15',
          '법정동': '역삼동',
          '지번': '123-4',
          '건축년도': '2010',
        },
        {
          '아파트': '삼성힐스테이트',
          '거래금액': '120,000',
          '전용면적': '114.5',
          '층': '25',
          '년': '2024',
          '월': '2',
          '일': '3',
          '법정동': '삼성동',
          '건축년도': '2015',
        },
      ];

      final response = RealPriceResponse.fromXmlItems(xmlItems);

      expect(response.items.length, 2);
      expect(response.items[0].aptName, '래미안역삼');
      expect(response.items[0].dealAmount, '85,000'); // trimmed
      expect(response.items[0].exclusiveArea, 84.98);
      expect(response.items[0].floor, 12);
      expect(response.items[0].dealYear, 2024);
      expect(response.items[0].dealMonth, 1);
      expect(response.items[0].dealDay, 15);
      expect(response.items[0].dongName, '역삼동');
      expect(response.items[0].jibun, '123-4');
      expect(response.items[0].buildYear, 2010);
    });

    test('TC-API05-002: 빈 XML items → 빈 리스트', () {
      final response = RealPriceResponse.fromXmlItems([]);
      expect(response.items, isEmpty);
    });
  });

  group('RealPriceItem 유틸리티 메서드', () {
    test('TC-API05-003: dealAmountInt — 쉼표 제거 후 정수 변환', () {
      final item = RealPriceItem(
        aptName: '테스트',
        dealAmount: '85,000',
        exclusiveArea: 84.98,
        floor: 12,
        dealYear: 2024,
        dealMonth: 1,
        dealDay: 15,
        dongName: '역삼동',
      );

      expect(item.dealAmountInt, 85000);
    });

    test('TC-API05-004: dealDate — DateTime 생성', () {
      final item = RealPriceItem(
        aptName: '테스트',
        dealAmount: '100,000',
        exclusiveArea: 84.98,
        floor: 5,
        dealYear: 2024,
        dealMonth: 3,
        dealDay: 20,
        dongName: '서초동',
      );

      expect(item.dealDate, DateTime(2024, 3, 20));
    });
  });

  group('RealPriceResponse 캐시 라운드트립', () {
    test('TC-API05-005: toCacheData → fromCacheData 라운드트립 보존', () {
      final original = RealPriceResponse(items: [
        RealPriceItem(
          aptName: '래미안역삼',
          dealAmount: '85,000',
          exclusiveArea: 84.98,
          floor: 12,
          dealYear: 2024,
          dealMonth: 1,
          dealDay: 15,
          dongName: '역삼동',
          jibun: '123-4',
          buildYear: 2010,
          regionCode: '11680',
        ),
      ]);

      final cacheData = original.toCacheData();
      final restored = RealPriceResponse.fromCacheData(cacheData);

      expect(restored.items.length, 1);
      expect(restored.items[0].aptName, '래미안역삼');
      expect(restored.items[0].dealAmount, '85,000');
      expect(restored.items[0].exclusiveArea, 84.98);
      expect(restored.items[0].floor, 12);
      expect(restored.items[0].buildYear, 2010);
    });
  });

  group('BuildingLedger + AptInfo 응답 파싱', () {
    test('TC-API05-006: RealPriceItem equality — 같은 거래 식별', () {
      final item1 = RealPriceItem(
        aptName: '래미안',
        dealAmount: '85,000',
        exclusiveArea: 84.98,
        floor: 12,
        dealYear: 2024,
        dealMonth: 1,
        dealDay: 15,
        dongName: '역삼동',
      );

      final item2 = RealPriceItem(
        aptName: '래미안',
        dealAmount: '85,000',
        exclusiveArea: 84.98,
        floor: 12,
        dealYear: 2024,
        dealMonth: 1,
        dealDay: 15,
        dongName: '역삼동',
      );

      expect(item1, equals(item2));
      expect(item1.hashCode, equals(item2.hashCode));
    });
  });
}
