import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_entity.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_status.dart';

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
    // 면적 필터 (대표 면적 <-> 평수 변환: 1평 = 3.305785m2)
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
    // 준공연도 필터 (approvalDate = "20100315" 형식 -> 앞 4자리)
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
        final aDate =
            a.lastInspectionAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            b.lastInspectionAt ?? DateTime.fromMillisecondsSinceEpoch(0);
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

/// 필터 상태 프로바이더
final complexListFilterProvider =
    StateProvider<ComplexListFilter>((ref) => const ComplexListFilter());

/// 정렬 상태 프로바이더
final complexSortOptionProvider =
    StateProvider<ComplexSortOption>((ref) => ComplexSortOption.recentlyAdded);

/// 홈 화면 단지 목록 프로바이더
final homeComplexListProvider =
    StateProvider<AsyncValue<List<ComplexEntity>>>(
  (_) => const AsyncData([]),
);
