// TC-CTRL-001 ~ TC-CTRL-005 (FR-AUTH-01, FR-AUTH-02 전체)
// 대상: lib/features/auth/presentation/providers/auth_controller.dart
// 레이어: Unit — Riverpod Controller (Repository 목 처리)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:imjang_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:imjang_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:imjang_app/features/auth/domain/entities/user_entity.dart';
import 'package:imjang_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:imjang_app/core/error/exceptions.dart';

import 'auth_controller_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockAuthRepository;
  late ProviderContainer container;

  const testEmail = 'test@example.com';
  const testPassword = 'password123';
  const testDisplayName = '테스트유저';

  final testUserEntity = UserEntity(
    uid: 'test-uid-001',
    email: testEmail,
    displayName: testDisplayName,
    photoUrl: null,
    authProvider: 'email',
    createdAt: DateTime(2026, 3, 31),
    lastLoginAt: DateTime(2026, 3, 31),
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        // authRepositoryProvider를 목으로 오버라이드
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('signUp', () {
    test('TC-CTRL-001: 회원가입 성공 → state = AsyncData(UserEntity)', () async {
      when(
        mockAuthRepository.signUpWithEmail(
          email: testEmail,
          password: testPassword,
          displayName: testDisplayName,
        ),
      ).thenAnswer((_) async => testUserEntity);

      final controller = container.read(authControllerProvider.notifier);

      await controller.signUp(
        email: testEmail,
        password: testPassword,
        displayName: testDisplayName,
      );

      final state = container.read(authControllerProvider);
      expect(state, isA<AsyncData<UserEntity?>>());
      expect(state.value, equals(testUserEntity));
    });

    test(
      'TC-CTRL-002: 이미 가입된 이메일 회원가입 → state = AsyncError with 이미 가입된 이메일입니다',
      () async {
        when(
          mockAuthRepository.signUpWithEmail(
            email: testEmail,
            password: testPassword,
            displayName: testDisplayName,
          ),
        ).thenThrow(
          AuthAppException(
            code: 'email-already-in-use',
            message: '이미 가입된 이메일입니다',
          ),
        );

        final controller = container.read(authControllerProvider.notifier);

        await controller.signUp(
          email: testEmail,
          password: testPassword,
          displayName: testDisplayName,
        );

        final state = container.read(authControllerProvider);
        expect(state, isA<AsyncError>());
        expect(
          (state as AsyncError).error.toString(),
          contains('이미 가입된 이메일입니다'),
        );
      },
    );
  });

  group('signIn', () {
    test('TC-CTRL-003: 로그인 성공 → state = AsyncData(UserEntity)', () async {
      when(
        mockAuthRepository.signInWithEmail(
          email: testEmail,
          password: testPassword,
        ),
      ).thenAnswer((_) async => testUserEntity);

      final controller = container.read(authControllerProvider.notifier);

      await controller.signIn(
        email: testEmail,
        password: testPassword,
      );

      final state = container.read(authControllerProvider);
      expect(state, isA<AsyncData<UserEntity?>>());
      expect(state.value, equals(testUserEntity));
    });

    test(
      'TC-CTRL-004: 잘못된 자격증명 로그인 → state = AsyncError with 이메일 또는 비밀번호가 일치하지 않습니다',
      () async {
        when(
          mockAuthRepository.signInWithEmail(
            email: testEmail,
            password: 'wrong-password',
          ),
        ).thenThrow(
          AuthAppException(
            code: 'wrong-password',
            message: '이메일 또는 비밀번호가 일치하지 않습니다',
          ),
        );

        final controller = container.read(authControllerProvider.notifier);

        await controller.signIn(
          email: testEmail,
          password: 'wrong-password',
        );

        final state = container.read(authControllerProvider);
        expect(state, isA<AsyncError>());
        expect(
          (state as AsyncError).error.toString(),
          contains('이메일 또는 비밀번호가 일치하지 않습니다'),
        );
      },
    );
  });

  group('signOut', () {
    test('TC-CTRL-005: 로그아웃 → state = AsyncData(null)', () async {
      when(mockAuthRepository.signOut()).thenAnswer((_) async {});

      // 먼저 로그인된 상태로 설정
      when(
        mockAuthRepository.signInWithEmail(
          email: testEmail,
          password: testPassword,
        ),
      ).thenAnswer((_) async => testUserEntity);

      final controller = container.read(authControllerProvider.notifier);
      await controller.signIn(email: testEmail, password: testPassword);

      // 로그아웃 실행
      await controller.signOut();

      final state = container.read(authControllerProvider);
      expect(state, isA<AsyncData<UserEntity?>>());
      expect(state.value, isNull);

      verify(mockAuthRepository.signOut()).called(1);
    });
  });
}
