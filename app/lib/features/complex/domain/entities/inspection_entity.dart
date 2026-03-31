import 'package:imjang_app/features/complex/domain/entities/check_item.dart';

class InspectionEntity {
  final String id;
  final String complexId;
  final String authorId;
  final String authorName;
  final DateTime visitDate;
  final List<String> visitTimeSlots;
  final CheckItem checkItems;
  final String? pros;
  final String? cons;
  final String? summary;
  final double overallRating;
  final int photoCount;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  InspectionEntity({
    required this.id,
    required this.complexId,
    required this.authorId,
    required this.authorName,
    required this.visitDate,
    this.visitTimeSlots = const [],
    required this.checkItems,
    this.pros,
    this.cons,
    this.summary,
    required this.overallRating,
    this.photoCount = 0,
    this.thumbnailUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspectionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'InspectionEntity(id: $id, complexId: $complexId, rating: $overallRating)';
}
