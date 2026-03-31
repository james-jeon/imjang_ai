import 'package:imjang_app/features/region/domain/entities/region_entity.dart';

/// Abstract interface for region local data source (drift-backed)
abstract class RegionLocalDataSource {
  Future<List<RegionEntity>> getSidoList();
  Future<List<RegionEntity>> getSigunguList({required String sidoCode});
  Future<List<RegionEntity>> getDongList({required String sigunguCode});
  Future<List<RegionEntity>> searchByName({required String query});
  Future<RegionEntity?> getByCode(String code);
}
