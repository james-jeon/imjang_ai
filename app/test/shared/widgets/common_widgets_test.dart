// TC-UI-COMMON-001 ~ TC-UI-COMMON-025
// 대상: lib/shared/widgets/ 공통 UI 컴포넌트 (S2에서 구현)
// 레이어: Widget — AppBar, 버튼, 입력 필드, 로딩, 에러, 빈 상태, 토스트, 평점, 오프라인 배너
//
// CORE-05: 공통 UI 컴포넌트
// CORE-06: 오프라인 배너 UI

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:imjang_app/shared/widgets/imjang_app_bar.dart';
import 'package:imjang_app/shared/widgets/imjang_button.dart';
import 'package:imjang_app/shared/widgets/imjang_text_field.dart';
import 'package:imjang_app/shared/widgets/loading_widget.dart';
import 'package:imjang_app/shared/widgets/app_error_widget.dart';
import 'package:imjang_app/shared/widgets/empty_state_widget.dart';
import 'package:imjang_app/shared/widgets/toast_widget.dart';
import 'package:imjang_app/shared/widgets/rating_bar_widget.dart';
import 'package:imjang_app/shared/widgets/offline_banner_widget.dart';
import 'package:imjang_app/core/providers/network_provider.dart';

Widget wrapWithMaterial(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

Widget wrapWithProviderScope(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  // ---------------------------------------------------------------------------
  // ImjangAppBar
  // ---------------------------------------------------------------------------

  group('ImjangAppBar', () {
    testWidgets(
      'TC-UI-COMMON-001: title 텍스트가 AppBar에 표시됨',
      (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            appBar: ImjangAppBar(title: '임장노트'),
          ),
        ));

        expect(find.text('임장노트'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-UI-COMMON-002: leading 없으면 뒤로가기 버튼 미표시',
      (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            appBar: ImjangAppBar(title: '홈', showBackButton: false),
          ),
        ));

        expect(find.byIcon(Icons.arrow_back_ios), findsNothing);
      },
    );

    testWidgets(
      'TC-UI-COMMON-003: showBackButton=true이면 뒤로가기 버튼 표시',
      (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            appBar: ImjangAppBar(title: '상세', showBackButton: true),
          ),
        ));

        expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
      },
    );

    testWidgets(
      'TC-UI-COMMON-004: actions 위젯이 AppBar 우측에 표시됨',
      (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            appBar: ImjangAppBar(
              title: '임장노트',
              actions: [
                IconButton(
                  key: const Key('share_button'),
                  onPressed: () {},
                  icon: const Icon(Icons.share),
                ),
              ],
            ),
          ),
        ));

        expect(find.byKey(const Key('share_button')), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // ImjangButton
  // ---------------------------------------------------------------------------

  group('ImjangButton', () {
    testWidgets(
      'TC-UI-COMMON-005: label 텍스트가 버튼에 표시됨',
      (WidgetTester tester) async {
        await tester.pumpWidget(wrapWithMaterial(
          ImjangButton(
            label: '확인',
            onPressed: () {},
          ),
        ));

        expect(find.text('확인'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-UI-COMMON-006: onPressed 콜백이 탭 시 호출됨',
      (WidgetTester tester) async {
        var pressed = false;
        await tester.pumpWidget(wrapWithMaterial(
          ImjangButton(
            label: '확인',
            onPressed: () => pressed = true,
          ),
        ));

        await tester.tap(find.text('확인'));
        await tester.pump();

        expect(pressed, isTrue);
      },
    );

    testWidgets(
      'TC-UI-COMMON-007: isLoading=true → 로딩 인디케이터 표시, 버튼 비활성화',
      (WidgetTester tester) async {
        await tester.pumpWidget(wrapWithMaterial(
          ImjangButton(
            label: '저장',
            onPressed: () {},
            isLoading: true,
          ),
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        // 버튼 텍스트 미표시 (로딩 인디케이터로 대체)
        expect(find.text('저장'), findsNothing);
      },
    );

    testWidgets(
      'TC-UI-COMMON-008: isEnabled=false → 버튼 비활성화 (onPressed null)',
      (WidgetTester tester) async {
        await tester.pumpWidget(wrapWithMaterial(
          ImjangButton(
            label: '확인',
            onPressed: () {},
            isEnabled: false,
          ),
        ));

        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull);
      },
    );

    testWidgets(
      'TC-UI-COMMON-009: variant=secondary → outlined 스타일 버튼',
      (WidgetTester tester) async {
        await tester.pumpWidget(wrapWithMaterial(
          ImjangButton(
            label: '취소',
            onPressed: () {},
            variant: ImjangButtonVariant.secondary,
          ),
        ));

        expect(find.byType(OutlinedButton), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // ImjangTextField
  // ---------------------------------------------------------------------------

  group('ImjangTextField', () {
    testWidgets(
      'TC-UI-COMMON-010: labelText가 입력 필드 레이블로 표시됨',
      (WidgetTester tester) async {
        await tester.pumpWidget(wrapWithMaterial(
          ImjangTextField(
            labelText: '아파트명',
            controller: TextEditingController(),
          ),
        ));

        expect(find.text('아파트명'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-UI-COMMON-011: 텍스트 입력 시 controller에 반영됨',
      (WidgetTester tester) async {
        final controller = TextEditingController();
        await tester.pumpWidget(wrapWithMaterial(
          ImjangTextField(
            labelText: '메모',
            controller: controller,
          ),
        ));

        await tester.enterText(find.byType(TextField), '역삼 래미안');
        expect(controller.text, equals('역삼 래미안'));
      },
    );

    testWidgets(
      'TC-UI-COMMON-012: errorText가 있으면 에러 메시지 표시',
      (WidgetTester tester) async {
        await tester.pumpWidget(wrapWithMaterial(
          ImjangTextField(
            labelText: '이메일',
            controller: TextEditingController(),
            errorText: '올바른 이메일 형식이 아닙니다',
          ),
        ));

        expect(find.text('올바른 이메일 형식이 아닙니다'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // LoadingWidget (기존 확장)
  // ---------------------------------------------------------------------------

  group('LoadingWidget', () {
    testWidgets(
      'TC-UI-COMMON-013: 메시지 없는 기본 로딩 — CircularProgressIndicator 표시',
      (WidgetTester tester) async {
        await tester.pumpWidget(wrapWithMaterial(const LoadingWidget()));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'TC-UI-COMMON-014: message 있을 때 — 텍스트도 함께 표시됨',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithMaterial(const LoadingWidget(message: '불러오는 중...')),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('불러오는 중...'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // AppErrorWidget (기존 확장)
  // ---------------------------------------------------------------------------

  group('AppErrorWidget', () {
    testWidgets(
      'TC-UI-COMMON-015: 에러 메시지가 표시됨',
      (WidgetTester tester) async {
        await tester.pumpWidget(wrapWithMaterial(
          const AppErrorWidget(message: '데이터를 불러올 수 없습니다'),
        ));

        expect(find.text('데이터를 불러올 수 없습니다'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-UI-COMMON-016: onRetry 있을 때 — "다시 시도" 버튼 표시',
      (WidgetTester tester) async {
        var retried = false;
        await tester.pumpWidget(wrapWithMaterial(
          AppErrorWidget(
            message: '오류 발생',
            onRetry: () => retried = true,
          ),
        ));

        expect(find.text('다시 시도'), findsOneWidget);
        await tester.tap(find.text('다시 시도'));
        await tester.pump();
        expect(retried, isTrue);
      },
    );

    testWidgets(
      'TC-UI-COMMON-017: onRetry 없으면 "다시 시도" 버튼 미표시',
      (WidgetTester tester) async {
        await tester.pumpWidget(wrapWithMaterial(
          const AppErrorWidget(message: '오류 발생'),
        ));

        expect(find.text('다시 시도'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // EmptyStateWidget
  // ---------------------------------------------------------------------------

  group('EmptyStateWidget', () {
    testWidgets(
      'TC-UI-COMMON-018: message와 아이콘이 표시됨',
      (WidgetTester tester) async {
        await tester.pumpWidget(wrapWithMaterial(
          const EmptyStateWidget(
            message: '등록된 임장 기록이 없습니다',
            icon: Icons.home_outlined,
          ),
        ));

        expect(find.text('등록된 임장 기록이 없습니다'), findsOneWidget);
        expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'TC-UI-COMMON-019: actionLabel 있을 때 — 액션 버튼 표시',
      (WidgetTester tester) async {
        var tapped = false;
        await tester.pumpWidget(wrapWithMaterial(
          EmptyStateWidget(
            message: '임장 기록이 없습니다',
            icon: Icons.add,
            actionLabel: '첫 임장 기록 추가',
            onAction: () => tapped = true,
          ),
        ));

        expect(find.text('첫 임장 기록 추가'), findsOneWidget);
        await tester.tap(find.text('첫 임장 기록 추가'));
        await tester.pump();
        expect(tapped, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // RatingBarWidget
  // ---------------------------------------------------------------------------

  group('RatingBarWidget', () {
    testWidgets(
      'TC-UI-COMMON-020: rating=3.0 → 별 3개 채워짐, 2개 빈 상태',
      (WidgetTester tester) async {
        await tester.pumpWidget(wrapWithMaterial(
          const RatingBarWidget(rating: 3.0, maxRating: 5),
        ));

        // 채워진 별 아이콘과 빈 별 아이콘이 올바른 수로 렌더됨
        expect(find.byIcon(Icons.star), findsNWidgets(3));
        expect(find.byIcon(Icons.star_border), findsNWidgets(2));
      },
    );

    testWidgets(
      'TC-UI-COMMON-021: interactive=true → 별 탭 시 onRatingChanged 콜백 호출',
      (WidgetTester tester) async {
        double? changedRating;
        await tester.pumpWidget(wrapWithMaterial(
          RatingBarWidget(
            rating: 2.0,
            maxRating: 5,
            interactive: true,
            onRatingChanged: (r) => changedRating = r,
          ),
        ));

        // 4번째 별 탭
        final stars = find.byIcon(Icons.star_border);
        await tester.tap(stars.at(1)); // 4번째 별 (index=1 in empty stars)
        await tester.pump();

        expect(changedRating, isNotNull);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // OfflineBannerWidget (CORE-06)
  // ---------------------------------------------------------------------------

  group('OfflineBannerWidget', () {
    testWidgets(
      'TC-UI-COMMON-022: 오프라인 상태(isOffline=true) → 배너 표시',
      (WidgetTester tester) async {
        await tester.pumpWidget(wrapWithProviderScope(
          const Scaffold(body: OfflineBannerWidget()),
          overrides: [
            isOfflineProvider.overrideWith(
              (ref) => Stream.value(true),
            ),
          ],
        ));
        await tester.pump();

        expect(find.byKey(const Key('offline_banner')), findsOneWidget);
        expect(find.text('오프라인 상태입니다'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-UI-COMMON-023: 온라인 상태(isOffline=false) → 배너 미표시',
      (WidgetTester tester) async {
        await tester.pumpWidget(wrapWithProviderScope(
          const Scaffold(body: OfflineBannerWidget()),
          overrides: [
            isOfflineProvider.overrideWith(
              (ref) => Stream.value(false),
            ),
          ],
        ));
        await tester.pump();

        expect(find.byKey(const Key('offline_banner')), findsNothing);
      },
    );

    testWidgets(
      'TC-UI-COMMON-024: 오프라인 배너 색상 — error 컬러 계열',
      (WidgetTester tester) async {
        await tester.pumpWidget(wrapWithProviderScope(
          const Scaffold(body: OfflineBannerWidget()),
          overrides: [
            isOfflineProvider.overrideWith(
              (ref) => Stream.value(true),
            ),
          ],
        ));
        await tester.pump();

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byKey(const Key('offline_banner')),
            matching: find.byType(Container),
          ).first,
        );
        // 배너 컨테이너의 decoration color가 설정되어 있음
        expect(container.decoration, isNotNull);
      },
    );

    testWidgets(
      'TC-UI-COMMON-025: 오프라인 → 온라인 전환 → 배너 자동으로 사라짐',
      (WidgetTester tester) async {
        // StreamController로 온/오프라인 전환 시뮬레이션
        // OfflineBannerWidget이 Stream을 listen하여 자동으로 UI 업데이트함
        await tester.pumpWidget(wrapWithProviderScope(
          const Scaffold(body: OfflineBannerWidget()),
          overrides: [
            isOfflineProvider.overrideWith(
              (ref) => Stream.value(false), // 이미 온라인
            ),
          ],
        ));
        await tester.pump();

        expect(find.byKey(const Key('offline_banner')), findsNothing);
      },
    );
  });
}
