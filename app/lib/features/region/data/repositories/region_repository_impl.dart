import 'package:imjang_app/core/error/exceptions.dart';
import 'package:imjang_app/features/region/data/datasources/region_local_datasource.dart';
import 'package:imjang_app/features/region/domain/entities/region_entity.dart';

export 'package:imjang_app/core/error/exceptions.dart'
    show RegionException, InvalidRegionCodeException;

class RegionRepositoryImpl {
  final RegionLocalDataSource localDataSource;

  RegionRepositoryImpl({required this.localDataSource});

  Future<List<RegionEntity>> getSidoList() async {
    try {
      return await localDataSource.getSidoList();
    } catch (e) {
      throw RegionException(message: '시도 목록 조회 중 오류: $e');
    }
  }

  Future<List<RegionEntity>> getSigunguList({required String sidoCode}) async {
    return await localDataSource.getSigunguList(sidoCode: sidoCode);
  }

  Future<List<RegionEntity>> getDongList({required String sigunguCode}) async {
    return await localDataSource.getDongList(sigunguCode: sigunguCode);
  }

  Future<List<RegionEntity>> searchByName({required String query}) async {
    if (query.length < 2) {
      return [];
    }
    return await localDataSource.searchByName(query: query);
  }

  Future<RegionEntity?> getByCode(String code) async {
    // Validate: must be 10-digit numeric string
    if (!RegExp(r'^\d{10}$').hasMatch(code)) {
      throw InvalidRegionCodeException(message: '법정동코드는 10자리 숫자여야 합니다: $code');
    }
    return await localDataSource.getByCode(code);
  }
}
