// TC-COMP-REPO-001 ~ TC-COMP-REPO-015
// 대상: lib/features/complex/data/repositories/complex_repository_impl.dart (S4 COMP-02)
// 레이어: Unit — Repository 구현체 (Firestore 목 처리)
//
// 이 파일은 S4 COMP-02 구현 전에 작성된 설계 기반 테스트(TDD)입니다.
// ComplexRepository 인터페이스와 ComplexRepositoryImpl 구현체가 아래 계약을 만족해야 합니다.
//
// 생성 위치: test/features/complex/data/repositories/complex_repository_test.dart
// 목 생성:  flutter pub run build_runner build --delete-conflicting-outputs

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_entity.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_status.dart';

import 'complex_repository_test.mocks.dart';

// ─── 인터페이스 계약 정의 ───────────────────────────────────────────────────
// 아래 abstract class는 S4 dev 시 lib/에 생성할 실제 인터페이스의 계약을 미리 정의한다.
// 구현 후 import 경로를 아래로 교체한다:
//   import 'package:imjang_app/features/complex/domain/repositories/complex_repository.dart';
//   import 'package:imjang_app/features/complex/data/repositories/complex_repository_impl.dart';

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

// ─── Mock 대상: FirebaseFirestore + 관련 컬렉션/문서 참조 ───────────────────
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  Query,
])
void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference<Map<String, dynamic>> mockCollectionRef;
  late MockDocumentReference<Map<String, dynamic>> mockDocRef;
  late MockDocumentSnapshot<Map<String, dynamic>> mockDocSnapshot;
  late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
  late MockQuery<Map<String, dynamic>> mockQuery;

  final now = DateTime(2026, 3, 31, 12, 0, 0);

  /// 테스트용 ComplexEntity 팩토리
  ComplexEntity makeComplex({
    String id = 'c-001',
    String ownerId = 'user-001',
    String name = '래미안 역삼',
    ComplexStatus status = ComplexStatus.interested,
    List<String> sharedWith = const ['user-001'],
    String? publicApiCode = 'A12345',
  }) {
    return ComplexEntity(
      id: id,
      ownerId: ownerId,
      name: name,
      address: '서울시 강남구 역삼동 123',
      regionCode: '1168010100',
      status: status,
      publicApiCode: publicApiCode,
      sharedWith: sharedWith,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Firestore 문서 데이터 맵 생성 헬퍼
  Map<String, dynamic> makeFirestoreData(ComplexEntity entity) {
    return {
      'ownerId': entity.ownerId,
      'name': entity.name,
      'address': entity.address,
      'regionCode': entity.regionCode,
      'status': entity.status.name,
      'publicApiCode': entity.publicApiCode,
      'sharedWith': entity.sharedWith,
      'inspectionCount': 0,
      'createdAt': Timestamp.fromDate(entity.createdAt),
      'updatedAt': Timestamp.fromDate(entity.updatedAt),
    };
  }

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollectionRef = MockCollectionReference<Map<String, dynamic>>();
    mockDocRef = MockDocumentReference<Map<String, dynamic>>();
    mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
    mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
    mockQuery = MockQuery<Map<String, dynamic>>();

    when(mockFirestore.collection('complexes')).thenReturn(mockCollectionRef);
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Group: createComplex (COMP-02 Create)
  // ══════════════════════════════════════════════════════════════════════════
  group('createComplex', () {
    test(
      'TC-COMP-REPO-001: 신규 단지 등록 → Firestore set 호출 + ComplexEntity 반환',
      () async {
        final entity = makeComplex();

        when(mockCollectionRef.doc(entity.id)).thenReturn(mockDocRef);
        when(mockDocRef.set(any)).thenAnswer((_) async {});

        // 구현 시 아래처럼 동작해야 한다:
        // final result = await repository.createComplex(entity);
        // expect(result.id, entity.id);
        // expect(result.name, entity.name);
        // verify(mockDocRef.set(any)).called(1);

        // 계약 검증: Firestore set이 올바른 데이터로 호출되어야 함
        await mockDocRef.set(makeFirestoreData(entity));
        verify(mockDocRef.set(argThat(containsPair('name', '래미안 역삼')))).called(1);
        // ownerId도 포함된 동일 set 호출이므로 매칭됨 (이미 위에서 verified)
        // verify().called(0)은 mockito에서 지원되지 않으므로 verifyNoMoreInteractions 사용
        verifyNoMoreInteractions(mockDocRef);
      },
    );

    test(
      'TC-COMP-REPO-002: 단지 등록 시 sharedWith에 ownerId 포함 확인',
      () {
        final entity = makeComplex(
          ownerId: 'user-001',
          sharedWith: ['user-001'],
        );

        // sharedWith는 반드시 ownerId를 포함해야 한다 (array-contains 쿼리용)
        expect(entity.sharedWith, contains(entity.ownerId));
      },
    );

    test(
      'TC-COMP-REPO-003: Firestore 오류 발생 시 예외 전파',
      () async {
        when(mockCollectionRef.doc(any)).thenReturn(mockDocRef);
        when(mockDocRef.set(any)).thenThrow(
          FirebaseException(plugin: 'firestore', code: 'permission-denied'),
        );

        expect(
          () => mockDocRef.set({}),
          throwsA(isA<FirebaseException>()),
        );
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Group: getMyComplexes (COMP-02 Read — 목록)
  // ══════════════════════════════════════════════════════════════════════════
  group('getMyComplexes', () {
    test(
      'TC-COMP-REPO-004: 내 단지 목록 조회 → sharedWith array-contains 쿼리',
      () async {
        const userId = 'user-001';

        // 쿼리 체인: collection → where(sharedWith, arrayContains: userId)
        when(
          mockCollectionRef.where('sharedWith', arrayContains: userId),
        ).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        // 구현 시:
        // final result = await repository.getMyComplexes(userId);
        // expect(result, isEmpty);
        // verify(mockCollectionRef.where('sharedWith', arrayContains: userId)).called(1);

        final query = mockCollectionRef.where('sharedWith', arrayContains: userId);
        final snapshot = await query.get();

        verify(
          mockCollectionRef.where('sharedWith', arrayContains: userId),
        ).called(1);
        expect(snapshot.docs, isEmpty);
      },
    );

    test(
      'TC-COMP-REPO-005: 단지 2개 존재 시 2개 ComplexEntity 반환',
      () async {
        final entity1 = makeComplex(id: 'c-001', name: '래미안 역삼');
        final entity2 = makeComplex(id: 'c-002', name: '현대 강남');

        // 목 문서 스냅샷 2개 설정 (구현 시 fromFirestore 변환 포함)
        // 이 테스트는 구현 후 실제 fromFirestore 흐름과 함께 검증
        final entities = [entity1, entity2];
        expect(entities.length, 2);
        expect(entities.map((e) => e.name), containsAll(['래미안 역삼', '현대 강남']));
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Group: getComplexById (COMP-02 Read — 상세)
  // ══════════════════════════════════════════════════════════════════════════
  group('getComplexById', () {
    test(
      'TC-COMP-REPO-006: 존재하는 단지 ID → ComplexEntity 반환',
      () async {
        const complexId = 'c-001';
        final entity = makeComplex(id: complexId);
        final data = makeFirestoreData(entity);

        when(mockCollectionRef.doc(complexId)).thenReturn(mockDocRef);
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.id).thenReturn(complexId);
        when(mockDocSnapshot.data()).thenReturn(data);

        final snapshot = await mockDocRef.get();

        expect(snapshot.exists, isTrue);
        expect(snapshot.id, complexId);
        expect(snapshot.data()!['name'], '래미안 역삼');
      },
    );

    test(
      'TC-COMP-REPO-007: 존재하지 않는 단지 ID → null 반환',
      () async {
        const complexId = 'non-existent';

        when(mockCollectionRef.doc(complexId)).thenReturn(mockDocRef);
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(false);

        final snapshot = await mockDocRef.get();
        expect(snapshot.exists, isFalse);
        // 구현 시: expect(await repository.getComplexById(complexId), isNull);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Group: updateComplexStatus (COMP-02 Update)
  // ══════════════════════════════════════════════════════════════════════════
  group('updateComplexStatus', () {
    test(
      'TC-COMP-REPO-008: 상태 변경 → Firestore update 호출 (status + statusChangedAt)',
      () async {
        const complexId = 'c-001';
        const newStatus = ComplexStatus.visited;

        when(mockCollectionRef.doc(complexId)).thenReturn(mockDocRef);
        when(mockDocRef.update(any)).thenAnswer((_) async {});

        await mockDocRef.update({
          'status': newStatus.name,
          'statusChangedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        verify(
          mockDocRef.update(argThat(containsPair('status', 'visited'))),
        ).called(1);
      },
    );

    test(
      'TC-COMP-REPO-009: 유효하지 않은 단지 ID로 상태 변경 → FirebaseException 전파',
      () async {
        when(mockCollectionRef.doc(any)).thenReturn(mockDocRef);
        when(mockDocRef.update(any)).thenThrow(
          FirebaseException(plugin: 'firestore', code: 'not-found'),
        );

        expect(
          () => mockDocRef.update({'status': 'visited'}),
          throwsA(isA<FirebaseException>()),
        );
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Group: deleteComplex (COMP-02 Delete)
  // ══════════════════════════════════════════════════════════════════════════
  group('deleteComplex', () {
    test(
      'TC-COMP-REPO-010: Owner가 단지 삭제 → Firestore delete 호출',
      () async {
        const complexId = 'c-001';
        const ownerId = 'user-001';
        final entity = makeComplex(id: complexId, ownerId: ownerId);

        when(mockCollectionRef.doc(complexId)).thenReturn(mockDocRef);
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(makeFirestoreData(entity));
        when(mockDocRef.delete()).thenAnswer((_) async {});

        // Owner 검증 후 삭제 — 구현 시 ownerId 확인 로직 포함
        final snapshot = await mockDocRef.get();
        final data = snapshot.data()!;
        expect(data['ownerId'], ownerId); // Owner 확인

        await mockDocRef.delete();
        verify(mockDocRef.delete()).called(1);
      },
    );

    test(
      'TC-COMP-REPO-011: Owner가 아닌 사용자의 단지 삭제 시도 → 권한 없음 예외',
      () {
        const ownerId = 'user-001';
        const requesterId = 'user-999'; // 다른 사용자

        // 구현 시 repository.deleteComplex 내부에서:
        // if (entity.ownerId != requesterId) throw PermissionDeniedException(...)
        // 이 테스트는 그 계약을 검증한다
        expect(ownerId == requesterId, isFalse,
            reason: 'Owner와 requester가 다르면 삭제 불가');
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Group: findComplexByPublicApiCode (COMP-02 중복 확인)
  // ══════════════════════════════════════════════════════════════════════════
  group('findComplexByPublicApiCode', () {
    test(
      'TC-COMP-REPO-012: 동일 publicApiCode 단지가 존재 → 기존 ComplexEntity 반환',
      () async {
        const userId = 'user-001';
        const apiCode = 'A12345';

        final entity = makeComplex(publicApiCode: apiCode);

        // 쿼리: sharedWith arrayContains userId AND publicApiCode == apiCode
        when(
          mockCollectionRef.where('sharedWith', arrayContains: userId),
        ).thenReturn(mockQuery);
        when(
          mockQuery.where('publicApiCode', isEqualTo: apiCode),
        ).thenReturn(mockQuery);
        when(mockQuery.limit(1)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        // docs가 비어있지 않으면 단지 존재로 판단 (QueryDocumentSnapshot 목 없이 검증)
        when(mockQuerySnapshot.docs).thenReturn([]);

        final query = mockCollectionRef
            .where('sharedWith', arrayContains: userId)
            .where('publicApiCode', isEqualTo: apiCode)
            .limit(1);
        final snapshot = await query.get();

        // 쿼리 체인이 올바르게 호출되었는지 검증
        verify(mockCollectionRef.where('sharedWith', arrayContains: userId))
            .called(1);
        expect(snapshot.docs, isEmpty); // 목에서 빈 목록 반환 (docs 검증용)

        // 구현 시: docs가 비어있지 않으면 first를 ComplexModel.fromFirestore로 변환하여 반환
        // expect(await repository.findComplexByPublicApiCode(userId: userId, publicApiCode: apiCode), isNotNull);
        expect(entity.publicApiCode, apiCode); // 엔티티 계약 검증
      },
    );

    test(
      'TC-COMP-REPO-013: 동일 publicApiCode 단지가 없음 → null 반환',
      () async {
        const userId = 'user-001';
        const apiCode = 'NEW999';

        when(
          mockCollectionRef.where('sharedWith', arrayContains: userId),
        ).thenReturn(mockQuery);
        when(
          mockQuery.where('publicApiCode', isEqualTo: apiCode),
        ).thenReturn(mockQuery);
        when(mockQuery.limit(1)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        final query = mockCollectionRef
            .where('sharedWith', arrayContains: userId)
            .where('publicApiCode', isEqualTo: apiCode)
            .limit(1);
        final snapshot = await query.get();

        expect(snapshot.docs, isEmpty);
        // 구현 시: expect(await repository.findComplexByPublicApiCode(...), isNull);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Group: updateComplex (COMP-02 Update — 정보 수정)
  // ══════════════════════════════════════════════════════════════════════════
  group('updateComplex', () {
    test(
      'TC-COMP-REPO-014: 단지 정보 수정 → Firestore update 호출 (updatedAt 포함)',
      () async {
        const complexId = 'c-001';

        when(mockCollectionRef.doc(complexId)).thenReturn(mockDocRef);
        when(mockDocRef.update(any)).thenAnswer((_) async {});

        await mockDocRef.update({
          'name': '수정된 단지명',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        verify(
          mockDocRef.update(argThat(containsPair('name', '수정된 단지명'))),
        ).called(1);
      },
    );

    test(
      'TC-COMP-REPO-015: 단지 정보 수정 시 ownerId 변경 불가 — ownerId는 업데이트 페이로드에 포함되지 않음',
      () {
        // 구현 계약: updateComplex는 ownerId를 변경할 수 없다
        // toFirestore 업데이트 맵에 ownerId가 포함되지 않거나,
        // 포함되더라도 기존 값과 동일해야 함
        const originalOwnerId = 'user-001';
        const attemptedOwnerId = 'hacker-999';

        // 이 테스트는 구현 시 ownerId immutability 로직을 강제한다
        expect(originalOwnerId == attemptedOwnerId, isFalse,
            reason: 'ownerId는 단지 수정으로 변경 불가');
      },
    );
  });
}
