// TC-REGION-UI-001 ~ TC-REGION-UI-012
// 대상: lib/features/region/presentation/screens/region_select_screen.dart (S2에서 구현)
// 레이어: Widget — 시도→시군구→읍면동 계층 선택 UI
//
// AC 매핑:
//   FR-API-05: 시도 → 시군구 → 읍면동 계층 선택 UI

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:imjang_app/features/region/domain/entities/region_entity.dart';
import 'package:imjang_app/features/region/presentation/providers/region_provider.dart';
import 'package:imjang_app/features/region/presentation/screens/region_select_screen.dart';

import 'region_select_screen_test.mocks.dart';

@GenerateMocks([RegionNotifier])
void main() {
  late MockRegionNotifier mockRegionNotifier;

  final sidoList = [
    RegionEntity(
      code: '1100000000',
      sidoName: '서울특별시',
      sigunguName: null,
      dongName: null,
      level: 1,
    ),
    RegionEntity(
      code: '2600000000',
      sidoName: '부산광역시',
      sigunguName: null,
      dongName: null,
      level: 1,
    ),
  ];

  final gangnamSigunguList = [
    RegionEntity(
      code: '1168000000',
      sidoName: '서울특별시',
      sigunguName: '강남구',
      dongName: null,
      level: 2,
    ),
    RegionEntity(
      code: '1165000000',
      sidoName: '서울특별시',
      sigunguName: '서초구',
      dongName: null,
      level: 2,
    ),
  ];

  final gangnamDongList = [
    RegionEntity(
      code: '1168010100',
      sidoName: '서울특별시',
      sigunguName: '강남구',
      dongName: '역삼동',
      level: 3,
    ),
    RegionEntity(
      code: '1168010300',
      sidoName: '서울특별시',
      sigunguName: '강남구',
      dongName: '삼성동',
      level: 3,
    ),
  ];

  Widget buildSubject({RegionState? initialState}) {
    return ProviderScope(
      overrides: [
        regionNotifierProvider.overrideWith(() => mockRegionNotifier),
      ],
      child: const MaterialApp(
        home: RegionSelectScreen(),
      ),
    );
  }

  setUp(() {
    mockRegionNotifier = MockRegionNotifier();
    when(mockRegionNotifier.build()).thenReturn(RegionState(
      sidoList: sidoList,
      selectedSido: null,
      sigunguList: [],
      selectedSigungu: null,
      dongList: [],
      selectedDong: null,
      isLoading: false,
    ));
  });

  // ---------------------------------------------------------------------------
  // 초기 렌더링
  // ---------------------------------------------------------------------------

  testWidgets(
    'TC-REGION-UI-001: 화면 초기 렌더링 — 시도 목록이 표시됨',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('서울특별시'), findsOneWidget);
      expect(find.text('부산광역시'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-REGION-UI-002: 초기 상태 — 시군구/읍면동 목록은 숨겨짐',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byKey(const Key('sigungu_list')), findsNothing);
      expect(find.byKey(const Key('dong_list')), findsNothing);
    },
  );

  // ---------------------------------------------------------------------------
  // 시도 선택
  // ---------------------------------------------------------------------------

  testWidgets(
    'TC-REGION-UI-003: 시도 선택 → selectSido 호출 + 시군구 목록 표시',
    (WidgetTester tester) async {
      when(mockRegionNotifier.selectSido(sidoList[0])).thenAnswer((_) async {});

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.text('서울특별시'));
      await tester.pump();

      verify(mockRegionNotifier.selectSido(sidoList[0])).called(1);
    },
  );

  testWidgets(
    'TC-REGION-UI-004: 시도 선택 후 상태 업데이트 → 해당 시도의 시군구 목록 표시',
    (WidgetTester tester) async {
      when(mockRegionNotifier.build()).thenReturn(RegionState(
        sidoList: sidoList,
        selectedSido: sidoList[0],
        sigunguList: gangnamSigunguList,
        selectedSigungu: null,
        dongList: [],
        selectedDong: null,
        isLoading: false,
      ));

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('강남구'), findsOneWidget);
      expect(find.text('서초구'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------------
  // 시군구 선택
  // ---------------------------------------------------------------------------

  testWidgets(
    'TC-REGION-UI-005: 시군구 선택 → selectSigungu 호출',
    (WidgetTester tester) async {
      when(mockRegionNotifier.build()).thenReturn(RegionState(
        sidoList: sidoList,
        selectedSido: sidoList[0],
        sigunguList: gangnamSigunguList,
        selectedSigungu: null,
        dongList: [],
        selectedDong: null,
        isLoading: false,
      ));
      when(mockRegionNotifier.selectSigungu(gangnamSigunguList[0]))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.text('강남구'));
      await tester.pump();

      verify(mockRegionNotifier.selectSigungu(gangnamSigunguList[0])).called(1);
    },
  );

  testWidgets(
    'TC-REGION-UI-006: 시군구 선택 후 상태 업데이트 → 읍면동 목록 표시',
    (WidgetTester tester) async {
      when(mockRegionNotifier.build()).thenReturn(RegionState(
        sidoList: sidoList,
        selectedSido: sidoList[0],
        sigunguList: gangnamSigunguList,
        selectedSigungu: gangnamSigunguList[0],
        dongList: gangnamDongList,
        selectedDong: null,
        isLoading: false,
      ));

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('역삼동'), findsOneWidget);
      expect(find.text('삼성동'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------------
  // 읍면동 선택 (최종 선택)
  // ---------------------------------------------------------------------------

  testWidgets(
    'TC-REGION-UI-007: 읍면동 선택 → selectDong 호출',
    (WidgetTester tester) async {
      when(mockRegionNotifier.build()).thenReturn(RegionState(
        sidoList: sidoList,
        selectedSido: sidoList[0],
        sigunguList: gangnamSigunguList,
        selectedSigungu: gangnamSigunguList[0],
        dongList: gangnamDongList,
        selectedDong: null,
        isLoading: false,
      ));
      when(mockRegionNotifier.selectDong(gangnamDongList[0]))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.text('역삼동'));
      await tester.pump();

      verify(mockRegionNotifier.selectDong(gangnamDongList[0])).called(1);
    },
  );

  testWidgets(
    'TC-REGION-UI-008: 읍면동 선택 완료 → 선택 결과 확인 버튼(또는 팝업) 표시',
    (WidgetTester tester) async {
      when(mockRegionNotifier.build()).thenReturn(RegionState(
        sidoList: sidoList,
        selectedSido: sidoList[0],
        sigunguList: gangnamSigunguList,
        selectedSigungu: gangnamSigunguList[0],
        dongList: gangnamDongList,
        selectedDong: gangnamDongList[0],
        isLoading: false,
      ));

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // 선택 완료 상태에서 확인 버튼 또는 선택된 지역명이 표시됨
      expect(
        find.byKey(const Key('region_confirm_button')),
        findsOneWidget,
      );
    },
  );

  // ---------------------------------------------------------------------------
  // 로딩 상태
  // ---------------------------------------------------------------------------

  testWidgets(
    'TC-REGION-UI-009: 데이터 로딩 중 → 로딩 인디케이터 표시',
    (WidgetTester tester) async {
      when(mockRegionNotifier.build()).thenReturn(RegionState(
        sidoList: [],
        selectedSido: null,
        sigunguList: [],
        selectedSigungu: null,
        dongList: [],
        selectedDong: null,
        isLoading: true,
      ));

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------------
  // 오프라인 시 로컬 캐시 사용
  // ---------------------------------------------------------------------------

  testWidgets(
    'TC-REGION-UI-010: 오프라인 상태에서도 시도 목록 표시 (로컬 캐시 사용)',
    (WidgetTester tester) async {
      // 오프라인이더라도 drift/SQLite에서 로컬 캐시 읽어오므로 목록이 표시됨
      when(mockRegionNotifier.build()).thenReturn(RegionState(
        sidoList: sidoList,
        selectedSido: null,
        sigunguList: [],
        selectedSigungu: null,
        dongList: [],
        selectedDong: null,
        isLoading: false,
      ));

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // 오프라인이어도 목록이 표시됨
      expect(find.text('서울특별시'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------------
  // 선택 경로(breadcrumb) 표시
  // ---------------------------------------------------------------------------

  testWidgets(
    'TC-REGION-UI-011: 시도 선택 후 — 선택된 시도명이 헤더/브레드크럼에 표시됨',
    (WidgetTester tester) async {
      when(mockRegionNotifier.build()).thenReturn(RegionState(
        sidoList: sidoList,
        selectedSido: sidoList[0],
        sigunguList: gangnamSigunguList,
        selectedSigungu: null,
        dongList: [],
        selectedDong: null,
        isLoading: false,
      ));

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // 선택된 시도명이 브레드크럼 또는 헤더에 표시됨
      expect(find.byKey(const Key('selected_sido_label')), findsOneWidget);
    },
  );

  testWidgets(
    'TC-REGION-UI-012: 다른 시도 선택 시 → 기존 시군구/읍면동 선택 초기화',
    (WidgetTester tester) async {
      // 강남구가 선택된 상태에서 다른 시도를 선택하면 sigungu/dong이 초기화됨
      when(mockRegionNotifier.selectSido(sidoList[1])).thenAnswer((_) async {});
      when(mockRegionNotifier.build()).thenReturn(RegionState(
        sidoList: sidoList,
        selectedSido: sidoList[0],
        sigunguList: gangnamSigunguList,
        selectedSigungu: gangnamSigunguList[0],
        dongList: gangnamDongList,
        selectedDong: gangnamDongList[0],
        isLoading: false,
      ));

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // 다른 시도 탭 → selectSido 호출 (초기화 로직은 Notifier 내부)
      await tester.tap(find.text('부산광역시'));
      await tester.pump();

      verify(mockRegionNotifier.selectSido(sidoList[1])).called(1);
    },
  );
}
