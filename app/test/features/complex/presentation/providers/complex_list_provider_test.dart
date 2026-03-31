// TC-COMP-PROV-001 ~ TC-COMP-PROV-018
// 대상: lib/features/complex/presentation/providers/ (S4 COMP-04 필터/정렬 로직)
// 레이어: Unit — Riverpod Provider (ComplexListFilter, 정렬, 필터링 순수 로직)
//
// 이 파일은 S4 dev 전에 작성된 설계 기반 테스트입니다.
// S4 구현 시 아래 import 경로를 실제 경로로 교체합니다:
//   import 'package:imjang_app/features/complex/presentation/providers/complex_list_provider.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_entity.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_status.dart';

// ─── 계약 정의 (S4 구현 전 인터페이스 명세) ──────────────────────────────────

/// 필터 상태 값 객체
class ComplexListFilter {
  final ComplexStatus? statusFilter; // null = 전체
  final double? minPrice; // 만원 단위
  final double? maxPrice;
  final List<int> areaFilters; // 평수 목록 (예: [24, 34, 59])
  final int? minHouseholds;
  final int? maxHouseholds;
  final int? minApprovalYear;
  final int? maxApprovalYear;
  final double? minRating;

  const ComplexListFilter({
    this.statusFilter,
    this.minPrice,
    this.maxPrice,
    this.areaFilters = const [],
    this.minHouseholds,
    this.maxHouseholds,
    this.minApprovalYear,
    this.maxApprovalYear,
    this.minRating,
  });

  ComplexListFilter copyWith({
    ComplexStatus? statusFilter,
    double? minPrice,
    double? maxPrice,
    List<int>? areaFilters,
    int? minHouseholds,
    int? maxHouseholds,
    int? minApprovalYear,
    int? maxApprovalYear,
    double? minRating,
    bool clearStatus = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
  }) {
    return ComplexListFilter(
      statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      areaFilters: areaFilters ?? this.areaFilters,
      minHouseholds: minHouseholds ?? this.minHouseholds,
      maxHouseholds: maxHouseholds ?? this.maxHouseholds,
      minApprovalYear: minApprovalYear ?? this.minApprovalYear,
      maxApprovalYear: maxApprovalYear ?? this.maxApprovalYear,
      minRating: minRating ?? this.minRating,
    );
  }

  bool get isEmpty =>
      statusFilter == null &&
      minPrice == null &&
      maxPrice == null &&
      areaFilters.isEmpty &&
      minHouseholds == null &&
      maxHouseholds == null &&
      minApprovalYear == null &&
      maxApprovalYear == null &&
      minRating == null;
}

/// 정렬 옵션
enum ComplexSortOption {
  recentlyAdded, // 최근 등록순
  nameAsc, // 이름순 (가나다)
  recentlyInspected, // 최근 임장순
  priceLow, // 매매가 낮은순
  priceHigh, // 매매가 높은순
}

/// 필터 + 정렬 적용 순수 함수 (Provider 구현에서 사용)
List<ComplexEntity> applyFilterAndSort({
  required List<ComplexEntity> complexes,
  required ComplexListFilter filter,
  required ComplexSortOption sort,
}) {
  var result = complexes.where((c) {
    // 상태 필터
    if (filter.statusFilter != null && c.status != filter.statusFilter) {
      return false;
    }
    // 매매가 필터 (만원 단위 정수, recentTradePrice = "85,000" 형식)
    if (filter.minPrice != null || filter.maxPrice != null) {
      final priceStr = c.recentTradePrice;
      if (priceStr == null) return false;
      final price =
          double.tryParse(priceStr.replaceAll(',', '').trim()) ?? 0.0;
      if (filter.minPrice != null && price < filter.minPrice!) return false;
      if (filter.maxPrice != null && price > filter.maxPrice!) return false;
    }
    // 면적 필터 (대표 면적 ↔ 평수 변환: 1평 = 3.305785m²)
    if (filter.areaFilters.isNotEmpty) {
      final area = c.representativeArea;
      if (area == null) return false;
      final areaPyeong = (area / 3.305785).round();
      if (!filter.areaFilters.contains(areaPyeong)) return false;
    }
    // 세대수 필터
    if (filter.minHouseholds != null &&
        (c.totalHouseholds ?? 0) < filter.minHouseholds!) {
      return false;
    }
    if (filter.maxHouseholds != null &&
        (c.totalHouseholds ?? 0) > filter.maxHouseholds!) {
      return false;
    }
    // 준공연도 필터 (approvalDate = "20100315" 형식 → 앞 4자리)
    if (filter.minApprovalYear != null || filter.maxApprovalYear != null) {
      final approval = c.approvalDate;
      if (approval == null || approval.length < 4) return false;
      final year = int.tryParse(approval.substring(0, 4)) ?? 0;
      if (filter.minApprovalYear != null && year < filter.minApprovalYear!) {
        return false;
      }
      if (filter.maxApprovalYear != null && year > filter.maxApprovalYear!) {
        return false;
      }
    }
    // 임장 평점 필터
    if (filter.minRating != null &&
        (c.averageRating ?? 0.0) < filter.minRating!) {
      return false;
    }
    return true;
  }).toList();

  // 정렬
  switch (sort) {
    case ComplexSortOption.recentlyAdded:
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    case ComplexSortOption.nameAsc:
      result.sort((a, b) => a.name.compareTo(b.name));
      break;
    case ComplexSortOption.recentlyInspected:
      result.sort((a, b) {
        final aDate = a.lastInspectionAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.lastInspectionAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      break;
    case ComplexSortOption.priceLow:
      result.sort((a, b) {
        final ap = double.tryParse(
                (a.recentTradePrice ?? '0').replaceAll(',', '').trim()) ??
            0.0;
        final bp = double.tryParse(
                (b.recentTradePrice ?? '0').replaceAll(',', '').trim()) ??
            0.0;
        return ap.compareTo(bp);
      });
      break;
    case ComplexSortOption.priceHigh:
      result.sort((a, b) {
        final ap = double.tryParse(
                (a.recentTradePrice ?? '0').replaceAll(',', '').trim()) ??
            0.0;
        final bp = double.tryParse(
                (b.recentTradePrice ?? '0').replaceAll(',', '').trim()) ??
            0.0;
        return bp.compareTo(ap);
      });
      break;
  }

  return result;
}

// ─── 테스트 데이터 ─────────────────────────────────────────────────────────

final _now = DateTime(2026, 3, 31);

ComplexEntity _makeComplex({
  required String id,
  required String name,
  ComplexStatus status = ComplexStatus.interested,
  String? recentTradePrice,
  double? representativeArea, // m²
  int? totalHouseholds,
  String? approvalDate, // "YYYYMMDD"
  double? averageRating,
  DateTime? lastInspectionAt,
  DateTime? createdAt,
}) {
  return ComplexEntity(
    id: id,
    ownerId: 'user-001',
    name: name,
    address: '서울시 강남구 역삼동 $id',
    regionCode: '1168010100',
    status: status,
    recentTradePrice: recentTradePrice,
    representativeArea: representativeArea,
    totalHouseholds: totalHouseholds,
    approvalDate: approvalDate,
    averageRating: averageRating,
    sharedWith: const ['user-001'],
    lastInspectionAt: lastInspectionAt,
    createdAt: createdAt ?? _now,
    updatedAt: _now,
  );
}

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // Group: ComplexListFilter 값 객체
  // ══════════════════════════════════════════════════════════════════════════
  group('ComplexListFilter', () {
    test('TC-COMP-PROV-001: 기본 필터는 isEmpty = true', () {
      const filter = ComplexListFilter();
      expect(filter.isEmpty, isTrue);
    });

    test('TC-COMP-PROV-002: 상태 필터 설정 후 isEmpty = false', () {
      const filter = ComplexListFilter(statusFilter: ComplexStatus.visited);
      expect(filter.isEmpty, isFalse);
    });

    test('TC-COMP-PROV-003: copyWith — statusFilter 변경', () {
      const original = ComplexListFilter();
      final updated =
          original.copyWith(statusFilter: ComplexStatus.planned);

      expect(updated.statusFilter, ComplexStatus.planned);
      expect(original.statusFilter, isNull); // 불변성 확인
    });

    test('TC-COMP-PROV-004: copyWith — clearStatus 옵션으로 상태 필터 초기화', () {
      const filter =
          ComplexListFilter(statusFilter: ComplexStatus.visited);
      final cleared = filter.copyWith(clearStatus: true);

      expect(cleared.statusFilter, isNull);
      expect(cleared.isEmpty, isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Group: 상태 필터 (FR-COMP-04)
  // ══════════════════════════════════════════════════════════════════════════
  group('상태 필터', () {
    late List<ComplexEntity> complexes;

    setUp(() {
      complexes = [
        _makeComplex(id: 'c1', name: '관심 단지', status: ComplexStatus.interested),
        _makeComplex(id: 'c2', name: '예정 단지', status: ComplexStatus.planned),
        _makeComplex(id: 'c3', name: '완료 단지1', status: ComplexStatus.visited),
        _makeComplex(id: 'c4', name: '완료 단지2', status: ComplexStatus.visited),
        _makeComplex(id: 'c5', name: '재방문 단지', status: ComplexStatus.revisit),
        _makeComplex(id: 'c6', name: '제외 단지', status: ComplexStatus.excluded),
      ];
    });

    test('TC-COMP-PROV-005: 상태 필터 없음(전체) → 전체 단지 반환', () {
      final result = applyFilterAndSort(
        complexes: complexes,
        filter: const ComplexListFilter(),
        sort: ComplexSortOption.recentlyAdded,
      );
      expect(result.length, 6);
    });

    test('TC-COMP-PROV-006: visited 필터 → 임장완료 단지만 반환 (2개)', () {
      final result = applyFilterAndSort(
        complexes: complexes,
        filter:
            const ComplexListFilter(statusFilter: ComplexStatus.visited),
        sort: ComplexSortOption.recentlyAdded,
      );
      expect(result.length, 2);
      expect(result.every((c) => c.status == ComplexStatus.visited), isTrue);
    });

    test('TC-COMP-PROV-007: excluded 필터 → 제외 단지만 반환 (1개)', () {
      final result = applyFilterAndSort(
        complexes: complexes,
        filter:
            const ComplexListFilter(statusFilter: ComplexStatus.excluded),
        sort: ComplexSortOption.recentlyAdded,
      );
      expect(result.length, 1);
      expect(result.first.name, '제외 단지');
    });

    test('TC-COMP-PROV-008: 조건에 맞는 단지 없음 → 빈 리스트 반환', () {
      // revisit이 1개 있으므로 비어있지 않음 — 실제로 없는 조건 테스트
      final emptyResult = applyFilterAndSort(
        complexes: [],
        filter:
            const ComplexListFilter(statusFilter: ComplexStatus.revisit),
        sort: ComplexSortOption.recentlyAdded,
      );
      expect(emptyResult, isEmpty);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Group: 매매가 필터 (FR-COMP-04 — 1억~30억 슬라이더)
  // ══════════════════════════════════════════════════════════════════════════
  group('매매가 필터', () {
    late List<ComplexEntity> complexes;

    setUp(() {
      complexes = [
        _makeComplex(id: 'c1', name: '5억 단지', recentTradePrice: '50000'),
        _makeComplex(id: 'c2', name: '10억 단지', recentTradePrice: '100000'),
        _makeComplex(id: 'c3', name: '15억 단지', recentTradePrice: '150,000'),
        _makeComplex(id: 'c4', name: '가격없음', recentTradePrice: null),
      ];
    });

    test('TC-COMP-PROV-009: minPrice=80000 → 10억, 15억 단지 반환', () {
      final result = applyFilterAndSort(
        complexes: complexes,
        filter: const ComplexListFilter(minPrice: 80000),
        sort: ComplexSortOption.recentlyAdded,
      );
      expect(result.length, 2);
      expect(result.map((c) => c.name),
          containsAll(['10억 단지', '15억 단지']));
    });

    test('TC-COMP-PROV-010: maxPrice=60000 → 5억 단지만 반환', () {
      final result = applyFilterAndSort(
        complexes: complexes,
        filter: const ComplexListFilter(maxPrice: 60000),
        sort: ComplexSortOption.recentlyAdded,
      );
      expect(result.length, 1);
      expect(result.first.name, '5억 단지');
    });

    test('TC-COMP-PROV-011: minPrice + maxPrice 범위 → 범위 내 단지만', () {
      final result = applyFilterAndSort(
        complexes: complexes,
        filter: const ComplexListFilter(minPrice: 90000, maxPrice: 110000),
        sort: ComplexSortOption.recentlyAdded,
      );
      expect(result.length, 1);
      expect(result.first.name, '10억 단지');
    });

    test('TC-COMP-PROV-012: 매매가 필터 적용 시 recentTradePrice가 null인 단지 제외', () {
      final result = applyFilterAndSort(
        complexes: complexes,
        filter: const ComplexListFilter(minPrice: 1000),
        sort: ComplexSortOption.recentlyAdded,
      );
      // '가격없음' 단지는 null이므로 제외
      expect(result.any((c) => c.name == '가격없음'), isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Group: 면적 필터 (평수 칩)
  // ══════════════════════════════════════════════════════════════════════════
  group('면적 필터 (평수 칩)', () {
    late List<ComplexEntity> complexes;

    setUp(() {
      // 24평 ≈ 79.3m², 34평 ≈ 112.4m², 59평 ≈ 195.0m²
      complexes = [
        _makeComplex(id: 'c1', name: '24평 단지', representativeArea: 79.34),
        _makeComplex(id: 'c2', name: '34평 단지', representativeArea: 112.40),
        _makeComplex(id: 'c3', name: '59평 단지', representativeArea: 194.97),
        _makeComplex(id: 'c4', name: '면적없음', representativeArea: null),
      ];
    });

    test('TC-COMP-PROV-013: 34평 칩 선택 → 34평 단지만 반환', () {
      final result = applyFilterAndSort(
        complexes: complexes,
        filter: const ComplexListFilter(areaFilters: [34]),
        sort: ComplexSortOption.recentlyAdded,
      );
      expect(result.length, 1);
      expect(result.first.name, '34평 단지');
    });

    test('TC-COMP-PROV-014: 복수 평수 칩 선택 (24, 59) → 2개 반환', () {
      final result = applyFilterAndSort(
        complexes: complexes,
        filter: const ComplexListFilter(areaFilters: [24, 59]),
        sort: ComplexSortOption.recentlyAdded,
      );
      expect(result.length, 2);
      expect(result.map((c) => c.name),
          containsAll(['24평 단지', '59평 단지']));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Group: 정렬 (FR-COMP-04)
  // ══════════════════════════════════════════════════════════════════════════
  group('정렬', () {
    late List<ComplexEntity> complexes;

    final t1 = DateTime(2026, 1, 1);
    final t2 = DateTime(2026, 2, 1);
    final t3 = DateTime(2026, 3, 1);

    setUp(() {
      complexes = [
        _makeComplex(
          id: 'c1',
          name: '나라 단지',
          recentTradePrice: '100000',
          createdAt: t2,
          lastInspectionAt: t3,
        ),
        _makeComplex(
          id: 'c2',
          name: '가나 단지',
          recentTradePrice: '50000',
          createdAt: t3,
          lastInspectionAt: t1,
        ),
        _makeComplex(
          id: 'c3',
          name: '다라 단지',
          recentTradePrice: '150000',
          createdAt: t1,
          lastInspectionAt: t2,
        ),
      ];
    });

    test('TC-COMP-PROV-015: 정렬 — 최근 등록순 (createdAt 내림차순)', () {
      final result = applyFilterAndSort(
        complexes: complexes,
        filter: const ComplexListFilter(),
        sort: ComplexSortOption.recentlyAdded,
      );
      expect(result[0].id, 'c2'); // t3
      expect(result[1].id, 'c1'); // t2
      expect(result[2].id, 'c3'); // t1
    });

    test('TC-COMP-PROV-016: 정렬 — 이름순 (가나다 오름차순)', () {
      final result = applyFilterAndSort(
        complexes: complexes,
        filter: const ComplexListFilter(),
        sort: ComplexSortOption.nameAsc,
      );
      expect(result[0].name, '가나 단지');
      expect(result[1].name, '나라 단지');
      expect(result[2].name, '다라 단지');
    });

    test('TC-COMP-PROV-017: 정렬 — 매매가 낮은순', () {
      final result = applyFilterAndSort(
        complexes: complexes,
        filter: const ComplexListFilter(),
        sort: ComplexSortOption.priceLow,
      );
      expect(result[0].name, '가나 단지'); // 50000
      expect(result[1].name, '나라 단지'); // 100000
      expect(result[2].name, '다라 단지'); // 150000
    });

    test('TC-COMP-PROV-018: 정렬 — 최근 임장순 (lastInspectionAt 내림차순)', () {
      final result = applyFilterAndSort(
        complexes: complexes,
        filter: const ComplexListFilter(),
        sort: ComplexSortOption.recentlyInspected,
      );
      expect(result[0].id, 'c1'); // t3
      expect(result[1].id, 'c3'); // t2
      expect(result[2].id, 'c2'); // t1
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Group: 복합 필터 + 정렬
  // ══════════════════════════════════════════════════════════════════════════
  group('복합 필터 + 정렬', () {
    test('TC-COMP-PROV-019: visited 상태 + minPrice 필터 + 이름순 정렬', () {
      final complexes = [
        _makeComplex(
            id: 'c1',
            name: '나 단지',
            status: ComplexStatus.visited,
            recentTradePrice: '120000'),
        _makeComplex(
            id: 'c2',
            name: '가 단지',
            status: ComplexStatus.visited,
            recentTradePrice: '80000'),
        _makeComplex(
            id: 'c3',
            name: '다 단지',
            status: ComplexStatus.interested,
            recentTradePrice: '120000'),
        _makeComplex(
            id: 'c4',
            name: '라 단지',
            status: ComplexStatus.visited,
            recentTradePrice: '50000'),
      ];

      final result = applyFilterAndSort(
        complexes: complexes,
        filter: const ComplexListFilter(
          statusFilter: ComplexStatus.visited,
          minPrice: 90000,
        ),
        sort: ComplexSortOption.nameAsc,
      );

      // visited이고 90000 이상인 것: c1(120000), c2는 80000이라 제외, c3는 interested라 제외, c4는 50000 제외
      expect(result.length, 1);
      expect(result.first.id, 'c1');
    });

    test('TC-COMP-PROV-020: 준공연도 필터 2010~2015 + 세대수 500이상', () {
      final complexes = [
        _makeComplex(
            id: 'c1',
            name: 'A',
            approvalDate: '20120315',
            totalHouseholds: 800),
        _makeComplex(
            id: 'c2',
            name: 'B',
            approvalDate: '20081020',
            totalHouseholds: 600),
        _makeComplex(
            id: 'c3',
            name: 'C',
            approvalDate: '20130601',
            totalHouseholds: 200),
      ];

      final result = applyFilterAndSort(
        complexes: complexes,
        filter: const ComplexListFilter(
          minApprovalYear: 2010,
          maxApprovalYear: 2015,
          minHouseholds: 500,
        ),
        sort: ComplexSortOption.recentlyAdded,
      );

      // A: 2012, 800세대 → 통과
      // B: 2008 → 연도 불통과
      // C: 2013, 200세대 → 세대수 불통과
      expect(result.length, 1);
      expect(result.first.id, 'c1');
    });
  });
}
