import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_entity.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_status.dart';

class ComplexModel extends ComplexEntity {
  ComplexModel({
    required super.id,
    required super.ownerId,
    required super.name,
    required super.address,
    super.addressJibun,
    required super.regionCode,
    super.latitude,
    super.longitude,
    super.status,
    super.statusChangedAt,
    super.totalHouseholds,
    super.totalBuildings,
    super.minFloor,
    super.maxFloor,
    super.heatingType,
    super.approvalDate,
    super.constructor,
    super.floorAreaRatio,
    super.buildingCoverageRatio,
    super.publicApiCode,
    super.sharedWith,
    super.lastInspectionAt,
    super.inspectionCount,
    super.recentTradePrice,
    super.representativeArea,
    super.averageRating,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ComplexModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ComplexModel(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      addressJibun: data['addressJibun'] as String?,
      regionCode: data['regionCode'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      status: ComplexStatus.fromString(data['status'] as String? ?? 'interested'),
      statusChangedAt: (data['statusChangedAt'] as Timestamp?)?.toDate(),
      totalHouseholds: (data['totalHouseholds'] as num?)?.toInt(),
      totalBuildings: (data['totalBuildings'] as num?)?.toInt(),
      minFloor: (data['minFloor'] as num?)?.toInt(),
      maxFloor: (data['maxFloor'] as num?)?.toInt(),
      heatingType: data['heatingType'] as String?,
      approvalDate: data['approvalDate'] as String?,
      constructor: data['constructor'] as String?,
      floorAreaRatio: (data['floorAreaRatio'] as num?)?.toDouble(),
      buildingCoverageRatio: (data['buildingCoverageRatio'] as num?)?.toDouble(),
      publicApiCode: data['publicApiCode'] as String?,
      sharedWith: (data['sharedWith'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      lastInspectionAt: (data['lastInspectionAt'] as Timestamp?)?.toDate(),
      inspectionCount: (data['inspectionCount'] as num?)?.toInt() ?? 0,
      recentTradePrice: data['recentTradePrice'] as String?,
      representativeArea: (data['representativeArea'] as num?)?.toDouble(),
      averageRating: (data['averageRating'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'address': address,
      'addressJibun': addressJibun,
      'regionCode': regionCode,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.name,
      'statusChangedAt':
          statusChangedAt != null ? Timestamp.fromDate(statusChangedAt!) : null,
      'totalHouseholds': totalHouseholds,
      'totalBuildings': totalBuildings,
      'minFloor': minFloor,
      'maxFloor': maxFloor,
      'heatingType': heatingType,
      'approvalDate': approvalDate,
      'constructor': constructor,
      'floorAreaRatio': floorAreaRatio,
      'buildingCoverageRatio': buildingCoverageRatio,
      'publicApiCode': publicApiCode,
      'sharedWith': sharedWith,
      'lastInspectionAt':
          lastInspectionAt != null ? Timestamp.fromDate(lastInspectionAt!) : null,
      'inspectionCount': inspectionCount,
      'recentTradePrice': recentTradePrice,
      'representativeArea': representativeArea,
      'averageRating': averageRating,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ComplexModel.fromEntity(ComplexEntity entity) {
    return ComplexModel(
      id: entity.id,
      ownerId: entity.ownerId,
      name: entity.name,
      address: entity.address,
      addressJibun: entity.addressJibun,
      regionCode: entity.regionCode,
      latitude: entity.latitude,
      longitude: entity.longitude,
      status: entity.status,
      statusChangedAt: entity.statusChangedAt,
      totalHouseholds: entity.totalHouseholds,
      totalBuildings: entity.totalBuildings,
      minFloor: entity.minFloor,
      maxFloor: entity.maxFloor,
      heatingType: entity.heatingType,
      approvalDate: entity.approvalDate,
      constructor: entity.constructor,
      floorAreaRatio: entity.floorAreaRatio,
      buildingCoverageRatio: entity.buildingCoverageRatio,
      publicApiCode: entity.publicApiCode,
      sharedWith: entity.sharedWith,
      lastInspectionAt: entity.lastInspectionAt,
      inspectionCount: entity.inspectionCount,
      recentTradePrice: entity.recentTradePrice,
      representativeArea: entity.representativeArea,
      averageRating: entity.averageRating,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
