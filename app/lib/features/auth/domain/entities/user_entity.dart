class UserEntity {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String authProvider;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.authProvider,
    required this.createdAt,
    required this.lastLoginAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() =>
      'UserEntity(uid: $uid, email: $email, displayName: $displayName)';
}
