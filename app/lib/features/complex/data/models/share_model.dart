import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:imjang_app/features/complex/domain/entities/share_entity.dart';
import 'package:imjang_app/features/complex/domain/entities/share_role.dart';

class ShareModel extends ShareEntity {
  ShareModel({
    required super.id,
    required super.complexId,
    required super.userId,
    required super.userEmail,
    required super.userName,
    required super.role,
    super.invitedBy,
    super.inviteToken,
    super.inviteRole,
    super.tokenExpiresAt,
    super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ShareModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ShareModel(
      id: doc.id,
      complexId: data['complexId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      role: ShareRole.fromString(data['role'] as String? ?? 'viewer'),
      invitedBy: data['invitedBy'] as String?,
      inviteToken: data['inviteToken'] as String?,
      inviteRole: data['inviteRole'] != null
          ? ShareRole.fromString(data['inviteRole'] as String)
          : null,
      tokenExpiresAt: (data['tokenExpiresAt'] as Timestamp?)?.toDate(),
      status: data['status'] as String? ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'complexId': complexId,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'role': role.name,
      'invitedBy': invitedBy,
      'inviteToken': inviteToken,
      'inviteRole': inviteRole?.name,
      'tokenExpiresAt':
          tokenExpiresAt != null ? Timestamp.fromDate(tokenExpiresAt!) : null,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
