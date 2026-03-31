import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:imjang_app/features/complex/domain/entities/photo_entity.dart';

class PhotoModel extends PhotoEntity {
  PhotoModel({
    required super.id,
    required super.inspectionId,
    required super.uploaderId,
    required super.storageUrl,
    super.thumbnailUrl,
    super.caption,
    required super.fileName,
    required super.fileSize,
    super.width,
    super.height,
    super.order,
    super.syncStatus,
    required super.createdAt,
  });

  factory PhotoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PhotoModel(
      id: doc.id,
      inspectionId: data['inspectionId'] as String? ?? '',
      uploaderId: data['uploaderId'] as String? ?? '',
      storageUrl: data['storageUrl'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String?,
      caption: data['caption'] as String?,
      fileName: data['fileName'] as String? ?? '',
      fileSize: (data['fileSize'] as num?)?.toInt() ?? 0,
      width: (data['width'] as num?)?.toInt(),
      height: (data['height'] as num?)?.toInt(),
      order: (data['order'] as num?)?.toInt() ?? 0,
      syncStatus: data['syncStatus'] as String? ?? 'synced',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'inspectionId': inspectionId,
      'uploaderId': uploaderId,
      'storageUrl': storageUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'fileName': fileName,
      'fileSize': fileSize,
      'width': width,
      'height': height,
      'order': order,
      'syncStatus': syncStatus,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
