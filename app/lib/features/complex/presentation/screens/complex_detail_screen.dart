import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_entity.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_status.dart';
import 'package:imjang_app/features/complex/presentation/providers/complex_detail_provider.dart';
import 'package:imjang_app/features/public_api/domain/entities/real_price_item.dart';

class ComplexDetailScreen extends ConsumerWidget {
  final String complexId;

  const ComplexDetailScreen({super.key, required this.complexId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complexState = ref.watch(complexDetailProvider);
    final realPrices = ref.watch(complexRealPriceListProvider);
    final selectedTab = ref.watch(complexDetailTabProvider);

    return complexState.when(
      loading: () => const Scaffold(
        body: Center(
            child: CircularProgressIndicator(key: Key('detail_loading'))),
      ),
      error: (e, _) => Scaffold(
        body: Center(
            child:
                Text('오류: $e', key: const Key('detail_error_text'))),
      ),
      data: (complex) {
        if (complex == null) {
          return const Scaffold(
            body: Center(
                child: Text('단지를 찾을 수 없습니다',
                    key: Key('detail_not_found'))),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(complex.name,
                key: const Key('detail_app_bar_title')),
            actions: [
              IconButton(
                key: const Key('detail_share_button'),
                icon: const Icon(Icons.share),
                onPressed: () {},
              ),
              PopupMenuButton<String>(
                key: const Key('detail_more_menu'),
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteDialog(context, ref);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    key: Key('menu_item_delete'),
                    value: 'delete',
                    child: Text('단지 삭제'),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // 상태 배지 (탭하여 변경)
              GestureDetector(
                key: const Key('detail_status_badge'),
                onTap: () => _showStatusChangeSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(complex.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    complex.status.label,
                    key: Key(
                        'detail_status_label_${complex.status.name}'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              // 3개 탭
              TabBar(
                controller: null, // 구현 시 TabController 사용
                tabs: const [
                  Tab(key: Key('tab_info'), text: '정보'),
                  Tab(key: Key('tab_price'), text: '실거래가'),
                  Tab(key: Key('tab_inspection'), text: '임장기록'),
                ],
              ),
              // 탭 콘텐츠
              Expanded(
                child: IndexedStack(
                  index: selectedTab,
                  children: [
                    _InfoTab(complex: complex),
                    _PriceTab(prices: realPrices),
                    _InspectionTab(complexId: complex.id),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(ComplexStatus status) {
    switch (status) {
      case ComplexStatus.interested:
        return Colors.blue;
      case ComplexStatus.planned:
        return Colors.orange;
      case ComplexStatus.visited:
        return Colors.green;
      case ComplexStatus.revisit:
        return Colors.purple;
      case ComplexStatus.excluded:
        return Colors.grey;
    }
  }

  void _showStatusChangeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ComplexStatus.values
            .map(
              (s) => ListTile(
                key: Key('status_option_${s.name}'),
                title: Text(s.label),
                onTap: () => Navigator.pop(context),
              ),
            )
            .toList(),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        key: const Key('delete_confirm_dialog'),
        title: const Text('단지 삭제'),
        content: const Text(
          '단지를 삭제하면 관련 임장 기록도 모두 삭제됩니다',
          key: Key('delete_warning_message'),
        ),
        actions: [
          TextButton(
            key: const Key('delete_cancel_button'),
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            key: const Key('delete_confirm_button'),
            onPressed: () {
              Navigator.pop(context);
              // TODO: ref.read(complexDetailProvider.notifier).deleteComplex()
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final ComplexEntity complex;

  const _InfoTab({required this.complex});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('info_tab_content'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: const Text('주소'),
                subtitle:
                    Text(complex.address, key: const Key('info_address')),
              ),
              if (complex.totalHouseholds != null)
                ListTile(
                  title: const Text('세대수'),
                  subtitle: Text('${complex.totalHouseholds}세대',
                      key: const Key('info_households')),
                ),
              if (complex.approvalDate != null)
                ListTile(
                  title: const Text('준공일'),
                  subtitle: Text(complex.approvalDate!,
                      key: const Key('info_approval_date')),
                ),
              if (complex.constructor != null)
                ListTile(
                  title: const Text('시공사'),
                  subtitle: Text(complex.constructor!,
                      key: const Key('info_constructor')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceTab extends StatelessWidget {
  final List<RealPriceItem> prices;

  const _PriceTab({required this.prices});

  @override
  Widget build(BuildContext context) {
    if (prices.isEmpty) {
      return const Center(
        child: Text('실거래가 정보가 없습니다',
            key: Key('price_tab_empty')),
      );
    }
    return ListView.builder(
      key: const Key('price_list'),
      itemCount: prices.length,
      itemBuilder: (context, index) {
        final item = prices[index];
        return ListTile(
          key: Key('price_item_$index'),
          title: Text(item.dealAmount),
          subtitle:
              Text('${item.dealYear}.${item.dealMonth}.${item.dealDay}'),
          trailing: Text('${item.floor}층 / ${item.exclusiveArea}m²'),
        );
      },
    );
  }
}

class _InspectionTab extends StatelessWidget {
  final String complexId;

  const _InspectionTab({required this.complexId});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('inspection_tab_content'),
      children: [
        Expanded(
          child: Center(
            child: Text('임장기록 목록 (complexId: $complexId)',
                key: const Key('inspection_list_placeholder')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            key: const Key('add_inspection_button'),
            icon: const Icon(Icons.add),
            label: const Text('임장 기록 작성'),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}
