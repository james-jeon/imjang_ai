import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imjang_app/features/region/domain/entities/region_entity.dart';

class RegionState {
  final List<RegionEntity> sidoList;
  final RegionEntity? selectedSido;
  final List<RegionEntity> sigunguList;
  final RegionEntity? selectedSigungu;
  final List<RegionEntity> dongList;
  final RegionEntity? selectedDong;
  final bool isLoading;

  RegionState({
    required this.sidoList,
    this.selectedSido,
    required this.sigunguList,
    this.selectedSigungu,
    required this.dongList,
    this.selectedDong,
    required this.isLoading,
  });

  RegionState copyWith({
    List<RegionEntity>? sidoList,
    RegionEntity? selectedSido,
    bool clearSelectedSido = false,
    List<RegionEntity>? sigunguList,
    RegionEntity? selectedSigungu,
    bool clearSelectedSigungu = false,
    List<RegionEntity>? dongList,
    RegionEntity? selectedDong,
    bool clearSelectedDong = false,
    bool? isLoading,
  }) {
    return RegionState(
      sidoList: sidoList ?? this.sidoList,
      selectedSido: clearSelectedSido ? null : (selectedSido ?? this.selectedSido),
      sigunguList: sigunguList ?? this.sigunguList,
      selectedSigungu: clearSelectedSigungu ? null : (selectedSigungu ?? this.selectedSigungu),
      dongList: dongList ?? this.dongList,
      selectedDong: clearSelectedDong ? null : (selectedDong ?? this.selectedDong),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// The Notifier for region selection
class RegionNotifier extends AutoDisposeNotifier<RegionState> {
  @override
  RegionState build() {
    return RegionState(
      sidoList: [],
      selectedSido: null,
      sigunguList: [],
      selectedSigungu: null,
      dongList: [],
      selectedDong: null,
      isLoading: true,
    );
  }

  Future<void> selectSido(RegionEntity sido) async {
    state = state.copyWith(
      selectedSido: sido,
      sigunguList: [],
      clearSelectedSigungu: true,
      dongList: [],
      clearSelectedDong: true,
    );
  }

  Future<void> selectSigungu(RegionEntity sigungu) async {
    state = state.copyWith(
      selectedSigungu: sigungu,
      dongList: [],
      clearSelectedDong: true,
    );
  }

  Future<void> selectDong(RegionEntity dong) async {
    state = state.copyWith(selectedDong: dong);
  }
}

final regionNotifierProvider =
    AutoDisposeNotifierProvider<RegionNotifier, RegionState>(
  RegionNotifier.new,
);
