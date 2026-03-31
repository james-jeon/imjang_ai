import 'package:imjang_app/features/auth/domain/entities/user_entity.dart';

/// Auth Repository 인터페이스 (Domain Layer)
/// 구현체는 Data Layer의 AuthRepositoryImpl
/// Provider는 Data Layer의 auth_repository_impl.dart에 정의
abstract class AuthRepository {
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Stream<UserEntity?> authStateChanges();

  UserEntity? get currentUser;
}
