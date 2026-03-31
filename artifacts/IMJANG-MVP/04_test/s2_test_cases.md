# IMJANG-MVP Sprint 2 테스트 케이스

> 작성일: 2026-03-31
> 범위: S2 (CORE-05, CORE-06, AUTH-03, AUTH-04, API-01, API-02)
> 방식: TDD — 빈 구현에 대해 FAIL하도록 설계

---

## 1. 인수조건 ↔ 테스트 1:1 매핑 테이블

### FR-AUTH-03 (Google 소셜 로그인)

| # | 인수조건 | 테스트 ID | 테스트 파일 | 레이어 |
|---|---------|-----------|------------|--------|
| 1 | Google 로그인 버튼 탭 시 Google 인증 화면 표시 | TC-SOCIAL-UI-001 | login_screen_social_test.dart | Widget |
| 2 | Google 인증 완료 시 홈 화면 이동 | TC-SOCIAL-001 | social_auth_test.dart | Unit |
| 3 | 최초 Google 로그인 시 Firestore users 컬렉션에 사용자 문서 생성 | TC-SOCIAL-002 | social_auth_test.dart | Unit |
| 4 | 재로그인 시 Firestore 문서 중복 생성 안 함 | TC-SOCIAL-003 | social_auth_test.dart | Unit |
| 5 | 사용자가 Google 인증 취소 → SocialAuthCancelledException | TC-SOCIAL-004 | social_auth_test.dart | Unit |
| 6 | Google 인증 중 FirebaseAuthException → AuthAppException | TC-SOCIAL-005 | social_auth_test.dart | Unit |

### FR-AUTH-04 (Apple 소셜 로그인 iOS)

| # | 인수조건 | 테스트 ID | 테스트 파일 | 레이어 |
|---|---------|-----------|------------|--------|
| 7 | iOS에서 Apple 로그인 버튼 표시 | TC-SOCIAL-UI-002 | login_screen_social_test.dart | Widget |
| 8 | Android에서 Apple 로그인 버튼 비표시 | TC-SOCIAL-UI-003 | login_screen_social_test.dart | Widget |
| 9 | Apple 인증 완료 시 홈 화면 이동 | TC-SOCIAL-007 | social_auth_test.dart | Unit |
| 10 | 최초 Apple 로그인 시 Firestore users 문서 생성 | TC-SOCIAL-008 | social_auth_test.dart | Unit |
| 11 | Apple 인증 취소 → SocialAuthCancelledException | TC-SOCIAL-009 | social_auth_test.dart | Unit |
| 12 | Firestore 문서에 createdAt/lastLoginAt 포함 | TC-SOCIAL-010 | social_auth_test.dart | Unit |

### FR-API-05 (법정동코드)

| # | 인수조건 | 테스트 ID | 테스트 파일 | 레이어 |
|---|---------|-----------|------------|--------|
| 13 | 법정동코드 로컬 캐시로 오프라인에서도 검색 가능 | TC-REGION-UI-010 | region_select_screen_test.dart | Widget |
| 14 | 시도 목록 조회 → level=1 RegionEntity 반환 | TC-REGION-001 | region_repository_test.dart | Unit |
| 15 | 시군구 목록 조회 → 특정 시도 하위 level=2 반환 | TC-REGION-004 | region_repository_test.dart | Unit |
| 16 | 읍면동 목록 조회 → 특정 시군구 하위 level=3 반환 | TC-REGION-007 | region_repository_test.dart | Unit |
| 17 | 시도 → 시군구 → 읍면동 계층 UI 선택 흐름 | TC-REGION-UI-003~008 | region_select_screen_test.dart | Widget |

---

## 2. 테스트 케이스 상세

### 2.1 Unit Tests — XML 파서 (xml_parser_test.dart)

**대상:** `lib/core/utils/xml_parser.dart`

| 테스트 ID | 입력 | 기대 결과 |
|-----------|------|---------|
| TC-XML-001 | 단건 item XML | List 1개, 필드값 정확 |
| TC-XML-002 | 복수 item XML | List n개, 순서 유지 |
| TC-XML-003 | `<items/>` 빈 XML | 빈 List |
| TC-XML-004 | resultCode="03" 에러 응답 | 빈 List |
| TC-XML-005 | 잘못된 XML 형식 | XmlParseException throw |
| TC-XML-006 | 빈 문자열 | XmlParseException throw |
| TC-XML-007 | 앞뒤 공백 포함 금액 (" 85,000") | trim 처리 → "85,000" |
| TC-XML-008 | resultCode="00" | isSuccessResponse=true |
| TC-XML-009 | resultCode="03" | isSuccessResponse=false |

### 2.2 Unit Tests — Dio HTTP 클라이언트 (dio_client_test.dart)

**대상:** `lib/core/network/dio_client.dart`

| 테스트 ID | 시나리오 | 기대 결과 |
|-----------|---------|---------|
| TC-DIO-001 | HTTP 200 정상 응답 | XML 문자열 반환 |
| TC-DIO-002 | 1회 실패 후 재시도 성공 | 응답 반환, 총 2회 호출 |
| TC-DIO-003 | 3회 모두 실패 | NetworkException throw |
| TC-DIO-004 | 재시도 딜레이 검증 | [1s, 2s, 4s] 지수 백오프 |
| TC-DIO-005 | HTTP 401 | UnauthorizedException throw |
| TC-DIO-006 | HTTP 429 | RateLimitException throw |
| TC-DIO-007 | HTTP 500 | ServerAppException throw |
| TC-DIO-008 | 연결 타임아웃 | NetworkException throw |
| TC-DIO-009 | 수신 타임아웃 | NetworkException throw |
| TC-DIO-010 | queryParameters 전달 | Dio.get에 파라미터 포함 |

### 2.3 Unit Tests — 네트워크 프로바이더 (network_provider_test.dart)

**대상:** `lib/core/providers/network_provider.dart`

| 테스트 ID | 시나리오 | 기대 결과 |
|-----------|---------|---------|
| TC-NET-001 | WiFi 연결 | networkStatusProvider → true |
| TC-NET-002 | 모바일 연결 | networkStatusProvider → true |
| TC-NET-003 | 연결 없음 | networkStatusProvider → false |
| TC-NET-004 | 온라인 → 오프라인 | [true, false] 순서 emit |
| TC-NET-005 | 오프라인 → 온라인 | [false, true] 순서 emit |
| TC-NET-006 | 오프라인 상태 | isOfflineProvider → true |
| TC-NET-007 | 온라인 상태 | isOfflineProvider → false |

### 2.4 Unit Tests — 소셜 인증 (social_auth_test.dart)

**대상:** `lib/features/auth/data/repositories/social_auth_repository_impl.dart`

| 테스트 ID | 시나리오 | 기대 결과 |
|-----------|---------|---------|
| TC-SOCIAL-001 | Google 로그인 성공 | UserEntity(authProvider="google") |
| TC-SOCIAL-002 | 최초 Google 로그인 | Firestore.set 호출 (users 문서 생성) |
| TC-SOCIAL-003 | 재로그인 (기존 사용자) | Firestore.set 미호출 |
| TC-SOCIAL-004 | Google 인증 취소 | SocialAuthCancelledException throw |
| TC-SOCIAL-005 | FirebaseAuthException | AuthAppException throw |
| TC-SOCIAL-006 | Google 로그인 결과 | photoUrl 포함 |
| TC-SOCIAL-007 | Apple 로그인 성공 | UserEntity(authProvider="apple") |
| TC-SOCIAL-008 | 최초 Apple 로그인 | Firestore.set 호출 |
| TC-SOCIAL-009 | Apple 인증 취소 | SocialAuthCancelledException throw |
| TC-SOCIAL-010 | Firestore 문서 | createdAt/lastLoginAt 포함 |
| TC-SOCIAL-011 | 소셜 로그아웃 | GoogleSignIn.signOut + FirebaseAuth.signOut 호출 |

### 2.5 Unit Tests — 법정동코드 Repository (region_repository_test.dart)

**대상:** `lib/features/region/data/repositories/region_repository_impl.dart`

| 테스트 ID | 시나리오 | 기대 결과 |
|-----------|---------|---------|
| TC-REGION-001 | 시도 목록 조회 | level=1 RegionEntity 리스트 |
| TC-REGION-002 | 시도 목록 항목 | sidoName 존재, sigunguName/dongName null |
| TC-REGION-003 | DB 오류 | RegionException throw |
| TC-REGION-004 | 시군구 목록 조회 | level=2, sidoName 일치 항목만 |
| TC-REGION-005 | 시군구 목록 항목 | sigunguName 존재 |
| TC-REGION-006 | 존재하지 않는 sidoCode | 빈 리스트 |
| TC-REGION-007 | 읍면동 목록 조회 | level=3, sigunguName 일치 항목만 |
| TC-REGION-008 | 읍면동 목록 항목 | dongName 존재 |
| TC-REGION-009 | "강남" 이름 검색 | 강남 포함 항목 반환 |
| TC-REGION-010 | 빈 쿼리 검색 | 빈 리스트, DataSource 미호출 |
| TC-REGION-011 | 1글자 쿼리 | 빈 리스트 (최소 2글자 정책) |
| TC-REGION-012 | 일치 없는 검색 | 빈 리스트 |
| TC-REGION-013 | 10자리 코드 조회 | RegionEntity 반환 |
| TC-REGION-014 | 존재하지 않는 코드 | null 반환 |
| TC-REGION-015 | 잘못된 코드 형식 | InvalidRegionCodeException throw |

### 2.6 Widget Tests — 지역 선택 화면 (region_select_screen_test.dart)

**대상:** `lib/features/region/presentation/screens/region_select_screen.dart`

| 테스트 ID | 시나리오 | 기대 UI |
|-----------|---------|--------|
| TC-REGION-UI-001 | 초기 렌더링 | 시도 목록 표시 |
| TC-REGION-UI-002 | 초기 상태 | 시군구/읍면동 숨겨짐 |
| TC-REGION-UI-003 | 시도 탭 | selectSido 호출 |
| TC-REGION-UI-004 | 시도 선택 후 | 해당 시군구 목록 표시 |
| TC-REGION-UI-005 | 시군구 탭 | selectSigungu 호출 |
| TC-REGION-UI-006 | 시군구 선택 후 | 읍면동 목록 표시 |
| TC-REGION-UI-007 | 읍면동 탭 | selectDong 호출 |
| TC-REGION-UI-008 | 읍면동 선택 완료 | 확인 버튼 표시 |
| TC-REGION-UI-009 | 로딩 중 | CircularProgressIndicator 표시 |
| TC-REGION-UI-010 | 오프라인 | 로컬 캐시로 시도 목록 표시 |
| TC-REGION-UI-011 | 시도 선택 후 | 선택된 시도명 브레드크럼 표시 |
| TC-REGION-UI-012 | 다른 시도 선택 | selectSido 호출 (초기화 트리거) |

### 2.7 Widget Tests — 공통 UI 컴포넌트 (common_widgets_test.dart)

**대상:** `lib/shared/widgets/`

#### ImjangAppBar
| TC ID | 시나리오 | 기대 결과 |
|-------|---------|---------|
| TC-UI-COMMON-001 | title 전달 | AppBar에 텍스트 표시 |
| TC-UI-COMMON-002 | showBackButton=false | 뒤로가기 버튼 없음 |
| TC-UI-COMMON-003 | showBackButton=true | 뒤로가기 버튼 표시 |
| TC-UI-COMMON-004 | actions 전달 | 우측에 위젯 표시 |

#### ImjangButton
| TC ID | 시나리오 | 기대 결과 |
|-------|---------|---------|
| TC-UI-COMMON-005 | label 전달 | 텍스트 표시 |
| TC-UI-COMMON-006 | 탭 | onPressed 호출 |
| TC-UI-COMMON-007 | isLoading=true | 로딩 인디케이터, 텍스트 숨김 |
| TC-UI-COMMON-008 | isEnabled=false | 버튼 비활성화 |
| TC-UI-COMMON-009 | variant=secondary | OutlinedButton 스타일 |

#### ImjangTextField
| TC ID | 시나리오 | 기대 결과 |
|-------|---------|---------|
| TC-UI-COMMON-010 | labelText 전달 | 레이블 표시 |
| TC-UI-COMMON-011 | 텍스트 입력 | controller에 반영 |
| TC-UI-COMMON-012 | errorText 전달 | 에러 메시지 표시 |

#### LoadingWidget/AppErrorWidget/EmptyStateWidget
| TC ID | 시나리오 | 기대 결과 |
|-------|---------|---------|
| TC-UI-COMMON-013 | 기본 로딩 | CircularProgressIndicator |
| TC-UI-COMMON-014 | 로딩 + 메시지 | 인디케이터 + 텍스트 |
| TC-UI-COMMON-015 | 에러 메시지 | 에러 텍스트 표시 |
| TC-UI-COMMON-016 | onRetry 있음 | "다시 시도" 버튼 + 콜백 |
| TC-UI-COMMON-017 | onRetry 없음 | "다시 시도" 버튼 없음 |
| TC-UI-COMMON-018 | 빈 상태 + 아이콘 | 메시지 + 아이콘 표시 |
| TC-UI-COMMON-019 | 빈 상태 + 액션 | 액션 버튼 + 콜백 |

#### RatingBarWidget
| TC ID | 시나리오 | 기대 결과 |
|-------|---------|---------|
| TC-UI-COMMON-020 | rating=3.0 | 채워진 별 3개, 빈 별 2개 |
| TC-UI-COMMON-021 | interactive=true + 탭 | onRatingChanged 콜백 호출 |

#### OfflineBannerWidget (CORE-06)
| TC ID | 시나리오 | 기대 결과 |
|-------|---------|---------|
| TC-UI-COMMON-022 | 오프라인 상태 | 배너 표시, "오프라인 상태입니다" |
| TC-UI-COMMON-023 | 온라인 상태 | 배너 숨김 |
| TC-UI-COMMON-024 | 오프라인 배너 | error 컬러 decoration |
| TC-UI-COMMON-025 | 온라인 전환 | 배너 자동 사라짐 |

---

## 3. 새로 추가된 예외 타입 (S2)

S2 구현 시 `lib/core/error/exceptions.dart`에 추가 필요:

```dart
// 네트워크
class NetworkException extends AppException { ... }
class UnauthorizedException extends AppException { ... }
class RateLimitException extends AppException { ... }
class ServerAppException extends AppException { ... }

// 소셜 인증
class SocialAuthCancelledException extends AppException { ... }

// XML 파싱
class XmlParseException extends AppException { ... }

// 지역 코드
class RegionException extends AppException { ... }
class InvalidRegionCodeException extends RegionException { ... }
```

---

## 4. 새로 추가된 Provider (S2)

`lib/core/providers/network_provider.dart`에 구현 필요:

```dart
// connectivity_plus 인스턴스 Provider (목 주입 가능)
final connectivityProvider = Provider<Connectivity>(...);

// 네트워크 연결 상태 스트림 (true=온라인, false=오프라인)
@riverpod
Stream<bool> networkStatus(NetworkStatusRef ref);

// 오프라인 여부 (networkStatus의 반전)
@riverpod
Stream<bool> isOffline(IsOfflineRef ref);
```

---

## 5. 테스트 실행 방법

```bash
# 전체 테스트 실행
flutter test

# S2 테스트만
flutter test test/core/utils/xml_parser_test.dart
flutter test test/core/network/dio_client_test.dart
flutter test test/core/providers/network_provider_test.dart
flutter test test/features/auth/data/repositories/social_auth_test.dart
flutter test test/features/region/
flutter test test/shared/widgets/common_widgets_test.dart

# Mock 코드 재생성
dart run build_runner build --delete-conflicting-outputs

# 커버리지 포함
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 6. 테스트 파일 ↔ 구현 파일 매핑

| 테스트 파일 | 구현 대상 파일 (S2 생성 예정) |
|------------|--------------------------|
| `test/core/utils/xml_parser_test.dart` | `lib/core/utils/xml_parser.dart` |
| `test/core/network/dio_client_test.dart` | `lib/core/network/dio_client.dart` |
| `test/core/providers/network_provider_test.dart` | `lib/core/providers/network_provider.dart` |
| `test/features/auth/data/repositories/social_auth_test.dart` | `lib/features/auth/data/repositories/social_auth_repository_impl.dart` |
| `test/features/region/data/repositories/region_repository_test.dart` | `lib/features/region/data/repositories/region_repository_impl.dart` |
| `test/features/region/presentation/screens/region_select_screen_test.dart` | `lib/features/region/presentation/screens/region_select_screen.dart` |
| `test/shared/widgets/common_widgets_test.dart` | `lib/shared/widgets/{imjang_app_bar, imjang_button, imjang_text_field, empty_state_widget, toast_widget, rating_bar_widget, offline_banner_widget}.dart` |
