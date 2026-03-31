import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:imjang_app/features/complex/domain/entities/check_item.dart';
import 'package:imjang_app/features/complex/domain/entities/inspection_entity.dart';

class InspectionModel extends InspectionEntity {
  InspectionModel({
    required super.id,
    required super.complexId,
    required super.authorId,
    required super.authorName,
    required super.visitDate,
    super.visitTimeSlots,
    required super.checkItems,
    super.pros,
    super.cons,
    super.summary,
    required super.overallRating,
    super.photoCount,
    super.thumbnailUrl,
    required super.createdAt,
    required super.updatedAt,
  });

  factory InspectionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return InspectionModel(
      id: doc.id,
      complexId: data['complexId'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      visitDate: (data['visitDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      visitTimeSlots: (data['visitTimeSlots'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      checkItems: data['checkItems'] is Map<String, dynamic>
          ? CheckItem.fromMap(data['checkItems'] as Map<String, dynamic>)
          : CheckItem(noise: 3, slope: 3, commercial: 3, parking: 3, sunlight: 3),
      pros: data['pros'] as String?,
      cons: data['cons'] as String?,
      summary: data['summary'] as String?,
      overallRating: (data['overallRating'] as num?)?.toDouble() ?? 0.0,
      photoCount: (data['photoCount'] as num?)?.toInt() ?? 0,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'complexId': complexId,
      'authorId': authorId,
      'authorName': authorName,
      'visitDate': Timestamp.fromDate(visitDate),
      'visitTimeSlots': visitTimeSlots,
      'checkItems': checkItems.toMap(),
      'pros': pros,
      'cons': cons,
      'summary': summary,
      'overallRating': overallRating,
      'photoCount': photoCount,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
