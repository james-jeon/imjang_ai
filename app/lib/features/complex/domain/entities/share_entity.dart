import 'package:imjang_app/features/complex/domain/entities/share_role.dart';

class ShareEntity {
  final String id;
  final String complexId;
  final String userId;
  final String userEmail;
  final String userName;
  final ShareRole role;
  final String? invitedBy;
  final String? inviteToken;
  final ShareRole? inviteRole;
  final DateTime? tokenExpiresAt;
  final String status; // 'active' or 'pending'
  final DateTime createdAt;
  final DateTime updatedAt;

  ShareEntity({
    required this.id,
    required this.complexId,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.role,
    this.invitedBy,
    this.inviteToken,
    this.inviteRole,
    this.tokenExpiresAt,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShareEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ShareEntity(id: $id, userId: $userId, role: ${role.name}, status: $status)';
}
