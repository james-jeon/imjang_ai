import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imjang_app/features/auth/domain/entities/user_entity.dart';
import 'package:imjang_app/features/auth/data/repositories/auth_repository_impl.dart';

/// Typedef so tests can reference the notifier type as AuthControllerNotifier
typedef AuthControllerNotifier = AuthController;

final authControllerProvider =
    AutoDisposeNotifierProvider<AuthController, AsyncValue<UserEntity?>>(
  AuthController.new,
);

class AuthController extends AutoDisposeNotifier<AsyncValue<UserEntity?>> {
  @override
  AsyncValue<UserEntity?> build() {
    return const AsyncData(null);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final user = await authRepository.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final user = await authRepository.signInWithEmail(
        email: email,
        password: password,
      );
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
