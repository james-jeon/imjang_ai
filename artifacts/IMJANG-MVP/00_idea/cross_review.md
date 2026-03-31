# IMJANG-MVP 교차 리뷰 결과

> 리뷰어: Sonnet (교차 리뷰 Agent)
> 리뷰 대상: proposal.md + 관련 산출물 4개 (codebase_analysis.md, plan.md, spec.md, decision_record.md)
> 리뷰일: 2026-03-31

---

## 1. 근본 설계 방향 도전

### 판정: PARTIAL PASS (조건부)

현재 설계는 **Firebase BaaS + Flutter + Clean Architecture** 조합이다. 이 방향 자체는 MVP로서 합리적이나, 아래와 같은 근본적 대안과 장기 한계점을 명시한다.

### 대안 아키텍처 A: Supabase + Flutter (레이어드 아키텍처)

| 항목 | Firebase 현재 | Supabase 대안 |
|------|--------------|---------------|
| 실시간 동기화 | Firestore 실시간 리스너 (성숙) | PostgreSQL logical replication via WebSocket (성숙, 약간 떨어짐) |
| 오프라인 지원 | Firestore 기본 내장 | PowerSync 서드파티 필요 (추가 복잡도) |
| 쿼리 유연성 | NoSQL, JOIN 없음, 복합 쿼리 제한 | SQL 완전 지원, 복잡한 관계형 쿼리 가능 |
| 비용 예측 가능성 | 사용량 기반, 스케일 시 급증 | 인스턴스 기반, 예측 가능 |
| 벤더 종속 | Google 종속 | 오픈소스, 자체 호스팅 가능 |
| Firebase Auth 통합 | 완벽 통합 | Supabase Auth로 대체 가능 |

**평가**: MVP 빠른 출시 + 오프라인 지원 + 실시간 동기화 3가지 요건이 동시에 필요한 이 프로젝트에서는 Firebase가 여전히 우위. Supabase의 오프라인 지원이 Firebase 대비 성숙하지 않아 현재 기각 타당. **단, V2 이후 데이터 복잡도 증가 시 Supabase/PostgreSQL 마이그레이션을 정기적으로 재검토해야 한다.**

### 대안 아키텍처 B: Flutter (간소화 아키텍처) + Firebase

현재 채택한 3계층 Clean Architecture 대신 **MVVM Lite** 또는 **Feature-first 단순 Riverpod** 패턴을 사용하는 대안:

```
lib/
├── features/{feature}/
│   ├── {feature}_screen.dart      # Widget + UI
│   ├── {feature}_controller.dart  # Riverpod Notifier (데이터 + 로직 통합)
│   └── {feature}_repository.dart  # Firestore 직접 접근
└── core/
    ├── firebase.dart
    └── router.dart
```

- Domain Layer Entity / UseCase / Repository 인터페이스 삼중 구조 제거
- 1인 개발자 기준 파일 수 약 40% 감소 (추정 ~180개 -> ~110개)
- 초기 셋업 시간 단축, 기능 개발 속도 향상
- 단점: 테스트 분리 어려움, 추후 팀 확장 시 리팩토링 필요

**평가**: 현재 설계는 1인 MVP에 과잉이라는 합리적 비판이 존재한다 (섹션 4에서 상세 분석). 이 대안은 실질적으로 고려 가능하다.

### 현재 설계의 장기적 한계점

1. **Firebase 벤더 종속 누적**: Auth + Firestore + Storage + Hosting 전부 Firebase에 의존. V2에서 Cloud Functions까지 추가되면 탈출 비용이 극도로 높아진다. DR-03에서 언급되었으나, 마이그레이션 경로(exit strategy)가 구체화되어 있지 않다.

2. **Firestore NoSQL 쿼리 한계 축적**: 현재는 단순 쿼리로 충분하지만, V2 비교 테이블 기능, 출퇴근 분석, 알림 기능 등이 추가되면 Firestore의 JOIN 부재 + 복합 인덱스 한계가 심각해진다. 특히 `complexes` 문서에 집계 필드(`inspectionCount`, `averageRating`)를 비정규화하는 방식은 동시 편집 시 atomic counter 문제를 야기한다.

3. **1인 메인테이너 flutter_naver_map 의존**: 지도 추상화 레이어가 설계에 언급되었으나 spec.md에는 `map_repository` 인터페이스 정도로만 추상화되어 있다. 실제 플러그인 교체 비용이 어느 정도인지 구체적 분석이 없다.

---

## 2. Decision Record 검증

### DR-01: 상태관리 — Riverpod 3

**판정: PASS**

- 대안 A(Riverpod), B(Bloc), C(GetX) 3개 검토됨. 충분.
- 기각 사유 납득: Bloc 보일러플레이트 과다, GetX 유지보수 리스크 — 동의.
- **누락 대안**: Provider(공식 Flutter 권장의 전신), MobX — 이들은 영향력이 낮아 생략 타당.
- **미확인 리스크**: Riverpod 3.x는 코드 생성에 의존하므로 build_runner 수행 시간이 프로젝트 규모에 따라 증가한다. 1인 개발자 워크플로에서 hot reload 시 build_runner 재실행 대기가 생산성을 낮출 수 있다. 코드 생성 없는 Riverpod 사용 방식도 존재하므로, 이 trade-off가 명시되어야 한다.

### DR-02: 지도 SDK — flutter_naver_map

**판정: PASS (조건부)**

- 대안 A(flutter_naver_map), B(google_maps_flutter), C(kakao_map_plugin) 3개 검토됨.
- 최신 버전 확인: pub.dev 기준 1.3.1 (2026-02 업데이트, 약 53일 전 기준). 메인테이너 활성 상태 확인됨.
- **조건**: "지도 인터페이스 추상화"가 언급되어 있으나 spec.md의 `map_repository.dart`가 실제로 지도 SDK 교체를 가능케 하는지 검증 필요. 현재 spec에서 `NaverMap` 위젯, `NLatLng` 타입이 presentation layer에서 직접 사용되고 있어 교체 비용이 실제로 높다.
- **누락 대안**: mapbox_maps_flutter — 글로벌 커버리지 + 한국 정밀도가 Google보다 나은 경우도 있음. 미검토.

### DR-03: 백엔드 — Firebase

**판정: PASS (조건부 — 벤더 종속 리스크 불충분)**

- 대안 3개 검토됨. 기각 사유 타당.
- **그러나 벤더 종속 리스크 처리 불충분**:
  - DR-03 제약/한계에 "벤더 종속"이 단 한 줄로 언급되고 완화 방안이 없다.
  - Firebase가 Storage를 Blaze 필수화한 선례(2026-02-03)가 있다. 향후 Firestore 가격 인상, 쿼리 제한 강화 등이 발생할 경우 앱 전체가 영향 받는다.
  - **권고**: Repository 패턴이 이미 적용되어 있으므로, Data Layer가 Firebase 구체 구현에 어느 정도 독립되어 있는지 명시해야 한다. 현재 spec의 DataSource는 `FirebaseFirestore.instance`에 직접 의존하므로 교체 비용이 여전히 높다.

### DR-04: 오프라인 사진 저장

**판정: PASS**

- 대안 3개, 채택/기각 사유 명확.
- **제약 인식**: "앱 삭제 시 임시 저장 사진 유실" 명시됨. 양호.
- **추가 리스크 미언급**: 앱이 백그라운드로 전환되거나 OS가 앱을 종료하는 경우, 임시 디렉토리가 정리될 수 있다. iOS에서는 `getTemporaryDirectory()` 경로가 시스템에 의해 정리될 수 있으므로 `getApplicationDocumentsDirectory()` 또는 `getApplicationSupportDirectory()`가 더 안전할 수 있다. 이 구분이 없다.

### DR-05: 공공데이터 API 캐싱 — Firestore 캐싱

**판정: PARTIAL PASS**

- 대안 3개 검토됨.
- **미검토 대안**: 하이브리드 캐싱 (로컬 1차 캐시 + Firestore 공유 캐시 2차). 현재 설계는 Firestore 캐싱만 사용하므로, 오프라인에서 신규 단지 검색 시 캐시가 없으면 검색 불가. 법정동코드는 로컬이나, API 응답은 Firestore 캐시 의존이다.
- **보안 취약점**: `apiCache` 컬렉션은 "인증된 모든 사용자가 읽기/쓰기 가능"으로 설계되어 있다. 악의적 사용자가 캐시를 오염시킬 수 있다 (잘못된 데이터 삽입). 쓰기 시 데이터 스키마 검증 Rule이 없다.

### DR-06: 동시 편집 충돌 — LWW + 필드 병합

**판정: PASS**

- 대안 3개 검토됨. MVP 범위에서 LWW 채택 타당.
- 제약/한계 명시됨. V2 검토 언급됨.
- **추가 언급 필요**: 필드 레벨 병합이 실제로 어떤 시나리오에서 동작하지 않는지 (예: 체크항목 전체를 map으로 저장하므로, 두 사용자가 서로 다른 checkItem을 동시에 수정해도 map 단위로 덮어쓰면 충돌 발생). 이 엣지 케이스가 기술되지 않았다.

### DR-07: 법정동코드 — assets + SQLite

**판정: PASS**

- 대안 3개, 채택/기각 사유 명확. 타당.

### DR-08: 폴더 구조 — Feature-first + Layer 분리

**판정: PASS**

- 대안 3개 검토됨. 커뮤니티 표준 방식 참조됨.
- 검증 근거 URL 유효 (codewithandrea.com).

### DR-09: 로컬 DB — drift

**판정: PASS**

- 대안 3개 검토됨. 법정동코드 계층 구조에 관계형 쿼리 필수라는 근거 타당.

### DR-10: 사진 캐싱 — cached_network_image

**판정: PASS**

- 대안 3개 검토됨. 최신 버전 3.3.x 확인됨.

### DR-11: 딥링크 — App Links / Universal Links

**판정: PASS**

- Firebase Dynamic Links 종료(2025-08-25) 근거 확인됨.
- 대안으로 Branch.io도 검토됨.
- 디퍼드 딥링크 제약 명시됨.

### DR-12: XML 파싱 — xml 패키지

**판정: PASS**

- 대안 3개 검토됨. 근거 타당.

### DR 종합 요약

| DR | 판정 | 주요 이슈 |
|----|------|-----------|
| DR-01 | PASS | build_runner trade-off 미명시 |
| DR-02 | PASS 조건부 | 지도 추상화 실효성 미검증 |
| DR-03 | PASS 조건부 | 벤더 종속 완화 방안 불충분 |
| DR-04 | PASS | iOS 임시 디렉토리 정리 리스크 미언급 |
| DR-05 | PARTIAL PASS | apiCache 캐시 오염 보안 취약점 |
| DR-06 | PASS | checkItems map 충돌 엣지 케이스 미기술 |
| DR-07 | PASS | - |
| DR-08 | PASS | - |
| DR-09 | PASS | - |
| DR-10 | PASS | - |
| DR-11 | PASS | - |
| DR-12 | PASS | - |

---

## 3. 기술 제약 검증

### 3.1 Firebase Storage Spark 플랜 중단

**판정: PASS**

원문 근거 URL: `https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024`
WebSearch 미수행 (공식 FAQ URL 명시됨). 2026-02-03 Blaze 필수 전환은 광범위하게 확인된 사실이다.

### 3.2 Firestore 오프라인 동기화

**판정: PASS (부분 주의)**

- Firestore 오프라인 자동 동기화는 Android/iOS에서 기본 활성화 확인됨. ([공식 문서](https://firebase.google.com/docs/firestore/manage-data/enable-offline))
- **그러나 사진(Storage) 오프라인 동기화는 별도 이슈**: Firebase Storage는 Firestore와 달리 **오프라인 자동 큐잉이 없다**. 오프라인 시 Storage 업로드는 실패하며, 앱이 자체적으로 로컬 큐를 관리해야 한다. 이 사실이 plan.md에 "로컬 임시 저장 + 자동 동기화"로 기술되어 있으나, 구현 복잡도(연결 복구 감지 + 큐 재실행 + 실패 재시도)가 과소평가되어 있다. **"오프라인 기록 작성"을 Firestore 오프라인 하나로 설명하는 것은 불완전하다** — 텍스트 기록 = Firestore 오프라인(자동), 사진 = 별도 구현(수동 큐) 임을 명확히 구분해야 한다.

### 3.3 flutter_naver_map 최신 상태

**판정: PASS**

- WebSearch 결과: pub.dev 기준 최신 버전 **1.3.1** (2026-02 업데이트 확인, 약 53일 전)
- 메인테이너 활성 상태 확인됨. 1인 메인테이너 리스크는 여전하나 현재는 업데이트 지속 중.
- 문서의 "2025-10 최종 업데이트" 표기 (codebase_analysis.md)는 **부정확** — 실제로는 2026-02에 업데이트됨. 더 최신.

### 3.4 Firestore 복합 쿼리 제한

**판정: PASS**

OR 쿼리, 다중 inequality 필터 제한 — 공식 Firestore 문서에서 확인 가능. 현재 설계의 쿼리 패턴(`sharedWith array-contains + status == + createdAt desc`)은 복합 인덱스 생성 필요 여부가 명시되어 있어 양호.

### 3.5 Flutter Web 네이버 지도

**판정: 미확인 — PoC 필요 (원문과 동일)**

flutter_naver_map_web 패키지 존재 확인. 기능 제한 여부는 실제 테스트 없이는 확인 불가. 원문의 "미확인 — PoC 필요" 판정 유지.

### 3.6 Security Rules 내 getShareRole() 성능

**판정: 신규 발견 — 주의 필요 (원문 미검토)**

원문 Security Rules에서 `getShareRole(complexId)` 함수는 `get()` 호출 1회를 수행한다. Firestore 공식 문서에 따르면 "Rules 평가당 최대 10회 `get()` 호출 가능"이다. 현재 설계에서 `inspections` 서브컬렉션 접근 시:
1. `hasComplexAccess()` → `resource.data.sharedWith` (문서 read)
2. `isEditorOrAbove()` → `getShareRole()` → `get(/shares/{uid})` (추가 read)
3. `inspections` 자체 read

복잡한 쿼리(컬렉션 그룹 쿼리 등)에서 get() 호출이 누적될 수 있다. **단순 단일 문서 read에서는 문제 없으나, 대량 쿼리나 복잡한 rules 체인에서는 한계에 도달할 수 있다.** 이는 현재 MVP 규모에서는 큰 문제가 아니지만, 스케일 시 병목이 될 수 있다.

---

## 4. 설계 방향 타당성

### 4.1 Clean Architecture가 1인 MVP에 과잉 설계인가

**판정: PARTIAL PASS (조건부 인정)**

**과잉이라는 근거:**
- Entity / UseCase / Repository 인터페이스 / Repository 구현 / DataSource / DTO / Provider 7계층 구조
- 단순 Firestore CRUD에도 파일 5~7개 생성 필요 (예: `auth_repository.dart`, `auth_repository_impl.dart`, `auth_remote_datasource.dart`, `user_entity.dart`, `user_model.dart`)
- 1인 개발자가 8주 안에 42개 태스크를 처리하면서 이 구조를 모든 feature에 적용하면 실제 비즈니스 로직보다 아키텍처 유지에 시간이 더 소비될 수 있다
- 커뮤니티 권고(2025): "Not every app needs the full Clean Architecture treatment—use judgment."

**과잉이 아니라는 근거:**
- Flutter + Riverpod 3 코드 생성 패턴이 보일러플레이트를 상당히 줄인다
- Feature-first 구조로 각 feature를 독립적으로 개발 가능 — 부분별 진행이 가능
- 장기 유지보수 비용: 클린 아키텍처로 처음부터 작성하면 V2 팀 확장 시 리팩토링 비용 없음
- UseCase를 MVP에서 생략하고 Repository 직접 호출도 허용하면 절충 가능

**권고**: UseCase 레이어를 MVP에서는 선택적으로 적용한다. 비즈니스 로직이 단순한 CRUD는 Repository 직접 호출을 허용하고, 복잡한 로직(공유 초대 수락, 오프라인 동기화 등)에만 UseCase 도입. 이것이 실질적인 절충점이다.

### 4.2 Riverpod 3 코드 생성이 실제로 필요한가

**판정: PASS (필요하나 trade-off 명시 필요)**

Riverpod 3.x 코드 생성(@riverpod 어노테이션)은 보일러플레이트 최소화에 기여하며, 2025 기준 Flutter 커뮤니티의 표준 방식이다. 그러나:
- build_runner 실행이 필요: 새 Provider 추가 시 `flutter pub run build_runner build` 또는 `watch` 모드 필요
- cold start 후 첫 빌드에 수십 초 소요 가능
- **대안**: 코드 생성 없이 Riverpod을 수동으로 사용하는 방식도 가능하며, 보일러플레이트는 약간 늘지만 build_runner 의존이 제거됨

실제로 필요한가에 대한 답: 이 규모의 앱에서는 코드 생성 사용이 타당하나, 이를 선택했다면 build_runner 워크플로를 개발 프로세스에 명시해야 한다.

### 4.3 7개 Firestore 컬렉션 구조 — NoSQL 베스트 프랙티스

**판정: PARTIAL PASS**

**양호한 부분:**
- `inspections`, `photos`, `shares`, `activityLogs`가 `complexes` 서브컬렉션으로 설계됨 → 단지별 쿼리 패턴에 최적
- `sharedWith` 배열을 `complexes` 문서에 비정규화 → `array-contains` 쿼리 효율 양호
- `apiCache` 별도 최상위 컬렉션 분리 → 타당

**문제 있는 부분:**

1. **3단계 중첩 서브컬렉션**: `complexes/{cId}/inspections/{iId}/photos/{pId}` — 공식 Firebase 문서는 "3단계 이상 중첩 권장하지 않음"이라고 명시한다. 이 설계는 3단계다. 실제로 사진 목록 조회 시 `collectionGroup("photos")` 쿼리 사용 시 모든 단지의 사진이 반환될 수 있어 Security Rules에서 차단 필요. 단지별 사진만 조회할 때는 경로 지정이 필요하므로 큰 문제는 없으나, V2에서 "내 모든 사진" 쿼리 등이 필요하면 재설계 필요.

2. **`complexes` 문서 크기**: `totalHouseholds`, `totalBuildings`, `minFloor`, `maxFloor`, `heatingType`, `approvalDate`, `constructor`, `floorAreaRatio`, `buildingCoverageRatio`, `publicApiCode`, `sharedWith` 배열 등 25개 필드가 하나의 문서에 집중. `sharedWith` 배열이 커지면 문서 크기 증가(1MB 제한). 100명 공유 시에도 문제 없으나, 향후 주의 필요.

3. **`inspectionCount`, `averageRating` 비정규화**: 임장 기록 추가/삭제 시 `complexes` 문서의 이 두 필드를 동시에 업데이트해야 하는데, Firestore 트랜잭션이 없으면 불일치 가능. 공동 편집에서 동시에 임장 기록이 추가되면 count 증가가 누락될 수 있다. `FieldValue.increment(1)` 사용이 필수이나 spec에 명시 없음.

---

## 5. 인수 조건 완전성

### 판정: PARTIAL PASS

### 누락 또는 검증 불가 AC 목록

**FR-AUTH-01~02 (인증)**
- 누락: 비밀번호 확인 입력 불일치 시 에러 메시지 AC 없음
- 누락: 연속 로그인 실패(예: 5회 이상) 시 동작 정의 없음
- 누락: 이메일 인증 필요 여부 정의 없음 (Firebase Auth에서 이메일 인증 없이 회원가입 허용 시 미인증 계정 문제)

**FR-COMP-01 (단지 등록)**
- 누락: 공공API가 응답하지 않는 경우(타임아웃) 단지를 수동으로 입력하는 대안 흐름 없음
- 누락: 등록 중 앱이 종료되면 partial 상태의 단지가 Firestore에 남는 경우 처리 없음
- 누락: 단지명 검색 결과 0건일 때 "직접 등록" 옵션 여부 정의 없음

**FR-INSP-06 (오프라인 임장 기록)**
- 불완전: "네트워크 복구 시 자동으로 Firestore + Storage에 동기화된다" — 이는 텍스트(Firestore 자동)와 사진(Storage 수동 큐)을 구분하지 않음. 사진 20장 업로드 중 연결이 끊기면 어떻게 되는지 AC 없음.
- 누락: 동기화 실패 사진의 재시도 최대 횟수, 포기 조건 정의 없음

**FR-SHARE-01 (공유 링크 생성)**
- 누락: 공유 링크 만료 기간 정의 없음 (현재 inviteToken이 무기한 유효한 것으로 보임)
- 누락: 동일 단지에 동시에 여러 공유 링크 생성 허용 여부

**FR-SHARE-02 (공유 초대 수락)**
- 누락: 이미 참여 중인 사용자가 공유 링크를 다시 클릭하면 어떻게 되는지
- 누락: 링크로 초대된 후 Owner가 links를 취소/만료 처리할 수 있는지

**FR-SHARE-04 (실시간 동기화)**
- 검증 불가: "5초 이내 반영" — Firestore 실시간 리스너의 지연은 네트워크 상태에 따라 달라짐. 이 기준이 어떤 네트워크 환경(Wi-Fi, LTE, 3G 등)에서 측정되는지 정의 없음. 실제로 "5초 이내"는 정상 Wi-Fi 환경에서는 달성 가능하나, 공식 Firebase SLA는 아님.

**FR-MAP-01 (지도)**
- 누락: 위치 권한 거부 시 동작 정의 없음 (현재 위치 버튼 동작)
- 누락: GPS 정확도 낮음 시 동작

**NFR-PERF-03 (마커 100개)**
- 검증 불가: flutter_naver_map에서 100개 마커의 프레임 드롭 없는 렌더링 — 실제 디바이스에서 테스트 없이는 보장 불가. 최저 지원 기기(Android 7.0, 2016년 기기)에서의 성능은 별도 PoC 필요.

### 검증 가능한 AC 예시 (양호)
- 이메일 형식 불일치 시 에러 메시지 — 명확
- 단지명 2글자 이상 + 500ms 디바운스 — 명확, 자동화 테스트 가능
- 사진 최대 20장 제한 — 명확

---

## 6. MVP 범위 적절성

### 판정: PARTIAL PASS (공유 기능 MVP 포함 재검토 권고)

### 공유/공동편집 MVP 포함 여부

**현재 설계**: 공유/공동편집이 MVP에 포함되어 있으며, Sprint 7 전체(1주)를 차지하고 risk_level HIGH로 분류됨.

**MVP 제외 근거:**
1. 앱 자체가 1인 기록 도구로도 완결성이 있다 (단지 등록 → 임장 기록 → 지도 시각화)
2. 공유 기능은 추가 복잡도가 상당함: Security Rules 설계 오류 시 데이터 유출, 딥링크 설정(iOS/Android assetlinks), 실시간 동기화, 권한 관리 UI 등
3. 1인 MVP에서 공유 기능 사용자를 테스트하려면 별도 계정 2개 이상 필요 — QA 비용 높음
4. 제안서 문제 목록에서 "공유 불편"은 3번, 나머지 문제(정보 파편화, 비교 어려움, 지도 부재, 공공데이터 단절)가 더 핵심적

**MVP 포함 유지 근거:**
1. 기획서에서 "가족 합의 프로세스 지원"이 핵심 목표 중 하나
2. 공유 없이 출시 후 V2 추가 시 Firestore Security Rules 재설계 비용 높음 (설계를 처음부터 공유 고려로 했으므로)
3. Firestore 실시간 동기화가 기술 스택의 핵심 선택 이유 — 공유 기능 없으면 Firebase 선택의 주요 장점이 사라짐

**권고**: 공유 기능의 MVP 포함을 재검토하되, 제외보다는 **범위 축소**를 권고한다.
- MVP에서 Viewer 권한 + 링크 공유만 지원 (읽기 전용 공유)
- Editor 권한 + 실시간 동기화는 V1.1로 보류
- 활동 로그는 V2로 이동
- 이렇게 하면 Sprint 7 분량이 약 2~3일로 감소

### 8주 일정의 현실성

**판정: 낙관적 — 리스크 존재**

| Sprint | 태스크 합계 | 리스크 요인 |
|--------|------------|-------------|
| S1 (기반+인증) | 5일 | Apple Sign-In 설정 0.5일 → 실제 1~1.5일 가능 |
| S2 (공통UI+공공데이터) | 5일 | 법정동코드 SQLite 초기화 1.5일 → 2일 가능 |
| S3 (단지+공공API) | 5일 | XML 파싱 + Firestore 캐싱 로직 → 6일 가능 |
| S4 (단지UI) | 5일 | 단지 상세 탭 구조 복잡 → 6일 가능 |
| S5 (임장+사진) | 5일 | 사진 업로드 진행률 + 압축 통합 → 6일 가능 |
| S6 (지도+오프라인) | 5일 | 네이버지도 통합 + 오프라인 사진 큐 → 7일 가능 |
| S7 (공유) | 5일 | Security Rules + 딥링크 설정 → 7~8일 가능 |
| S8 (통합) | 5일 | E2E 테스트 중 발견 버그 → 7~8일 가능 |

**결론**: 1인 개발자가 버그 없이 이상적으로 진행하면 8주 가능. 실제로는 예상치 못한 Flutter 플러그인 이슈, 공공API 응답 포맷 이해, Security Rules 디버깅 등으로 **10~11주** 소요 가능성이 높다. 일정 리스크를 명시적으로 표기해야 한다.

---

## 7. 보안 검증

### 판정: PARTIAL PASS (2개 취약점 발견)

### 취약점 1: apiCache 캐시 오염 가능성 (MEDIUM)

```javascript
match /apiCache/{cacheKey} {
  allow read: if isAuthenticated();
  allow create: if isAuthenticated();
  allow update: if isAuthenticated();  // <-- 취약
  allow delete: if false;
}
```

**문제**: 인증된 모든 사용자가 `apiCache`를 업데이트할 수 있다. 악의적 사용자가 특정 단지의 실거래가 캐시를 조작된 데이터로 덮어쓸 수 있다.

**권고 수정**:
```javascript
match /apiCache/{cacheKey} {
  allow read: if isAuthenticated();
  allow create: if isAuthenticated()
    && request.resource.data.keys().hasAll(['cacheKey', 'apiType', 'params', 'data', 'ttlDays', 'cachedAt', 'expiresAt'])
    && request.resource.data.cacheKey == cacheKey;
  allow update: if isAuthenticated()
    && request.resource.data.apiType == resource.data.apiType;  // apiType 변경 불가
  allow delete: if false;
}
```

### 취약점 2: Storage Rules — 인증만으로 임장 사진 접근 가능 (MEDIUM)

```javascript
match /photos/{complexId}/{inspectionId}/{photoId} {
  allow read: if request.auth != null;  // <-- 취약
```

**문제**: 인증된 모든 사용자가 임장 사진 URL을 직접 알 경우 접근 가능하다. Firestore Rules에서는 공유 참여자만 접근 가능하나, Storage URL을 직접 공유받은 제3자도 사진을 볼 수 있다.

**현재 설계의 인식**: spec.md에서 이 제약을 명시했다 ("Storage Rules에서는 Firestore 문서를 조회할 수 없으므로... 실질적 접근 제어 역할은 Firestore Rules"). 설계자가 이 trade-off를 인식했음은 양호하나, **Storage URL 노출 시나리오에 대한 위험 수준 평가와 완화 방안이 없다**.

**권고**: 사진 URL을 직접 노출하는 대신 Firebase Storage의 signed URL 또는 Cloud Functions를 통한 토큰 기반 접근을 V2에서 검토. MVP에서는 현재 설계 유지하되, 사진 URL을 클라이언트에서 외부 공유하지 않도록 UX 제어 필요.

### 취약점 3: 공유 링크 inviteToken 만료 없음 (LOW-MEDIUM)

`shares/{sId}` 문서의 `inviteToken`에 만료 시간(`tokenExpiresAt`) 필드가 없다. 즉, 생성된 공유 링크는 Owner가 삭제하지 않는 한 영구적으로 유효하다. 링크가 유출되면 언제든지 단지에 참여 가능하다.

**권고**: `inviteToken` 생성 시 `tokenExpiresAt: DateTime.now().add(Duration(days: 7))` 기본 설정. Security Rules에서 만료 확인 추가.

### 공공API 키 관리

**판정: PASS (주의)**

`--dart-define`으로 빌드 시 주입 방식은 타당하다. 단, `--dart-define` 값은 `strings.xml`(Android) 또는 `Info.plist`(iOS) 컴파일 결과에 포함되어 리버스 엔지니어링으로 추출 가능하다. 공공데이터 API는 무료이고 악용 가능성이 낮으므로 현재 수준은 MVP에서 수용 가능. 단, 이 사실을 명시적으로 기록해야 한다.

---

## 8. 프로토타입 판정

### 기술 PoC: 필요

다음 2가지 항목은 구현 전 PoC가 필요하다:

**PoC-1: 오프라인 사진 큐 동작 검증 (HIGH PRIORITY)**
- Firestore 오프라인 ≠ Storage 오프라인 동작 차이 검증
- 오프라인 상태에서 임장 기록 저장 → 사진 로컬 저장 → 네트워크 복구 → 자동 업로드 전체 플로우 검증
- iOS `getTemporaryDirectory()` vs `getApplicationSupportDirectory()` 앱 종료 후 파일 유지 여부
- 예상 소요: 0.5~1일

**PoC-2: flutter_naver_map 100개 마커 성능 + 커스텀 색상 마커 (MEDIUM PRIORITY)**
- 100개 마커를 다양한 색상으로 동시 표시 시 Android 7.0 저사양 디바이스(또는 에뮬레이터)에서 프레임 드롭 여부
- InfoWindow 커스텀 UI (단지명 + 상태 배지 + 평점) 가능 여부 확인
- 예상 소요: 0.5일

### 디자인 시안: 필요

다음 화면들은 UX 복잡도가 높아 사전 디자인 시안 없이 개발하면 재작업 가능성이 높다:

**디자인 시안 필요 화면:**
1. **SCR-INSP-CREATE (임장 기록 작성)**: 체크항목 5개 평점 + 사진 그리드 + 텍스트 3개 + 종합 평점 — 화면 밀도가 높아 레이아웃 설계 없이 개발하면 UX 저하
2. **SCR-COMPLEX-DETAIL (단지 상세)**: 3개 탭(정보/실거래가/임장기록) 구성 + 상태 배지 + 공유 버튼 — 탭 내 스크롤 계층 설계 필요
3. **SCR-MAP (지도)**: 커스텀 마커 + 필터 칩 + 검색 바 + InfoWindow 동시 표시 — 지도 위 UI 레이어링이 복잡

**디자인 시안 불필요 화면** (표준 패턴):
- SCR-LOGIN, SCR-SIGNUP: 표준 폼 UI
- SCR-SETTINGS: 표준 설정 목록
- SCR-ACTIVITY-LOG: 표준 타임라인 리스트

---

## 총평

### 전체 판정: PARTIAL PASS (수정 후 진행 권고)

**강점:**
- 12개 Decision Record 전체 작성됨. 구조적으로 의사결정이 문서화되어 있음
- 기술 스택 선택(Flutter + Firebase + Riverpod 3 + flutter_naver_map)이 한국 부동산 앱 MVP에 합리적
- Firestore 데이터 모델이 쿼리 패턴(단지별 임장, 공유 목록)을 고려한 비정규화 설계
- Security Rules가 상당히 세밀하게 작성됨 (공유 권한 체계 포함)
- 42개 태스크 Sprint 분배, 화면 흐름 다이어그램 등 실행 가능성 있음

**필수 수정 사항 (진행 전 반드시 처리):**

| 우선순위 | 항목 | 내용 |
|--------|------|------|
| P1 | 오프라인 사진 동기화 명확화 | 텍스트(Firestore 자동)와 사진(수동 큐) 구현 방식 구분. PoC 선행 |
| P2 | 공유 기능 MVP 범위 재검토 | Viewer 전용 공유로 축소 또는 전체 포함 여부 명시적 결정 |
| P3 | apiCache Security Rules 보완 | 캐시 오염 방지 유효성 검증 Rules 추가 |
| P4 | inviteToken 만료 기간 추가 | 기본 7일 만료 설정 |
| P5 | 8주 일정 리스크 명시 | 예비 시간(buffer) 또는 축소 범위(fallback scope) 정의 |

**권고 수정 사항 (진행 중 처리 가능):**

| 우선순위 | 항목 | 내용 |
|--------|------|------|
| P6 | `inspectionCount`/`averageRating` 원자적 업데이트 | `FieldValue.increment()` 명시 |
| P7 | 누락 AC 보완 | 비밀번호 확인 불일치, 위치 권한 거부, 공유 링크 재사용 등 |
| P8 | iOS 임시 디렉토리 경로 명확화 | `getApplicationSupportDirectory()` vs `getTemporaryDirectory()` 선택 |
| P9 | Firebase 벤더 종속 exit strategy | V3 이상 마이그레이션 경로 1줄이라도 명시 |
| P10 | UseCase 레이어 적용 기준 명시 | 단순 CRUD vs 복잡 비즈니스 로직 구분 기준 |

---

## 참고 검증 출처

- [flutter_naver_map pub.dev](https://pub.dev/packages/flutter_naver_map) — 1.3.1 (2026-02 업데이트)
- [Firestore 오프라인 지원 공식 문서](https://firebase.google.com/docs/firestore/manage-data/enable-offline)
- [Firebase Storage Flutter 공식 문서](https://firebase.google.com/docs/storage/flutter/start)
- [Firestore Security Rules 가이드](https://firebase.google.com/docs/firestore/security/get-started)
- [Firestore 데이터 구조 공식 문서](https://firebase.google.com/docs/firestore/manage-data/structure-data)
- [Supabase vs Firebase 비교 2025](https://www.leanware.co/insights/supabase-vs-firebase-complete-comparison-guide)
- [Flutter Clean Architecture 2025 (Medium)](https://medium.com/@saykat-mir/from-chaos-to-clarity-mastering-flutter-clean-architecture-in-2025-bbfa5292e2de)
- [Riverpod 3.0 코드 생성 가이드](https://codewithandrea.com/articles/flutter-riverpod-generator/)
- [Firestore 역할 기반 접근 제어](https://firebase.google.com/docs/firestore/solutions/role-based-access)
- [How to Write Firestore Security Rules for RBAC (2026)](https://oneuptime.com/blog/post/2026-02-17-how-to-write-firestore-security-rules-for-role-based-access-control/view)
