import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore 기반 API 캐시 데이터소스
/// apiCache/{cacheKey} 컬렉션 관리
class ApiCacheDatasource {
  final FirebaseFirestore firestore;

  static const String _collection = 'apiCache';

  ApiCacheDatasource({required this.firestore});

  /// 캐시 키 생성 패턴
  static String complexListKey(String regionCode) =>
      'complexList_$regionCode';

  static String complexInfoKey(String publicApiCode) =>
      'complexInfo_$publicApiCode';

  static String realPriceKey(String regionCode, String yearMonth) =>
      'realPrice_${regionCode}_$yearMonth';

  static String buildingLedgerKey(
          String sigunguCode, String bun, String ji) =>
      'buildingLedger_${sigunguCode}_${bun}_$ji';

  /// 캐시 조회 — 유효한 경우 data(List<Map>) 반환, 만료/미존재 시 null
  Future<List<dynamic>?> getCachedData(String cacheKey) async {
    final doc = await firestore.collection(_collection).doc(cacheKey).get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    // TTL 만료 확인
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
    if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
      // 만료된 캐시 삭제
      await firestore.collection(_collection).doc(cacheKey).delete();
      return null;
    }

    // hitCount 증가
    await firestore.collection(_collection).doc(cacheKey).update({
      'hitCount': FieldValue.increment(1),
    });

    return data['data'] as List<dynamic>?;
  }

  /// 캐시 저장
  Future<void> setCachedData({
    required String cacheKey,
    required String apiType,
    required Map<String, dynamic> params,
    required List<Map<String, dynamic>> data,
    required int ttlDays,
  }) async {
    final now = DateTime.now();
    final expiresAt = now.add(Duration(days: ttlDays));

    await firestore.collection(_collection).doc(cacheKey).set({
      'cacheKey': cacheKey,
      'apiType': apiType,
      'params': params,
      'data': data,
      'ttlDays': ttlDays,
      'cachedAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'hitCount': 0,
    });
  }

  /// 캐시 삭제
  Future<void> deleteCachedData(String cacheKey) async {
    await firestore.collection(_collection).doc(cacheKey).delete();
  }

  /// 만료된 캐시 일괄 정리
  Future<int> cleanExpiredCache() async {
    final now = Timestamp.fromDate(DateTime.now());
    final expiredDocs = await firestore
        .collection(_collection)
        .where('expiresAt', isLessThan: now)
        .get();

    final batch = firestore.batch();
    for (final doc in expiredDocs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    return expiredDocs.docs.length;
  }
}
