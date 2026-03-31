// TC-UI-LOGIN-001 ~ TC-UI-LOGIN-006 + TC-AUTH-007a
// 대상: lib/features/auth/presentation/screens/login_screen.dart
// 레이어: Widget Test — 폼 렌더링, 유효성 검증 UI, 에러 메시지 표시

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:imjang_app/features/auth/domain/entities/user_entity.dart';
import 'package:imjang_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:imjang_app/features/auth/presentation/screens/login_screen.dart';
import 'package:imjang_app/core/error/exceptions.dart';

import 'login_screen_test.mocks.dart';

@GenerateMocks([AuthControllerNotifier])
void main() {
  late MockAuthControllerNotifier mockAuthController;

  Widget buildSubject({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => mockAuthController),
        ...overrides,
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  setUp(() {
    mockAuthController = MockAuthControllerNotifier();
    // 기본 초기 상태: 로딩 없음
    when(mockAuthController.build()).thenReturn(const AsyncData(null));
  });

  testWidgets(
    'TC-UI-LOGIN-001: 화면 렌더링 — 필수 UI 요소 존재',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());

      // 이메일 입력 필드
      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      // 비밀번호 입력 필드
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      // 로그인 버튼
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      // 회원가입 링크
      expect(find.byKey(const Key('login_signup_link')), findsOneWidget);
    },
  );

  testWidgets(
    'TC-UI-LOGIN-002: 빈 폼 제출 — 이메일 에러 메시지 표시',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump();

      expect(find.text('이메일을 입력해 주세요'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-UI-LOGIN-003: 잘못된 이메일 형식 입력 후 제출 — 형식 에러 표시',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'not-an-email',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump();

      expect(find.text('올바른 이메일 형식이 아닙니다'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-UI-LOGIN-004: 올바른 입력으로 로그인 버튼 탭 → AuthController.signIn 호출',
    (WidgetTester tester) async {
      when(
        mockAuthController.signIn(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(buildSubject());

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'password123',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump();

      verify(
        mockAuthController.signIn(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    },
  );

  testWidgets(
    'TC-UI-LOGIN-005: 로그인 중 로딩 상태 — 로딩 인디케이터 표시',
    (WidgetTester tester) async {
      // 로딩 상태를 시뮬레이션하기 위해 컨트롤러 상태를 AsyncLoading으로 설정
      when(mockAuthController.build())
          .thenReturn(const AsyncLoading<UserEntity?>());

      await tester.pumpWidget(buildSubject(
        overrides: [
          authControllerProvider.overrideWith(() {
            mockAuthController;
            return mockAuthController;
          }),
        ],
      ));

      // 로딩 인디케이터 존재 확인
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // 로그인 버튼이 비활성화되어 있거나 로딩 인디케이터로 대체됨
      final submitButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('login_submit_button')),
      );
      expect(submitButton.onPressed, isNull);
    },
  );

  testWidgets(
    'TC-UI-LOGIN-006 (TC-AUTH-007a): 로그인 실패 → 에러 메시지 표시',
    (WidgetTester tester) async {
      // 에러 상태 시뮬레이션
      when(mockAuthController.build()).thenReturn(
        AsyncError<UserEntity?>(
          AuthAppException(
            code: 'wrong-password',
            message: '이메일 또는 비밀번호가 일치하지 않습니다',
          ),
          StackTrace.current,
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('이메일 또는 비밀번호가 일치하지 않습니다'), findsOneWidget);
    },
  );
}
