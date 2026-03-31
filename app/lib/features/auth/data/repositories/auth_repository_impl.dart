import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imjang_app/core/error/exceptions.dart';
import 'package:imjang_app/core/providers/firebase_providers.dart';
import 'package:imjang_app/features/auth/data/models/user_model.dart';
import 'package:imjang_app/features/auth/domain/entities/user_entity.dart';
import 'package:imjang_app/features/auth/domain/repositories/auth_repository.dart';

/// Provider는 Data Layer에 위치 (Clean Architecture: Domain은 Data를 모른다)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthRepositoryImpl(firebaseAuth: firebaseAuth);
});

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth firebaseAuth;

  AuthRepositoryImpl({required this.firebaseAuth});

  @override
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw AuthAppException(
          code: 'user-null',
          message: '회원가입 중 오류가 발생했습니다',
        );
      }
      return UserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw AuthAppException(
          code: 'user-null',
          message: '로그인 중 오류가 발생했습니다',
        );
      }
      return UserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  @override
  Stream<UserEntity?> authStateChanges() {
    return firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return UserModel.fromFirebaseUser(user);
    });
  }

  @override
  UserEntity? get currentUser {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;
    return UserModel.fromFirebaseUser(user);
  }

  AuthAppException _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return AuthAppException(
          code: 'email-already-in-use',
          message: '이미 가입된 이메일입니다',
        );
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-credential':
        return AuthAppException(
          code: e.code,
          message: '이메일 또는 비밀번호가 일치하지 않습니다',
        );
      default:
        return AuthAppException(
          code: e.code,
          message: '인증 오류가 발생했습니다: ${e.message}',
        );
    }
  }
}
