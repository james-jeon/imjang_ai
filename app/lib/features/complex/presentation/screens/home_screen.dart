import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_entity.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_status.dart';
import 'package:imjang_app/features/complex/presentation/providers/complex_list_provider.dart';
import 'package:imjang_app/shared/widgets/empty_state_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complexState = ref.watch(homeComplexListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('임장노트'),
        actions: [
          IconButton(
            key: const Key('home_search_button'),
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to search
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 상태 필터 칩 바
          SizedBox(
            height: 48,
            child: ListView(
              key: const Key('home_status_filter_bar'),
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _StatusChip(
                    label: '전체', status: null, key: const Key('chip_all')),
                _StatusChip(
                    label: '관심',
                    status: ComplexStatus.interested,
                    key: const Key('chip_interested')),
                _StatusChip(
                    label: '임장예정',
                    status: ComplexStatus.planned,
                    key: const Key('chip_planned')),
                _StatusChip(
                    label: '임장완료',
                    status: ComplexStatus.visited,
                    key: const Key('chip_visited')),
                _StatusChip(
                    label: '재방문',
                    status: ComplexStatus.revisit,
                    key: const Key('chip_revisit')),
                _StatusChip(
                    label: '제외',
                    status: ComplexStatus.excluded,
                    key: const Key('chip_excluded')),
              ],
            ),
          ),
          // 단지 목록
          Expanded(
            child: complexState.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (complexes) {
                if (complexes.isEmpty) {
                  return EmptyStateWidget(
                    key: const Key('home_empty_state'),
                    message: '조건에 맞는 단지가 없습니다',
                    icon: Icons.apartment_outlined,
                    actionLabel: '필터 초기화',
                    onAction: () {},
                  );
                }
                return ListView.builder(
                  key: const Key('home_complex_list'),
                  itemCount: complexes.length,
                  itemBuilder: (context, index) {
                    final complex = complexes[index];
                    return _ComplexCard(
                      key: Key('complex_card_${complex.id}'),
                      complex: complex,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('home_fab'),
        onPressed: () {
          // TODO: Navigate to search/register
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        key: const Key('home_bottom_nav'),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.apartment), label: '단지'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: '지도'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final ComplexStatus? status;

  const _StatusChip({super.key, required this.label, this.status});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        onSelected: (_) {},
      ),
    );
  }
}

class _ComplexCard extends StatelessWidget {
  final ComplexEntity complex;

  const _ComplexCard({super.key, required this.complex});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(complex.name, key: Key('card_name_${complex.id}')),
        subtitle: Text(complex.address),
        trailing: Chip(
          label: Text(
            complex.status.label,
            key: Key('status_badge_${complex.status.name}'),
          ),
        ),
      ),
    );
  }
}
