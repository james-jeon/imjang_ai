import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imjang_app/core/constants/firestore_paths.dart';
import 'package:imjang_app/core/providers/firebase_providers.dart';
import 'package:imjang_app/features/complex/data/models/complex_model.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_entity.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_status.dart';
import 'package:imjang_app/features/complex/domain/repositories/complex_repository.dart';

/// Provider는 Data Layer에 위치 (Clean Architecture: Domain은 Data를 모른다)
final complexRepositoryProvider = Provider<ComplexRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return ComplexRepositoryImpl(firestore: firestore);
});

class ComplexRepositoryImpl implements ComplexRepository {
  final FirebaseFirestore firestore;

  ComplexRepositoryImpl({required this.firestore});

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection(FirestorePaths.complexes);

  @override
  Future<ComplexEntity> createComplex(ComplexEntity complex) async {
    final model = ComplexModel.fromEntity(complex);
    await _collection.doc(complex.id).set(model.toFirestore());
    return complex;
  }

  @override
  Future<List<ComplexEntity>> getMyComplexes(String userId) async {
    final snapshot = await _collection
        .where('sharedWith', arrayContains: userId)
        .get();

    return snapshot.docs
        .map((doc) => ComplexModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<ComplexEntity?> getComplexById(String complexId) async {
    final doc = await _collection.doc(complexId).get();
    if (!doc.exists) return null;
    return ComplexModel.fromFirestore(doc);
  }

  @override
  Future<void> updateComplexStatus(
      String complexId, ComplexStatus status) async {
    await _collection.doc(complexId).update({
      'status': status.name,
      'statusChangedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateComplex(ComplexEntity complex) async {
    final model = ComplexModel.fromEntity(complex);
    final data = model.toFirestore();
    // ownerId는 업데이트 페이로드에서 제거 (immutable)
    data.remove('ownerId');
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _collection.doc(complex.id).update(data);
  }

  @override
  Future<void> deleteComplex({
    required String complexId,
    required String requesterId,
  }) async {
    final doc = await _collection.doc(complexId).get();
    if (!doc.exists) {
      throw FirebaseException(
          plugin: 'firestore', code: 'not-found', message: '단지를 찾을 수 없습니다');
    }

    final data = doc.data()!;
    final ownerId = data['ownerId'] as String?;
    if (ownerId != requesterId) {
      throw FirebaseException(
          plugin: 'firestore',
          code: 'permission-denied',
          message: 'Owner만 단지를 삭제할 수 있습니다');
    }

    await _collection.doc(complexId).delete();
  }

  @override
  Future<ComplexEntity?> findComplexByPublicApiCode({
    required String userId,
    required String publicApiCode,
  }) async {
    final snapshot = await _collection
        .where('sharedWith', arrayContains: userId)
        .where('publicApiCode', isEqualTo: publicApiCode)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return ComplexModel.fromFirestore(snapshot.docs.first);
  }
}
