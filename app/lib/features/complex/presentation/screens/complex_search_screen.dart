import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imjang_app/features/complex/presentation/providers/complex_search_provider.dart';

class ComplexSearchScreen extends ConsumerStatefulWidget {
  const ComplexSearchScreen({super.key});

  @override
  ConsumerState<ComplexSearchScreen> createState() =>
      _ComplexSearchScreenState();
}

class _ComplexSearchScreenState extends ConsumerState<ComplexSearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(complexSearchStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('단지 검색'),
        leading: BackButton(key: const Key('search_back_button')),
      ),
      body: Column(
        children: [
          // 검색 입력 필드
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              key: const Key('search_text_field'),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '단지명을 입력하세요 (2글자 이상)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        key: const Key('search_clear_button'),
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
                // TODO: 500ms 디바운스 후 검색
              },
            ),
          ),
          // 지역 선택 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: OutlinedButton.icon(
              key: const Key('search_region_button'),
              icon: const Icon(Icons.location_on),
              label: const Text('지역 선택'),
              onPressed: () {
                // TODO: context.push('/region-select')
              },
            ),
          ),
          const SizedBox(height: 8),
          // 검색 결과 목록
          Expanded(
            child: _buildResultList(state),
          ),
        ],
      ),
    );
  }

  Widget _buildResultList(ComplexSearchState state) {
    if (state.isLoading) {
      return const Center(
          child: CircularProgressIndicator(key: Key('search_loading')));
    }
    if (state.error != null) {
      return Center(
        child: Text(
          '검색 오류: ${state.error}',
          key: const Key('search_error_text'),
        ),
      );
    }
    if (state.searchResults.isEmpty) {
      return const Center(
        child: Text(
          '검색 결과가 없습니다',
          key: Key('search_empty_text'),
        ),
      );
    }
    return ListView.builder(
      key: const Key('search_results_list'),
      itemCount: state.searchResults.length,
      itemBuilder: (context, index) {
        final item = state.searchResults[index];
        final isRegistered =
            state.registeredApiCodes.contains(item.complexCode);
        return ListTile(
          key: Key('search_result_item_${item.complexCode}'),
          title: Text(item.complexName),
          subtitle: item.address != null ? Text(item.address!) : null,
          trailing: isRegistered
              ? const Chip(
                  key: Key('already_registered_badge'),
                  label: Text('등록됨'),
                )
              : Text(
                  item.totalHouseholds != null
                      ? '${item.totalHouseholds}세대'
                      : '',
                ),
          onTap: isRegistered
              ? null
              : () {
                  // TODO: registerComplex
                },
        );
      },
    );
  }
}
