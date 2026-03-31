# IMJANG-MVP 아이디어 분석 (Ideator AI 산출물)

> 작성일: 2026-03-31
> 단계: 00_idea (Ideator)

---

## [아이디어 분석]

### 문제 정의

부동산 매수 희망자가 아파트 단지를 직접 방문(임장)하여 수집한 정보를 **체계적으로 기록하고 비교할 수단이 없다.** 현재는 메모장, 사진첩, 엑셀 등에 분산 저장되어 있어 다음과 같은 문제가 발생한다:

1. **정보 파편화** -- 단지별 체크항목, 사진, 메모가 별도 앱에 흩어져 있어 검색/비교 불가
2. **비교 어려움** -- 여러 단지를 동일 기준으로 나란히 비교할 도구 부재
3. **공유 불편** -- 가족/지인과 임장 결과를 공유하려면 수동 정리 필요
4. **지도 기반 탐색 부재** -- 방문한 단지와 관심 단지를 지도 위에서 한눈에 볼 수 없음
5. **공공데이터 단절** -- 실거래가, 단지 기본정보 등 공공데이터를 직접 검색해야 함

### 목표

실거주 목적의 부동산 매수 희망자가 **임장 전-중-후** 전 과정을 하나의 앱에서 관리할 수 있는 모바일 플랫폼을 제공한다.

- 단지 등록 ~ 임장 기록 ~ 비교 ~ 공유를 **단일 워크플로우**로 연결
- 공공데이터 연동으로 **실거래가/단지정보 자동 조회**
- 지도 기반 시각화로 **공간적 맥락** 제공
- 공유/공동편집으로 **가족 합의 프로세스** 지원

### 대상 사용자

| 사용자 유형 | 특성 | 핵심 니즈 |
|------------|------|-----------|
| 1차: 실거주 매수 희망자 | 30~40대, 첫 내집 마련 또는 이사 계획 | 여러 단지 비교, 체계적 기록 |
| 2차: 가족 구성원 | 배우자/부모 등 의사결정 참여자 | 공유된 정보로 함께 평가 |
| 3차: 부동산 스터디 그룹 | 임장 스터디 참여자 | 공동 기록, 정보 교환 |

### 기대 효과

1. 임장 정보 관리 시간 **50% 이상 절감** (분산 → 통합)
2. 단지 비교 의사결정 품질 향상 (동일 기준 비교)
3. 가족 간 부동산 정보 공유 마찰 감소
4. 공공데이터 자동 연동으로 정보 수집 부담 감소

---

## [기술 스택]

| 영역 | 선택 | 근거 | 검증 |
|------|------|------|:----:|
| **프론트엔드** | Flutter (Dart) | iOS + Android + 추후 Web 단일 코드베이스. 지도, 사진 등 네이티브 기능 지원 우수 | 확인 |
| **상태관리** | Riverpod 3 | 보일러플레이트 적음, 컴파일 타임 안전성, Firebase 스트림과 자연스러운 통합. 소규모 팀/MVP에 적합 | 확인 |
| **백엔드** | Firebase (서버리스) | 인프라 관리 불필요, 실시간 동기화 내장, 인증/저장소 통합. MVP 빠른 출시에 최적 | 확인 |
| **DB** | Cloud Firestore | 실시간 리스너, 오프라인 자동 동기화, NoSQL 유연한 스키마. 임장 기록 구조에 적합 | 확인 |
| **인증** | Firebase Auth | Google/Apple/이메일 로그인. 공유/권한 관리의 기반 | 확인 |
| **파일 저장** | Firebase Cloud Storage | 사진 업로드/다운로드. Blaze 플랜 필수 (2026-02-03 이후) | 확인 |
| **지도** | kakao_map_plugin (1차) + google_maps_flutter (대안) | 한국 특화 정밀 지도. Kakao Developers 앱 등록 필요 | 확인 |
| **라우팅** | go_router | Flutter 공식 추천, 딥링크/공유 링크 지원 | 확인 |
| **이미지 처리** | image_picker + flutter_image_compress | 촬영/갤러리 선택 + 업로드 전 압축 | 확인 |

---

## [기술 스택 대안 검토]

### Decision Record 1: 상태관리

| 항목 | 내용 |
|------|------|
| **결정 사항** | Riverpod 3 채택 |
| **대안 A** | **Riverpod 3** -- @riverpod 매크로로 보일러플레이트 최소화, AsyncNotifier로 Firebase 스트림 자연 통합 |
| **대안 B** | **Bloc** -- event/state 아키텍처, 대규모 팀/엔터프라이즈에 강점. 보일러플레이트 많음 |
| **대안 C** | **GetX** -- 가장 쉬운 러닝커브. 그러나 테스트 어려움, 대규모 앱에서 유지보수 문제 |
| **채택 사유** | 1인~소규모 팀 MVP에서 Riverpod의 낮은 보일러플레이트와 Firebase 스트림 통합이 생산성 극대화. 2025년 기준 Flutter 커뮤니티에서 가장 추천되는 솔루션 |
| **기각 사유** | Bloc: MVP 단계에서 과도한 보일러플레이트. GetX: 장기 유지보수 리스크 |
| **제약/한계** | Riverpod 고유 패턴 학습 필요. 코드 생성(build_runner) 의존 |

> 검증 근거: [Flutter State Management 2025 비교](https://www.creolestudios.com/flutter-state-management-tool-comparison/), [Riverpod vs Bloc 심층 비교](https://tech.appunite.com/posts/a-deep-dive-into-riverpod-vs-bloc)

### Decision Record 2: 지도 SDK

| 항목 | 내용 |
|------|------|
| **결정 사항** | kakao_map_plugin 채택 (1차), google_maps_flutter (대안/글로벌) |
| **대안 A** | **kakao_map_plugin** -- 한국 지도 정밀도 높음, 무료 할당량 충분(일 30만건), 한글 POI 정확 |
| **대안 B** | **google_maps_flutter** -- 글로벌 커버리지, 풍부한 API(Directions, Places). 한국 건물/도로 정밀도 Kakao 대비 부족 |
| **대안 C** | **flutter_naver_map** -- 한국 정밀도 최고. 다만 2025-07 이후 무료 할당량 종료로 유료 전환 필요 |
| **채택 사유** | 한국 아파트 단지 탐색이 핵심 기능이므로 한국 지도 정밀도가 최우선. Kakao Map은 무료 할당량(일 30만건)이 충분하고 정책 안정성 우수 |
| **기각 사유** | Google Maps: 한국 도로/건물 데이터 부정확. Naver: 2025-07 이후 무료 할당량 종료로 비용 발생 위험 |
| **제약/한계** | Kakao Developers 가입 및 JavaScript 앱 키 발급 필요. 일 30만건 무료 할당량 범위 내 운영 필수 |

> 검증 근거: [kakao_map_plugin pub.dev](https://pub.dev/packages/kakao_map_plugin), [Kakao Maps API](https://apis.map.kakao.com/)

### Decision Record 3: 백엔드 아키텍처

| 항목 | 내용 |
|------|------|
| **결정 사항** | Firebase (서버리스) 채택 |
| **대안 A** | **Firebase** -- Firestore 실시간 동기화, Auth, Storage 통합. 서버 관리 불필요 |
| **대안 B** | **Supabase** -- PostgreSQL 기반, SQL 쿼리 가능, 오픈소스. 실시간 기능은 Firebase 대비 제한적 |
| **대안 C** | **자체 서버 (Node.js/Spring + PostgreSQL)** -- 완전한 제어. 인프라 관리 부담 큼 |
| **채택 사유** | MVP 빠른 출시가 최우선. Firebase의 실시간 동기화가 "공유/공동편집" 핵심 기능에 직결. 오프라인 자동 동기화 내장 |
| **기각 사유** | Supabase: 실시간 동기화/오프라인 지원이 Firebase 대비 약함. 자체 서버: MVP 단계에서 인프라 오버헤드 과다 |
| **제약/한계** | Firestore NoSQL 특성상 복잡한 관계형 쿼리 제한. 벤더 종속. Blaze 플랜 전환 필수 (Storage) |

> 검증 근거: [Firebase Firestore 실시간 동기화 문서](https://firebase.google.com/docs/firestore/manage-data/enable-offline), [Firebase 가격 정책](https://firebase.google.com/pricing)

---

## [외부 API/서비스]

| API/서비스 | 용도 | URL | 비고 |
|------------|------|-----|------|
| **국토교통부 공동주택 단지 목록** | 아파트 단지 검색/자동완성 | https://www.data.go.kr/data/15057332/openapi.do | 법정동코드로 조회. 무료. 활용신청 필요 |
| **국토교통부 공동주택 기본 정보** | 단지 상세정보 (세대수, 난방, 면적 등) | https://www.data.go.kr/data/15058453/openapi.do | 무료. 활용신청 필요 |
| **국토교통부 아파트 매매 실거래가** | 실거래가 자동 조회 | https://www.data.go.kr/data/15126469/openapi.do | 법정동코드 + 계약년월로 조회. 무료 |
| **국토교통부 건축물대장 정보** | 건물 상세정보 (면적, 사용승인일 등) | https://www.data.go.kr/data/15134735/openapi.do | 무료. 활용신청 필요 |
| **Kakao Maps SDK** | 지도 표시, 마커, 경로 | https://developers.kakao.com/console/app | Kakao Developers 가입 필요. 일 30만건 무료 할당량 |
| **Firebase Auth** | 사용자 인증 | https://firebase.google.com/docs/auth | Google/Apple/이메일 로그인 |
| **Firebase Firestore** | 데이터 저장 + 실시간 동기화 | https://firebase.google.com/docs/firestore | 오프라인 자동 동기화 내장 |
| **Firebase Cloud Storage** | 사진 저장 | https://firebase.google.com/docs/storage | Blaze 플랜 필수 (2026-02-03~) |
| **행정표준코드관리시스템** | 법정동코드 조회 (공공API 파라미터용) | https://www.code.go.kr/ | 법정동코드 사전 데이터 필요 |

---

## [기술 제약]

| 제약 항목 | 주장 | 근거 | 검증 여부 |
|-----------|------|------|:---------:|
| **Firebase Storage Spark 플랜 중단** | 2026-02-03 이후 Spark 플랜에서 Storage 접근 불가. Blaze 필수 | [Firebase 공식 FAQ](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024) | 확인 |
| **Firestore 오프라인 동기화** | Android/iOS/Web에서 기본 지원. 오프라인 상태에서 쓰기 후 자동 동기화 | [Firestore 오프라인 문서](https://firebase.google.com/docs/firestore/manage-data/enable-offline) | 확인 |
| **Kakao Map 한국 전용** | 한국 영역만 고정밀 지도 제공. 해외 커버리지 없음 | [Kakao Maps API 문서](https://apis.map.kakao.com/) | 확인 |
| **공공데이터 API 호출 제한** | 일일 호출 횟수 제한 존재 (보통 1,000~10,000회/일) | [공공데이터포털](https://www.data.go.kr/) | 확인 -- 각 API별 제한 상이, 신청 시 확인 필요 |
| **Firestore 복합 쿼리 제한** | OR 쿼리, 다중 inequality 필터 제한. 복잡한 필터링 시 클라이언트 처리 필요 | [Firestore 쿼리 제한 문서](https://firebase.google.com/docs/firestore/quotas) | 확인 |
| **Kakao Map 무료 할당량** | 일 30만건 무료 제공. 초과 시 추가 요금 발생 | [Kakao Maps 가격 정책](https://apis.map.kakao.com/faq/usage) | 확인 |
| **실시간 공동편집 충돌** | Firestore 트랜잭션으로 동시 쓰기 충돌 해결 가능. 단, Google Docs 수준 실시간 편집은 추가 설계 필요 | [Firestore 트랜잭션 문서](https://firebase.google.com/docs/firestore/manage-data/transactions) | 확인 -- MVP는 "마지막 쓰기 우선" 또는 필드 레벨 병합으로 충분 |
| **Blaze 플랜 비용** | 무료 할당량 유지됨. 소규모 사용 시 실질 비용 $0에 가까움. 그러나 신용카드 등록 필수 | [Firebase 가격 정책](https://firebase.google.com/pricing) | 확인 |

---

## [MVP 추가 기능 제안]

| 기능 | 설명 | 구현 난이도 | MVP 포함 권장 | 사유 |
|------|------|:-----------:|:------------:|------|
| **공공데이터 실거래가 자동 조회** | 단지 등록 시 최근 실거래가를 자동으로 불러와 표시 | 중 | **권장** | 핵심 차별점. 사용자가 직접 검색하는 수고 제거. 국토교통부 API 무료 |
| **단지 검색/자동완성** | 단지명 입력 시 공공데이터 기반 자동완성 목록 제공 | 중 | **권장** | UX 핵심. 수동 입력 오류 방지. 공동주택 단지 목록 API 활용 |
| **오프라인 임장 기록** | 네트워크 없는 현장에서 기록 작성 후 자동 동기화 | 낮음 | **권장** | Firestore 오프라인 기능 기본 내장. 추가 구현 최소. 현장 사용성 핵심 |
| **사진 압축 후 업로드** | 고해상도 사진을 자동 압축하여 Storage 비용/시간 절감 | 낮음 | **권장** | flutter_image_compress로 간단 구현. Storage 비용 40~70% 절감 |
| **데이터 내보내기 (PDF/Excel)** | 임장 기록을 PDF 또는 Excel로 내보내기 | 중 | 보류 | 유용하나 MVP 핵심 아님. V2에서 추가 |
| **출퇴근 시간 분석** | 직장 주소 → 단지 간 대중교통/자가용 소요시간 | 높음 | 보류 | 외부 경로 API(Naver Directions 등) 추가 연동 필요. V2 |
| **단지 비교 테이블** | 2~4개 단지를 나란히 놓고 항목별 비교 | 중 | 보류 (V1.1) | 핵심 기능이나 MVP 최소 범위에서는 단지별 상세 조회로 충분. 빠른 후속 |
| **알림 (관심 단지 실거래 발생)** | 관심 등록 단지에 새 실거래가 등록 시 푸시 알림 | 높음 | 보류 | Cloud Functions + FCM 필요. V2 |
| **법정동코드 로컬 캐시** | 공공API 파라미터인 법정동코드를 로컬 DB에 캐싱 | 낮음 | **권장** | API 호출 절감 + 오프라인 검색 지원. SQLite 또는 Hive로 간단 구현 |
| **아파트 검색 (호갱노노 스타일)** | 미등록 단지 탐색/검색/시세 조회. 공공API 기반 전국 아파트 탐색 | 높음 | 보류 | MVP는 등록한 단지만 관리. V2에서 검색 → 등록 플로우 확장 |

---

## [실현 가능성]

### 난이도: **중 (Medium)**

- Flutter + Firebase 조합은 성숙한 스택으로 레퍼런스 풍부
- 지도 통합(Kakao Map)과 공공데이터 API 연동이 주요 복잡도 요인
- 공유/공동편집은 Firestore 실시간 리스너로 기본 수준 구현 가능 (Google Docs 수준은 아님)

### 외부 의존성

| 의존성 | 리스크 | 완화 방안 |
|--------|--------|-----------|
| 공공데이터 API | 간헐적 장애, 호출 제한, 응답 포맷 변경 | 캐싱 레이어, 에러 핸들링, 폴백 UI |
| Kakao Maps SDK | 무료 할당량 초과(일 30만건), 정책 변경 | 캐싱 레이어로 호출 절감, Google Maps 대안 준비 |
| Firebase | 가격 정책 변경 (Storage Blaze 필수화 사례) | Blaze 플랜 전환. 무료 할당량 내 운영 가능 |
| kakao_map_plugin 플러그인 | 플러그인 안정성 | Google Maps 대안 준비 |

### 예상 규모

| 항목 | 예상 수치 |
|------|-----------|
| 화면 수 | 12~15개 (로그인, 홈, 단지 목록, 단지 상세, 임장 기록 작성, 임장 기록 조회, 지도, 검색, 설정, 공유 관리 등) |
| Firestore 컬렉션 수 | 5~7개 (users, complexes, inspections, photos, shares, settings 등) |
| 공공데이터 API 연동 수 | 3~4개 (단지 목록, 단지 정보, 실거래가, 건축물대장) |
| 예상 개발 기간 (1인) | MVP 6~8주 |
| 예상 개발 기간 (2인) | MVP 4~5주 |

### Firebase 비용 예측 (MVP/소규모)

| 항목 | 무료 할당량 | 예상 사용량 (100 MAU) | 비용 |
|------|------------|----------------------|------|
| Firestore 읽기 | 50,000/일 | ~5,000/일 | $0 |
| Firestore 쓰기 | 20,000/일 | ~1,000/일 | $0 |
| Storage | 5GB (Blaze 무료) | ~2GB | $0 |
| Auth | 무제한 (이메일/Google) | ~100명 | $0 |
| **합계** | -- | -- | **$0 (Blaze 플랜, 무료 할당량 내)** |

---

## [다음 단계]

1. **Planner AI에게 전달할 항목:**
   - MVP 화면 목록 및 화면 흐름(Flow) 설계
   - Firestore 데이터 모델 설계 (컬렉션/문서 구조)
   - 공공데이터 API 연동 설계 (캐싱 전략 포함)
   - 공유/권한 모델 설계
   - 개발 우선순위 및 스프린트 분배

2. **사전 준비 필요 항목:**
   - [ ] 공공데이터포털 회원가입 + API 활용신청 (4개 API)
   - [ ] Kakao Developers 가입 + JavaScript 앱 키 발급
   - [ ] Firebase 프로젝트 생성 + Blaze 플랜 전환
   - [ ] Flutter 프로젝트 초기화

3. **PoC 필요 항목:**
   - [ ] kakao_map_plugin Web 기능 범위 확인 (Web 확장 시)
   - [ ] 공공데이터 API 실제 응답 포맷/속도 테스트
   - [ ] Firestore Security Rules 설계 (공유/권한 모델)

---

## 검증 출처

- [국토교통부 아파트 매매 실거래가 API](https://www.data.go.kr/data/15126469/openapi.do)
- [국토교통부 공동주택 단지 목록 API](https://www.data.go.kr/data/15057332/openapi.do)
- [국토교통부 공동주택 기본 정보 API](https://www.data.go.kr/data/15058453/openapi.do)
- [국토교통부 건축물대장 정보 API](https://www.data.go.kr/data/15134735/openapi.do)
- [kakao_map_plugin (pub.dev)](https://pub.dev/packages/kakao_map_plugin)
- [Kakao Maps API (developers.kakao.com)](https://developers.kakao.com/console/app)
- [Firebase Pricing](https://firebase.google.com/pricing)
- [Firebase Storage 정책 변경 FAQ](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024)
- [Firestore 오프라인 지원](https://firebase.google.com/docs/firestore/manage-data/enable-offline)
- [Flutter State Management 2025 비교](https://www.creolestudios.com/flutter-state-management-tool-comparison/)
- [Riverpod vs Bloc 심층 비교](https://tech.appunite.com/posts/a-deep-dive-into-riverpod-vs-bloc)
- [Firebase Firestore 실시간 앱 가이드 (2026)](https://medium.com/@saadalidev/building-real-time-flutter-apps-with-firebase-firestore-2026-complete-guide-4f12338b0c50)
