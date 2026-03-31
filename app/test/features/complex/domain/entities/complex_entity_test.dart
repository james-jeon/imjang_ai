// TC-COMP-ENT-001 ~ TC-COMP-ENT-012
// 대상: complex/domain/entities (COMP-01)
// 레이어: Unit — Firestore 데이터 모델 엔티티

import 'package:flutter_test/flutter_test.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_entity.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_status.dart';
import 'package:imjang_app/features/complex/domain/entities/inspection_entity.dart';
import 'package:imjang_app/features/complex/domain/entities/check_item.dart';
import 'package:imjang_app/features/complex/domain/entities/photo_entity.dart';
import 'package:imjang_app/features/complex/domain/entities/share_entity.dart';
import 'package:imjang_app/features/complex/domain/entities/share_role.dart';
import 'package:imjang_app/features/complex/domain/entities/activity_log_entity.dart';

void main() {
  final now = DateTime(2026, 3, 31);

  group('ComplexStatus enum', () {
    test('TC-COMP-ENT-001: ComplexStatus.fromString — 유효한 값 변환', () {
      expect(ComplexStatus.fromString('interested'), ComplexStatus.interested);
      expect(ComplexStatus.fromString('planned'), ComplexStatus.planned);
      expect(ComplexStatus.fromString('visited'), ComplexStatus.visited);
      expect(ComplexStatus.fromString('revisit'), ComplexStatus.revisit);
      expect(ComplexStatus.fromString('excluded'), ComplexStatus.excluded);
    });

    test('TC-COMP-ENT-002: ComplexStatus.fromString — 잘못된 값 → interested 기본값', () {
      expect(ComplexStatus.fromString('unknown'), ComplexStatus.interested);
      expect(ComplexStatus.fromString(''), ComplexStatus.interested);
    });

    test('TC-COMP-ENT-003: ComplexStatus.label — 한글 라벨 반환', () {
      expect(ComplexStatus.interested.label, '관심');
      expect(ComplexStatus.planned.label, '임장예정');
      expect(ComplexStatus.visited.label, '임장완료');
      expect(ComplexStatus.revisit.label, '재방문');
      expect(ComplexStatus.excluded.label, '제외');
    });
  });

  group('ShareRole enum', () {
    test('TC-COMP-ENT-004: ShareRole.fromString — 유효한 값 변환', () {
      expect(ShareRole.fromString('owner'), ShareRole.owner);
      expect(ShareRole.fromString('editor'), ShareRole.editor);
      expect(ShareRole.fromString('viewer'), ShareRole.viewer);
    });

    test('TC-COMP-ENT-005: ShareRole.fromString — 잘못된 값 → viewer 기본값', () {
      expect(ShareRole.fromString('admin'), ShareRole.viewer);
    });
  });

  group('CheckItem', () {
    test('TC-COMP-ENT-006: CheckItem 생성 + toMap/fromMap 라운드트립', () {
      final item = CheckItem(
        noise: 4,
        slope: 3,
        commercial: 5,
        parking: 2,
        sunlight: 4,
      );

      final map = item.toMap();
      expect(map['noise'], 4);
      expect(map['slope'], 3);
      expect(map['commercial'], 5);
      expect(map['parking'], 2);
      expect(map['sunlight'], 4);

      final restored = CheckItem.fromMap(map);
      expect(restored, equals(item));
    });

    test('TC-COMP-ENT-007: CheckItem.average — 평균값 계산', () {
      final item = CheckItem(
        noise: 1, slope: 2, commercial: 3, parking: 4, sunlight: 5,
      );
      expect(item.average, 3.0);
    });

    test('TC-COMP-ENT-008: CheckItem.fromMap — 누락 필드 기본값 3', () {
      final item = CheckItem.fromMap({});
      expect(item.noise, 3);
      expect(item.slope, 3);
      expect(item.commercial, 3);
      expect(item.parking, 3);
      expect(item.sunlight, 3);
    });
  });

  group('ComplexEntity', () {
    test('TC-COMP-ENT-009: ComplexEntity 생성 + equality (id 기준)', () {
      final c1 = ComplexEntity(
        id: 'c1',
        ownerId: 'u1',
        name: '래미안',
        address: '서울시 강남구',
        regionCode: '11680',
        createdAt: now,
        updatedAt: now,
      );

      final c2 = ComplexEntity(
        id: 'c1',
        ownerId: 'u2',
        name: '다른이름',
        address: '서울시 서초구',
        regionCode: '11650',
        createdAt: now,
        updatedAt: now,
      );

      expect(c1, equals(c2)); // same id
      expect(c1.status, ComplexStatus.interested); // default
      expect(c1.inspectionCount, 0);
      expect(c1.sharedWith, isEmpty);
    });
  });

  group('InspectionEntity', () {
    test('TC-COMP-ENT-010: InspectionEntity 생성 + equality', () {
      final inspection = InspectionEntity(
        id: 'i1',
        complexId: 'c1',
        authorId: 'u1',
        authorName: '홍길동',
        visitDate: now,
        visitTimeSlots: ['오전', '오후'],
        checkItems: CheckItem(
          noise: 4, slope: 3, commercial: 5, parking: 2, sunlight: 4,
        ),
        overallRating: 4.2,
        createdAt: now,
        updatedAt: now,
      );

      expect(inspection.id, 'i1');
      expect(inspection.visitTimeSlots, ['오전', '오후']);
      expect(inspection.checkItems.noise, 4);
      expect(inspection.photoCount, 0);
    });
  });

  group('PhotoEntity', () {
    test('TC-COMP-ENT-011: PhotoEntity 생성 + 기본값', () {
      final photo = PhotoEntity(
        id: 'p1',
        inspectionId: 'i1',
        uploaderId: 'u1',
        storageUrl: 'gs://bucket/photo.jpg',
        fileName: 'photo.jpg',
        fileSize: 1024000,
        createdAt: now,
      );

      expect(photo.order, 0);
      expect(photo.syncStatus, 'synced');
      expect(photo.thumbnailUrl, isNull);
      expect(photo.caption, isNull);
    });
  });

  group('ShareEntity', () {
    test('TC-COMP-ENT-012: ShareEntity 생성 + isActive/isPending', () {
      final activeShare = ShareEntity(
        id: 's1',
        complexId: 'c1',
        userId: 'u2',
        userEmail: 'test@test.com',
        userName: '테스트',
        role: ShareRole.editor,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      expect(activeShare.isActive, isTrue);
      expect(activeShare.isPending, isFalse);

      final pendingShare = ShareEntity(
        id: 's2',
        complexId: 'c1',
        userId: 'u3',
        userEmail: 'pending@test.com',
        userName: '대기자',
        role: ShareRole.viewer,
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      );

      expect(pendingShare.isActive, isFalse);
      expect(pendingShare.isPending, isTrue);
    });
  });

  group('ActivityLogEntity', () {
    test('TC-COMP-ENT-013: ActivityLogEntity 생성', () {
      final log = ActivityLogEntity(
        id: 'l1',
        complexId: 'c1',
        actorId: 'u1',
        actorName: '홍길동',
        action: 'inspection_created',
        targetType: 'inspection',
        targetId: 'i1',
        details: {'rating': 4.2},
        createdAt: now,
      );

      expect(log.action, 'inspection_created');
      expect(log.details?['rating'], 4.2);
    });
  });
}
