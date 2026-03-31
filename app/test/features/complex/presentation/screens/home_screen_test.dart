// TC-COMP-HOME-001 ~ TC-COMP-HOME-012
// 대상: lib/features/complex/presentation/screens/home_screen.dart (S4 COMP-04)
// 레이어: Widget Test — 단지 목록 화면 (SCR-HOME)
//
// S4 구현 후 아래 import를 활성화한다:
//   import 'package:imjang_app/features/complex/presentation/screens/home_screen.dart';
//   import 'package:imjang_app/features/complex/presentation/providers/complex_list_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_entity.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_status.dart';
import 'package:imjang_app/shared/widgets/empty_state_widget.dart';

import 'home_screen_test.mocks.dart';

// ─── S4 구현 전 스텁 인터페이스 ─────────────────────────────────────────────
// 구현 후 실제 클래스로 대체

abstract class ComplexListNotifier {
  AsyncValue<List<ComplexEntity>> build();
  Future<void> refresh();
  void setStatusFilter(ComplexStatus? status);
  void toggleAreaFilter(int pyeong);
  void clearFilters();
}

// 홈 화면 스텁 (S4 구현 전 테스트용)
class _HomeScreenStub extends ConsumerWidget {
  const _HomeScreenStub();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // S4 구현 후 실제 homeComplexListProvider를 watch한다
    // final complexState = ref.watch(homeComplexListProvider);
    // 현재는 테스트에서 override로 주입
    final complexState = ref.watch(_testComplexListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('임장노트'),
        actions: [
          // 검색/필터 버튼
          IconButton(
            key: const Key('home_search_button'),
            icon: const Icon(Icons.search),
            onPressed: () {},
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _StatusChip(label: '전체', status: null, key: const Key('chip_all')),
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
      // FAB (+) → 단지 검색/등록
      floatingActionButton: FloatingActionButton(
        key: const Key('home_fab'),
        onPressed: () {},
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
        label: RichText(text: TextSpan(text: label, style: DefaultTextStyle.of(context).style)),
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
        trailing: _StatusBadge(status: complex.status),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ComplexStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        status.label,
        key: Key('status_badge_${status.name}'),
      ),
    );
  }
}

// 테스트 전용 프로바이더 (실제 구현 시 homeComplexListProvider로 대체)
final _testComplexListProvider =
    StateProvider<AsyncValue<List<ComplexEntity>>>(
  (_) => const AsyncData([]),
);

// ─── Mock 생성 대상 ───────────────────────────────────────────────────────
@GenerateMocks([ComplexListNotifier])
void main() {
  final now = DateTime(2026, 3, 31);

  List<ComplexEntity> makeComplexList() => [
        ComplexEntity(
          id: 'c-001',
          ownerId: 'user-001',
          name: '래미안 역삼',
          address: '서울시 강남구 역삼동 123',
          regionCode: '1168010100',
          status: ComplexStatus.interested,
          sharedWith: const ['user-001'],
          createdAt: now,
          updatedAt: now,
        ),
        ComplexEntity(
          id: 'c-002',
          ownerId: 'user-001',
          name: '현대 강남',
          address: '서울시 강남구 대치동 456',
          regionCode: '1168010200',
          status: ComplexStatus.visited,
          lastInspectionAt: now.subtract(const Duration(days: 3)),
          averageRating: 4.2,
          recentTradePrice: '120,000',
          representativeArea: 84.98,
          sharedWith: const ['user-001'],
          createdAt: now.subtract(const Duration(days: 10)),
          updatedAt: now.subtract(const Duration(days: 3)),
        ),
        ComplexEntity(
          id: 'c-003',
          ownerId: 'user-001',
          name: '자이 서초',
          address: '서울시 서초구 반포동 789',
          regionCode: '1165010300',
          status: ComplexStatus.planned,
          sharedWith: const ['user-001'],
          createdAt: now.subtract(const Duration(days: 5)),
          updatedAt: now.subtract(const Duration(days: 5)),
        ),
      ];

  Widget buildSubject(AsyncValue<List<ComplexEntity>> complexState) {
    return ProviderScope(
      overrides: [
        _testComplexListProvider
            .overrideWith((ref) => complexState),
      ],
      child: const MaterialApp(
        home: _HomeScreenStub(),
      ),
    );
  }

  setUp(() {
    // mockNotifier reserved for S4 implementation override
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 렌더링
  // ══════════════════════════════════════════════════════════════════════════
  group('렌더링', () {
    testWidgets(
      'TC-COMP-HOME-001: 화면 렌더링 — 필수 UI 요소 존재',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildSubject(const AsyncData([])));

        expect(find.byKey(const Key('home_status_filter_bar')), findsOneWidget);
        expect(find.byKey(const Key('home_fab')), findsOneWidget);
        expect(find.byKey(const Key('home_bottom_nav')), findsOneWidget);
        expect(find.byKey(const Key('chip_all')), findsOneWidget);
        expect(find.byKey(const Key('chip_visited')), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-HOME-002: 상태 필터 칩 6개 표시 — 전체/관심/임장예정/임장완료/재방문/제외',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildSubject(const AsyncData([])));

        expect(find.byKey(const Key('chip_all')), findsOneWidget);
        expect(find.byKey(const Key('chip_interested')), findsOneWidget);
        expect(find.byKey(const Key('chip_planned')), findsOneWidget);
        expect(find.byKey(const Key('chip_visited')), findsOneWidget);
        expect(find.byKey(const Key('chip_revisit')), findsOneWidget);
        expect(find.byKey(const Key('chip_excluded')), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-HOME-003: 하단 탭 네비게이션 — 단지/지도/설정 탭 존재',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildSubject(const AsyncData([])));

        expect(find.text('단지'), findsOneWidget);
        expect(find.text('지도'), findsOneWidget);
        expect(find.text('설정'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-HOME-004: FAB(+) 버튼 존재',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildSubject(const AsyncData([])));
        expect(find.byKey(const Key('home_fab')), findsOneWidget);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 단지 목록 표시
  // ══════════════════════════════════════════════════════════════════════════
  group('단지 목록 표시', () {
    testWidgets(
      'TC-COMP-HOME-005: 단지 3개 → 카드 3개 표시',
      (WidgetTester tester) async {
        final complexes = makeComplexList();

        await tester.pumpWidget(
            buildSubject(AsyncData(complexes)));

        expect(find.byKey(const Key('home_complex_list')), findsOneWidget);
        expect(find.byKey(const Key('complex_card_c-001')), findsOneWidget);
        expect(find.byKey(const Key('complex_card_c-002')), findsOneWidget);
        expect(find.byKey(const Key('complex_card_c-003')), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-HOME-006: 카드에 단지명 표시',
      (WidgetTester tester) async {
        final complexes = makeComplexList();

        await tester.pumpWidget(
            buildSubject(AsyncData(complexes)));

        expect(find.text('래미안 역삼'), findsOneWidget);
        expect(find.text('현대 강남'), findsOneWidget);
        expect(find.text('자이 서초'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-HOME-007: 카드에 상태 배지 표시',
      (WidgetTester tester) async {
        final complexes = makeComplexList();

        await tester.pumpWidget(
            buildSubject(AsyncData(complexes)));
        await tester.pump();

        // interested = '관심', visited = '임장완료', planned = '임장예정'
        expect(find.text('관심'), findsWidgets);
        expect(find.text('임장완료'), findsOneWidget);
        expect(find.text('임장예정'), findsOneWidget);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 빈 상태
  // ══════════════════════════════════════════════════════════════════════════
  group('빈 상태', () {
    testWidgets(
      'TC-COMP-HOME-008: 빈 단지 목록 → EmptyStateWidget 표시',
      (WidgetTester tester) async {
        await tester
            .pumpWidget(buildSubject(const AsyncData([])));

        expect(find.byKey(const Key('home_empty_state')), findsOneWidget);
        expect(find.byType(EmptyStateWidget), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-HOME-009: 빈 상태 메시지 — "조건에 맞는 단지가 없습니다" 표시',
      (WidgetTester tester) async {
        await tester
            .pumpWidget(buildSubject(const AsyncData([])));

        expect(find.text('조건에 맞는 단지가 없습니다'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-HOME-010: 빈 상태 → "필터 초기화" 버튼 표시',
      (WidgetTester tester) async {
        await tester
            .pumpWidget(buildSubject(const AsyncData([])));

        expect(find.text('필터 초기화'), findsOneWidget);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 로딩 / 에러 상태
  // ══════════════════════════════════════════════════════════════════════════
  group('로딩 / 에러 상태', () {
    testWidgets(
      'TC-COMP-HOME-011: 로딩 상태 → CircularProgressIndicator 표시',
      (WidgetTester tester) async {
        await tester.pumpWidget(
            buildSubject(const AsyncLoading()));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byKey(const Key('home_complex_list')), findsNothing);
      },
    );

    testWidgets(
      'TC-COMP-HOME-012: 에러 상태 → 에러 메시지 표시',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildSubject(
            AsyncError<List<ComplexEntity>>(
              Exception('네트워크 오류'),
              StackTrace.current,
            ),
          ),
        );
        await tester.pump();

        expect(find.textContaining('오류'), findsOneWidget);
        expect(find.byKey(const Key('home_complex_list')), findsNothing);
      },
    );
  });
}
