// TC-SOCIAL-001 ~ TC-SOCIAL-010
// 대상: lib/features/auth/data/repositories/social_auth_repository_impl.dart (S2에서 구현)
// 레이어: Unit — Google/Apple 소셜 로그인, Firestore 사용자 문서 생성
//
// AC 매핑:
//   FR-AUTH-03: Google 로그인 버튼 탭 → 인증 → Firestore users 문서 생성 → 홈 이동
//   FR-AUTH-04: Apple 로그인 (iOS 전용) → 인증 → 홈 이동

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:imjang_app/core/error/exceptions.dart';
import 'package:imjang_app/features/auth/data/repositories/social_auth_repository_impl.dart';
import 'package:imjang_app/features/auth/domain/entities/user_entity.dart';

import 'social_auth_test.mocks.dart';

@GenerateMocks([
  FirebaseAuth,
  FirebaseFirestore,
  GoogleSignIn,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
  UserCredential,
  User,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
])
void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;
  late MockGoogleSignInAccount mockGoogleAccount;
  late MockGoogleSignInAuthentication mockGoogleAuth;
  late MockCollectionReference<Map<String, dynamic>> mockUsersCollection;
  late MockDocumentReference<Map<String, dynamic>> mockDocRef;
  late MockDocumentSnapshot<Map<String, dynamic>> mockDocSnapshot;
  late SocialAuthRepositoryImpl repository;

  const testUid = 'google-uid-001';
  const testEmail = 'google.user@gmail.com';
  const testDisplayName = '구글유저';
  const testPhotoUrl = 'https://lh3.googleusercontent.com/photo.jpg';
  const testIdToken = 'test-google-id-token';
  const testAccessToken = 'test-google-access-token';

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockGoogleSignIn = MockGoogleSignIn();
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();
    mockGoogleAccount = MockGoogleSignInAccount();
    mockGoogleAuth = MockGoogleSignInAuthentication();
    mockUsersCollection = MockCollectionReference<Map<String, dynamic>>();
    mockDocRef = MockDocumentReference<Map<String, dynamic>>();
    mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

    repository = SocialAuthRepositoryImpl(
      firebaseAuth: mockFirebaseAuth,
      firestore: mockFirestore,
      googleSignIn: mockGoogleSignIn,
    );

    // 공통 User 목 설정
    when(mockUser.uid).thenReturn(testUid);
    when(mockUser.email).thenReturn(testEmail);
    when(mockUser.displayName).thenReturn(testDisplayName);
    when(mockUser.photoURL).thenReturn(testPhotoUrl);
    when(mockUserCredential.user).thenReturn(mockUser);

    // Firestore 체인 목 설정
    when(mockFirestore.collection('users')).thenReturn(mockUsersCollection);
    when(mockUsersCollection.doc(testUid)).thenReturn(mockDocRef);
    when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
  });

  // ---------------------------------------------------------------------------
  // Google 로그인 (FR-AUTH-03)
  // ---------------------------------------------------------------------------

  group('signInWithGoogle — FR-AUTH-03', () {
    void setupGoogleSignInSuccess() {
      when(mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockGoogleAccount);
      when(mockGoogleAccount.authentication)
          .thenAnswer((_) async => mockGoogleAuth);
      when(mockGoogleAuth.idToken).thenReturn(testIdToken);
      when(mockGoogleAuth.accessToken).thenReturn(testAccessToken);
      when(mockFirebaseAuth.signInWithCredential(any))
          .thenAnswer((_) async => mockUserCredential);
    }

    test(
      'TC-SOCIAL-001: Google 로그인 성공 → UserEntity 반환',
      () async {
        setupGoogleSignInSuccess();
        when(mockDocSnapshot.exists).thenReturn(true); // 기존 사용자

        final result = await repository.signInWithGoogle();

        expect(result, isA<UserEntity>());
        expect(result.uid, equals(testUid));
        expect(result.email, equals(testEmail));
        expect(result.authProvider, equals('google'));
      },
    );

    test(
      'TC-SOCIAL-002: 최초 Google 로그인 → Firestore users 컬렉션에 사용자 문서 생성',
      () async {
        setupGoogleSignInSuccess();
        when(mockDocSnapshot.exists).thenReturn(false); // 신규 사용자
        when(mockDocRef.set(any)).thenAnswer((_) async {});

        await repository.signInWithGoogle();

        verify(mockDocRef.set(argThat(
          allOf(
            containsPair('uid', testUid),
            containsPair('email', testEmail),
            containsPair('authProvider', 'google'),
          ),
        ))).called(1);
      },
    );

    test(
      'TC-SOCIAL-003: 재로그인 (기존 사용자) → Firestore 문서 set 미호출',
      () async {
        setupGoogleSignInSuccess();
        when(mockDocSnapshot.exists).thenReturn(true); // 기존 사용자

        await repository.signInWithGoogle();

        verifyNever(mockDocRef.set(any));
      },
    );

    test(
      'TC-SOCIAL-004: 사용자가 Google 인증 화면을 취소 → SocialAuthCancelledException throw',
      () async {
        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null); // 취소

        expect(
          () => repository.signInWithGoogle(),
          throwsA(isA<SocialAuthCancelledException>()),
        );
      },
    );

    test(
      'TC-SOCIAL-005: Google 인증 중 FirebaseAuthException → AuthAppException throw',
      () async {
        when(mockGoogleSignIn.signIn())
            .thenAnswer((_) async => mockGoogleAccount);
        when(mockGoogleAccount.authentication)
            .thenAnswer((_) async => mockGoogleAuth);
        when(mockGoogleAuth.idToken).thenReturn(testIdToken);
        when(mockGoogleAuth.accessToken).thenReturn(testAccessToken);
        when(mockFirebaseAuth.signInWithCredential(any))
            .thenThrow(FirebaseAuthException(code: 'account-exists-with-different-credential'));

        expect(
          () => repository.signInWithGoogle(),
          throwsA(isA<AuthAppException>()),
        );
      },
    );

    test(
      'TC-SOCIAL-006: Google 로그인 결과 UserEntity에 photoUrl 포함',
      () async {
        setupGoogleSignInSuccess();
        when(mockDocSnapshot.exists).thenReturn(true);

        final result = await repository.signInWithGoogle();

        expect(result.photoUrl, equals(testPhotoUrl));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Apple 로그인 (FR-AUTH-04)
  // ---------------------------------------------------------------------------

  group('signInWithApple — FR-AUTH-04', () {
    const testAppleIdToken = 'test-apple-id-token';
    const testAppleNonce = 'test-nonce-abc123';

    test(
      'TC-SOCIAL-007: Apple 로그인 성공 → UserEntity 반환 (authProvider="apple")',
      () async {
        // AppleSignIn은 플랫폼 채널을 통해 동작하므로 repository 내부에서
        // AppleSignInService를 주입받아 목 처리
        when(mockFirebaseAuth.signInWithCredential(any))
            .thenAnswer((_) async => mockUserCredential);
        when(mockDocSnapshot.exists).thenReturn(false);
        when(mockDocRef.set(any)).thenAnswer((_) async {});

        final result = await repository.signInWithAppleForTest(
          idToken: testAppleIdToken,
          rawNonce: testAppleNonce,
        );

        expect(result, isA<UserEntity>());
        expect(result.authProvider, equals('apple'));
      },
    );

    test(
      'TC-SOCIAL-008: 최초 Apple 로그인 → Firestore users 문서 생성',
      () async {
        when(mockFirebaseAuth.signInWithCredential(any))
            .thenAnswer((_) async => mockUserCredential);
        when(mockDocSnapshot.exists).thenReturn(false);
        when(mockDocRef.set(any)).thenAnswer((_) async {});

        await repository.signInWithAppleForTest(
          idToken: testAppleIdToken,
          rawNonce: testAppleNonce,
        );

        verify(mockDocRef.set(argThat(
          containsPair('authProvider', 'apple'),
        ))).called(1);
      },
    );

    test(
      'TC-SOCIAL-009: Apple 인증 취소 → SocialAuthCancelledException throw',
      () async {
        // signInWithAppleForTest에 null 전달 시 취소 처리
        expect(
          () => repository.signInWithAppleForTest(
            idToken: null,
            rawNonce: null,
          ),
          throwsA(isA<SocialAuthCancelledException>()),
        );
      },
    );

    test(
      'TC-SOCIAL-010: Apple 로그인 후 Firestore 문서에 createdAt 타임스탬프 포함',
      () async {
        when(mockFirebaseAuth.signInWithCredential(any))
            .thenAnswer((_) async => mockUserCredential);
        when(mockDocSnapshot.exists).thenReturn(false);

        Map<String, dynamic>? capturedData;
        when(mockDocRef.set(any)).thenAnswer((invocation) async {
          capturedData = invocation.positionalArguments[0] as Map<String, dynamic>;
        });

        await repository.signInWithAppleForTest(
          idToken: testAppleIdToken,
          rawNonce: testAppleNonce,
        );

        expect(capturedData, isNotNull);
        expect(capturedData!.containsKey('createdAt'), isTrue);
        expect(capturedData!.containsKey('lastLoginAt'), isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // signOut
  // ---------------------------------------------------------------------------

  group('signOut — 소셜 로그아웃', () {
    test(
      'TC-SOCIAL-011: Google 로그아웃 → GoogleSignIn.signOut + FirebaseAuth.signOut 호출',
      () async {
        when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
        when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});

        await repository.signOut();

        verify(mockGoogleSignIn.signOut()).called(1);
        verify(mockFirebaseAuth.signOut()).called(1);
      },
    );
  });
}
