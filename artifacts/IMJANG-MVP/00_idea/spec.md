# IMJANG-MVP 설계 문서 (Spec AI 산출물)

> 작성일: 2026-03-31
> 단계: 00_idea (Spec)
> 기반 산출물: `codebase_analysis.md` (Ideator), `plan.md` (Planner)

---

## 1. 앱 아키텍처

### 1.1 레이어 구조

3계층 Clean Architecture 변형을 채택한다. 각 레이어의 의존 방향은 단방향(Presentation -> Domain -> Data)이다.

```
┌──────────────────────────────────────┐
│          Presentation Layer          │
│  (Widget, Screen, Controller/State)  │
│  - Flutter Widget                    │
│  - Riverpod Provider (UI State)      │
│  - go_router 라우트 정의             │
└──────────────┬───────────────────────┘
               │ 의존
┌──────────────▼───────────────────────┐
│            Domain Layer              │
│  (Entity, UseCase, Repository 인터페이스) │
│  - 순수 Dart (Flutter 의존 없음)     │
│  - 비즈니스 로직                     │
│  - Repository 추상 인터페이스        │
└──────────────┬───────────────────────┘
               │ 의존
┌──────────────▼───────────────────────┐
│             Data Layer               │
│  (Repository 구현, DataSource, Model)│
│  - Firestore DataSource              │
│  - Firebase Storage DataSource       │
│  - 공공API DataSource (dio + XML)    │
│  - 로컬 DB DataSource (drift)        │
│  - DTO <-> Entity 변환               │
└──────────────────────────────────────┘
```

**각 레이어 책임:**

| 레이어 | 책임 | 포함 요소 |
|--------|------|-----------|
| **Presentation** | UI 렌더링, 사용자 입력 처리, UI 상태 관리 | Widget, Screen, Riverpod Provider (UI용), Controller |
| **Domain** | 비즈니스 규칙, 유효성 검증, 엔티티 정의 | Entity, UseCase, Repository 인터페이스 (abstract class) |
| **Data** | 외부 데이터 소스 접근, DTO 변환, 캐싱 | Repository 구현체, RemoteDataSource, LocalDataSource, DTO/Model |

### 1.2 폴더 구조

**Feature-first + 내부 Layer 분리** 구조를 채택한다. (Decision Record DR-SPEC-01 참조)

```
lib/
├── app/
│   ├── app.dart                    # MaterialApp + ProviderScope
│   ├── router.dart                 # GoRouter 라우트 정의
│   └── theme.dart                  # 앱 테마 (색상, 타이포그래피)
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart      # 앱 상수 (타임아웃, 제한값 등)
│   │   ├── api_constants.dart      # 공공API URL, 서비스키 등
│   │   └── firestore_paths.dart    # Firestore 컬렉션/필드 경로 상수
│   ├── error/
│   │   ├── failures.dart           # Failure 클래스 정의
│   │   └── exceptions.dart         # 커스텀 Exception 정의
│   ├── network/
│   │   ├── network_info.dart       # 온/오프라인 감지 (connectivity_plus)
│   │   └── dio_client.dart         # dio 인스턴스 + 인터셉터
│   ├── utils/
│   │   ├── date_utils.dart         # 날짜 포맷 유틸
│   │   ├── validators.dart         # 이메일, 비밀번호 검증
│   │   └── xml_parser.dart         # XML 응답 파싱 유틸
│   └── providers/
│       ├── firebase_providers.dart # FirebaseFirestore, FirebaseAuth, FirebaseStorage 인스턴스
│       └── network_provider.dart   # 네트워크 상태 Provider
│
├── shared/
│   ├── widgets/
│   │   ├── app_bar.dart            # 공통 AppBar
│   │   ├── loading_widget.dart     # 로딩 인디케이터
│   │   ├── error_widget.dart       # 에러 표시 위젯
│   │   ├── empty_state_widget.dart # 빈 상태 표시
│   │   ├── rating_bar.dart         # 평점 입력/표시 위젯
│   │   ├── photo_grid.dart         # 사진 그리드 위젯
│   │   └── offline_banner.dart     # 오프라인 상태 배너
│   └── extensions/
│       └── context_extensions.dart # BuildContext 확장
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── user_model.dart          # Firestore DTO
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user_entity.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart     # abstract
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── auth_provider.dart        # 인증 상태 Provider
│   │       │   └── auth_controller.dart      # 로그인/회원가입 로직
│   │       └── screens/
│   │           ├── splash_screen.dart
│   │           ├── login_screen.dart
│   │           ├── signup_screen.dart
│   │           └── widgets/                  # 화면 전용 위젯
│   │
│   ├── complex/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── complex_remote_datasource.dart
│   │   │   │   └── complex_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── complex_model.dart
│   │   │   └── repositories/
│   │   │       └── complex_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── complex_entity.dart
│   │   │   │   └── complex_status.dart      # enum
│   │   │   └── repositories/
│   │   │       └── complex_repository.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── complex_list_provider.dart
│   │       │   ├── complex_detail_provider.dart
│   │       │   └── complex_search_provider.dart
│   │       └── screens/
│   │           ├── home_screen.dart
│   │           ├── complex_detail_screen.dart
│   │           ├── complex_search_screen.dart
│   │           └── widgets/
│   │
│   ├── inspection/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── inspection_remote_datasource.dart
│   │   │   │   └── photo_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── inspection_model.dart
│   │   │   │   └── photo_model.dart
│   │   │   └── repositories/
│   │   │       ├── inspection_repository_impl.dart
│   │   │       └── photo_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── inspection_entity.dart
│   │   │   │   ├── photo_entity.dart
│   │   │   │   └── check_item.dart          # 체크항목 평점
│   │   │   └── repositories/
│   │   │       ├── inspection_repository.dart
│   │   │       └── photo_repository.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── inspection_list_provider.dart
│   │       │   ├── inspection_form_provider.dart
│   │       │   └── photo_upload_provider.dart
│   │       └── screens/
│   │           ├── inspection_create_screen.dart
│   │           ├── inspection_detail_screen.dart
│   │           ├── inspection_edit_screen.dart
│   │           ├── photo_viewer_screen.dart
│   │           └── widgets/
│   │
│   ├── map/
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── map_repository_impl.dart
│   │   ├── domain/
│   │   │   └── repositories/
│   │   │       └── map_repository.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── map_provider.dart
│   │       │   └── map_filter_provider.dart
│   │       └── screens/
│   │           ├── map_screen.dart
│   │           └── widgets/
│   │               ├── map_filter_chips.dart
│   │               └── map_search_bar.dart
│   │
│   ├── share/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── share_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── share_model.dart
│   │   │   │   └── activity_log_model.dart
│   │   │   └── repositories/
│   │   │       ├── share_repository_impl.dart
│   │   │       └── activity_log_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── share_entity.dart
│   │   │   │   ├── share_role.dart          # enum: owner, editor, viewer
│   │   │   │   └── activity_log_entity.dart
│   │   │   └── repositories/
│   │   │       ├── share_repository.dart
│   │   │       └── activity_log_repository.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── share_provider.dart
│   │       │   └── activity_log_provider.dart
│   │       └── screens/
│   │           ├── share_settings_screen.dart
│   │           ├── activity_log_screen.dart
│   │           └── widgets/
│   │
│   ├── public_api/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── complex_list_api_datasource.dart
│   │   │   │   ├── complex_info_api_datasource.dart
│   │   │   │   ├── real_price_api_datasource.dart
│   │   │   │   ├── building_ledger_api_datasource.dart
│   │   │   │   └── api_cache_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── apt_list_response.dart
│   │   │   │   ├── apt_info_response.dart
│   │   │   │   ├── real_price_response.dart
│   │   │   │   └── building_ledger_response.dart
│   │   │   └── repositories/
│   │   │       └── public_api_repository_impl.dart
│   │   └── domain/
│   │       ├── entities/
│   │       │   ├── apt_list_item.dart
│   │       │   ├── apt_detail_info.dart
│   │       │   ├── real_price_item.dart
│   │       │   └── building_ledger_info.dart
│   │       └── repositories/
│   │           └── public_api_repository.dart
│   │
│   ├── region/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── region_local_datasource.dart  # drift DB
│   │   │   ├── models/
│   │   │   │   └── region_code_model.dart
│   │   │   └── repositories/
│   │   │       └── region_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── region_entity.dart
│   │   │   └── repositories/
│   │   │       └── region_repository.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── region_select_provider.dart
│   │       └── screens/
│   │           └── region_select_screen.dart
│   │
│   └── settings/
│       └── presentation/
│           ├── providers/
│           │   └── settings_provider.dart
│           └── screens/
│               └── settings_screen.dart
│
├── database/
│   ├── app_database.dart           # drift Database 정의
│   ├── tables/
│   │   └── region_codes.dart       # 법정동코드 테이블
│   └── daos/
│       └── region_code_dao.dart    # DAO
│
└── main.dart                       # 앱 진입점
```

### 1.3 Riverpod 프로바이더 패턴

Riverpod 3.x의 코드 생성 기반 프로바이더(@riverpod 어노테이션)를 사용한다.

**프로바이더 계층 구조:**

```
Firebase 인스턴스 Provider (글로벌)
  └── DataSource Provider
       └── Repository Provider
            └── UseCase / Domain Provider
                 └── UI State Provider (Controller)
                      └── Widget (ref.watch)
```

**프로바이더 유형별 사용 기준:**

| 유형 | 용도 | 예시 |
|------|------|------|
| `Provider` | 싱글톤 인스턴스 (변경 불가) | FirebaseFirestore, dio 인스턴스 |
| `FutureProvider` | 1회성 비동기 데이터 로딩 | 단지 상세정보 조회, API 호출 |
| `StreamProvider` | 실시간 데이터 스트림 | Firestore 실시간 리스너, 인증 상태 |
| `AsyncNotifierProvider` | 비동기 상태 + CRUD 동작 | 단지 목록 (필터/정렬 포함), 임장 기록 폼 |
| `NotifierProvider` | 동기 상태 관리 | 지도 필터 상태, UI 전용 상태 |

**핵심 프로바이더 목록:**

```dart
// === core/providers ===
// Firebase 인스턴스 (앱 전역)
@Riverpod(keepAlive: true)
FirebaseFirestore firestore(...) => FirebaseFirestore.instance;

@Riverpod(keepAlive: true)
FirebaseAuth firebaseAuth(...) => FirebaseAuth.instance;

@Riverpod(keepAlive: true)
FirebaseStorage firebaseStorage(...) => FirebaseStorage.instance;

// 네트워크 상태
@riverpod
Stream<bool> networkStatus(...) => // connectivity_plus 스트림

// === features/auth ===
@Riverpod(keepAlive: true)
Stream<User?> authStateChanges(...) => // Firebase Auth 상태 스트림

@riverpod
class AuthController extends _$AuthController {
  // signIn, signUp, signOut, updateProfile
}

// === features/complex ===
@riverpod
Stream<List<ComplexEntity>> complexList(...) => // Firestore 실시간 쿼리

@riverpod
class ComplexListController extends _$ComplexListController {
  // filter, sort, delete
}

@riverpod
Future<ComplexEntity> complexDetail(... , String complexId) => // 단지 상세

// === features/inspection ===
@riverpod
Stream<List<InspectionEntity>> inspectionList(... , String complexId) =>

@riverpod
class InspectionFormController extends _$InspectionFormController {
  // 폼 상태 관리, save, validate
}

@riverpod
class PhotoUploadController extends _$PhotoUploadController {
  // pickImage, compress, upload, delete, progress
}

// === features/map ===
@riverpod
class MapFilterState extends _$MapFilterState {
  // 필터 칩 상태 관리 (Set<ComplexStatus>)
}

// === features/share ===
@riverpod
Stream<List<ShareEntity>> shareMembers(... , String complexId) =>

@riverpod
class ShareController extends _$ShareController {
  // createLink, acceptInvite, updateRole, removeMember
}

// === features/public_api ===
@riverpod
Future<List<AptListItem>> searchApartments(... , {required String keyword, required String regionCode}) =>

@riverpod
Future<List<RealPriceItem>> realPrices(... , {required String regionCode, required String aptName}) =>
```

**family Provider 사용 규칙:**

- 화면/엔티티별로 파라미터가 필요한 Provider는 함수 파라미터를 사용 (Riverpod 3에서 자동 family 생성)
- 예: `complexDetail(ref, complexId: 'abc')` -> 자동으로 complexId별 캐싱

**keepAlive 사용 규칙:**

- Firebase 인스턴스, Auth 상태 등 앱 전역 데이터만 `keepAlive: true`
- 화면별 데이터는 기본 autoDispose (화면 벗어나면 해제)

---

## 2. Firestore 데이터 모델

### 2.1 users

**경로:** `users/{userId}`

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `uid` | `string` | O | Firebase Auth UID (문서 ID와 동일) |
| `email` | `string` | O | 이메일 주소 |
| `displayName` | `string` | O | 닉네임 (2~20자) |
| `photoUrl` | `string?` | X | 프로필 사진 Storage URL |
| `authProvider` | `string` | O | 인증 방식: `email`, `google`, `apple` |
| `createdAt` | `timestamp` | O | 가입일시 (서버 타임스탬프) |
| `updatedAt` | `timestamp` | O | 마지막 수정일시 |
| `lastLoginAt` | `timestamp` | O | 마지막 로그인일시 |

### 2.2 complexes

**경로:** `complexes/{complexId}`

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | `string` | O | 문서 ID (자동 생성) |
| `ownerId` | `string` | O | 등록자 Firebase UID |
| `name` | `string` | O | 단지명 |
| `address` | `string` | O | 도로명주소 |
| `addressJibun` | `string?` | X | 지번주소 |
| `regionCode` | `string` | O | 법정동코드 (10자리) |
| `latitude` | `number` | O | 위도 |
| `longitude` | `number` | O | 경도 |
| `status` | `string` | O | 상태: `interested`, `planned`, `visited`, `revisit`, `excluded` |
| `statusChangedAt` | `timestamp` | O | 상태 변경일시 |
| `totalHouseholds` | `number?` | X | 세대수 |
| `totalBuildings` | `number?` | X | 동수 |
| `minFloor` | `number?` | X | 최저층 |
| `maxFloor` | `number?` | X | 최고층 |
| `heatingType` | `string?` | X | 난방방식 |
| `approvalDate` | `string?` | X | 사용승인일 (YYYY-MM-DD) |
| `constructor` | `string?` | X | 건설사 |
| `floorAreaRatio` | `number?` | X | 용적률 |
| `buildingCoverageRatio` | `number?` | X | 건폐율 |
| `publicApiCode` | `string?` | X | 공공API 단지 고유코드 (중복 등록 방지용) |
| `sharedWith` | `array<string>` | O | 공유 참여자 UID 배열 (쿼리 필터용, 기본: [ownerId]) |
| `lastInspectionAt` | `timestamp?` | X | 마지막 임장 기록일시 |
| `inspectionCount` | `number` | O | 임장 기록 수 (기본: 0) |
| `averageRating` | `number?` | X | 평균 종합 평점 |
| `createdAt` | `timestamp` | O | 등록일시 |
| `updatedAt` | `timestamp` | O | 수정일시 |

> **설계 근거:** `sharedWith` 배열을 문서에 포함한 이유는 Firestore에서 `array-contains`로 "내가 접근 가능한 단지" 쿼리를 효율적으로 수행하기 위함. Firestore는 JOIN이 없으므로 비정규화가 필수.

### 2.3 inspections

**경로:** `complexes/{complexId}/inspections/{inspectionId}`

서브컬렉션으로 설계한다. 단지별 임장 기록 조회가 주요 쿼리 패턴이므로.

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | `string` | O | 문서 ID |
| `complexId` | `string` | O | 부모 단지 ID |
| `authorId` | `string` | O | 작성자 Firebase UID |
| `authorName` | `string` | O | 작성자 닉네임 (비정규화) |
| `visitDate` | `timestamp` | O | 방문 날짜 |
| `visitTimeSlots` | `array<string>` | O | 방문 시간대: `morning`, `forenoon`, `afternoon`, `evening`, `night` |
| `checkItems` | `map` | O | 체크항목 평점 (아래 상세) |
| `checkItems.noise` | `number` | O | 소음 (1~5) |
| `checkItems.slope` | `number` | O | 경사 (1~5) |
| `checkItems.commercial` | `number` | O | 상권 (1~5) |
| `checkItems.parking` | `number` | O | 주차 (1~5) |
| `checkItems.sunlight` | `number` | O | 일조권 (1~5) |
| `pros` | `string?` | X | 장점 (최대 1000자) |
| `cons` | `string?` | X | 단점 (최대 1000자) |
| `summary` | `string?` | X | 총평 (최대 2000자) |
| `overallRating` | `number` | O | 종합 평점 (1.0~5.0, 0.5 단위) |
| `photoCount` | `number` | O | 첨부 사진 수 (기본: 0) |
| `thumbnailUrl` | `string?` | X | 첫 번째 사진 썸네일 URL |
| `createdAt` | `timestamp` | O | 작성일시 |
| `updatedAt` | `timestamp` | O | 수정일시 |

### 2.4 photos

**경로:** `complexes/{complexId}/inspections/{inspectionId}/photos/{photoId}`

서브컬렉션으로 설계. 임장 기록별 사진 조회가 주요 패턴.

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | `string` | O | 문서 ID |
| `inspectionId` | `string` | O | 부모 임장 기록 ID |
| `uploaderId` | `string` | O | 업로더 Firebase UID |
| `storageUrl` | `string` | O | Firebase Storage 원본 URL |
| `thumbnailUrl` | `string?` | X | 썸네일 URL (추후 Cloud Functions로 자동 생성 가능) |
| `caption` | `string?` | X | 사진 메모 (최대 200자) |
| `fileName` | `string` | O | 원본 파일명 |
| `fileSize` | `number` | O | 파일 크기 (bytes, 압축 후) |
| `width` | `number?` | X | 이미지 너비 (px) |
| `height` | `number?` | X | 이미지 높이 (px) |
| `order` | `number` | O | 정렬 순서 (0부터) |
| `syncStatus` | `string` | O | 동기화 상태: `synced`, `pending`, `failed` |
| `createdAt` | `timestamp` | O | 업로드일시 |

**Storage 경로 규칙:**
```
photos/{complexId}/{inspectionId}/{photoId}.jpg
profiles/{userId}/profile.jpg
```

### 2.5 shares

**경로:** `complexes/{complexId}/shares/{shareId}`

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | `string` | O | 문서 ID |
| `complexId` | `string` | O | 대상 단지 ID |
| `userId` | `string` | O | 참여자 Firebase UID |
| `userEmail` | `string` | O | 참여자 이메일 (표시용) |
| `userName` | `string` | O | 참여자 닉네임 (비정규화) |
| `role` | `string` | O | 권한: `owner`, `editor`, `viewer` |
| `invitedBy` | `string` | O | 초대한 사용자 UID |
| `inviteToken` | `string?` | X | 초대 토큰 (링크 생성 시) |
| `inviteRole` | `string?` | X | 초대 시 부여할 권한 |
| `tokenExpiresAt` | `timestamp?` | X | 초대 토큰 만료 일시 (기본: 생성 후 7일). 만료된 토큰으로 수락 시 거부 |
| `status` | `string` | O | `active`, `pending` (초대 수락 대기) |
| `createdAt` | `timestamp` | O | 초대/참여 일시 |
| `updatedAt` | `timestamp` | O | 수정일시 |

### 2.6 activityLogs

**경로:** `complexes/{complexId}/activityLogs/{logId}`

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | `string` | O | 문서 ID |
| `complexId` | `string` | O | 대상 단지 ID |
| `actorId` | `string` | O | 수행자 Firebase UID |
| `actorName` | `string` | O | 수행자 닉네임 (비정규화) |
| `action` | `string` | O | `inspection_created`, `inspection_updated`, `status_changed`, `member_added`, `member_removed`, `role_changed` |
| `targetType` | `string?` | X | 대상 유형: `inspection`, `complex`, `share` |
| `targetId` | `string?` | X | 대상 문서 ID |
| `details` | `map?` | X | 추가 정보 (예: `{from: "interested", to: "visited"}`) |
| `createdAt` | `timestamp` | O | 활동 일시 |

### 2.7 apiCache

**경로:** `apiCache/{cacheKey}`

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `cacheKey` | `string` | O | 캐시 키 (문서 ID). 규칙: `{apiType}_{paramHash}` |
| `apiType` | `string` | O | `complexList`, `complexInfo`, `realPrice`, `buildingLedger` |
| `params` | `map` | O | API 요청 파라미터 (재조회용) |
| `data` | `array<map>` | O | API 응답 데이터 (JSON 변환된 목록) |
| `ttlDays` | `number` | O | 캐시 유효 기간 (일) |
| `cachedAt` | `timestamp` | O | 캐싱 일시 |
| `expiresAt` | `timestamp` | O | 만료 일시 (`cachedAt` + `ttlDays`) |
| `hitCount` | `number` | O | 조회 횟수 (기본: 0) |

**캐시 키 생성 규칙:**

| API 유형 | 캐시 키 패턴 | TTL |
|----------|-------------|-----|
| 단지 목록 | `complexList_{regionCode}` | 7일 |
| 단지 정보 | `complexInfo_{publicApiCode}` | 30일 |
| 실거래가 | `realPrice_{regionCode}_{yearMonth}` | 7일 |
| 건축물대장 | `buildingLedger_{sigunguCode}_{번}_{지}` | 영구 (365일) |

### 2.8 인덱스 설계

Firestore 복합 인덱스 (자동 생성되지 않는 쿼리용):

| 컬렉션 | 인덱스 필드 | 용도 |
|--------|-------------|------|
| `complexes` | `sharedWith (array-contains)` + `status (==)` + `createdAt (desc)` | 내 단지 목록 상태 필터 + 최근순 |
| `complexes` | `sharedWith (array-contains)` + `name (asc)` | 내 단지 목록 이름순 |
| `complexes` | `sharedWith (array-contains)` + `lastInspectionAt (desc)` | 내 단지 목록 최근 임장순 |
| `complexes` | `ownerId (==)` + `publicApiCode (==)` | 중복 단지 등록 확인 |
| `apiCache` | `apiType (==)` + `expiresAt (asc)` | 만료 캐시 정리용 |

> **참고:** Firestore는 단일 필드 인덱스는 자동 생성. 위는 복합 인덱스만 기재. 실제 개발 시 Firestore 콘솔의 인덱스 생성 안내 링크를 따라 추가.

---

## 3. Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // === 헬퍼 함수 ===

    // 인증 확인
    function isAuthenticated() {
      return request.auth != null;
    }

    // 본인 확인
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // 단지 접근 권한 확인 (sharedWith 배열에 포함)
    function hasComplexAccess(complexData) {
      return isAuthenticated()
        && request.auth.uid in complexData.sharedWith;
    }

    // 단지 Owner 확인
    function isComplexOwner(complexData) {
      return isAuthenticated()
        && request.auth.uid == complexData.ownerId;
    }

    // 공유 역할 확인 (shares 서브컬렉션에서)
    function getShareRole(complexId) {
      return get(/databases/$(database)/documents/complexes/$(complexId)/shares/$(request.auth.uid)).data.role;
    }

    // Editor 이상 권한
    function isEditorOrAbove(complexId) {
      let role = getShareRole(complexId);
      return role == 'owner' || role == 'editor';
    }

    // 문서 크기/필드 유효성
    function isValidString(field, maxLen) {
      return field is string && field.size() <= maxLen;
    }

    // === users 컬렉션 ===
    match /users/{userId} {
      allow read: if isAuthenticated();
      // 본인만 자기 문서 쓰기 가능
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if false; // 사용자 삭제는 Cloud Functions 또는 관리자만
    }

    // === complexes 컬렉션 ===
    match /complexes/{complexId} {
      // 읽기: sharedWith에 포함된 사용자만
      allow read: if hasComplexAccess(resource.data);

      // 생성: 인증된 사용자, ownerId가 본인
      allow create: if isAuthenticated()
        && request.resource.data.ownerId == request.auth.uid
        && request.auth.uid in request.resource.data.sharedWith;

      // 수정: Editor 이상
      allow update: if hasComplexAccess(resource.data)
        && isEditorOrAbove(complexId);

      // 삭제: Owner만
      allow delete: if isComplexOwner(resource.data);

      // === inspections 서브컬렉션 ===
      match /inspections/{inspectionId} {
        allow read: if hasComplexAccess(
          get(/databases/$(database)/documents/complexes/$(complexId)).data
        );

        allow create: if isEditorOrAbove(complexId)
          && request.resource.data.authorId == request.auth.uid;

        allow update: if isEditorOrAbove(complexId);

        allow delete: if isEditorOrAbove(complexId);

        // === photos 서브컬렉션 ===
        match /photos/{photoId} {
          allow read: if hasComplexAccess(
            get(/databases/$(database)/documents/complexes/$(complexId)).data
          );

          allow create: if isEditorOrAbove(complexId)
            && request.resource.data.uploaderId == request.auth.uid;

          allow update: if isEditorOrAbove(complexId);
          allow delete: if isEditorOrAbove(complexId);
        }
      }

      // === shares 서브컬렉션 ===
      match /shares/{shareId} {
        allow read: if hasComplexAccess(
          get(/databases/$(database)/documents/complexes/$(complexId)).data
        );

        // Owner만 참여자 추가/수정/삭제 가능
        allow create: if isComplexOwner(
          get(/databases/$(database)/documents/complexes/$(complexId)).data
        );

        allow update: if isComplexOwner(
          get(/databases/$(database)/documents/complexes/$(complexId)).data
        );

        allow delete: if isComplexOwner(
          get(/databases/$(database)/documents/complexes/$(complexId)).data
        );
      }

      // === activityLogs 서브컬렉션 ===
      match /activityLogs/{logId} {
        // 참여자면 읽기 가능
        allow read: if hasComplexAccess(
          get(/databases/$(database)/documents/complexes/$(complexId)).data
        );

        // Editor 이상이면 로그 생성 가능
        allow create: if isEditorOrAbove(complexId)
          && request.resource.data.actorId == request.auth.uid;

        // 로그는 수정/삭제 불가 (불변)
        allow update, delete: if false;
      }
    }

    // === apiCache 컬렉션 ===
    match /apiCache/{cacheKey} {
      // 인증된 사용자면 읽기 가능 (공유 캐시)
      allow read: if isAuthenticated();

      // 쓰기: 인증 + 필수 필드 존재 + 스키마 유효성 검증 (캐시 오염 방지)
      allow create: if isAuthenticated()
        && request.resource.data.keys().hasAll(['cacheKey', 'apiType', 'params', 'data', 'ttlDays', 'cachedAt', 'expiresAt'])
        && request.resource.data.cacheKey == cacheKey
        && request.resource.data.apiType in ['complexList', 'complexInfo', 'realPrice', 'buildingLedger']
        && request.resource.data.ttlDays is number;

      // 업데이트: apiType 변경 불가 + 캐시 키 변경 불가 (데이터 무결성 보장)
      allow update: if isAuthenticated()
        && request.resource.data.apiType == resource.data.apiType
        && request.resource.data.cacheKey == resource.data.cacheKey;

      allow delete: if false; // 만료 캐시 삭제는 Cloud Functions로
    }
  }
}
```

**Storage Security Rules:**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // 프로필 사진: 본인만 업로드, 인증된 사용자 모두 읽기
    match /profiles/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId
        && request.resource.size < 5 * 1024 * 1024  // 5MB 제한
        && request.resource.contentType.matches('image/.*');
    }

    // 임장 사진: 단지 참여자만 접근
    // (Storage Rules에서 Firestore 쿼리 불가하므로, 인증 + 경로 기반 제한)
    match /photos/{complexId}/{inspectionId}/{photoId} {
      allow read: if request.auth != null;
      // 업로드 제한: 인증 + 파일 크기 + 이미지 타입
      allow write: if request.auth != null
        && request.resource.size < 10 * 1024 * 1024  // 10MB 제한
        && request.resource.contentType.matches('image/.*');
    }
  }
}
```

> **제약/한계:** Storage Security Rules에서는 Firestore 문서를 조회할 수 없다. 따라서 Storage에서는 "인증된 사용자 + 파일 타입/크기 제한"만 적용하고, 세밀한 권한은 Firestore Rules + 앱 로직에서 처리한다. 사진 URL을 Firestore에 저장하므로, Firestore Rules가 실질적 접근 제어 역할을 한다.
>
> **Storage 사진 URL 보안 한계:** 인증된 모든 사용자가 Storage URL을 직접 알 경우 사진에 접근할 수 있다. MVP에서는 이 제약을 수용하되, 앱 UI에서 사진 URL을 외부 공유하는 기능을 제공하지 않는다. V2에서 Firebase Storage의 signed URL 또는 Cloud Functions를 통한 토큰 기반 접근으로 강화를 검토한다.

### 3.1 오프라인 사진 업로드 큐 설계

> **중요:** Firebase Storage는 Firestore와 달리 오프라인 자동 큐잉을 지원하지 않는다. 텍스트 데이터(Firestore)는 자동 동기화되나, 사진(Storage)은 앱에서 수동으로 업로드 큐를 관리해야 한다.

```
┌────────────────────────────────────────────────────────────┐
│                  오프라인 사진 업로드 큐                      │
│                                                            │
│  [사진 촬영/선택]                                           │
│    │                                                       │
│    ▼                                                       │
│  앱 documents 디렉토리에 저장                               │
│  (getApplicationDocumentsDirectory, 시스템 정리 방지)       │
│    │                                                       │
│    ▼                                                       │
│  photos 문서에 syncStatus: "pending" 기록                   │
│    │                                                       │
│    ▼                                                       │
│  네트워크 상태 감시 (connectivity_plus)                      │
│    │                                                       │
│    ├─ 오프라인 ──> 큐에 대기. 로컬 파일 경로로 UI 표시      │
│    │                                                       │
│    └─ 온라인 복구                                           │
│         │                                                  │
│         ▼                                                  │
│    큐에서 pending 사진 순차 업로드                           │
│         │                                                  │
│         ├─ 성공 ──> syncStatus: "synced"                    │
│         │          로컬 파일 삭제                            │
│         │                                                  │
│         └─ 실패 ──> 최대 3회 재시도 (지수 백오프)            │
│              │                                             │
│              ├─ 재시도 성공 ──> syncStatus: "synced"         │
│              └─ 3회 실패 ──> syncStatus: "failed"           │
│                   사용자에게 수동 재시도 버튼 표시            │
└────────────────────────────────────────────────────────────┘
```

**구현 핵심:**
- 사진 저장 경로: `getApplicationDocumentsDirectory()` 사용 (iOS `getTemporaryDirectory()`는 시스템에 의해 정리될 수 있으므로 사용하지 않음)
- 업로드 큐는 Riverpod Provider로 관리하며, 앱 재시작 시 pending 상태 사진을 Firestore에서 조회하여 큐 재구성
- 동시 업로드 최대 2개 (네트워크 대역폭 고려)

---

## 4. 화면별 상세 설계

### 4.1 SCR-SPLASH (스플래시)

**UI 구성:**
- 앱 로고 (중앙)
- 로딩 인디케이터 (하단)

**State:**
```dart
enum SplashState {
  loading,      // Auth 상태 확인 중
  authenticated,    // -> HomeScreen
  unauthenticated,  // -> LoginScreen
}
```

**Provider:** `authStateChangesProvider` (StreamProvider)

**동작 흐름:**
1. 앱 시작 -> Firebase 초기화
2. `authStateChanges` 스트림 1회 확인
3. 로그인 상태면 HomeScreen, 아니면 LoginScreen으로 리다이렉트
4. go_router의 `redirect` 로직에서 처리

---

### 4.2 SCR-LOGIN (로그인)

**UI 구성:**
- 앱 로고
- 이메일 입력 TextField
- 비밀번호 입력 TextField (obscure)
- "로그인" 버튼 (ElevatedButton)
- "Google로 로그인" 버튼
- "Apple로 로그인" 버튼 (iOS만 표시, `Platform.isIOS`)
- "회원가입" 텍스트 버튼 -> SCR-SIGNUP 이동
- 에러 메시지 표시 영역

**State:**
```dart
@freezed
class LoginState with _$LoginState {
  const factory LoginState({
    @Default('') String email,
    @Default('') String password,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _LoginState;
}
```

**Provider:** `authControllerProvider` (AsyncNotifierProvider)

**유효성 검사:**
- 이메일: 정규식 검증
- 비밀번호: 8자 이상

---

### 4.3 SCR-SIGNUP (회원가입)

**UI 구성:**
- 이메일 입력 TextField
- 비밀번호 입력 TextField
- 비밀번호 확인 TextField
- 닉네임 입력 TextField (2~20자)
- "가입하기" 버튼

**State:**
```dart
@freezed
class SignupState with _$SignupState {
  const factory SignupState({
    @Default('') String email,
    @Default('') String password,
    @Default('') String passwordConfirm,
    @Default('') String displayName,
    @Default(false) bool isLoading,
    String? errorMessage,
    Map<String, String>? fieldErrors,  // 필드별 에러
  }) = _SignupState;
}
```

**Provider:** `authControllerProvider` (LoginScreen과 공유)

---

### 4.4 SCR-HOME (홈 - 단지 목록)

**UI 구성:**
- AppBar: 앱 타이틀, 오프라인 배너 (네트워크 상태에 따라)
- 필터 칩 바: 전체 / 관심 / 방문예정 / 방문완료 / 재방문 / 제외
- 정렬 드롭다운: 최근 등록순 / 이름순 / 최근 임장순
- 단지 목록 (ListView):
  - 카드형 아이템: 단지명, 주소, 상태 아이콘/배지, 최근 임장일, 평균 평점
  - 빈 상태: "등록된 단지가 없습니다. 단지를 검색하여 등록해보세요"
- FloatingActionButton (+): SCR-SEARCH로 이동
- 하단 탭 네비게이션

**State:**
```dart
@freezed
class ComplexListState with _$ComplexListState {
  const factory ComplexListState({
    @Default([]) List<ComplexEntity> complexes,
    @Default(ComplexStatusFilter.all) ComplexStatusFilter filter,
    @Default(ComplexSortOrder.recentCreated) ComplexSortOrder sortOrder,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _ComplexListState;
}

enum ComplexStatusFilter { all, interested, planned, visited, revisit, excluded }
enum ComplexSortOrder { recentCreated, nameAsc, recentInspection }
```

**Provider:** `complexListControllerProvider` (AsyncNotifierProvider)

**무한 스크롤:** Firestore `limit(20)` + `startAfterDocument` 로 페이지네이션

---

### 4.5 SCR-SEARCH (단지 검색)

**UI 구성:**
- 검색 TextField (자동완성 + 디바운스 500ms)
- 지역 선택 버튼 -> SCR-REGION-SELECT
- 선택된 지역 표시 칩
- 검색 결과 목록 (ListView):
  - 단지명, 주소, 세대수
  - 이미 등록된 단지는 "등록됨" 배지 표시
- 로딩 인디케이터
- 에러/빈 결과 표시

**State:**
```dart
@freezed
class ComplexSearchState with _$ComplexSearchState {
  const factory ComplexSearchState({
    @Default('') String keyword,
    String? selectedRegionCode,
    String? selectedRegionName,
    @Default(AsyncValue.data([])) AsyncValue<List<AptListItem>> results,
    @Default(false) bool isRegistering,
  }) = _ComplexSearchState;
}
```

**Provider:** `complexSearchProviderProvider` (AsyncNotifierProvider)

---

### 4.6 SCR-COMPLEX-DETAIL (단지 상세)

**UI 구성:**
- AppBar: 단지명, 공유 버튼, 더보기 메뉴 (삭제, 상태 변경)
- 상태 배지 (탭하여 변경)
- 탭 바:
  - **정보 탭:** 기본정보 카드 (세대수, 동수, 층수 등) + 건축물대장 정보
  - **실거래가 탭:** 최근 6개월 거래 목록 (계약일, 면적, 가격, 층) + 새로고침 버튼
  - **임장 기록 탭:** 임장 기록 목록 + 작성 버튼
- 각 탭은 독립적으로 데이터 로딩

**State:**
```dart
@freezed
class ComplexDetailState with _$ComplexDetailState {
  const factory ComplexDetailState({
    required ComplexEntity complex,
    @Default(0) int selectedTabIndex,
    @Default(AsyncValue.loading()) AsyncValue<List<RealPriceItem>> realPrices,
    @Default(AsyncValue.loading()) AsyncValue<List<InspectionEntity>> inspections,
    @Default(AsyncValue.loading()) AsyncValue<BuildingLedgerInfo?> buildingLedger,
  }) = _ComplexDetailState;
}
```

**Provider:**
- `complexDetailProvider(complexId)` (FutureProvider)
- `realPricesProvider(regionCode, aptName)` (FutureProvider)
- `inspectionListProvider(complexId)` (StreamProvider)

---

### 4.7 SCR-INSP-CREATE (임장 기록 작성)

**UI 구성:**
- 방문 날짜 선택 (DatePicker, 기본: 오늘)
- 방문 시간대 선택 (ChoiceChip, 다중 선택)
- 체크항목 평점 섹션:
  - 소음 / 경사 / 상권 / 주차 / 일조권 각각 별점 (1~5)
  - 커스텀 RatingBar 위젯
- 장점 TextField (최대 1000자, 글자수 카운터)
- 단점 TextField (최대 1000자)
- 총평 TextField (최대 2000자)
- 종합 평점 (0.5 단위 별점)
- 사진 섹션:
  - 사진 그리드 (추가된 사진 미리보기)
  - "사진 추가" 버튼 (카메라/갤러리 선택 BottomSheet)
  - 각 사진에 캡션 입력 가능
  - 업로드 진행률 LinearProgressIndicator
- "저장" 버튼

**State:**
```dart
@freezed
class InspectionFormState with _$InspectionFormState {
  const factory InspectionFormState({
    required String complexId,
    DateTime? visitDate,
    @Default([]) List<String> visitTimeSlots,
    @Default(CheckItems()) CheckItems checkItems,
    @Default('') String pros,
    @Default('') String cons,
    @Default('') String summary,
    @Default(0.0) double overallRating,
    @Default([]) List<PhotoFormItem> photos,
    @Default(false) bool isSaving,
    String? errorMessage,
  }) = _InspectionFormState;
}

@freezed
class CheckItems with _$CheckItems {
  const factory CheckItems({
    @Default(0) int noise,
    @Default(0) int slope,
    @Default(0) int commercial,
    @Default(0) int parking,
    @Default(0) int sunlight,
  }) = _CheckItems;
}

@freezed
class PhotoFormItem with _$PhotoFormItem {
  const factory PhotoFormItem({
    required String localPath,
    @Default('') String caption,
    @Default(PhotoUploadStatus.pending) PhotoUploadStatus uploadStatus,
    @Default(0.0) double uploadProgress,
    String? storageUrl,
  }) = _PhotoFormItem;
}

enum PhotoUploadStatus { pending, uploading, completed, failed }
```

**Provider:** `inspectionFormControllerProvider(complexId)` (AsyncNotifierProvider)

---

### 4.8 SCR-INSP-DETAIL (임장 기록 상세)

**UI 구성:**
- AppBar: 방문일, 수정 버튼, 삭제 버튼
- 방문 시간대 칩
- 체크항목 평점 표시 (읽기 전용 별점)
- 장점/단점/총평 텍스트
- 종합 평점 표시
- 사진 그리드 (탭 -> SCR-PHOTO-VIEWER)
- 작성자/수정일 정보

**State:** `inspectionDetailProvider(complexId, inspectionId)` (FutureProvider)

---

### 4.9 SCR-INSP-EDIT (임장 기록 수정)

SCR-INSP-CREATE와 동일한 UI/State 구조. 초기값을 기존 기록으로 채움.

**Provider:** `inspectionFormControllerProvider`에 기존 데이터 로드 메서드 추가

---

### 4.10 SCR-MAP (지도)

**UI 구성:**
- KakaoMap 위젯 (전체 화면)
- 상단: 검색 바 + 필터 칩 바
- 하단: 현재 위치 FAB
- 마커 탭 시 InfoWindow:
  - 단지명, 상태 배지, 종합 평점
  - 탭 시 SCR-COMPLEX-DETAIL 이동

**State:**
```dart
@freezed
class MapState with _$MapState {
  const factory MapState({
    @Default({}) Set<ComplexStatus> activeFilters,  // 빈 셋 = 전체 표시
    @Default('') String searchQuery,
    NLatLng? currentPosition,
    @Default([]) List<ComplexMarkerData> markers,
    String? selectedComplexId,
  }) = _MapState;
}

@freezed
class ComplexMarkerData with _$ComplexMarkerData {
  const factory ComplexMarkerData({
    required String complexId,
    required String name,
    required double latitude,
    required double longitude,
    required ComplexStatus status,
    double? averageRating,
  }) = _ComplexMarkerData;
}
```

**Provider:**
- `mapControllerProvider` (NotifierProvider)
- `mapFilterProvider` (NotifierProvider)

**마커 색상 매핑:**
| 상태 | 색상 (Hex) | 설명 |
|------|-----------|------|
| interested | `#FFC107` | 노랑 (Amber) |
| planned | `#2196F3` | 파랑 (Blue) |
| visited | `#4CAF50` | 초록 (Green) |
| revisit | `#FF9800` | 주황 (Orange) |
| excluded | `#9E9E9E` | 회색 (Grey) |

---

### 4.11 SCR-SHARE-SETTINGS (공유 설정)

**UI 구성:**
- 공유 링크 생성 섹션:
  - 권한 선택 (Editor / Viewer) SegmentedButton
  - "링크 생성" 버튼
  - 생성된 링크 + 복사 버튼 + OS 공유 버튼
- 참여자 목록:
  - 각 항목: 프로필 사진, 닉네임, 이메일, 역할 배지
  - Owner: 권한 변경 DropdownButton, 제거 버튼
  - 본인: "(나)" 표시

**State:**
```dart
@freezed
class ShareSettingsState with _$ShareSettingsState {
  const factory ShareSettingsState({
    required String complexId,
    @Default(ShareRole.viewer) ShareRole inviteRole,
    String? generatedLink,
    @Default(AsyncValue.loading()) AsyncValue<List<ShareEntity>> members,
    @Default(false) bool isGeneratingLink,
  }) = _ShareSettingsState;
}
```

**Provider:** `shareControllerProvider(complexId)` (AsyncNotifierProvider)

---

### 4.12 SCR-ACTIVITY-LOG (활동 로그)

**UI 구성:**
- 활동 로그 목록 (ListView):
  - 각 항목: 수행자 아바타, 닉네임, 활동 내용, 시간 (상대적: "3분 전")
  - 아이콘: 활동 유형별 아이콘
- 50건 표시 + "더 보기" 버튼

**State:** `activityLogProvider(complexId)` (FutureProvider, 페이지네이션)

---

### 4.13 SCR-SETTINGS (설정)

**UI 구성:**
- 프로필 섹션:
  - 프로필 사진 (탭하여 변경)
  - 닉네임 (탭하여 편집)
  - 이메일 (읽기 전용)
- 앱 정보 섹션:
  - 버전 정보
  - 오픈소스 라이선스
- "로그아웃" 버튼 (확인 다이얼로그)

**Provider:** `settingsControllerProvider` (AsyncNotifierProvider)

---

### 4.14 SCR-PHOTO-VIEWER (사진 뷰어)

**UI 구성:**
- 전체 화면 사진 표시 (PageView + InteractiveViewer)
- 스와이프로 사진 넘기기
- 핀치 줌 확대/축소
- 상단: 닫기 버튼, 사진 순번 (3/10)
- 하단: 캡션 표시

**State:**
```dart
@freezed
class PhotoViewerState with _$PhotoViewerState {
  const factory PhotoViewerState({
    required List<PhotoEntity> photos,
    @Default(0) int currentIndex,
  }) = _PhotoViewerState;
}
```

**Provider:** `photoViewerProvider` (NotifierProvider)

---

### 4.15 SCR-REGION-SELECT (지역 선택)

**UI 구성:**
- 계층적 선택 UI (3단계):
  - 1단계: 시/도 목록 (ListView)
  - 2단계: 시/군/구 목록 (선택된 시/도 하위)
  - 3단계: 읍/면/동 목록 (선택된 시/군/구 하위)
- 각 단계 선택 시 다음 단계로 애니메이션 전환
- 선택 완료 시 법정동코드와 함께 이전 화면으로 반환

**State:**
```dart
@freezed
class RegionSelectState with _$RegionSelectState {
  const factory RegionSelectState({
    @Default(0) int currentStep,  // 0: 시도, 1: 시군구, 2: 읍면동
    @Default([]) List<RegionEntity> sidoList,
    @Default([]) List<RegionEntity> sigunguList,
    @Default([]) List<RegionEntity> dongList,
    RegionEntity? selectedSido,
    RegionEntity? selectedSigungu,
    RegionEntity? selectedDong,
  }) = _RegionSelectState;
}
```

**Provider:** `regionSelectControllerProvider` (NotifierProvider)

---

## 5. 공공데이터 API 연동 설계

### 5.1 공통 HTTP 클라이언트 설계

```
dio 인스턴스
├── BaseOptions
│   ├── connectTimeout: 10초
│   ├── receiveTimeout: 10초
│   └── responseType: ResponseType.plain (XML 원문 수신)
├── Interceptors
│   ├── RetryInterceptor (3회 재시도, 1초 간격, 지수 백오프)
│   ├── LogInterceptor (디버그 모드)
│   └── CacheCheckInterceptor (요청 전 Firestore 캐시 확인)
└── 에러 매핑
    ├── DioException.connectionTimeout -> NetworkFailure
    ├── DioException.receiveTimeout -> TimeoutFailure
    ├── DioException.response (4xx/5xx) -> ServerFailure
    └── FormatException (XML 파싱 실패) -> ParseFailure
```

### 5.2 XML 파싱 전략

`xml` 패키지(Dart 기본)를 사용하여 XML을 직접 파싱한다. `xml2json`은 불필요한 변환 오버헤드가 있으므로 사용하지 않는다.

**파싱 흐름:**
```
XML 응답 (String)
  -> xml.XmlDocument.parse()
  -> XPath로 필요한 노드 추출
  -> Dart Model (DTO) 변환
  -> Domain Entity 변환
```

### 5.3 API별 상세 설계

#### API 1: 공동주택 단지 목록 (국토교통부)

**엔드포인트:** `http://apis.data.go.kr/1613000/AptListService2/getLegaldongAptList`

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `serviceKey` | string | 인증키 (URL 인코딩) |
| `bjdCode` | string | 법정동코드 (10자리) |
| `pageNo` | int | 페이지 번호 |
| `numOfRows` | int | 한 페이지 결과 수 (기본 100) |

**응답 DTO:**
```dart
class AptListResponse {
  final int totalCount;
  final List<AptListItemDto> items;
}

class AptListItemDto {
  final String kaptCode;     // 단지 고유코드
  final String kaptName;     // 단지명
  final String kaptAddr;     // 도로명주소
  final String bjdCode;      // 법정동코드
  final int? kaptdaCnt;      // 세대수
  final String? kaptUseDate; // 사용승인일
  final double? kaptLat;     // 위도 (일부 API에서 제공)
  final double? kaptLon;     // 경도
}
```

#### API 2: 공동주택 기본 정보 (국토교통부)

**엔드포인트:** `http://apis.data.go.kr/1613000/AptBasisInfoService1/getAphusBassInfo`

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `serviceKey` | string | 인증키 |
| `kaptCode` | string | 단지 고유코드 |

**응답 DTO:**
```dart
class AptInfoDto {
  final String kaptCode;
  final String kaptName;
  final String kaptAddr;
  final int? kaptdaCnt;         // 세대수
  final int? kaptBdCnt;         // 동수
  final int? kaptMinFloor;      // 최저층
  final int? kaptMaxFloor;      // 최고층
  final String? kaptHeatType;   // 난방방식
  final String? kaptUseDate;    // 사용승인일
  final String? kaptBuilder;    // 건설사
  final double? kaptFloorAreaRatio; // 용적률
  final double? kaptBuildingCoverageRatio; // 건폐율
}
```

#### API 3: 아파트 매매 실거래가 (국토교통부)

**엔드포인트:** `http://apis.data.go.kr/1613000/RTMSDataSvcAptTradeDev/getRTMSDataSvcAptTradeDev`

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `serviceKey` | string | 인증키 |
| `LAWD_CD` | string | 법정동코드 앞 5자리 (시군구코드) |
| `DEAL_YMD` | string | 계약년월 (YYYYMM) |
| `pageNo` | int | 페이지 번호 |
| `numOfRows` | int | 결과 수 |

**응답 DTO:**
```dart
class RealPriceDto {
  final String aptName;     // 아파트명
  final double excluArea;   // 전용면적 (m2)
  final String dealAmount;  // 거래금액 (만원, 쉼표 포함 문자열)
  final int dealYear;       // 계약년
  final int dealMonth;      // 계약월
  final int dealDay;        // 계약일
  final int? floor;         // 층
  final String? buildYear;  // 건축년도
  final String? roadName;   // 도로명
}
```

> **주의:** `dealAmount`는 "70,000" 형태의 문자열. 쉼표 제거 + int 파싱 필요.

#### API 4: 건축물대장 정보 (국토교통부)

**엔드포인트:** `http://apis.data.go.kr/1613000/BldRgstService/getBrExposPubuseAreaInfo`

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `serviceKey` | string | 인증키 |
| `sigunguCd` | string | 시군구코드 (5자리) |
| `bjdongCd` | string | 법정동코드 뒤 5자리 |
| `bun` | string | 번 (4자리, 앞 0 채움) |
| `ji` | string | 지 (4자리, 앞 0 채움) |

**응답 DTO:**
```dart
class BuildingLedgerDto {
  final double? platArea;       // 대지면적
  final double? archArea;       // 건축면적
  final double? totArea;        // 연면적
  final String? useAprDay;      // 사용승인일 (YYYYMMDD)
  final int? grndFlrCnt;        // 지상층수
  final int? ugrndFlrCnt;       // 지하층수
  final String? mainPurpsCdNm;  // 주용도
}
```

### 5.4 캐싱 전략 상세

```
┌─────────────────────────────────────────────────────┐
│                   API 호출 흐름                      │
│                                                     │
│  요청 발생                                           │
│    │                                                 │
│    ▼                                                 │
│  Firestore apiCache에서 캐시 키 조회                  │
│    │                                                 │
│    ├─ 캐시 존재 & 미만료 ──> 캐시 데이터 반환          │
│    │                                                 │
│    └─ 캐시 없음 또는 만료                             │
│         │                                            │
│         ▼                                            │
│    네트워크 확인                                       │
│         │                                            │
│         ├─ 오프라인 & 캐시 존재(만료) ──> 만료 캐시 반환 │
│         │   + "최신 데이터가 아닐 수 있습니다" 표시      │
│         │                                            │
│         ├─ 오프라인 & 캐시 없음 ──> 에러 반환           │
│         │   + "네트워크 연결이 필요합니다" 표시          │
│         │                                            │
│         └─ 온라인 ──> API 호출                        │
│              │                                       │
│              ├─ 성공 ──> Firestore 캐싱 + 데이터 반환  │
│              │                                       │
│              └─ 실패 ──> 만료 캐시 있으면 반환          │
│                   + "최신 데이터를 불러올 수 없습니다"   │
│                   없으면 에러 표시                     │
└─────────────────────────────────────────────────────┘
```

### 5.5 에러 핸들링 + 재시도 전략

| 상황 | 처리 |
|------|------|
| 타임아웃 (10초) | 최대 3회 재시도 (1초, 2초, 4초 지수 백오프) |
| HTTP 4xx | 재시도 안 함. 에러 메시지 표시 |
| HTTP 5xx | 최대 3회 재시도 |
| XML 파싱 실패 | 재시도 안 함. "데이터 형식 오류" 로그 + 캐시 폴백 |
| 일일 호출 제한 초과 | "잠시 후 다시 시도해주세요" (제한 리셋까지 대기) |
| 네트워크 없음 | 캐시 폴백 또는 "네트워크 연결 필요" |

**API 키 보호:**
- 환경변수 또는 `--dart-define`으로 빌드 시 주입
- Firebase Remote Config는 MVP 이후 검토 (설정 변경 시 앱 업데이트 없이 키 교체 가능)

---

## 6. 공유/권한 모델 설계

### 6.1 공유 데이터 흐름

```
┌────────────────────────────────────────────────────────────┐
│                  공유 링크 생성 흐름                         │
│                                                            │
│  [Owner] "공유" 버튼                                        │
│    │                                                        │
│    ▼                                                        │
│  권한 선택 (Editor / Viewer)                                │
│    │                                                        │
│    ▼                                                        │
│  shares 서브컬렉션에 pending 문서 생성                       │
│    - inviteToken: UUID v4                                    │
│    - inviteRole: 선택한 권한                                 │
│    - status: "pending"                                       │
│    │                                                        │
│    ▼                                                        │
│  딥링크 생성: imjang://invite/{complexId}?token={inviteToken}│
│    │                                                        │
│    ▼                                                        │
│  클립보드 복사 또는 OS Share Sheet                           │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│                  초대 수락 흐름                              │
│                                                            │
│  [초대받은 사용자] 딥링크 클릭                               │
│    │                                                        │
│    ▼                                                        │
│  앱 열림 (미설치 시 스토어)                                  │
│    │                                                        │
│    ▼                                                        │
│  go_router 딥링크 핸들러                                     │
│    │                                                        │
│    ├─ 미로그인 ──> 로그인 화면 (리다이렉트 URL 저장)         │
│    │               로그인 성공 후 초대 수락 처리              │
│    │                                                        │
│    └─ 로그인됨 ──> 초대 수락 처리                            │
│         │                                                   │
│         ▼                                                   │
│    Firestore 트랜잭션:                                       │
│      1. shares/{inviteToken} 문서 조회                       │
│      2. status: "pending" 확인                               │
│      2.5. tokenExpiresAt > now 확인 (만료 시 에러 반환)      │
│      3. shares에 사용자 문서 생성 (status: "active")         │
│      4. complexes/{complexId}.sharedWith 배열에 UID 추가     │
│      5. pending 문서 삭제 또는 status 업데이트                │
│         │                                                   │
│         ▼                                                   │
│    단지 상세 화면으로 이동                                    │
└────────────────────────────────────────────────────────────┘
```

### 6.2 권한 매트릭스

| 동작 | Owner | Editor | Viewer |
|------|:-----:|:------:|:------:|
| 단지 정보 조회 | O | O | O |
| 임장 기록 조회 | O | O | O |
| 사진 조회 | O | O | O |
| 활동 로그 조회 | O | O | O |
| 임장 기록 작성 | O | O | X |
| 임장 기록 수정 | O | O | X |
| 임장 기록 삭제 | O | O | X |
| 사진 추가/삭제 | O | O | X |
| 단지 상태 변경 | O | O | X |
| 공유 링크 생성 | O | X | X |
| 참여자 권한 변경 | O | X | X |
| 참여자 제거 | O | X | X |
| 단지 삭제 | O | X | X |

### 6.3 딥링크 구조

Firebase Dynamic Links가 2025-08-25 서비스 종료되었으므로, **App Links (Android) + Universal Links (iOS)** 방식으로 직접 구현한다. `app_links` 패키지를 활용한다.

**딥링크 URL 구조:**

```
# 공유 초대
https://imjang.app/invite/{complexId}?token={inviteToken}

# 앱 스킴 (대안)
imjang://invite/{complexId}?token={inviteToken}
```

**go_router 설정:**
```
GoRoute(
  path: '/invite/:complexId',
  redirect: (context, state) {
    // 미로그인 시 로그인 화면으로 + 리다이렉트 URL 저장
    // 로그인 후 자동으로 초대 수락 처리
  },
)
```

**구현 요구사항:**
- Android: `AndroidManifest.xml`에 `<intent-filter>` 추가 + `.well-known/assetlinks.json` 호스팅
- iOS: `Associated Domains` 설정 + `.well-known/apple-app-site-association` 호스팅
- 호스팅: Firebase Hosting으로 `.well-known` 파일 배포

### 6.4 실시간 동기화 설계

**Firestore 실시간 리스너 배치:**

| 데이터 | 리스너 위치 | 조건 |
|--------|-------------|------|
| 단지 목록 | SCR-HOME | `sharedWith array-contains uid` |
| 단지 상세 | SCR-COMPLEX-DETAIL | 해당 `complexId` 문서 |
| 임장 기록 목록 | SCR-COMPLEX-DETAIL (임장 탭) | `inspections` 서브컬렉션 |
| 공유 참여자 | SCR-SHARE-SETTINGS | `shares` 서브컬렉션 |
| 활동 로그 | SCR-ACTIVITY-LOG | `activityLogs` 서브컬렉션 (최근 50건) |

**충돌 해결 전략 (MVP):**
- **Last Write Wins (LWW):** 동일 필드 동시 수정 시 나중 쓰기가 남음
- **필드 레벨 병합:** `Firestore.update()`는 전달한 필드만 덮어쓰므로, 서로 다른 필드 수정 시 양쪽 반영
- `updatedAt` 필드를 서버 타임스탬프(`FieldValue.serverTimestamp()`)로 항상 기록
- V2에서 충돌 감지 UI 검토 (수정 전 버전 비교)

---

## 7. Decision Records

### DR-SPEC-01: 폴더 구조 결정

| 항목 | 내용 |
|------|------|
| **결정 사항** | Feature-first + 내부 Layer 분리 (하이브리드) |
| **대안 A** | **Feature-first + 내부 Layer 분리** — `lib/features/{feature}/data|domain|presentation/`. 기능별 독립성 유지 + 내부는 Clean Architecture 레이어 |
| **대안 B** | **순수 Layer-first** — `lib/data/`, `lib/domain/`, `lib/presentation/` 최상위 분리. 레이어 간 경계 명확하나 기능별 파일이 분산 |
| **대안 C** | **순수 Feature-first (레이어 없음)** — `lib/features/{feature}/` 안에 레이어 구분 없이 모든 파일. 단순하나 규모 커지면 혼란 |
| **채택 사유** | Feature-first가 2025 Flutter 커뮤니티의 표준 권장 방식 (Andrea Bizzotto, Flutter 공식 가이드). 기능별 독립 모듈화로 병렬 개발 가능. 내부 레이어 분리로 테스트 용이성 유지. 기능 삭제 시 폴더 하나만 제거하면 됨 |
| **기각 사유** | 대안 B: 서로 다른 기능의 파일이 같은 폴더에 섞여 탐색 어려움. 기능 삭제 시 여러 폴더에서 파일 찾아야 함. 대안 C: MVP 이후 규모 성장 시 가독성 저하. Domain/Data 분리 없으면 테스트 작성 어려움 |
| **제약/한계** | feature 간 공유 코드는 `core/` 또는 `shared/`에 배치 필요. feature 간 의존성 방향 관리 필요 (순환 의존 주의) |

> 검증 근거: [Flutter Project Structure: Feature-first or Layer-first? (codewithandrea.com)](https://codewithandrea.com/articles/flutter-project-structure/), [Best Practices for Folder Structure 2025 (pravux.com)](https://www.pravux.com/best-practices-for-folder-structure-in-large-flutter-projects-2025-guide/)

### DR-SPEC-02: 로컬 DB 선택

| 항목 | 내용 |
|------|------|
| **결정 사항** | drift (SQLite ORM) 채택 |
| **대안 A** | **drift** — SQLite 기반 ORM. 타입 안전 쿼리, 코드 생성, 마이그레이션 지원. 관계형 데이터(법정동코드 계층 구조)에 최적 |
| **대안 B** | **sqflite** — 순수 SQLite 래퍼. Raw SQL 작성 필요. 보일러플레이트 많음 |
| **대안 C** | **hive** — NoSQL 키-값 저장소. 빠른 성능. 그러나 관계형 쿼리 불가 |
| **채택 사유** | 법정동코드가 시/도 > 시/군/구 > 읍/면/동 계층 구조이므로 관계형 쿼리(WHERE parent_code = ?)가 필수. drift는 Dart 코드로 타입 안전하게 쿼리 작성 가능. build_runner 코드 생성으로 보일러플레이트 최소화. 마이그레이션 내장 |
| **기각 사유** | 대안 B: Raw SQL 작성 부담, 타입 안전성 없음, 마이그레이션 수동 관리. 대안 C: 계층 구조 검색(WHERE 조건 필터)에 부적합. 법정동코드는 명확한 관계형 데이터 |
| **제약/한계** | build_runner 의존 (Riverpod과 공유하므로 추가 부담 없음). 러닝 커브 존재하나 문서 풍부 |

> 검증 근거: [drift pub.dev](https://pub.dev/packages/drift) (최신 버전 2.x 안정), [Flutter databases comparison 2025 (greenrobot.org)](https://greenrobot.org/database/flutter-databases-overview/), [Best Local Database Guide (dinkomarinac.dev)](https://dinkomarinac.dev/best-local-database-for-flutter-apps-a-complete-guide)

### DR-SPEC-03: 사진 캐싱 전략

| 항목 | 내용 |
|------|------|
| **결정 사항** | cached_network_image 패키지 사용 |
| **대안 A** | **cached_network_image** — 네트워크 이미지 자동 디스크 캐싱. placeholder/error 위젯 내장. Flutter 생태계 표준 |
| **대안 B** | **수동 캐싱** — dio로 다운로드 + path_provider로 로컬 저장 + Image.file()로 표시. 완전 제어 가능하나 구현 복잡 |
| **대안 C** | **Firebase Storage 캐시 의존** — Firebase SDK 내장 캐시 사용. 제어 불가, 캐시 정책 커스터마이즈 어려움 |
| **채택 사유** | 대안 A: flutter_cache_manager 기반으로 자동 디스크 캐싱 + 메모리 캐싱. placeholder(로딩), errorWidget(에러) 내장. 인터넷 끊김 시 캐시된 이미지 표시. 가장 널리 사용되는 이미지 캐싱 솔루션 (pub.dev likes 10,000+) |
| **기각 사유** | 대안 B: 상당한 구현 노력 대비 cached_network_image와 동일 결과. 캐시 무효화/LRU 정책 직접 구현 필요. 대안 C: 캐시 크기/기간 제어 불가. 오프라인 보장 불확실 |
| **제약/한계** | 오프라인에서 새 이미지는 표시 불가 (이전 캐시된 것만 가능). 캐시 크기 기본 제한 없으므로 `MaxNrOfCacheObjects`로 제한 설정 필요 |

> 검증 근거: [cached_network_image pub.dev](https://pub.dev/packages/cached_network_image) (최신 3.3.x, 2025-11 업데이트)

### DR-SPEC-04: 딥링크 구현 방식

| 항목 | 내용 |
|------|------|
| **결정 사항** | App Links / Universal Links + `app_links` 패키지 |
| **대안 A** | **App Links (Android) + Universal Links (iOS)** — OS 네이티브 딥링크. `app_links` 패키지로 Flutter 통합. 무료. 자체 도메인 필요 |
| **대안 B** | **Firebase Dynamic Links** — 2025-08-25 서비스 종료. 사용 불가 |
| **대안 C** | **Branch.io** — 서드파티 딥링크 서비스. 무료 티어 존재. 디퍼드 딥링크 지원. 벤더 종속 |
| **채택 사유** | 대안 A: Firebase Dynamic Links 종료로 네이티브 딥링크가 유일한 무료 옵션. `app_links` 패키지로 Android/iOS 모두 지원. Firebase Hosting으로 `.well-known` 파일 무료 호스팅 가능. 벤더 종속 없음 |
| **기각 사유** | 대안 B: 서비스 종료 (2025-08-25). 대안 C: 벤더 종속 + MVP 단계에서 불필요한 외부 의존성 |
| **제약/한계** | 디퍼드 딥링크(앱 미설치 -> 스토어 -> 설치 -> 원래 URL 처리)는 네이티브 App Links만으로는 불완전. MVP에서는 "앱 미설치 시 스토어 이동"까지만 지원. 디퍼드 딥링크는 V2에서 검토 |

> 검증 근거: [Firebase Dynamic Links Deprecation FAQ](https://firebase.google.com/support/dynamic-links-faq), [Firebase Dynamic Links Deprecated: Guide to Alternatives (leancode.co)](https://leancode.co/blog/firebase-dynamic-links-deprecated), [app_links pub.dev](https://pub.dev/packages/app_links)

### DR-SPEC-05: 공공데이터 XML 파싱 방식

| 항목 | 내용 |
|------|------|
| **결정 사항** | `xml` 패키지로 직접 파싱 (xml2json 미사용) |
| **대안 A** | **xml 패키지 직접 파싱** — Dart 공식 XML 라이브러리. DOM 파싱 + XPath 지원. XML -> Dart Model 직접 변환 |
| **대안 B** | **xml2json 패키지** — XML -> JSON 자동 변환 후 JSON 파싱. 변환 오버헤드 존재 |
| **대안 C** | **서버 사이드 변환** — Cloud Functions에서 XML -> JSON 변환 후 앱에 JSON 제공. 추가 인프라 필요 |
| **채택 사유** | 대안 A: 불필요한 XML->JSON 변환 단계 제거로 성능 우위. 공공API 응답 구조가 고정적이므로 직접 파싱이 명확. `xml` 패키지의 XPath로 필요 노드만 정확히 추출 가능 |
| **기각 사유** | 대안 B: JSON 변환 시 데이터 구조 변형으로 디버깅 어려움. 불필요한 메모리 할당. 대안 C: Cloud Functions 비용 + 설정 복잡도. MVP 과잉 |
| **제약/한계** | 공공API 응답 포맷 변경 시 파싱 코드 수정 필요. 유닛 테스트로 포맷 검증 필수 |

> 검증 근거: [xml pub.dev](https://pub.dev/packages/xml) (Dart 공식 라이브러리, 활발한 유지보수)

---

## 부록: 패키지 의존성 목록 (pubspec.yaml 참조)

| 패키지 | 버전 (권장) | 용도 |
|--------|-------------|------|
| `flutter_riverpod` | ^3.3.0 | 상태 관리 |
| `riverpod_annotation` | ^3.x | @riverpod 코드 생성 |
| `riverpod_generator` | ^3.x | 코드 생성기 (dev) |
| `go_router` | ^14.x | 라우팅 + 딥링크 |
| `firebase_core` | 최신 | Firebase 코어 |
| `firebase_auth` | 최신 | 인증 |
| `cloud_firestore` | 최신 | Firestore |
| `firebase_storage` | 최신 | 파일 저장 |
| `kakao_map_plugin` | 최신 | 카카오 지도 |
| `dio` | ^5.x | HTTP 클라이언트 |
| `xml` | ^6.x | XML 파싱 |
| `drift` | ^2.x | 로컬 SQLite ORM |
| `drift_flutter` | ^0.3.x | drift Flutter 통합 |
| `image_picker` | ^1.x | 사진 선택/촬영 |
| `flutter_image_compress` | ^2.x | 사진 압축 |
| `cached_network_image` | ^3.3.x | 이미지 캐싱 |
| `connectivity_plus` | ^6.x | 네트워크 상태 감지 |
| `app_links` | ^6.x | 딥링크 처리 |
| `share_plus` | ^9.x | OS 공유 시트 |
| `geolocator` | ^12.x | GPS 위치 |
| `freezed_annotation` | ^2.x | 불변 데이터 클래스 |
| `freezed` | ^2.x | 코드 생성기 (dev) |
| `json_annotation` | ^4.x | JSON 직렬화 |
| `json_serializable` | ^6.x | 코드 생성기 (dev) |
| `build_runner` | ^2.x | 코드 생성 실행기 (dev) |
| `uuid` | ^4.x | UUID 생성 (초대 토큰) |
| `intl` | ^0.19.x | 날짜/숫자 포맷 |
| `path_provider` | ^2.x | 파일 시스템 경로 |
| `google_sign_in` | ^6.x | Google 로그인 |
| `sign_in_with_apple` | ^6.x | Apple 로그인 |

---

## 검증 출처

- [Riverpod 3 공식 문서](https://riverpod.dev/)
- [flutter_riverpod pub.dev](https://pub.dev/packages/flutter_riverpod) — 최신 3.3.x
- [kakao_map_plugin pub.dev](https://pub.dev/packages/kakao_map_plugin)
- [drift pub.dev](https://pub.dev/packages/drift) — 최신 2.x
- [cached_network_image pub.dev](https://pub.dev/packages/cached_network_image) — 최신 3.3.x
- [xml pub.dev](https://pub.dev/packages/xml) — 최신 6.x
- [app_links pub.dev](https://pub.dev/packages/app_links)
- [Firebase Dynamic Links Deprecation FAQ](https://firebase.google.com/support/dynamic-links-faq) — 2025-08-25 종료 확인
- [Flutter Project Structure (codewithandrea.com)](https://codewithandrea.com/articles/flutter-project-structure/)
- [Flutter databases overview 2025 (greenrobot.org)](https://greenrobot.org/database/flutter-databases-overview/)
- [Firestore Security Rules 가이드](https://firebase.google.com/docs/firestore/security/get-started)
- Ideator AI 산출물: `artifacts/IMJANG-MVP/00_idea/codebase_analysis.md`
- Planner AI 산출물: `artifacts/IMJANG-MVP/00_idea/plan.md`
