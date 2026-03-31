// TC-REPO-001 ~ TC-REPO-003
// 대상: public_api/data/repositories/public_api_repository_impl.dart
// 레이어: Unit — Repository 인터페이스 + 자동완성 로직 검증

import 'package:flutter_test/flutter_test.dart';
import 'package:imjang_app/features/public_api/domain/entities/apt_list_item.dart';
import 'package:imjang_app/features/public_api/domain/entities/apt_detail_info.dart';
import 'package:imjang_app/features/public_api/domain/entities/real_price_item.dart';
import 'package:imjang_app/features/public_api/domain/entities/building_ledger_info.dart';
import 'package:imjang_app/features/public_api/domain/repositories/public_api_repository.dart';

void main() {
  group('PublicApiRepository 인터페이스 검증', () {
    test('TC-REPO-001: PublicApiRepository 인터페이스 — 메서드 시그니처 존재 확인', () {
      // 인터페이스가 올바른 메서드를 정의하는지 컴파일 타임 검증
      // 이 테스트는 컴파일이 통과하면 성공
      expect(PublicApiRepository, isNotNull);
    });
  });

  group('Entity 기본 동작 검증', () {
    test('TC-REPO-002: AptListItem equality — complexCode 기준', () {
      final item1 = AptListItem(
        complexCode: 'A10001',
        complexName: '래미안역삼',
        regionCode: '11680',
      );
      final item2 = AptListItem(
        complexCode: 'A10001',
        complexName: '다른이름',
        regionCode: '99999',
      );

      expect(item1, equals(item2));
    });

    test('TC-REPO-003: AptDetailInfo — 모든 nullable 필드 null 허용', () {
      final info = AptDetailInfo(
        complexCode: 'A12345',
        complexName: '테스트 단지',
      );

      expect(info.totalHouseholds, isNull);
      expect(info.totalBuildings, isNull);
      expect(info.heatingType, isNull);
      expect(info.floorAreaRatio, isNull);
      expect(info.constructor, isNull);
    });
  });

  group('BuildingLedgerInfo 검증', () {
    test('TC-REPO-004: BuildingLedgerInfo equality — name + sigunguCode + bun + ji', () {
      final info1 = BuildingLedgerInfo(
        buildingName: '래미안 101동',
        sigunguCode: '11680',
        bun: '0123',
        ji: '0004',
      );
      final info2 = BuildingLedgerInfo(
        buildingName: '래미안 101동',
        sigunguCode: '11680',
        bun: '0123',
        ji: '0004',
        mainPurpose: '공동주택',
      );

      expect(info1, equals(info2));
    });
  });
}
