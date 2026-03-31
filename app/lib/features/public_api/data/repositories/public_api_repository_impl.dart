import 'package:imjang_app/features/public_api/data/datasources/building_ledger_api_datasource.dart';
import 'package:imjang_app/features/public_api/data/datasources/complex_info_api_datasource.dart';
import 'package:imjang_app/features/public_api/data/datasources/complex_list_api_datasource.dart';
import 'package:imjang_app/features/public_api/data/datasources/real_price_api_datasource.dart';
import 'package:imjang_app/features/public_api/domain/entities/apt_detail_info.dart';
import 'package:imjang_app/features/public_api/domain/entities/apt_list_item.dart';
import 'package:imjang_app/features/public_api/domain/entities/building_ledger_info.dart';
import 'package:imjang_app/features/public_api/domain/entities/real_price_item.dart';
import 'package:imjang_app/features/public_api/domain/repositories/public_api_repository.dart';

class PublicApiRepositoryImpl implements PublicApiRepository {
  final ComplexListApiDatasource complexListDatasource;
  final ComplexInfoApiDatasource complexInfoDatasource;
  final RealPriceApiDatasource realPriceDatasource;
  final BuildingLedgerApiDatasource buildingLedgerDatasource;

  PublicApiRepositoryImpl({
    required this.complexListDatasource,
    required this.complexInfoDatasource,
    required this.realPriceDatasource,
    required this.buildingLedgerDatasource,
  });

  @override
  Future<List<AptListItem>> getComplexList({
    required String regionCode,
    int pageNo = 1,
    int numOfRows = 100,
  }) {
    return complexListDatasource.getComplexList(
      regionCode: regionCode,
      pageNo: pageNo,
      numOfRows: numOfRows,
    );
  }

  @override
  List<AptListItem> searchAutoComplete(
    List<AptListItem> items,
    String query,
  ) {
    return complexListDatasource.searchAutoComplete(items, query);
  }

  @override
  Future<AptDetailInfo?> getComplexInfo({
    required String publicApiCode,
  }) {
    return complexInfoDatasource.getComplexInfo(
      publicApiCode: publicApiCode,
    );
  }

  @override
  Future<List<RealPriceItem>> getRealPriceList({
    required String regionCode,
    required String yearMonth,
    int pageNo = 1,
    int numOfRows = 100,
  }) {
    return realPriceDatasource.getRealPriceList(
      regionCode: regionCode,
      yearMonth: yearMonth,
      pageNo: pageNo,
      numOfRows: numOfRows,
    );
  }

  @override
  Future<List<BuildingLedgerInfo>> getBuildingLedger({
    required String sigunguCode,
    required String bjdongCode,
    required String bun,
    required String ji,
  }) {
    return buildingLedgerDatasource.getBuildingLedger(
      sigunguCode: sigunguCode,
      bjdongCode: bjdongCode,
      bun: bun,
      ji: ji,
    );
  }
}
