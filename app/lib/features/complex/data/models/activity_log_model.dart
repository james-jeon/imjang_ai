import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:imjang_app/features/complex/domain/entities/activity_log_entity.dart';

class ActivityLogModel extends ActivityLogEntity {
  ActivityLogModel({
    required super.id,
    required super.complexId,
    required super.actorId,
    required super.actorName,
    required super.action,
    super.targetType,
    super.targetId,
    super.details,
    required super.createdAt,
  });

  factory ActivityLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ActivityLogModel(
      id: doc.id,
      complexId: data['complexId'] as String? ?? '',
      actorId: data['actorId'] as String? ?? '',
      actorName: data['actorName'] as String? ?? '',
      action: data['action'] as String? ?? '',
      targetType: data['targetType'] as String?,
      targetId: data['targetId'] as String?,
      details: data['details'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'complexId': complexId,
      'actorId': actorId,
      'actorName': actorName,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'details': details,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
