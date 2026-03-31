import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_entity.dart';
import 'package:imjang_app/features/public_api/domain/entities/real_price_item.dart';

/// 단지 상세 상태 프로바이더
final complexDetailProvider =
    StateProvider<AsyncValue<ComplexEntity?>>((ref) => const AsyncData(null));

/// 실거래가 목록 프로바이더
final complexRealPriceListProvider =
    StateProvider<List<RealPriceItem>>((ref) => []);

/// 선택된 탭 인덱스 프로바이더
final complexDetailTabProvider = StateProvider<int>((ref) => 0);
