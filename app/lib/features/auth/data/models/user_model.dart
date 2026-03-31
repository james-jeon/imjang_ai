import 'package:imjang_app/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.uid,
    required super.email,
    required super.displayName,
    super.photoUrl,
    required super.authProvider,
    required super.createdAt,
    required super.lastLoginAt,
  });

  factory UserModel.fromFirebaseUser(
    dynamic firebaseUser, {
    String authProvider = 'email',
  }) {
    final now = DateTime.now();
    return UserModel(
      uid: firebaseUser.uid as String,
      email: (firebaseUser.email as String?) ?? '',
      displayName: (firebaseUser.displayName as String?) ?? '',
      photoUrl: firebaseUser.photoURL as String?,
      authProvider: authProvider,
      createdAt: now,
      lastLoginAt: now,
    );
  }
}
