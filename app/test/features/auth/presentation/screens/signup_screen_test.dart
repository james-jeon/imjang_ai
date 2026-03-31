// TC-UI-SIGNUP-001 ~ TC-UI-SIGNUP-006 (FR-AUTH-01 전체)
// 대상: lib/features/auth/presentation/screens/signup_screen.dart
// 레이어: Widget Test — 회원가입 폼 유효성 검증 UI

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:imjang_app/features/auth/domain/entities/user_entity.dart';
import 'package:imjang_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:imjang_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:imjang_app/core/error/exceptions.dart';

import 'signup_screen_test.mocks.dart';

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
        home: SignupScreen(),
      ),
    );
  }

  setUp(() {
    mockAuthController = MockAuthControllerNotifier();
    when(mockAuthController.build()).thenReturn(const AsyncData(null));
  });

  testWidgets(
    'TC-UI-SIGNUP-001: 화면 렌더링 — 필수 UI 요소 존재',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());

      // 이메일 입력 필드
      expect(find.byKey(const Key('signup_email_field')), findsOneWidget);
      // 비밀번호 입력 필드
      expect(find.byKey(const Key('signup_password_field')), findsOneWidget);
      // 비밀번호 확인 입력 필드
      expect(
        find.byKey(const Key('signup_password_confirm_field')),
        findsOneWidget,
      );
      // 가입 버튼
      expect(find.byKey(const Key('signup_submit_button')), findsOneWidget);
    },
  );

  testWidgets(
    'TC-UI-SIGNUP-002 (TC-AUTH-003a): 잘못된 이메일 형식 → 이메일 에러 표시',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(
        find.byKey(const Key('signup_email_field')),
        'not-valid-email',
      );
      await tester.tap(find.byKey(const Key('signup_submit_button')));
      await tester.pump();

      expect(find.text('올바른 이메일 형식이 아닙니다'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-UI-SIGNUP-003 (TC-AUTH-004a): 비밀번호 7자 입력 후 제출 → 길이 에러 표시',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(
        find.byKey(const Key('signup_email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('signup_password_field')),
        'short12', // 7자
      );
      await tester.tap(find.byKey(const Key('signup_submit_button')));
      await tester.pump();

      expect(find.text('비밀번호는 8자 이상이어야 합니다'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-UI-SIGNUP-004 (TC-AUTH-005a): 비밀번호 불일치 입력 후 제출 → 불일치 에러 표시',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(
        find.byKey(const Key('signup_email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('signup_password_field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('signup_password_confirm_field')),
        'different456',
      );
      await tester.tap(find.byKey(const Key('signup_submit_button')));
      await tester.pump();

      expect(find.text('비밀번호가 일치하지 않습니다'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-UI-SIGNUP-005: 올바른 입력으로 가입 버튼 탭 → AuthController.signUp 호출',
    (WidgetTester tester) async {
      when(
        mockAuthController.signUp(
          email: 'test@example.com',
          password: 'password123',
          displayName: anyNamed('displayName'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(buildSubject());

      await tester.enterText(
        find.byKey(const Key('signup_email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('signup_password_field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('signup_password_confirm_field')),
        'password123',
      );
      await tester.tap(find.byKey(const Key('signup_submit_button')));
      await tester.pump();

      verify(
        mockAuthController.signUp(
          email: 'test@example.com',
          password: 'password123',
          displayName: anyNamed('displayName'),
        ),
      ).called(1);
    },
  );

  testWidgets(
    'TC-UI-SIGNUP-006 (TC-AUTH-002a): 이미 가입된 이메일 에러 → 에러 메시지 표시',
    (WidgetTester tester) async {
      when(mockAuthController.build()).thenReturn(
        AsyncError<UserEntity?>(
          AuthAppException(
            code: 'email-already-in-use',
            message: '이미 가입된 이메일입니다',
          ),
          StackTrace.current,
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('이미 가입된 이메일입니다'), findsOneWidget);
    },
  );
}
