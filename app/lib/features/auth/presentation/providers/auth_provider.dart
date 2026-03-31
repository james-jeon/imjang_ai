import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imjang_app/features/auth/domain/entities/user_entity.dart';
import 'package:imjang_app/features/auth/data/repositories/auth_repository_impl.dart';

final authStateChangesProvider = StreamProvider<UserEntity?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges();
});
