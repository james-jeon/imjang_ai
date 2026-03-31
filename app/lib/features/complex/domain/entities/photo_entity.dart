class PhotoEntity {
  final String id;
  final String inspectionId;
  final String uploaderId;
  final String storageUrl;
  final String? thumbnailUrl;
  final String? caption;
  final String fileName;
  final int fileSize;
  final int? width;
  final int? height;
  final int order;
  final String syncStatus;
  final DateTime createdAt;

  PhotoEntity({
    required this.id,
    required this.inspectionId,
    required this.uploaderId,
    required this.storageUrl,
    this.thumbnailUrl,
    this.caption,
    required this.fileName,
    required this.fileSize,
    this.width,
    this.height,
    this.order = 0,
    this.syncStatus = 'synced',
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PhotoEntity(id: $id, fileName: $fileName, order: $order)';
}
