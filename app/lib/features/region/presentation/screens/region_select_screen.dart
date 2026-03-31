import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imjang_app/features/region/domain/entities/region_entity.dart';
import 'package:imjang_app/features/region/presentation/providers/region_provider.dart';

class RegionSelectScreen extends ConsumerWidget {
  const RegionSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(regionNotifierProvider);
    final notifier = ref.read(regionNotifierProvider.notifier);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('지역 선택')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          if (state.selectedSido != null)
            Padding(
              key: const Key('selected_sido_label'),
              padding: const EdgeInsets.all(16),
              child: Text(
                _buildBreadcrumb(state),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Confirm button when dong is selected
          if (state.selectedDong != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                key: const Key('region_confirm_button'),
                onPressed: () {
                  Navigator.of(context).pop(state.selectedDong);
                },
                child: Text(
                  '${state.selectedDong!.dongName} 선택 완료',
                ),
              ),
            ),

          // Region lists
          Expanded(
            child: _buildRegionList(context, state, notifier),
          ),
        ],
      ),
    );
  }

  String _buildBreadcrumb(RegionState state) {
    final parts = <String>[];
    if (state.selectedSido != null) {
      parts.add(state.selectedSido!.sidoName);
    }
    if (state.selectedSigungu != null) {
      parts.add(state.selectedSigungu!.sigunguName!);
    }
    if (state.selectedDong != null) {
      parts.add(state.selectedDong!.dongName!);
    }
    return parts.join(' > ');
  }

  Widget _buildRegionList(
    BuildContext context,
    RegionState state,
    RegionNotifier notifier,
  ) {
    // Show dong list if sigungu is selected
    if (state.selectedSigungu != null && state.dongList.isNotEmpty) {
      return Column(
        children: [
          // Still show sido list for re-selection
          _buildSidoList(state, notifier),
          // Show sigungu list
          _buildSigunguList(state, notifier),
          // Show dong list
          Expanded(
            child: ListView.builder(
              key: const Key('dong_list'),
              itemCount: state.dongList.length,
              itemBuilder: (context, index) {
                final dong = state.dongList[index];
                return ListTile(
                  title: Text(dong.dongName ?? ''),
                  selected: state.selectedDong == dong,
                  onTap: () => notifier.selectDong(dong),
                );
              },
            ),
          ),
        ],
      );
    }

    // Show sigungu list if sido is selected
    if (state.selectedSido != null && state.sigunguList.isNotEmpty) {
      return Column(
        children: [
          // Sido list for re-selection
          _buildSidoList(state, notifier),
          // Sigungu list
          Expanded(
            child: ListView.builder(
              key: const Key('sigungu_list'),
              itemCount: state.sigunguList.length,
              itemBuilder: (context, index) {
                final sigungu = state.sigunguList[index];
                return ListTile(
                  title: Text(sigungu.sigunguName ?? ''),
                  selected: state.selectedSigungu == sigungu,
                  onTap: () => notifier.selectSigungu(sigungu),
                );
              },
            ),
          ),
        ],
      );
    }

    // Show sido list only
    return ListView.builder(
      itemCount: state.sidoList.length,
      itemBuilder: (context, index) {
        final sido = state.sidoList[index];
        return ListTile(
          title: Text(sido.sidoName),
          selected: state.selectedSido == sido,
          onTap: () => notifier.selectSido(sido),
        );
      },
    );
  }

  Widget _buildSidoList(RegionState state, RegionNotifier notifier) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.sidoList.length,
        itemBuilder: (context, index) {
          final sido = state.sidoList[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(sido.sidoName),
              selected: state.selectedSido == sido,
              onSelected: (_) => notifier.selectSido(sido),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSigunguList(RegionState state, RegionNotifier notifier) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.sigunguList.length,
        itemBuilder: (context, index) {
          final sigungu = state.sigunguList[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(sigungu.sigunguName ?? ''),
              selected: state.selectedSigungu == sigungu,
              onSelected: (_) => notifier.selectSigungu(sigungu),
            ),
          );
        },
      ),
    );
  }
}
