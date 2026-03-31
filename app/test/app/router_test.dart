// TC-ROUTER-001 ~ TC-ROUTER-004 + TC-CORE-001~003
// 대상: lib/app/router.dart
// 레이어: Widget/Integration — 인증 상태에 따른 라우팅 가드

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:imjang_app/app/router.dart';
import 'package:imjang_app/core/providers/firebase_providers.dart';
import 'package:imjang_app/features/auth/domain/entities/user_entity.dart';
import 'package:imjang_app/features/auth/presentation/providers/auth_provider.dart';

/// 테스트용 더미 화면 위젯 — 실제 화면 구현 전 라우팅만 검증
class _FakeLoginScreen extends StatelessWidget {
  const _FakeLoginScreen();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('LoginScreen'));
}

class _FakeHomeScreen extends StatelessWidget {
  const _FakeHomeScreen();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('HomeScreen'));
}

void main() {
  /// 미인증 상태(null) 오버라이드 세트
  List<Override> unauthenticatedOverrides() => [
        authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
      ];

  /// 인증 상태 오버라이드 세트
  List<Override> authenticatedOverrides() => [
        authStateChangesProvider.overrideWith(
          (ref) => Stream.value(
            UserEntity(
              uid: 'test-uid',
              email: 'test@example.com',
              displayName: '테스트유저',
              photoUrl: null,
              authProvider: 'email',
              createdAt: DateTime(2026, 3, 31),
              lastLoginAt: DateTime(2026, 3, 31),
            ),
          ),
        ),
      ];

  Widget buildApp({required List<Override> overrides}) {
    return ProviderScope(
      overrides: overrides,
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(routerProvider);
          return MaterialApp.router(
            routerConfig: router,
          );
        },
      ),
    );
  }

  testWidgets(
    'TC-ROUTER-001 (TC-CORE-001): 미인증 상태에서 앱 시작 → /login 화면 표시',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(overrides: unauthenticatedOverrides()));
      // 스트림이 resolve될 때까지 대기
      await tester.pumpAndSettle();

      expect(find.text('LoginScreen'), findsOneWidget);
      expect(find.text('HomeScreen'), findsNothing);
    },
  );

  testWidgets(
    'TC-ROUTER-002 (TC-CORE-002): 인증된 상태에서 앱 시작 → /home 화면 표시',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(overrides: authenticatedOverrides()));
      await tester.pumpAndSettle();

      expect(find.text('HomeScreen'), findsOneWidget);
      expect(find.text('LoginScreen'), findsNothing);
    },
  );

  testWidgets(
    'TC-ROUTER-003 (TC-CORE-003): 인증된 상태에서 /login 직접 접근 → /home으로 리디렉션',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(overrides: authenticatedOverrides()));
      await tester.pumpAndSettle();

      // 인증된 상태에서 /login 경로 push 시도
      final BuildContext context = tester.element(find.text('HomeScreen'));
      context.go('/login');
      await tester.pumpAndSettle();

      // /home으로 리디렉션되어야 함
      expect(find.text('HomeScreen'), findsOneWidget);
      expect(find.text('LoginScreen'), findsNothing);
    },
  );

  testWidgets(
    'TC-ROUTER-004: 미인증 상태에서 /home 직접 접근 → /login으로 리디렉션',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(overrides: unauthenticatedOverrides()));
      await tester.pumpAndSettle();

      // 미인증 상태에서 /home 경로 push 시도
      final BuildContext context = tester.element(find.text('LoginScreen'));
      context.go('/home');
      await tester.pumpAndSettle();

      // /login으로 리디렉션되어야 함
      expect(find.text('LoginScreen'), findsOneWidget);
      expect(find.text('HomeScreen'), findsNothing);
    },
  );

  group('routerProvider', () {
    test('TC-CORE-001b: routerProvider가 GoRouter 인스턴스를 반환한다', () {
      final container = ProviderContainer(
        overrides: unauthenticatedOverrides(),
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      expect(router, isA<GoRouter>());
    });
  });
}
