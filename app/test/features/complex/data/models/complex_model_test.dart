// TC-COMP-MOD-001 ~ TC-COMP-MOD-008
// 대상: complex/data/models (COMP-01)
// 레이어: Unit — Firestore 모델 fromFirestore/toFirestore 변환

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imjang_app/features/complex/data/models/complex_model.dart';
import 'package:imjang_app/features/complex/data/models/inspection_model.dart';
import 'package:imjang_app/features/complex/data/models/photo_model.dart';
import 'package:imjang_app/features/complex/data/models/share_model.dart';
import 'package:imjang_app/features/complex/data/models/activity_log_model.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_entity.dart';
import 'package:imjang_app/features/complex/domain/entities/check_item.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_status.dart';
import 'package:imjang_app/features/complex/domain/entities/share_role.dart';

void main() {
  final now = DateTime(2026, 3, 31, 12, 0, 0);
  final ts = Timestamp.fromDate(now);

  group('ComplexModel', () {
    test('TC-COMP-MOD-001: toFirestore — 모든 필드 포함', () {
      final model = ComplexModel(
        id: 'c1',
        ownerId: 'u1',
        name: '래미안 역삼',
        address: '서울시 강남구 역삼동 123',
        addressJibun: '역삼동 123-4',
        regionCode: '1168010100',
        latitude: 37.5012,
        longitude: 127.0396,
        status: ComplexStatus.visited,
        statusChangedAt: now,
        totalHouseholds: 1200,
        totalBuildings: 15,
        minFloor: 5,
        maxFloor: 35,
        heatingType: '지역난방',
        approvalDate: '20100315',
        constructor: '삼성물산',
        floorAreaRatio: 249.5,
        buildingCoverageRatio: 18.3,
        publicApiCode: 'A12345',
        sharedWith: ['u2', 'u3'],
        lastInspectionAt: now,
        inspectionCount: 3,
        recentTradePrice: '85,000',
        representativeArea: 84.98,
        averageRating: 4.2,
        createdAt: now,
        updatedAt: now,
      );

      final data = model.toFirestore();

      expect(data['ownerId'], 'u1');
      expect(data['name'], '래미안 역삼');
      expect(data['status'], 'visited');
      expect(data['totalHouseholds'], 1200);
      expect(data['sharedWith'], ['u2', 'u3']);
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['statusChangedAt'], isA<Timestamp>());
      expect(data['floorAreaRatio'], 249.5);
      // id는 toFirestore에 포함되지 않음 (doc ID로 관리)
      expect(data.containsKey('id'), isFalse);
    });

    test('TC-COMP-MOD-002: toFirestore — nullable 필드 null 처리', () {
      final model = ComplexModel(
        id: 'c2',
        ownerId: 'u1',
        name: '테스트 단지',
        address: '서울시 서초구',
        regionCode: '11650',
        createdAt: now,
        updatedAt: now,
      );

      final data = model.toFirestore();

      expect(data['addressJibun'], isNull);
      expect(data['latitude'], isNull);
      expect(data['statusChangedAt'], isNull);
      expect(data['totalHouseholds'], isNull);
      expect(data['status'], 'interested'); // default
      expect(data['inspectionCount'], 0);
      expect(data['sharedWith'], isEmpty);
    });

    test('TC-COMP-MOD-003: fromEntity — Entity에서 Model 변환', () {
      final entity = ComplexEntity(
        id: 'c3',
        ownerId: 'u1',
        name: '엔티티 단지',
        address: '서울시 송파구',
        regionCode: '11710',
        status: ComplexStatus.planned,
        createdAt: now,
        updatedAt: now,
      );

      final model = ComplexModel.fromEntity(entity);

      expect(model.id, 'c3');
      expect(model.name, '엔티티 단지');
      expect(model.status, ComplexStatus.planned);
      expect(model, isA<ComplexModel>());
      expect(model, isA<ComplexEntity>());
    });
  });

  group('InspectionModel', () {
    test('TC-COMP-MOD-004: toFirestore — checkItems map 포함', () {
      final model = InspectionModel(
        id: 'i1',
        complexId: 'c1',
        authorId: 'u1',
        authorName: '홍길동',
        visitDate: now,
        visitTimeSlots: ['오전', '오후'],
        checkItems: _defaultCheckItem(),
        pros: '역세권',
        cons: '소음',
        summary: '전체적으로 양호',
        overallRating: 4.0,
        photoCount: 5,
        createdAt: now,
        updatedAt: now,
      );

      final data = model.toFirestore();

      expect(data['complexId'], 'c1');
      expect(data['visitTimeSlots'], ['오전', '오후']);
      expect(data['checkItems'], isA<Map<String, int>>());
      expect((data['checkItems'] as Map)['noise'], 4);
      expect(data['overallRating'], 4.0);
      expect(data['photoCount'], 5);
    });
  });

  group('PhotoModel', () {
    test('TC-COMP-MOD-005: toFirestore — 사진 메타데이터 포함', () {
      final model = PhotoModel(
        id: 'p1',
        inspectionId: 'i1',
        uploaderId: 'u1',
        storageUrl: 'gs://bucket/p1.jpg',
        thumbnailUrl: 'gs://bucket/p1_thumb.jpg',
        caption: '현관 사진',
        fileName: 'p1.jpg',
        fileSize: 2048000,
        width: 1920,
        height: 1080,
        order: 0,
        syncStatus: 'synced',
        createdAt: now,
      );

      final data = model.toFirestore();

      expect(data['storageUrl'], 'gs://bucket/p1.jpg');
      expect(data['fileSize'], 2048000);
      expect(data['width'], 1920);
      expect(data['height'], 1080);
      expect(data['order'], 0);
      expect(data['syncStatus'], 'synced');
    });
  });

  group('ShareModel', () {
    test('TC-COMP-MOD-006: toFirestore — role enum → string', () {
      final model = ShareModel(
        id: 's1',
        complexId: 'c1',
        userId: 'u2',
        userEmail: 'editor@test.com',
        userName: '편집자',
        role: ShareRole.editor,
        invitedBy: 'u1',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      final data = model.toFirestore();

      expect(data['role'], 'editor');
      expect(data['invitedBy'], 'u1');
      expect(data['status'], 'active');
    });

    test('TC-COMP-MOD-007: toFirestore — invite 관련 nullable 필드', () {
      final model = ShareModel(
        id: 's2',
        complexId: 'c1',
        userId: 'u3',
        userEmail: 'viewer@test.com',
        userName: '뷰어',
        role: ShareRole.viewer,
        inviteToken: 'abc123',
        inviteRole: ShareRole.viewer,
        tokenExpiresAt: now.add(const Duration(days: 7)),
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      );

      final data = model.toFirestore();

      expect(data['inviteToken'], 'abc123');
      expect(data['inviteRole'], 'viewer');
      expect(data['tokenExpiresAt'], isA<Timestamp>());
      expect(data['status'], 'pending');
    });
  });

  group('ActivityLogModel', () {
    test('TC-COMP-MOD-008: toFirestore — details map 포함', () {
      final model = ActivityLogModel(
        id: 'l1',
        complexId: 'c1',
        actorId: 'u1',
        actorName: '홍길동',
        action: 'status_changed',
        targetType: 'complex',
        targetId: 'c1',
        details: {'from': 'interested', 'to': 'planned'},
        createdAt: now,
      );

      final data = model.toFirestore();

      expect(data['action'], 'status_changed');
      expect(data['targetType'], 'complex');
      expect(data['details'], {'from': 'interested', 'to': 'planned'});
      expect(data.containsKey('id'), isFalse);
    });
  });
}

CheckItem _defaultCheckItem() => CheckItem(
      noise: 4,
      slope: 3,
      commercial: 5,
      parking: 2,
      sunlight: 4,
    );
