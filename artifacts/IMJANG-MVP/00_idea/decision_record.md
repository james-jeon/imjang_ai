# IMJANG-MVP Decision Records (통합)

> 작성일: 2026-03-31
> 범위: Ideator + Planner + Spec 전 단계
> 본 문서는 모든 단계의 주요 기술 결정을 통합 관리한다.

---

## 목차

| ID | 결정 사항 | 단계 | 카테고리 |
|----|-----------|------|----------|
| DR-01 | 상태관리: Riverpod 3 채택 | Ideator | 기술 스택 |
| DR-02 | 지도 SDK: kakao_map_plugin 채택 | Ideator | 기술 스택 |
| DR-03 | 백엔드: Firebase (서버리스) 채택 | Ideator | 기술 스택 |
| DR-04 | 오프라인 사진 저장: 앱 임시 디렉토리 | Planner | 오프라인 |
| DR-05 | 공공데이터 API 캐싱: Firestore 캐싱 | Planner | 데이터 |
| DR-06 | 동시 편집 충돌: LWW + 필드 병합 | Planner | 공유 |
| DR-07 | 법정동코드 저장: 앱 assets + SQLite | Planner | 데이터 |
| DR-08 | 폴더 구조: Feature-first + 내부 Layer 분리 | Spec | 아키텍처 |
| DR-09 | 로컬 DB: drift (SQLite ORM) | Spec | 기술 스택 |
| DR-10 | 사진 캐싱: cached_network_image | Spec | 성능 |
| DR-11 | 딥링크: App Links / Universal Links | Spec | 기술 스택 |
| DR-12 | XML 파싱: xml 패키지 직접 파싱 | Spec | 데이터 |

---

## DR-01: 상태관리 — Riverpod 3 채택

**단계:** Ideator

| 항목 | 내용 |
|------|------|
| **결정 사항** | Riverpod 3 채택 |
| **대안 A** | **Riverpod 3** — @riverpod 매크로로 보일러플레이트 최소화, AsyncNotifier로 Firebase 스트림 자연 통합 |
| **대안 B** | **Bloc** — event/state 아키텍처, 대규모 팀/엔터프라이즈에 강점. 보일러플레이트 많음 |
| **대안 C** | **GetX** — 가장 쉬운 러닝커브. 그러나 테스트 어려움, 대규모 앱에서 유지보수 문제 |
| **채택 사유** | 1인~소규모 팀 MVP에서 Riverpod의 낮은 보일러플레이트와 Firebase 스트림 통합이 생산성 극대화. 2025년 기준 Flutter 커뮤니티에서 가장 추천되는 솔루션 |
| **기각 사유** | Bloc: MVP 단계에서 과도한 보일러플레이트. GetX: 장기 유지보수 리스크 |
| **제약/한계** | Riverpod 고유 패턴 학습 필요. 코드 생성(build_runner) 의존 |

> 검증 근거: [Flutter State Management 2025 비교](https://www.creolestudios.com/flutter-state-management-tool-comparison/), [Riverpod vs Bloc 심층 비교](https://tech.appunite.com/posts/a-deep-dive-into-riverpod-vs-bloc), [flutter_riverpod pub.dev](https://pub.dev/packages/flutter_riverpod) — 최신 3.3.x 확인

---

## DR-02: 지도 SDK — kakao_map_plugin 채택

**단계:** Ideator

| 항목 | 내용 |
|------|------|
| **결정 사항** | kakao_map_plugin 채택 (1차), google_maps_flutter (대안/글로벌) |
| **대안 A** | **kakao_map_plugin** — 한국 지도 정밀도 높음, 무료 할당량 충분(일 30만건), 한글 POI 정확 |
| **대안 B** | **google_maps_flutter** — 글로벌 커버리지, 풍부한 API. 한국 건물/도로 정밀도 Kakao 대비 부족 |
| **대안 C** | **flutter_naver_map** — 한국 정밀도 최고. 다만 2025-07 이후 무료 할당량 종료로 유료 전환 필요 |
| **채택 사유** | 한국 아파트 단지 탐색이 핵심 기능이므로 한국 지도 정밀도가 최우선. Kakao Map은 무료 할당량(일 30만건)이 충분하고 정책 안정성 우수 |
| **기각 사유** | Google Maps: 한국 도로/건물 데이터 부정확. Naver: 2025-07 이후 무료 할당량 종료로 비용 발생 위험 |
| **제약/한계** | Kakao Developers 가입 및 JavaScript 앱 키 발급 필요. 일 30만건 무료 할당량 범위 내 운영 필수 |

> 검증 근거: [kakao_map_plugin pub.dev](https://pub.dev/packages/kakao_map_plugin), [Kakao Maps API](https://apis.map.kakao.com/)

---

## DR-03: 백엔드 아키텍처 — Firebase 채택

**단계:** Ideator

| 항목 | 내용 |
|------|------|
| **결정 사항** | Firebase (서버리스) 채택 |
| **대안 A** | **Firebase** — Firestore 실시간 동기화, Auth, Storage 통합. 서버 관리 불필요 |
| **대안 B** | **Supabase** — PostgreSQL 기반, SQL 쿼리 가능, 오픈소스. 실시간 기능은 Firebase 대비 제한적 |
| **대안 C** | **자체 서버 (Node.js/Spring + PostgreSQL)** — 완전한 제어. 인프라 관리 부담 큼 |
| **채택 사유** | MVP 빠른 출시가 최우선. Firebase의 실시간 동기화가 "공유/공동편집" 핵심 기능에 직결. 오프라인 자동 동기화 내장 |
| **기각 사유** | Supabase: 실시간 동기화/오프라인 지원이 Firebase 대비 약함. 자체 서버: MVP 단계에서 인프라 오버헤드 과다 |
| **제약/한계** | Firestore NoSQL 특성상 복잡한 관계형 쿼리 제한. 벤더 종속. Blaze 플랜 전환 필수 (Storage) |

**벤더 종속 완화 — Exit Strategy:**

현재 설계는 Clean Architecture의 Repository 패턴을 적용하여 Data Layer를 추상화한다. 이를 통해 Firebase 벤더 종속을 완화한다.

| 레이어 | Firebase 종속 여부 | 전환 시 변경 범위 |
|--------|:------------------:|-------------------|
| **Presentation** | 없음 (Provider/Widget만) | 변경 없음 |
| **Domain** | 없음 (순수 Dart Entity + Repository 인터페이스) | 변경 없음 |
| **Data - Repository 구현체** | 있음 (Firestore 직접 의존) | 구현체 교체 필요 |
| **Data - DataSource** | 있음 (FirebaseFirestore.instance 등) | 전면 교체 |
| **Data - Model/DTO** | 있음 (Firestore 직렬화 형식) | DTO 재작성 |

**Firestore -> Supabase 전환 시 예상 작업:**
1. `*_remote_datasource.dart` 파일 전체 재작성 (Firestore API -> Supabase Client)
2. Model/DTO의 `fromFirestore()` / `toFirestore()` -> `fromJson()` / `toJson()` 변환
3. Security Rules -> Row Level Security (RLS) 정책 재설계
4. 실시간 리스너: `snapshots()` -> Supabase Realtime Channel 전환
5. Storage: Firebase Storage -> Supabase Storage API 전환
6. Auth: Firebase Auth -> Supabase Auth 전환 (가장 큰 변경)

**변경 규모 예상:** feature당 DataSource + Model 2~4개 파일 수정. 전체 약 20~30개 파일. Domain/Presentation은 변경 없음.

**재검토 트리거:** V2 이후 Firestore NoSQL 쿼리 한계(JOIN 부재, 복합 인덱스 제한)가 비즈니스 로직을 제약하거나, Firebase 가격 정책 변경이 발생하면 마이그레이션을 재검토한다.

> 검증 근거: [Firebase Firestore 오프라인 문서](https://firebase.google.com/docs/firestore/manage-data/enable-offline), [Firebase 가격 정책](https://firebase.google.com/pricing)

---

## DR-04: 오프라인 사진 저장 전략

**단계:** Planner

| 항목 | 내용 |
|------|------|
| **결정 사항** | 오프라인 사진을 앱 임시 디렉토리에 저장하고 온라인 복귀 시 Storage 업로드 |
| **대안 A** | **앱 임시 디렉토리 저장** + 연결 복구 시 순차 업로드 |
| **대안 B** | **SQLite BLOB 저장** (사진을 DB에 직접 저장) |
| **대안 C** | **Firestore offline cache에 의존** (사진 URL만 저장, 실제 파일은 별도 처리 안 함) |
| **채택 사유** | 파일 시스템이 대용량 바이너리에 최적. path_provider로 임시 경로 접근 간단 |
| **기각 사유** | 대안 B: DB에 바이너리 저장은 DB 크기 급증 + 성능 저하. 대안 C: Firestore는 파일 저장 불가, Storage 업로드는 별도 로직 필수 |
| **제약/한계** | 앱 삭제 시 임시 저장 사진 유실. 앱 재설치 전 동기화 미완료 사진 경고 필요 |

---

## DR-05: 공공데이터 API 캐싱 — Firestore 캐싱

**단계:** Planner

| 항목 | 내용 |
|------|------|
| **결정 사항** | Firestore에 API 응답을 캐싱 (컬렉션: `apiCache`) |
| **대안 A** | **Firestore 캐싱** (서버 사이드, 모든 디바이스 공유) |
| **대안 B** | **로컬 DB (Hive/SQLite) 캐싱** (디바이스별 독립) |
| **대안 C** | **Firebase Cloud Functions**에서 주기적으로 API 호출 + Firestore에 저장 |
| **채택 사유** | 한 사용자가 조회한 데이터를 다른 사용자도 활용. 공공API 호출 횟수 절감. 오프라인에서도 Firestore 캐시로 접근 가능 |
| **기각 사유** | 대안 B: 디바이스마다 중복 호출. 공유 사용자 간 캐시 불가. 대안 C: Cloud Functions 비용 + 설정 복잡도 증가. MVP 과잉 |
| **제약/한계** | Firestore 쓰기 비용 발생 (무료 할당량 내 가능). 캐시 무효화 로직 필요 |

---

## DR-06: 동시 편집 충돌 해결 — LWW + 필드 병합

**단계:** Planner

| 항목 | 내용 |
|------|------|
| **결정 사항** | MVP에서는 Last Write Wins (LWW) + 필드 레벨 병합 |
| **대안 A** | **LWW + 필드 레벨 병합** (Firestore merge) |
| **대안 B** | **OT (Operational Transformation)** 기반 실시간 충돌 해결 |
| **대안 C** | **비관적 잠금** (한 사용자만 편집 가능) |
| **채택 사유** | Firestore `set(merge: true)` / `update()`로 자연스럽게 구현. 서로 다른 필드 편집 시 양쪽 반영. MVP 범위에서 충분 |
| **기각 사유** | 대안 B: 구현 복잡도 극히 높음. MVP 과잉. 대안 C: UX 저하 (편집 대기). 2인 이상 동시 사용 시 병목 |
| **제약/한계** | 동일 필드 동시 수정 시 나중 쓰기만 남음. V2에서 충돌 알림/머지 UI 검토 |

---

## DR-07: 법정동코드 저장 방식 — 앱 assets + SQLite

**단계:** Planner

| 항목 | 내용 |
|------|------|
| **결정 사항** | 앱 assets에 JSON/CSV 파일 번들 + 로컬 SQLite에 로딩 |
| **대안 A** | **앱 assets 번들 + SQLite** |
| **대안 B** | **최초 실행 시 서버에서 다운로드** + 로컬 저장 |
| **대안 C** | **매번 API 호출** (행정표준코드관리시스템) |
| **채택 사유** | 법정동코드 약 5,000건은 소용량(~500KB). 앱에 포함하면 설치 즉시 사용 가능. 오프라인 완벽 지원 |
| **기각 사유** | 대안 B: 최초 실행 시 네트워크 필수. 다운로드 실패 시 앱 사용 불가. 대안 C: API 호출 제한 + 오프라인 불가 |
| **제약/한계** | 법정동코드 변경(연 1~2회) 시 앱 업데이트 필요. 앱 번들 크기 ~500KB 증가 |

---

## DR-08: 폴더 구조 — Feature-first + 내부 Layer 분리

**단계:** Spec

| 항목 | 내용 |
|------|------|
| **결정 사항** | Feature-first + 내부 Layer 분리 (하이브리드) |
| **대안 A** | **Feature-first + 내부 Layer 분리** — `lib/features/{feature}/data|domain|presentation/`. 기능별 독립성 유지 + 내부는 Clean Architecture 레이어 |
| **대안 B** | **순수 Layer-first** — `lib/data/`, `lib/domain/`, `lib/presentation/` 최상위 분리. 레이어 간 경계 명확하나 기능별 파일이 분산 |
| **대안 C** | **순수 Feature-first (레이어 없음)** — `lib/features/{feature}/` 안에 레이어 구분 없이 모든 파일 |
| **채택 사유** | Feature-first가 2025 Flutter 커뮤니티의 표준 권장 방식. 기능별 독립 모듈화로 병렬 개발 가능. 내부 레이어 분리로 테스트 용이성 유지. 기능 삭제 시 폴더 하나만 제거하면 됨 |
| **기각 사유** | 대안 B: 서로 다른 기능의 파일이 같은 폴더에 섞여 탐색 어려움. 기능 삭제 시 여러 폴더에서 파일 찾아야 함. 대안 C: MVP 이후 규모 성장 시 가독성 저하. Domain/Data 분리 없으면 테스트 작성 어려움 |
| **제약/한계** | feature 간 공유 코드는 `core/` 또는 `shared/`에 배치 필요. feature 간 의존성 방향 관리 필요 (순환 의존 주의) |

> 검증 근거: [Flutter Project Structure (codewithandrea.com)](https://codewithandrea.com/articles/flutter-project-structure/), [Best Practices 2025 (pravux.com)](https://www.pravux.com/best-practices-for-folder-structure-in-large-flutter-projects-2025-guide/)

---

## DR-09: 로컬 DB — drift (SQLite ORM)

**단계:** Spec

| 항목 | 내용 |
|------|------|
| **결정 사항** | drift (SQLite ORM) 채택 |
| **대안 A** | **drift** — SQLite 기반 ORM. 타입 안전 쿼리, 코드 생성, 마이그레이션 지원 |
| **대안 B** | **sqflite** — 순수 SQLite 래퍼. Raw SQL 작성 필요. 보일러플레이트 많음 |
| **대안 C** | **hive** — NoSQL 키-값 저장소. 빠른 성능. 관계형 쿼리 불가 |
| **채택 사유** | 법정동코드가 시/도 > 시/군/구 > 읍/면/동 계층 구조이므로 관계형 쿼리 필수. drift는 Dart 코드로 타입 안전하게 쿼리 작성 가능. build_runner 코드 생성으로 보일러플레이트 최소화 |
| **기각 사유** | 대안 B: Raw SQL 작성 부담, 타입 안전성 없음. 대안 C: 계층 구조 검색에 부적합 |
| **제약/한계** | build_runner 의존 (Riverpod과 공유하므로 추가 부담 없음) |

> 검증 근거: [drift pub.dev](https://pub.dev/packages/drift) — 최신 2.x, [Flutter databases comparison 2025](https://greenrobot.org/database/flutter-databases-overview/)

---

## DR-10: 사진 캐싱 — cached_network_image

**단계:** Spec

| 항목 | 내용 |
|------|------|
| **결정 사항** | cached_network_image 패키지 사용 |
| **대안 A** | **cached_network_image** — 네트워크 이미지 자동 디스크 캐싱. placeholder/error 내장 |
| **대안 B** | **수동 캐싱** — dio 다운로드 + 로컬 저장 + Image.file() |
| **대안 C** | **Firebase Storage 캐시 의존** — SDK 내장 캐시 사용 |
| **채택 사유** | flutter_cache_manager 기반 자동 캐싱. 오프라인 시 캐시 이미지 표시. 가장 널리 사용되는 이미지 캐싱 솔루션 (pub.dev likes 10,000+) |
| **기각 사유** | 대안 B: 구현 노력 대비 동일 결과. 대안 C: 캐시 제어 불가 |
| **제약/한계** | 오프라인에서 새 이미지 불가. `MaxNrOfCacheObjects`로 캐시 크기 제한 필요 |

> 검증 근거: [cached_network_image pub.dev](https://pub.dev/packages/cached_network_image) — 최신 3.3.x (2025-11 업데이트)

---

## DR-11: 딥링크 — App Links / Universal Links

**단계:** Spec

| 항목 | 내용 |
|------|------|
| **결정 사항** | App Links (Android) + Universal Links (iOS) + `app_links` 패키지 |
| **대안 A** | **App Links / Universal Links** — OS 네이티브 딥링크. 무료. 자체 도메인 필요 |
| **대안 B** | **Firebase Dynamic Links** — 2025-08-25 서비스 종료. 사용 불가 |
| **대안 C** | **Branch.io** — 서드파티 딥링크 서비스. 벤더 종속 |
| **채택 사유** | Firebase Dynamic Links 종료로 네이티브 딥링크가 유일한 무료 옵션. Firebase Hosting으로 `.well-known` 파일 호스팅 가능. 벤더 종속 없음 |
| **기각 사유** | 대안 B: 서비스 종료. 대안 C: 벤더 종속 + MVP 불필요 |
| **제약/한계** | 디퍼드 딥링크(앱 미설치 -> 스토어 -> 설치 -> 원래 URL)는 네이티브만으로 불완전. MVP에서는 "스토어 이동"까지만 지원 |

> 검증 근거: [Firebase Dynamic Links FAQ](https://firebase.google.com/support/dynamic-links-faq) — 2025-08-25 종료 확인, [Firebase Dynamic Links Deprecated: Alternatives (leancode.co)](https://leancode.co/blog/firebase-dynamic-links-deprecated)

---

## DR-12: XML 파싱 — xml 패키지 직접 파싱

**단계:** Spec

| 항목 | 내용 |
|------|------|
| **결정 사항** | `xml` 패키지로 직접 파싱 (xml2json 미사용) |
| **대안 A** | **xml 패키지 직접 파싱** — Dart 공식 XML 라이브러리. DOM + XPath 지원 |
| **대안 B** | **xml2json 패키지** — XML -> JSON 자동 변환 후 파싱. 변환 오버헤드 |
| **대안 C** | **서버 사이드 변환** — Cloud Functions에서 XML -> JSON 변환 |
| **채택 사유** | 불필요한 XML->JSON 변환 단계 제거. 공공API 응답 구조 고정적이므로 직접 파싱이 명확. XPath로 필요 노드만 추출 |
| **기각 사유** | 대안 B: 변환 시 구조 변형으로 디버깅 어려움. 대안 C: Cloud Functions 비용 + MVP 과잉 |
| **제약/한계** | 공공API 응답 포맷 변경 시 파싱 코드 수정 필요. 유닛 테스트로 포맷 검증 필수 |

> 검증 근거: [xml pub.dev](https://pub.dev/packages/xml) — Dart 공식 라이브러리

---

## 변경 이력

| 날짜 | 변경 내용 | 담당 |
|------|-----------|------|
| 2026-03-31 | DR-01 ~ DR-03 최초 작성 (Ideator) | AI |
| 2026-03-31 | DR-04 ~ DR-07 추가 (Planner) | AI |
| 2026-03-31 | DR-08 ~ DR-12 추가 (Spec) | AI |
| 2026-03-31 | 전체 통합 문서 생성 | AI |
