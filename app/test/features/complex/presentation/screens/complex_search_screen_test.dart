// TC-COMP-SEARCH-001 ~ TC-COMP-SEARCH-012
// 대상: lib/features/complex/presentation/screens/complex_search_screen.dart (S4 COMP-03)
// 레이어: Widget Test — 단지 검색/등록 화면 (SCR-SEARCH)
//
// S4 구현 후 아래 import를 활성화한다:
//   import 'package:imjang_app/features/complex/presentation/screens/complex_search_screen.dart';
//   import 'package:imjang_app/features/complex/presentation/providers/complex_search_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:imjang_app/features/public_api/domain/entities/apt_list_item.dart';

import 'complex_search_screen_test.mocks.dart';

// ─── S4 구현 전 스텁 ────────────────────────────────────────────────────────

/// 검색 화면 상태 (구현 시 실제 Provider로 대체)
class ComplexSearchState {
  final List<AptListItem> searchResults;
  final bool isLoading;
  final String? error;
  final Set<String> registeredApiCodes; // 이미 등록된 단지 publicApiCode 집합

  const ComplexSearchState({
    this.searchResults = const [],
    this.isLoading = false,
    this.error,
    this.registeredApiCodes = const {},
  });
}

abstract class ComplexSearchNotifier {
  ComplexSearchState build();
  Future<void> search(String query);
  Future<void> registerComplex(AptListItem item);
}

// 검색 화면 스텁 (S4 구현 전 테스트용)
class _ComplexSearchScreenStub extends ConsumerStatefulWidget {
  const _ComplexSearchScreenStub();

  @override
  ConsumerState<_ComplexSearchScreenStub> createState() =>
      _ComplexSearchScreenStubState();
}

class _ComplexSearchScreenStubState
    extends ConsumerState<_ComplexSearchScreenStub> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_testSearchStateProvider);

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
                // 구현 시: 500ms 디바운스 후 ref.read(searchProvider.notifier).search(value)
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
                // 구현 시: context.push('/region-select')
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
                  // 구현 시: ref.read(searchProvider.notifier).registerComplex(item)
                },
        );
      },
    );
  }
}

// 테스트 전용 상태 프로바이더
final _testSearchStateProvider = StateProvider<ComplexSearchState>(
  (_) => const ComplexSearchState(),
);

@GenerateMocks([ComplexSearchNotifier])
void main() {
  AptListItem makeItem({
    required String code,
    required String name,
    String? address,
    int? households,
  }) {
    return AptListItem(
      complexCode: code,
      complexName: name,
      regionCode: '1168010100',
      address: address,
      totalHouseholds: households,
    );
  }

  Widget buildSubject(ComplexSearchState searchState) {
    return ProviderScope(
      overrides: [
        _testSearchStateProvider.overrideWith((_) => searchState),
      ],
      child: const MaterialApp(
        home: _ComplexSearchScreenStub(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 렌더링
  // ══════════════════════════════════════════════════════════════════════════
  group('렌더링', () {
    testWidgets(
      'TC-COMP-SEARCH-001: 화면 렌더링 — 필수 UI 요소 존재',
      (WidgetTester tester) async {
        await tester.pumpWidget(
            buildSubject(const ComplexSearchState()));

        expect(find.byKey(const Key('search_text_field')), findsOneWidget);
        expect(find.byKey(const Key('search_region_button')), findsOneWidget);
        expect(find.byKey(const Key('search_back_button')), findsOneWidget);
        expect(find.text('단지 검색'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-SEARCH-002: 초기 상태 — "검색 결과가 없습니다" 또는 힌트 표시',
      (WidgetTester tester) async {
        await tester.pumpWidget(
            buildSubject(const ComplexSearchState()));

        // 검색 전 초기 상태
        expect(find.byKey(const Key('search_results_list')), findsNothing);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 검색 입력 (FR-COMP-01 — 2글자 이상 + 디바운스)
  // ══════════════════════════════════════════════════════════════════════════
  group('검색 입력', () {
    testWidgets(
      'TC-COMP-SEARCH-003: 검색어 입력 → TextField에 텍스트 반영',
      (WidgetTester tester) async {
        await tester.pumpWidget(
            buildSubject(const ComplexSearchState()));

        await tester.enterText(
            find.byKey(const Key('search_text_field')), '래미안');
        expect(find.text('래미안'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-SEARCH-004: 텍스트 입력 후 지우기 버튼 표시',
      (WidgetTester tester) async {
        await tester.pumpWidget(
            buildSubject(const ComplexSearchState()));

        await tester.enterText(
            find.byKey(const Key('search_text_field')), '래미안');
        await tester.pump();

        expect(find.byKey(const Key('search_clear_button')), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-SEARCH-005: 지우기 버튼 탭 → 검색어 초기화',
      (WidgetTester tester) async {
        await tester.pumpWidget(
            buildSubject(const ComplexSearchState()));

        await tester.enterText(
            find.byKey(const Key('search_text_field')), '래미안');
        await tester.pump();

        await tester.tap(find.byKey(const Key('search_clear_button')));
        await tester.pump();

        // TextField가 비어있어야 함
        final textField = tester.widget<TextField>(
            find.byKey(const Key('search_text_field')));
        expect(textField.controller?.text, isEmpty);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 검색 결과 표시
  // ══════════════════════════════════════════════════════════════════════════
  group('검색 결과 표시', () {
    testWidgets(
      'TC-COMP-SEARCH-006: 검색 결과 2개 → 목록 항목 2개 표시',
      (WidgetTester tester) async {
        final results = [
          makeItem(code: 'A001', name: '래미안 역삼', address: '서울시 강남구', households: 500),
          makeItem(code: 'A002', name: '현대 강남', address: '서울시 강남구', households: 300),
        ];

        await tester.pumpWidget(
          buildSubject(ComplexSearchState(searchResults: results)),
        );

        expect(find.byKey(const Key('search_results_list')), findsOneWidget);
        expect(find.byKey(const Key('search_result_item_A001')), findsOneWidget);
        expect(find.byKey(const Key('search_result_item_A002')), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-SEARCH-007: 검색 결과 항목에 단지명, 주소, 세대수 표시',
      (WidgetTester tester) async {
        final results = [
          makeItem(
            code: 'A001',
            name: '래미안 역삼',
            address: '서울시 강남구 역삼동',
            households: 1200,
          ),
        ];

        await tester.pumpWidget(
          buildSubject(ComplexSearchState(searchResults: results)),
        );

        expect(find.text('래미안 역삼'), findsOneWidget);
        expect(find.text('서울시 강남구 역삼동'), findsOneWidget);
        expect(find.text('1200세대'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-SEARCH-008: 로딩 중 → CircularProgressIndicator 표시',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildSubject(const ComplexSearchState(isLoading: true)),
        );

        expect(find.byKey(const Key('search_loading')), findsOneWidget);
        expect(find.byKey(const Key('search_results_list')), findsNothing);
      },
    );

    testWidgets(
      'TC-COMP-SEARCH-009: 검색 오류 → 에러 메시지 표시',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildSubject(const ComplexSearchState(error: '네트워크 오류')),
        );

        expect(find.byKey(const Key('search_error_text')), findsOneWidget);
        expect(find.textContaining('검색 오류'), findsOneWidget);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 이미 등록된 단지 (FR-COMP-01)
  // ══════════════════════════════════════════════════════════════════════════
  group('이미 등록된 단지', () {
    testWidgets(
      'TC-COMP-SEARCH-010: 이미 등록된 단지 → "등록됨" 배지 표시',
      (WidgetTester tester) async {
        final results = [
          makeItem(code: 'A001', name: '래미안 역삼', households: 500),
          makeItem(code: 'A002', name: '현대 강남', households: 300),
        ];

        await tester.pumpWidget(
          buildSubject(
            ComplexSearchState(
              searchResults: results,
              registeredApiCodes: {'A001'}, // A001이 이미 등록됨
            ),
          ),
        );

        expect(find.byKey(const Key('already_registered_badge')), findsOneWidget);
        expect(find.text('등록됨'), findsOneWidget);
        // A002는 등록되지 않았으므로 세대수 표시
        expect(find.text('300세대'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-COMP-SEARCH-011: 이미 등록된 단지 항목은 탭 불가 (onTap = null)',
      (WidgetTester tester) async {
        final results = [
          makeItem(code: 'A001', name: '래미안 역삼'),
        ];

        await tester.pumpWidget(
          buildSubject(
            ComplexSearchState(
              searchResults: results,
              registeredApiCodes: {'A001'},
            ),
          ),
        );

        final listTile = tester.widget<ListTile>(
          find.byKey(const Key('search_result_item_A001')),
        );
        // 이미 등록된 단지는 onTap이 null이어야 함
        expect(listTile.onTap, isNull);
      },
    );

    testWidgets(
      'TC-COMP-SEARCH-012: 등록되지 않은 단지 항목은 탭 가능 (onTap != null)',
      (WidgetTester tester) async {
        final results = [
          makeItem(code: 'B001', name: '자이 서초'),
        ];

        await tester.pumpWidget(
          buildSubject(
            ComplexSearchState(
              searchResults: results,
              registeredApiCodes: const {}, // 등록된 단지 없음
            ),
          ),
        );

        final listTile = tester.widget<ListTile>(
          find.byKey(const Key('search_result_item_B001')),
        );
        expect(listTile.onTap, isNotNull);
      },
    );
  });
}
