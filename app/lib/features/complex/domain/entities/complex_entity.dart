import 'package:imjang_app/features/complex/domain/entities/complex_status.dart';

class ComplexEntity {
  final String id;
  final String ownerId;
  final String name;
  final String address;
  final String? addressJibun;
  final String regionCode;
  final double? latitude;
  final double? longitude;
  final ComplexStatus status;
  final DateTime? statusChangedAt;
  final int? totalHouseholds;
  final int? totalBuildings;
  final int? minFloor;
  final int? maxFloor;
  final String? heatingType;
  final String? approvalDate;
  final String? constructor;
  final double? floorAreaRatio;
  final double? buildingCoverageRatio;
  final String? publicApiCode;
  final List<String> sharedWith;
  final DateTime? lastInspectionAt;
  final int inspectionCount;
  final String? recentTradePrice;
  final double? representativeArea;
  final double? averageRating;
  final DateTime createdAt;
  final DateTime updatedAt;

  ComplexEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    this.addressJibun,
    required this.regionCode,
    this.latitude,
    this.longitude,
    this.status = ComplexStatus.interested,
    this.statusChangedAt,
    this.totalHouseholds,
    this.totalBuildings,
    this.minFloor,
    this.maxFloor,
    this.heatingType,
    this.approvalDate,
    this.constructor,
    this.floorAreaRatio,
    this.buildingCoverageRatio,
    this.publicApiCode,
    this.sharedWith = const [],
    this.lastInspectionAt,
    this.inspectionCount = 0,
    this.recentTradePrice,
    this.representativeArea,
    this.averageRating,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComplexEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ComplexEntity(id: $id, name: $name, status: ${status.name})';
}
