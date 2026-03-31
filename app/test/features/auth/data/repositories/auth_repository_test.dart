// TC-REPO-001 ~ TC-REPO-006 + TC-AUTH-008
// 대상: lib/features/auth/data/repositories/auth_repository_impl.dart
// 레이어: Unit — Repository 구현체 (Firebase 목 처리)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:imjang_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:imjang_app/features/auth/domain/entities/user_entity.dart';
import 'package:imjang_app/core/error/exceptions.dart';

import 'auth_repository_test.mocks.dart';

@GenerateMocks([
  FirebaseAuth,
  UserCredential,
  User,
])
void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;
  late AuthRepositoryImpl repository;

  const testEmail = 'test@example.com';
  const testPassword = 'password123';
  const testUid = 'test-uid-001';
  const testDisplayName = '테스트유저';

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();
    repository = AuthRepositoryImpl(firebaseAuth: mockFirebaseAuth);

    // 기본 User 목 설정
    when(mockUser.uid).thenReturn(testUid);
    when(mockUser.email).thenReturn(testEmail);
    when(mockUser.displayName).thenReturn(testDisplayName);
    when(mockUser.photoURL).thenReturn(null);
    when(mockUserCredential.user).thenReturn(mockUser);
  });

  group('signUpWithEmail', () {
    test('TC-REPO-001: 신규 이메일 회원가입 성공 → UserEntity 반환', () async {
      when(
        mockFirebaseAuth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        ),
      ).thenAnswer((_) async => mockUserCredential);

      final result = await repository.signUpWithEmail(
        email: testEmail,
        password: testPassword,
        displayName: testDisplayName,
      );

      expect(result, isA<UserEntity>());
      expect(result.uid, equals(testUid));
      expect(result.email, equals(testEmail));

      verify(
        mockFirebaseAuth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        ),
      ).called(1);
    });

    test(
      'TC-REPO-002: 이미 등록된 이메일 회원가입 → AuthAppException throw',
      () async {
        when(
          mockFirebaseAuth.createUserWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
        ).thenThrow(
          FirebaseAuthException(code: 'email-already-in-use'),
        );

        expect(
          () => repository.signUpWithEmail(
            email: testEmail,
            password: testPassword,
            displayName: testDisplayName,
          ),
          throwsA(
            isA<AuthAppException>().having(
              (e) => e.code,
              'code',
              'email-already-in-use',
            ),
          ),
        );
      },
    );
  });

  group('signInWithEmail', () {
    test('TC-REPO-003: 올바른 자격증명 로그인 성공 → UserEntity 반환', () async {
      when(
        mockFirebaseAuth.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        ),
      ).thenAnswer((_) async => mockUserCredential);

      final result = await repository.signInWithEmail(
        email: testEmail,
        password: testPassword,
      );

      expect(result, isA<UserEntity>());
      expect(result.uid, equals(testUid));
      expect(result.email, equals(testEmail));
    });

    test(
      'TC-REPO-004: 잘못된 비밀번호 로그인 → AuthAppException throw',
      () async {
        when(
          mockFirebaseAuth.signInWithEmailAndPassword(
            email: testEmail,
            password: 'wrong-password',
          ),
        ).thenThrow(
          FirebaseAuthException(code: 'wrong-password'),
        );

        expect(
          () => repository.signInWithEmail(
            email: testEmail,
            password: 'wrong-password',
          ),
          throwsA(
            isA<AuthAppException>().having(
              (e) => e.code,
              'code',
              'wrong-password',
            ),
          ),
        );
      },
    );
  });

  group('signOut', () {
    test('TC-REPO-005: 로그아웃 성공 → FirebaseAuth.signOut() 호출됨', () async {
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});

      await repository.signOut();

      verify(mockFirebaseAuth.signOut()).called(1);
    });
  });

  group('authStateChanges — TC-AUTH-008 (로그인 상태 지속)', () {
    test(
      'TC-REPO-006: authStateChanges 스트림이 현재 User를 emit한다',
      () async {
        when(mockFirebaseAuth.authStateChanges()).thenAnswer(
          (_) => Stream.value(mockUser),
        );

        final stream = repository.authStateChanges();

        await expectLater(
          stream,
          emits(
            isA<UserEntity>().having((u) => u.uid, 'uid', testUid),
          ),
        );
      },
    );

    test(
      'TC-AUTH-008: 앱 재시작 후 로그인 상태 유지 — currentUser가 non-null이면 UserEntity 반환',
      () {
        when(mockFirebaseAuth.currentUser).thenReturn(mockUser);

        final currentUser = repository.currentUser;

        expect(currentUser, isNotNull);
        expect(currentUser!.uid, equals(testUid));
      },
    );

    test('앱 재시작 후 미인증 상태 — currentUser가 null이면 null 반환', () {
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      final currentUser = repository.currentUser;

      expect(currentUser, isNull);
    });
  });
}
