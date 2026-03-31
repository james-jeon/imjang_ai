// TC-COMP-DETAIL-001 ~ TC-COMP-DETAIL-016
// 대상: lib/features/complex/presentation/screens/complex_detail_screen.dart (S4 COMP-05, COMP-06)
// 레이어: Widget Test — 단지 상세 화면 (SCR-COMPLEX-DETAIL)
//
// S4 구현 후 아래 import를 활성화한다:
//   import 'package:imjang_app/features/complex/presentation/screens/complex_detail_screen.dart';
//   import 'package:imjang_app/features/complex/presentation/providers/complex_detail_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_entity.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_status.dart';
import 'package:imjang_app/features/public_api/domain/entities/real_price_item.dart';

import 'complex_detail_screen_test.mocks.dart';

// ─── S4 구현 전 스텁 ────────────────────────────────────────────────────────

abstract class ComplexDetailNotifier {
  AsyncValue<ComplexEntity?> build();
  Future<void> updateStatus(ComplexStatus newStatus);
  Future<void> deleteComplex();
}

// 상세 화면 스텁 (S4 구현 전 테스트용)
class _ComplexDetailScreenStub extends ConsumerWidget {
  final String complexId;

  const _ComplexDetailScreenStub({required this.complexId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complexState = ref.watch(_testComplexDetailProvider);
    final realPrices = ref.watch(_testRealPriceListProvider);
    final selectedTab = ref.watch(_testSelectedTabProvider);

    return complexState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(key: Key('detail_loading'))),
      ),
      error: (e, _) => Scaffold(
        body: Center(
            child: Text('오류: $e', key: const Key('detail_error_text'))),
      ),
      data: (complex) {
        if (complex == null) {
          return const Scaffold(
            body: Center(
                child: Text('단지를 찾을 수 없습니다',
                    key: Key('detail_not_found'))),
          );
        }
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(complex.name, key: const Key('detail_app_bar_title')),
              actions: [
                // 공유 버튼
                IconButton(
                  key: const Key('detail_share_button'),
                  icon: const Icon(Icons.share),
                  onPressed: () {},
                ),
                // 더보기 메뉴
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
                      key: Key('detail_status_label_${complex.status.name}'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                // 3개 탭
                const TabBar(
                  tabs: [
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
                      // 정보 탭
                      _InfoTab(complex: complex),
                      // 실거래가 탭
                      _PriceTab(prices: realPrices),
                      // 임장기록 탭
                      _InspectionTab(complexId: complex.id),
                    ],
                  ),
                ),
              ],
            ),
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
              // 구현 시: ref.read(complexDetailProvider.notifier).deleteComplex()
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
          subtitle: Text('${item.dealYear}.${item.dealMonth}.${item.dealDay}'),
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
        // 기록 작성 버튼
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

// 테스트 전용 프로바이더
final _testComplexDetailProvider =
    StateProvider<AsyncValue<ComplexEntity?>>((ref) => const AsyncData(null));

final _testRealPriceListProvider =
    StateProvider<List<RealPriceItem>>((ref) => []);

final _testSelectedTabProvider = StateProvider<int>((ref) => 0);

ComplexEntity _makeTestComplex({
  String id = 'c-001',
  String name = '래미안 역삼',
  ComplexStatus status = ComplexStatus.interested,
}) {
  final now = DateTime(2026, 3, 31);
  return ComplexEntity(
    id: id,
    ownerId: 'user-001',
    name: name,
    address: '서울시 강남구 역삼동 123',
    regionCode: '1168010100',
    status: status,
    totalHouseholds: 1200,
    approvalDate: '20100315',
    constructor: '삼성물산',
    sharedWith: const ['user-001'],
    createdAt: now,
    updatedAt: now,
  );
}

@GenerateMocks([ComplexDetailNotifier])
void main() {
  Widget buildSubject({
    required AsyncValue<ComplexEntity?> complexState,
    List<RealPriceItem> prices = const [],
    int selectedTab = 0,
    String complexId = 'c-001',
  }) {
    return ProviderScope(
      overrides: [
        _testComplexDetailProvider.overrideWith((_) => complexState),
        _testRealPriceListProvider.overrideWith((_) => prices),
        _testSelectedTabProvider.overrideWith((_) => selectedTab),
      ],
      child: MaterialApp(
        home: _ComplexDetailScreenStub(complexId: complexId),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 렌더링 — AppBar + 상태 배지
  // ══════════════════════════════════════════════════════════════════════════
  group('렌더링 — AppBar + 상태 배지', () {
    testWidgets(
      'TC-COMP-DETAIL-001: 화면 렌더링 — AppBar 단지명, 공유 버튼, 더보기 메뉴 존재',
      (WidgetTester tester) async {
        final complex = _makeTestComplex();

        await tester.pumpWidget(
          buildSubject(complexState: AsyncData(complex)),
        );

        expect(find.byKey(const Key('detail_app_bar_title')), findsOneWidget);
        expect(find.text('래미안 역삼'), findsWidgets);
        expect(find.byKey(const Key('detail_share_button')), findsOneWidget);
        expect(find.byKey(const Key('detail_more_menu')), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-DETAIL-002: 상태 배지 표시 — interested 상태',
      (WidgetTester tester) async {
        final complex =
            _makeTestComplex(status: ComplexStatus.interested);

        await tester.pumpWidget(
          buildSubject(complexState: AsyncData(complex)),
        );

        expect(find.byKey(const Key('detail_status_badge')), findsOneWidget);
        expect(
          find.byKey(const Key('detail_status_label_interested')),
          findsOneWidget,
        );
        expect(find.text('관심'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-DETAIL-003: 상태 배지 표시 — visited 상태',
      (WidgetTester tester) async {
        final complex =
            _makeTestComplex(status: ComplexStatus.visited);

        await tester.pumpWidget(
          buildSubject(complexState: AsyncData(complex)),
        );

        expect(
          find.byKey(const Key('detail_status_label_visited')),
          findsOneWidget,
        );
        expect(find.text('임장완료'), findsOneWidget);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 탭 구조 (COMP-05)
  // ══════════════════════════════════════════════════════════════════════════
  group('탭 구조', () {
    testWidgets(
      'TC-COMP-DETAIL-004: 3개 탭 존재 — 정보/실거래가/임장기록',
      (WidgetTester tester) async {
        final complex = _makeTestComplex();

        await tester.pumpWidget(
          buildSubject(complexState: AsyncData(complex)),
        );

        expect(find.byKey(const Key('tab_info')), findsOneWidget);
        expect(find.byKey(const Key('tab_price')), findsOneWidget);
        expect(find.byKey(const Key('tab_inspection')), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-DETAIL-005: 기본 탭(정보) — 기본정보 카드 표시',
      (WidgetTester tester) async {
        final complex = _makeTestComplex();

        await tester.pumpWidget(
          buildSubject(complexState: AsyncData(complex), selectedTab: 0),
        );

        expect(find.byKey(const Key('info_tab_content')), findsOneWidget);
        expect(find.byKey(const Key('info_address')), findsOneWidget);
        expect(find.text('서울시 강남구 역삼동 123'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-DETAIL-006: 정보 탭 — 세대수, 준공일, 시공사 표시',
      (WidgetTester tester) async {
        final complex = _makeTestComplex();

        await tester.pumpWidget(
          buildSubject(complexState: AsyncData(complex), selectedTab: 0),
        );

        expect(find.byKey(const Key('info_households')), findsOneWidget);
        expect(find.text('1200세대'), findsOneWidget);
        expect(find.byKey(const Key('info_approval_date')), findsOneWidget);
        expect(find.byKey(const Key('info_constructor')), findsOneWidget);
        expect(find.text('삼성물산'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-DETAIL-007: 실거래가 탭 — 거래 목록 표시',
      (WidgetTester tester) async {
        final complex = _makeTestComplex();
        final prices = [
          RealPriceItem(
            aptName: '래미안 역삼',
            dealAmount: '120,000',
            exclusiveArea: 84.98,
            floor: 15,
            dealYear: 2026,
            dealMonth: 3,
            dealDay: 15,
            dongName: '역삼동',
          ),
          RealPriceItem(
            aptName: '래미안 역삼',
            dealAmount: '115,000',
            exclusiveArea: 84.98,
            floor: 7,
            dealYear: 2026,
            dealMonth: 2,
            dealDay: 20,
            dongName: '역삼동',
          ),
        ];

        await tester.pumpWidget(
          buildSubject(
            complexState: AsyncData(complex),
            prices: prices,
            selectedTab: 1,
          ),
        );

        expect(find.byKey(const Key('price_list')), findsOneWidget);
        expect(find.text('120,000'), findsOneWidget);
        expect(find.text('115,000'), findsOneWidget);
        expect(find.text('15층 / 84.98m²'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-DETAIL-008: 실거래가 탭 — 데이터 없음 → "실거래가 정보가 없습니다" 표시',
      (WidgetTester tester) async {
        final complex = _makeTestComplex();

        await tester.pumpWidget(
          buildSubject(
            complexState: AsyncData(complex),
            prices: [],
            selectedTab: 1,
          ),
        );

        expect(find.byKey(const Key('price_tab_empty')), findsOneWidget);
        expect(find.text('실거래가 정보가 없습니다'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-DETAIL-009: 임장기록 탭 — "임장 기록 작성" 버튼 존재',
      (WidgetTester tester) async {
        final complex = _makeTestComplex();

        await tester.pumpWidget(
          buildSubject(
            complexState: AsyncData(complex),
            selectedTab: 2,
          ),
        );

        expect(
            find.byKey(const Key('inspection_tab_content')), findsOneWidget);
        expect(
            find.byKey(const Key('add_inspection_button')), findsOneWidget);
        expect(find.text('임장 기록 작성'), findsOneWidget);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 상태 변경 (COMP-06)
  // ══════════════════════════════════════════════════════════════════════════
  group('상태 변경 (COMP-06)', () {
    testWidgets(
      'TC-COMP-DETAIL-010: 상태 배지 탭 → 상태 변경 바텀시트 표시',
      (WidgetTester tester) async {
        final complex = _makeTestComplex();

        await tester.pumpWidget(
          buildSubject(complexState: AsyncData(complex)),
        );

        await tester.tap(find.byKey(const Key('detail_status_badge')));
        await tester.pumpAndSettle();

        // 바텀시트에 모든 상태 옵션이 표시되어야 함
        expect(find.byKey(const Key('status_option_interested')), findsOneWidget);
        expect(find.byKey(const Key('status_option_planned')), findsOneWidget);
        expect(find.byKey(const Key('status_option_visited')), findsOneWidget);
        expect(find.byKey(const Key('status_option_revisit')), findsOneWidget);
        expect(find.byKey(const Key('status_option_excluded')), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-DETAIL-011: 바텀시트에 5개 상태 옵션 표시',
      (WidgetTester tester) async {
        final complex = _makeTestComplex();

        await tester.pumpWidget(
          buildSubject(complexState: AsyncData(complex)),
        );

        await tester.tap(find.byKey(const Key('detail_status_badge')));
        await tester.pumpAndSettle();

        expect(find.text('관심'), findsWidgets);
        expect(find.text('임장예정'), findsWidgets);
        expect(find.text('임장완료'), findsWidgets);
        expect(find.text('재방문'), findsWidgets);
        expect(find.text('제외'), findsWidgets);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 단지 삭제 (FR-COMP-05)
  // ══════════════════════════════════════════════════════════════════════════
  group('단지 삭제 (FR-COMP-05)', () {
    testWidgets(
      'TC-COMP-DETAIL-012: 더보기 메뉴 → "단지 삭제" 옵션 존재',
      (WidgetTester tester) async {
        final complex = _makeTestComplex();

        await tester.pumpWidget(
          buildSubject(complexState: AsyncData(complex)),
        );

        await tester.tap(find.byKey(const Key('detail_more_menu')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('menu_item_delete')), findsOneWidget);
        expect(find.text('단지 삭제'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-DETAIL-013: 단지 삭제 선택 → 경고 다이얼로그 표시',
      (WidgetTester tester) async {
        final complex = _makeTestComplex();

        await tester.pumpWidget(
          buildSubject(complexState: AsyncData(complex)),
        );

        // 더보기 메뉴 열기
        await tester.tap(find.byKey(const Key('detail_more_menu')));
        await tester.pumpAndSettle();

        // "단지 삭제" 선택
        await tester.tap(find.byKey(const Key('menu_item_delete')));
        await tester.pumpAndSettle();

        // 경고 다이얼로그 표시
        expect(
            find.byKey(const Key('delete_confirm_dialog')), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-DETAIL-014: 삭제 경고 메시지 — "관련 임장 기록도 모두 삭제됩니다" 표시',
      (WidgetTester tester) async {
        final complex = _makeTestComplex();

        await tester.pumpWidget(
          buildSubject(complexState: AsyncData(complex)),
        );

        await tester.tap(find.byKey(const Key('detail_more_menu')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('menu_item_delete')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('delete_warning_message')),
          findsOneWidget,
        );
        expect(
          find.textContaining('관련 임장 기록도 모두 삭제됩니다'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'TC-COMP-DETAIL-015: 삭제 다이얼로그 — 취소/삭제 버튼 존재',
      (WidgetTester tester) async {
        final complex = _makeTestComplex();

        await tester.pumpWidget(
          buildSubject(complexState: AsyncData(complex)),
        );

        await tester.tap(find.byKey(const Key('detail_more_menu')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('menu_item_delete')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('delete_cancel_button')), findsOneWidget);
        expect(find.byKey(const Key('delete_confirm_button')), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-DETAIL-016: 삭제 다이얼로그 취소 → 다이얼로그 닫힘',
      (WidgetTester tester) async {
        final complex = _makeTestComplex();

        await tester.pumpWidget(
          buildSubject(complexState: AsyncData(complex)),
        );

        await tester.tap(find.byKey(const Key('detail_more_menu')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('menu_item_delete')));
        await tester.pumpAndSettle();

        // 취소 버튼 탭
        await tester.tap(find.byKey(const Key('delete_cancel_button')));
        await tester.pumpAndSettle();

        // 다이얼로그가 닫혀야 함
        expect(
            find.byKey(const Key('delete_confirm_dialog')), findsNothing);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 로딩 / 에러 / 404 상태
  // ══════════════════════════════════════════════════════════════════════════
  group('로딩 / 에러 / 404 상태', () {
    testWidgets(
      'TC-COMP-DETAIL-017: 로딩 상태 → CircularProgressIndicator 표시',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildSubject(complexState: const AsyncLoading()),
        );

        expect(find.byKey(const Key('detail_loading')), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-DETAIL-018: 에러 상태 → 에러 메시지 표시',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildSubject(
            complexState: AsyncError<ComplexEntity?>(
              Exception('Firestore 오류'),
              StackTrace.current,
            ),
          ),
        );
        await tester.pump();

        expect(find.byKey(const Key('detail_error_text')), findsOneWidget);
        expect(find.textContaining('오류'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-DETAIL-019: 단지 없음(null) → "단지를 찾을 수 없습니다" 표시',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildSubject(complexState: const AsyncData(null)),
        );

        expect(find.byKey(const Key('detail_not_found')), findsOneWidget);
        expect(find.text('단지를 찾을 수 없습니다'), findsOneWidget);
      },
    );
  });
}
