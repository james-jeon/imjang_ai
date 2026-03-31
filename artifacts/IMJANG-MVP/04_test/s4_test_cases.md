# S4 테스트 케이스 명세

> Sprint 4 (COMP-02~06) 인수 조건 기반 테스트 설계
> 작성일: 2026-03-31
> 상태: 테스트 파일 작성 완료 (S4 구현 전 TDD 방식)

---

## 파일 구조

```
test/features/complex/
├── data/repositories/
│   ├── complex_repository_test.dart          # TC-COMP-REPO-001~015
│   └── complex_repository_test.mocks.dart
├── presentation/
│   ├── providers/
│   │   └── complex_list_provider_test.dart   # TC-COMP-PROV-001~020 ✅ 통과
│   └── screens/
│       ├── home_screen_test.dart             # TC-COMP-HOME-001~012
│       ├── home_screen_test.mocks.dart
│       ├── complex_search_screen_test.dart   # TC-COMP-SEARCH-001~012
│       ├── complex_search_screen_test.mocks.dart
│       ├── complex_detail_screen_test.dart   # TC-COMP-DETAIL-001~019
│       └── complex_detail_screen_test.mocks.dart
```

> **실행 현황**: `complex_list_provider_test.dart` 20개 테스트 전부 통과 (`flutter test`).
> 나머지 파일은 S4 구현 완료 후 build_runner 실행 + 실제 화면 클래스 import 교체 필요.

---

## TC-COMP-REPO: 단지 Repository 유닛 테스트 (COMP-02)

| TC ID | 테스트명 | 대상 메서드 | 시나리오 | 기대 결과 |
|-------|---------|-----------|---------|---------|
| TC-COMP-REPO-001 | 단지 등록 성공 | `createComplex` | 신규 ComplexEntity 등록 | Firestore `set` 호출 + ComplexEntity 반환 |
| TC-COMP-REPO-002 | sharedWith ownerId 포함 | `createComplex` | ownerId = 'user-001' | `sharedWith`에 ownerId 반드시 포함 |
| TC-COMP-REPO-003 | Firestore 오류 전파 | `createComplex` | permission-denied | FirebaseException throw |
| TC-COMP-REPO-004 | 내 단지 목록 쿼리 | `getMyComplexes` | userId = 'user-001' | `where(sharedWith, arrayContains: userId)` 호출 |
| TC-COMP-REPO-005 | 단지 2개 반환 | `getMyComplexes` | 결과 2건 | List<ComplexEntity> 길이 2 |
| TC-COMP-REPO-006 | 단지 상세 조회 성공 | `getComplexById` | 존재하는 ID | ComplexEntity 반환, snapshot.exists = true |
| TC-COMP-REPO-007 | 단지 상세 조회 없음 | `getComplexById` | 존재하지 않는 ID | null 반환, snapshot.exists = false |
| TC-COMP-REPO-008 | 상태 변경 | `updateComplexStatus` | visited로 변경 | `update({status: 'visited', statusChangedAt: ...})` 호출 |
| TC-COMP-REPO-009 | 잘못된 ID 상태 변경 | `updateComplexStatus` | not-found | FirebaseException throw |
| TC-COMP-REPO-010 | Owner 단지 삭제 | `deleteComplex` | ownerId == requesterId | Firestore `delete()` 호출 |
| TC-COMP-REPO-011 | 비Owner 삭제 시도 | `deleteComplex` | ownerId != requesterId | 권한 없음 예외 (계약 검증) |
| TC-COMP-REPO-012 | 중복 단지 존재 확인 | `findComplexByPublicApiCode` | apiCode 'A12345' 존재 | 쿼리 체인 올바름 |
| TC-COMP-REPO-013 | 중복 단지 없음 | `findComplexByPublicApiCode` | 새 apiCode | docs 빈 목록, null 반환 |
| TC-COMP-REPO-014 | 단지 정보 수정 | `updateComplex` | name 변경 | `update({name: '수정된 단지명', updatedAt: ...})` 호출 |
| TC-COMP-REPO-015 | ownerId 불변 | `updateComplex` | ownerId 변경 시도 | ownerId != 변경값 (불변성 계약) |

---

## TC-COMP-PROV: 필터/정렬 Provider 유닛 테스트 (COMP-04) ✅ 20/20 통과

### ComplexListFilter 값 객체

| TC ID | 테스트명 | 시나리오 | 기대 결과 |
|-------|---------|---------|---------|
| TC-COMP-PROV-001 | 기본 필터 isEmpty | 모든 필드 null | isEmpty = true |
| TC-COMP-PROV-002 | 상태 필터 isEmpty | statusFilter = visited | isEmpty = false |
| TC-COMP-PROV-003 | copyWith 변경 | statusFilter 변경 | 새 인스턴스 반환, 원본 불변 |
| TC-COMP-PROV-004 | clearStatus | clearStatus: true | statusFilter = null |

### 상태 필터

| TC ID | 테스트명 | 입력 | 기대 결과 |
|-------|---------|-----|---------|
| TC-COMP-PROV-005 | 전체 | statusFilter = null | 전체 6개 반환 |
| TC-COMP-PROV-006 | visited 필터 | statusFilter = visited | 임장완료 2개 반환 |
| TC-COMP-PROV-007 | excluded 필터 | statusFilter = excluded | 제외 1개 반환 |
| TC-COMP-PROV-008 | 빈 결과 | 조건 없는 빈 목록 | [] 반환 |

### 매매가 필터

| TC ID | 테스트명 | 입력 | 기대 결과 |
|-------|---------|-----|---------|
| TC-COMP-PROV-009 | minPrice | minPrice = 80000 | 10억, 15억 2개 |
| TC-COMP-PROV-010 | maxPrice | maxPrice = 60000 | 5억 1개 |
| TC-COMP-PROV-011 | 범위 필터 | min=90000, max=110000 | 10억 1개 |
| TC-COMP-PROV-012 | null 가격 제외 | minPrice = 1000 | null 가격 단지 제외됨 |

### 면적 필터 (평수 칩)

| TC ID | 테스트명 | 입력 | 기대 결과 |
|-------|---------|-----|---------|
| TC-COMP-PROV-013 | 단일 평수 칩 | areaFilters = [34] | 34평 단지 1개 |
| TC-COMP-PROV-014 | 복수 평수 칩 | areaFilters = [24, 59] | 2개 반환 |

### 정렬

| TC ID | 테스트명 | 입력 | 기대 결과 |
|-------|---------|-----|---------|
| TC-COMP-PROV-015 | 최근 등록순 | recentlyAdded | createdAt 내림차순 |
| TC-COMP-PROV-016 | 이름순 | nameAsc | 가나다 오름차순 |
| TC-COMP-PROV-017 | 매매가 낮은순 | priceLow | 가격 오름차순 |
| TC-COMP-PROV-018 | 최근 임장순 | recentlyInspected | lastInspectionAt 내림차순 |

### 복합 필터 + 정렬

| TC ID | 테스트명 | 시나리오 | 기대 결과 |
|-------|---------|---------|---------|
| TC-COMP-PROV-019 | visited + minPrice + 이름순 | 복합 조건 | visited & 9억 이상인 단지 1개, 이름순 |
| TC-COMP-PROV-020 | 준공연도 + 세대수 필터 | 2010~2015 & 500세대이상 | 조건 통과 단지 1개 |

---

## TC-COMP-HOME: 단지 목록 화면 위젯 테스트 (COMP-04 SCR-HOME)

| TC ID | 테스트명 | 시나리오 | 기대 결과 |
|-------|---------|---------|---------|
| TC-COMP-HOME-001 | 필수 UI 요소 | 화면 렌더링 | 필터 바, FAB, 하단탭 존재 |
| TC-COMP-HOME-002 | 상태 필터 칩 6개 | 화면 렌더링 | 전체/관심/임장예정/임장완료/재방문/제외 칩 6개 |
| TC-COMP-HOME-003 | 하단 탭 | 화면 렌더링 | 단지/지도/설정 탭 존재 |
| TC-COMP-HOME-004 | FAB 버튼 | 화면 렌더링 | `home_fab` 키 존재 |
| TC-COMP-HOME-005 | 카드 3개 | data(복수) | 카드 3개 렌더링 |
| TC-COMP-HOME-006 | 카드 단지명 | data(복수) | 단지명 텍스트 표시 |
| TC-COMP-HOME-007 | 카드 상태 배지 | data(복수) | interested='관심', visited='임장완료' |
| TC-COMP-HOME-008 | 빈 상태 EmptyState | data([]) | EmptyStateWidget 렌더링 |
| TC-COMP-HOME-009 | 빈 상태 메시지 | data([]) | "조건에 맞는 단지가 없습니다" |
| TC-COMP-HOME-010 | 초기화 버튼 | data([]) | "필터 초기화" 버튼 |
| TC-COMP-HOME-011 | 로딩 상태 | AsyncLoading | CircularProgressIndicator |
| TC-COMP-HOME-012 | 에러 상태 | AsyncError | 에러 메시지 표시 |

---

## TC-COMP-SEARCH: 단지 검색/등록 화면 위젯 테스트 (COMP-03 SCR-SEARCH)

| TC ID | 테스트명 | 시나리오 | 기대 결과 |
|-------|---------|---------|---------|
| TC-COMP-SEARCH-001 | 필수 UI 요소 | 화면 렌더링 | 검색 필드, 지역 선택, 뒤로가기 |
| TC-COMP-SEARCH-002 | 초기 상태 | 검색 전 | 결과 목록 없음 |
| TC-COMP-SEARCH-003 | 검색어 입력 | "래미안" 입력 | TextField에 반영 |
| TC-COMP-SEARCH-004 | 지우기 버튼 표시 | 텍스트 입력 후 | `search_clear_button` 표시 |
| TC-COMP-SEARCH-005 | 지우기 버튼 | 탭 | TextField 초기화 |
| TC-COMP-SEARCH-006 | 결과 2개 | searchResults 2개 | ListTile 2개 |
| TC-COMP-SEARCH-007 | 단지명/주소/세대수 | 결과 있음 | 3가지 정보 표시 |
| TC-COMP-SEARCH-008 | 로딩 상태 | isLoading = true | CircularProgressIndicator |
| TC-COMP-SEARCH-009 | 검색 오류 | error != null | 에러 메시지 |
| TC-COMP-SEARCH-010 | 등록됨 배지 | registeredApiCodes에 포함 | "등록됨" Chip 표시 |
| TC-COMP-SEARCH-011 | 등록됨 탭 불가 | registeredApiCodes에 포함 | `onTap == null` |
| TC-COMP-SEARCH-012 | 미등록 탭 가능 | registeredApiCodes 없음 | `onTap != null` |

---

## TC-COMP-DETAIL: 단지 상세 화면 위젯 테스트 (COMP-05, COMP-06 SCR-COMPLEX-DETAIL)

### AppBar + 상태 배지

| TC ID | 테스트명 | 시나리오 | 기대 결과 |
|-------|---------|---------|---------|
| TC-COMP-DETAIL-001 | AppBar 요소 | 화면 렌더링 | 단지명, 공유 버튼, 더보기 메뉴 |
| TC-COMP-DETAIL-002 | 상태 배지 interested | status=interested | '관심' 텍스트 |
| TC-COMP-DETAIL-003 | 상태 배지 visited | status=visited | '임장완료' 텍스트 |

### 탭 구조 (COMP-05)

| TC ID | 테스트명 | 시나리오 | 기대 결과 |
|-------|---------|---------|---------|
| TC-COMP-DETAIL-004 | 3개 탭 | 화면 렌더링 | 정보/실거래가/임장기록 탭 |
| TC-COMP-DETAIL-005 | 정보 탭 기본정보 | selectedTab=0 | 기본정보 카드 + 주소 |
| TC-COMP-DETAIL-006 | 정보 탭 상세정보 | selectedTab=0 | 세대수, 준공일, 시공사 |
| TC-COMP-DETAIL-007 | 실거래가 탭 목록 | selectedTab=1, prices=2개 | 거래 2건 표시 |
| TC-COMP-DETAIL-008 | 실거래가 탭 빈 상태 | selectedTab=1, prices=[] | "실거래가 정보가 없습니다" |
| TC-COMP-DETAIL-009 | 임장기록 탭 버튼 | selectedTab=2 | "임장 기록 작성" 버튼 |

### 상태 변경 (COMP-06)

| TC ID | 테스트명 | 시나리오 | 기대 결과 |
|-------|---------|---------|---------|
| TC-COMP-DETAIL-010 | 상태 배지 탭 → 바텀시트 | 배지 탭 | 상태 변경 바텀시트 표시 |
| TC-COMP-DETAIL-011 | 바텀시트 5개 옵션 | 바텀시트 열림 | 전체 ComplexStatus 5개 표시 |

### 단지 삭제 (FR-COMP-05)

| TC ID | 테스트명 | 시나리오 | 기대 결과 |
|-------|---------|---------|---------|
| TC-COMP-DETAIL-012 | 더보기 → 삭제 메뉴 | 메뉴 열기 | "단지 삭제" 옵션 |
| TC-COMP-DETAIL-013 | 삭제 선택 → 다이얼로그 | "단지 삭제" 탭 | AlertDialog 표시 |
| TC-COMP-DETAIL-014 | 경고 메시지 | 다이얼로그 표시 | "관련 임장 기록도 모두 삭제됩니다" |
| TC-COMP-DETAIL-015 | 취소/삭제 버튼 | 다이얼로그 표시 | 양쪽 버튼 존재 |
| TC-COMP-DETAIL-016 | 취소 → 다이얼로그 닫힘 | 취소 탭 | AlertDialog 사라짐 |

### 상태 처리

| TC ID | 테스트명 | 시나리오 | 기대 결과 |
|-------|---------|---------|---------|
| TC-COMP-DETAIL-017 | 로딩 상태 | AsyncLoading | CircularProgressIndicator |
| TC-COMP-DETAIL-018 | 에러 상태 | AsyncError | 에러 메시지 |
| TC-COMP-DETAIL-019 | 단지 없음 | data(null) | "단지를 찾을 수 없습니다" |

---

## 테스트 실행 방법

### 현재 실행 가능한 테스트 (빌드런너 불필요)

```bash
# 필터/정렬 로직 (순수 Dart — 즉시 실행 가능)
flutter test test/features/complex/presentation/providers/complex_list_provider_test.dart
```

### S4 구현 완료 후 전체 실행

```bash
# 1. Mock 재생성 (S4 실제 클래스 import 후)
flutter pub run build_runner build --delete-conflicting-outputs

# 2. 전체 테스트
flutter test test/features/complex/

# 3. 커버리지 확인
flutter test --coverage test/features/complex/
```

---

## S4 구현 시 연동 가이드

### S4 dev가 생성해야 할 파일

| 파일 경로 | 테스트 연동 |
|---------|-----------|
| `lib/features/complex/domain/repositories/complex_repository.dart` | TC-COMP-REPO 전체 |
| `lib/features/complex/data/repositories/complex_repository_impl.dart` | TC-COMP-REPO 전체 |
| `lib/features/complex/presentation/screens/home_screen.dart` | TC-COMP-HOME 전체 |
| `lib/features/complex/presentation/providers/complex_list_provider.dart` | TC-COMP-PROV 전체 |
| `lib/features/complex/presentation/screens/complex_search_screen.dart` | TC-COMP-SEARCH 전체 |
| `lib/features/complex/presentation/screens/complex_detail_screen.dart` | TC-COMP-DETAIL 전체 |

### import 교체 포인트

테스트 파일 상단의 `// S4 구현 후 아래 import를 활성화한다:` 주석을 제거하고
실제 경로로 교체한 뒤 `@GenerateMocks` 대상 클래스를 실제 클래스로 변경한다.

### 필수 Key 목록 (UI 구현 시 반드시 지정)

**HomeScreen:**
- `home_status_filter_bar`, `home_fab`, `home_bottom_nav`
- `chip_all`, `chip_interested`, `chip_planned`, `chip_visited`, `chip_revisit`, `chip_excluded`
- `home_complex_list`, `complex_card_{complexId}`, `home_empty_state`

**ComplexSearchScreen:**
- `search_text_field`, `search_region_button`, `search_back_button`
- `search_clear_button`, `search_results_list`, `search_result_item_{complexCode}`
- `already_registered_badge`, `search_loading`, `search_error_text`, `search_empty_text`

**ComplexDetailScreen:**
- `detail_app_bar_title`, `detail_share_button`, `detail_more_menu`
- `detail_status_badge`, `detail_status_label_{statusName}`
- `tab_info`, `tab_price`, `tab_inspection`
- `info_tab_content`, `info_address`, `info_households`, `info_approval_date`, `info_constructor`
- `price_list`, `price_item_{index}`, `price_tab_empty`
- `inspection_tab_content`, `add_inspection_button`
- `menu_item_delete`, `delete_confirm_dialog`, `delete_warning_message`
- `delete_cancel_button`, `delete_confirm_button`
- `detail_loading`, `detail_error_text`, `detail_not_found`
- `status_option_{statusName}` (바텀시트 5개)
