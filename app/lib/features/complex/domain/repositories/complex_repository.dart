import 'package:imjang_app/features/complex/domain/entities/complex_entity.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_status.dart';

abstract class ComplexRepository {
  /// COMP-02 Create: 단지 등록
  Future<ComplexEntity> createComplex(ComplexEntity complex);

  /// COMP-02 Read: 내 단지 목록 (sharedWith array-contains)
  Future<List<ComplexEntity>> getMyComplexes(String userId);

  /// COMP-02 Read: 단지 상세
  Future<ComplexEntity?> getComplexById(String complexId);

  /// COMP-02 Update: 상태 변경
  Future<void> updateComplexStatus(String complexId, ComplexStatus status);

  /// COMP-02 Update: 정보 수정
  Future<void> updateComplex(ComplexEntity complex);

  /// COMP-02 Delete: 단지 삭제 (Owner만)
  Future<void> deleteComplex({
    required String complexId,
    required String requesterId,
  });

  /// COMP-02 Read: 이미 등록된 단지 확인 (publicApiCode 기준)
  Future<ComplexEntity?> findComplexByPublicApiCode({
    required String userId,
    required String publicApiCode,
  });
}
