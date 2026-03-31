import 'package:firebase_auth/firebase_auth.dart';

/// Auth DataSource 인터페이스
/// S1 Decision: Auth는 단순 CRUD이므로 Repository가 FirebaseAuth를 직접 사용.
/// DataSource 구현체는 복잡한 데이터 소스(공공API, 로컬DB 등)에서 도입 예정.
/// 참고: 교차 리뷰 권고 — "단순 CRUD는 UseCase/DataSource 생략 가능"
abstract class AuthRemoteDataSource {
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Stream<User?> authStateChanges();

  User? get currentUser;
}
