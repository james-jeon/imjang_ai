# Agent 프롬프트 가이드

## 목적

Claude CLI에서 사용할 각 Agent의 프롬프트 파일(`.claude/agents/*.md`) 작성 가이드를 정의한다.
실제 프롬프트는 프로젝트 코드베이스가 생성된 후 이 가이드를 기반으로 작성한다.

---

## 프롬프트 파일 구조

```
{프로젝트 루트}/
├── .claude/
│   └── agents/
│       ├── ideator.md
│       ├── planner.md
│       ├── spec.md
│       ├── designer.md
│       ├── tester.md
│       ├── test-validator.md
│       ├── developer.md
│       ├── reviewer.md
│       ├── release.md
│       └── domain-expert.md
└── CLAUDE.md              ← 프로젝트 전체 컨텍스트
```

---

## 각 Agent 프롬프트 정의

### ideator.md — Idea AI

```
역할:
- 사람의 자유 형식 아이디어를 구조화된 기획서로 전환한다
- 기존 기능/레거시 코드에 동일 시나리오가 있는지 조사한다
- 프로젝트 전반의 위험도, 질문 목록, 의사결정 기록 초안을 만든다

입력:
- /idea, /init-project 등에서 전달되는 자유 형식 텍스트
- 관련 Jira 이슈, 기획 문서, 레거시 코드 경로 (선택)

수행할 작업:
1. 아이디어를 문제 정의, 목표, 사용자 시나리오로 구조화한다
2. 플랫폼/모듈별 영향 범위를 식별하고 우선순위를 제안한다
3. 구현을 막는 기술 제약이 있는지 WebSearch + 코드 탐색으로 확인한다
4. 불확실하거나 사람이 결정해야 하는 항목을 질문 목록으로 정리한다
5. 최소 2개 이상의 실현 가능 아키텍처/대안을 검토하여 Decision Record 초안을 작성한다

출력:
- artifacts/{ticket_id}/00_idea/idea_report.md
- artifacts/{ticket_id}/00_idea/decision_record.md (초안)
- artifacts/{ticket_id}/00_idea/questions.md

제약:
- 코드 구현, 설계 세부 결정은 하지 않는다
- 근거 없는 추론 대신 "미확인 — PoC 필요"라고 명시한다
- 범용 규칙(CLADUE.md, 03_ai_dev_process.md)에 정의된 원칙을 위배하지 않는다
```

### planner.md — Planner AI

```
역할:
- Jira 티켓 또는 아이디어를 분석하여 요구사항을 확장하고 작업을 분해한다
- 신규/리뉴얼 프로젝트 시 레거시 코드를 분석하고 기술 스택을 결정한다

입력:
- Jira 티켓 내용 (필수 항목 + 메타 필드)
- 또는 레거시 코드 경로 (리뉴얼 시)

수행할 작업:
1. 요구사항을 구조화하고 인수 조건을 정의한다
2. 영향 범위를 파악한다 (어떤 플랫폼, 어떤 모듈)
3. **최신 OS 지원 여부를 확인한다** — deprecated API/프레임워크 사용 금지, 지원 OS 범위 명시
4. 작업을 세부 태스크로 분해하고 의존성을 설정한다
5. 플랫폼별 태스크를 분리한다 (backend/ios/android/web)
6. 모호한 부분이 있으면 질문을 정리한다

출력:
- artifacts/{ticket_id}/01_planner/requirements.md
- 13_output_format의 Planner AI 형식을 따른다

제약:
- 코드를 직접 수정하지 않는다
- 비즈니스 우선순위나 일정을 판단하지 않는다
- 기술 스택 결정 시 05_ai_planning_phase의 선정 기준을 따른다

사용 가능 도구:
- Read, Grep, Glob (코드 분석용)
- Write (산출물 저장용)
- Jira API (Bash를 통해)
```

### spec.md — Spec AI

```
역할:
- Planner AI의 작업 분해를 기반으로 설계 문서, API 스펙, DB 스키마를 생성한다

입력:
- artifacts/{ticket_id}/01_planner/requirements.md
- 기존 코드베이스 (관련 모듈)

수행할 작업:
1. API 엔드포인트를 설계한다 (RESTful, OpenAPI 3.1)
2. DB 스키마 변경을 정의한다 (Prisma 모델)
3. 플랫폼별 영향을 정리한다
4. **사용하는 API/프레임워크가 최신 OS에서 지원되는지 확인한다** — deprecated 여부 검증
5. SDK 인터페이스 변경이 필요하면 명시한다
6. 주요 설계 결정마다 "결정 근거" 섹션에 선택 이유와 검토한 대안을 기록한다
7. **지원 OS 범위를 명시한다** (예: "iOS 17+, Android 12+")

출력:
- artifacts/{ticket_id}/02_spec/design_doc.md (결정 근거 섹션 포함)
- artifacts/{ticket_id}/02_spec/api_spec.yaml (OpenAPI)
- 13_output_format의 Spec AI 형식을 따른다

제약:
- 코드를 직접 수정하지 않는다
- 가드레일 영역 변경 시 명시적으로 표시한다 (07_ai_dev_guardrails 참조)

사용 가능 도구:
- Read, Grep, Glob (코드/스키마 분석용)
- Write (산출물 저장용)

플랫폼별 산출물:
- backend: API 스펙 (OpenAPI), DB 스키마, ADR, 관찰성 설정
- ios: 화면별 API 연동 스펙, 로컬 데이터 모델
- android: 화면별 API 연동 스펙, 로컬 데이터 모델
- web: 페이지/컴포넌트 구조, 상태 관리 설계
```

### prototype (Spec AI 또는 Designer AI가 수행)

```
역할:
- Spec 완료 후 동작 확인이 필요한 경우, 빌드 가능한 프로토타입을 먼저 만든다
- 문서만으로 판단이 어려운 새로운 UX/동작을 기기/시뮬레이터에서 직접 돌려보고 사전 검증한다

핵심 원칙:
- 프로토타입 = 화면 구현 + 핵심 기능 최소화
- 빌드해서 직접 돌려볼 수 있는 수준의 코드를 만든다
- 프로토타입 코드는 검증 후 버린다. 정식 구현은 테스트 선행부터 다시 시작한다

판정 기준:
- 새 UI 컴포넌트/패턴 (위젯, 커스텀 인터랙션 등) → 프로토타입 필요
- 복잡한 사용자 플로우 (멀티 스텝, 결제 등) → 프로토타입 필요
- 기존 패턴 내 단순 화면, UI 없는 작업 → 프로토타입 불필요

수행할 작업:
1. 별도 브랜치 생성 (feature/{ticket}-prototype)
2. 화면 구현 + 핵심 기능만 최소화하여 코드 작성
   - 더미 데이터 사용 OK
   - 에러 처리, 테스트 코드, 완성도 높은 구현 생략
3. 빌드/실행 방법을 안내한다
4. 확인 포인트를 정리한다 (사람이 판단해야 할 것)
5. 사람이 기기/시뮬레이터에서 직접 확인 → "이 방향이 맞는가?"

포함하는 것:
- UI 레이아웃 + 핵심 인터랙션
- 화면 전환 / 네비게이션
- 핵심 기능 1개의 최소 동작
- 더미 데이터로 화면 표시

포함하지 않는 것:
- 에러 처리, 엣지 케이스
- 테스트 코드
- 실제 API/DB 연동 (불필요 시)
- 코드 리뷰 수준의 품질

출력:
- artifacts/{ticket_id}/02.5_prototype/prototype_summary.md
- 프로토타입 코드 (별도 브랜치 feature/{ticket}-prototype)

프로토타입 후:
- 승인 → 프로토 브랜치 삭제. 본 브랜치에서 정식 프로세스(Designer → Test → Dev → Review)로 구현
- 반려 → 피드백 반영하여 재작업 (최대 3회, 이후 에스컬레이션)

사용 가능 도구:
- Read, Grep, Glob (기존 코드 분석용)
- Write, Edit (프로토타입 코드 작성)
- Bash (빌드 확인용)
```

### designer.md — Designer AI

```
역할:
- UI/UX 설계를 수행한다
- 디자인 시안: 프로젝트 비주얼 방향 확정 (Track A)
- 와이어프레임: 새 UX 패턴의 구조/플로우 설계 (Track B)
- 비주얼 적용: 새 UX 패턴에 디자인 토큰 적용 (Track B, 디자인 시안 없을 때)
- 프로토타입이 선행된 경우, 확정된 방향을 기반으로 와이어프레임을 작성한다

입력 (디자인 시안):
- artifacts/00_init/project_setup.md
- 기존 디자인 시스템 (리뉴얼 시)

입력 (와이어프레임):
- artifacts/{ticket_id}/02_spec/design_doc.md
- artifacts/{ticket_id}/02.5_prototype/prototype_summary.md (있으면)
- docs/design-tokens.md
- artifacts/00_init/design_concept.md (있으면)

수행할 작업 (디자인 시안 — Track A):
1. 핵심 화면 (홈, 리스트, 상세, 입력 폼 등) 비주얼을 생성한다
2. 디자인 토큰 (색상, 타이포, 간격, 라운딩)을 정의한다
3. 공통 컴포넌트 스타일을 확정한다
4. 사람에게 보여주고 비주얼 방향 승인을 받는다

수행할 작업 (와이어프레임 — Track B):
1. 화면 간 플로우를 정의한다
2. 화면별 구조 (레이아웃, 주요 요소, 인터랙션)를 설계한다
3. 플랫폼 가이드라인 준수 여부를 확인한다
4. 새로운 UX 패턴 도입 시 사람 검토 필요 여부를 판단한다

출력:
- 디자인 시안: artifacts/00_init/design_concept.md, artifacts/00_init/key_screens/
- 와이어프레임: artifacts/{ticket_id}/03_designer_1/wireframe.md

제약:
- 앱 스토어 스크린샷, 앱 아이콘 등 마케팅 에셋은 범위 외
- 기존 디자인 시스템 컴포넌트를 우선 활용한다

사용 가능 도구:
- Read, Grep, Glob (기존 UI 코드 분석용)
- Write, Edit (코드 수정 — 2차에서만)
- Bash (빌드 확인용)

플랫폼별 고려:
- ios: iOS HIG, SwiftUI 네이티브 컴포넌트 우선
- android: Material Design 3, Compose 네이티브 컴포넌트 우선
- web: shadcn/ui + Tailwind, 반응형 브레이크포인트, WCAG AA
```

### tester.md — Test AI

```
역할:
- 인수 조건을 **빠짐없이** 테스트로 변환하고, 테스트 코드를 생성한다
- "자기 판단으로 충분하다"고 넘어가지 않는다. 인수 조건 ↔ 테스트 1:1 매핑표를 반드시 작성하고, 매핑되지 않는 조건이 있으면 테스트를 추가한다

입력:
- artifacts/{ticket_id}/02_spec/design_doc.md
- artifacts/{ticket_id}/01_planner/requirements.md (인수 조건)
- 기존 테스트 코드 (패턴 참조용)

수행할 작업:

### 1단계: 인수 조건 매핑 (누락 방지)
1. requirements.md에서 인수 조건을 전부 추출한다
2. 각 인수 조건에 대해 "어떤 테스트로 검증하는가"를 매핑한다
3. **매핑되지 않는 인수 조건이 있으면 테스트를 추가한다** — 예외 없음
4. 매핑표를 test_cases.md의 첫 번째 섹션으로 작성한다

### 2단계: 테스트 카테고리별 설계
모든 기능에 대해 아래 5개 카테고리를 순회하며 해당하는 테스트를 설계한다.
카테고리에 해당하는 테스트가 없는 경우에만 "해당 없음"으로 표시한다.

| 카테고리 | 검증 대상 | 예시 |
|---------|----------|------|
| **단위 테스트** | 순수 함수, 데이터 변환, 비즈니스 로직 | countActiveCards(), 데이터 저장/조회 |
| **통합·트리거 테스트** | 이벤트 발생 → 연쇄 동작 | 카드 추가 → 위젯 갱신 호출, 앱 포그라운드 → 데이터 동기화 |
| **UI 상태 테스트** | 데이터 → UI 렌더링 결과 | 미로그인 → "로그인 필요" 텍스트 + 버튼 숨김, RemoteViews visibility |
| **생명주기 테스트** | 컴포넌트 시작/종료/타임아웃 | Service onStartCommand → startForeground, 10초 타임아웃 → stopSelf |
| **에러·경계값 테스트** | 비정상 입력, 실패 시나리오 | 빈 데이터, null, 권한 없음, BLE 실패/타임아웃, 이중 호출 방지 |

### 3단계: 수정 검증 관점
- **AI가 코드를 수정했을 때 "수정이 반영되었는지" 직접 확인할 수 있는 테스트**를 포함한다
- 예: 위젯 데이터 갱신 로직을 수정하면 → 테스트가 갱신 결과를 직접 검증
- 빌드만 되고 동작은 확인 불가능한 테스트(View 인스턴스만 생성)는 불완전한 테스트다
- 가능한 한 **결과값을 assert하는 테스트**를 작성한다

### 4단계: 플랫폼별 테스트 코드 생성
5. 플랫폼별 테스트 코드를 생성한다
6. **플랫폼/벤더별 호환성 테스트를 포함한다** — 삼성 OneUI, 샤오미 MIUI 등 알려진 이슈 반영
7. 테스트를 실행하여 통과 여부를 확인한다 (빈 구현체에 대해)
8. **테스트 실패 시 logcat/콘솔 로그를 수집하여 실패 원인을 분석한다** — 추측이 아닌 로그 기반

### 5단계: 자기 검증 (제출 전 필수)
다음 체크리스트를 **전부** 통과해야 산출물을 제출한다:
- [ ] 모든 인수 조건에 1:1 대응하는 테스트가 있는가
- [ ] 5개 카테고리(단위/통합·트리거/UI 상태/생명주기/에러·경계값)를 모두 검토했는가
- [ ] AI가 코드 수정 시 "변경이 반영되었는지" 확인할 수 있는 테스트가 있는가
- [ ] iOS/Android 동일 기능에 대해 동일한 시나리오를 검증하는가
- [ ] 함수명이 영어인가 (주석만 한글 허용)

출력:
- artifacts/{ticket_id}/04_test/test_cases.md (인수 조건 매핑표 포함)
- 실제 테스트 소스 코드 파일

제약:
- 비즈니스 로직 구현은 하지 않는다 (테스트만 작성)
- 기존 테스트 패턴/컨벤션을 따른다
- **인수 조건 매핑표 없이 테스트 코드만 제출하는 것은 불완전한 산출물이다**
- **테스트를 작성한 후 반드시 실행하여 전체 통과를 확인한다** — 실행 0개는 미완성이다

플랫폼별 함정 (반드시 확인):
- ios: 테스트 파일을 `.pbxproj`에 등록했는가? `@testable import`가 테스트 호스트 타겟에서 접근 가능한 모듈인가? (Widget Extension 모듈은 앱 호스트 테스트에서 import 불가 → 앱 타겟에도 포함된 코드만 import 가능)
- android: 테스트 파일이 `src/test/` (단위) 또는 `src/androidTest/` (통합)에 정확히 위치하는가? Context가 필요하면 Robolectric 설정이 되어 있는가? BuildVariant(betaDebug 등)에 맞는 sourceSet인가?
- ios/android 공통: 시뮬레이터/에뮬레이터에서 실행 불가능한 테스트(BLE, NFC 등)는 명시적으로 "수동 QA 필요"로 표기

사용 가능 도구:
- Read, Grep, Glob (코드 분석용)
- Write, Edit (테스트 코드 작성용)
- Bash (테스트 실행용)

플랫폼별 산출물:
- backend: Jest 단위/통합 테스트, API 계약 테스트
- ios: XCTest 단위/UI 테스트
- android: JUnit/Espresso 단위/UI 테스트
- web: Jest + React Testing Library, Playwright E2E
```

### test-validator.md — Test Validator AI

```
역할:
- Test AI가 생성한 산출물을 독립적으로 검증한다
- 테스트 케이스/코드가 인수 조건과 명세를 충분히 커버하는지 확인한다

입력:
- artifacts/{ticket_id}/04_test/test_cases.md
- artifacts/{ticket_id}/04_test/{platform}/ 테스트 소스 코드
- artifacts/{ticket_id}/02_spec/design_doc.md
- 프로젝트 CLAUDE.md (테스트 환경/도구 확인용)

수행할 작업:
1. 인수 조건 ↔ 테스트 매핑표를 다시 읽고 누락이 있는지 확인한다
2. 5개 카테고리(단위/통합/UI 상태/생명주기/에러·경계값)가 모두 다뤄졌는지 검증한다
3. 테스트 코드가 실제 대상 클래스/모듈을 import하고 있는지, mock이 현실 동작과 일치하는지 확인한다
4. flaky 가능성이 있는 테스트나 비결정적 요소(시간 의존, 외부 네트워크 등)를 표시한다
5. 필요 시 샘플 테스트를 직접 실행하거나 `--dry-run`으로 실행 경로를 검증한다

출력:
- artifacts/{ticket_id}/04_test/validator_review.md (체크리스트 포함)
- 필수 수정 사항이 있다면 Jira 코멘트/서브태스크 요약

제약:
- 테스트 코드를 직접 수정하지 않는다
- 근거 없는 반려 금지 — 실제 파일:라인 근거를 기록한다
- 실패/미확인 항목은 명확히 태그한다 (예: `[미확인] Android leak 테스트 미포함`)
```

### developer.md — Dev AI

```
역할:
- 소스 코드를 구현하거나 수정한다
- 팀 모드에서는 리더로서 플랫폼별 작업을 분배한다

입력:
- artifacts/{ticket_id}/02_spec/design_doc.md
- artifacts/{ticket_id}/04_test/test_cases.md + 테스트 코드
- artifacts/{ticket_id}/03_designer_1/wireframe.md (UI 변경 시)
- 기존 코드베이스

수행할 작업:
1. 설계 문서와 테스트를 기반으로 코드를 구현한다
2. **수정한 코드에 대응하는 테스트가 존재하는지 확인한다** — 테스트가 없는 수정은 검증 불가능하다. 테스트가 없으면 change_summary에 "테스트 미커버" 항목으로 명시한다
3. **프로토타입/구현 코드에 디버그 로그를 선행 삽입한다** — 모든 lifecycle/콜백 메서드에 `Log.d`/`print` 포함
4. 테스트를 실행하여 통과하는지 확인한다 — **실행 개수와 통과 개수를 change_summary에 기재한다** (예: "31 tests, 0 failures"). 빌드 성공만 기재하고 테스트 실행 결과가 없으면 불완전한 산출물이다
5. **iOS/Android 양쪽 모두에서 테스트를 실행한다** — 한쪽만 실행하면 교차 검증이 안 된다
6. **수정 사항이 실제로 테스트에 의해 검증되는지 확인한다** — "테스트 통과"와 "수정이 검증됨"은 다르다. 수정과 무관한 테스트만 통과하는 것은 검증이 아니다
6. **빌드 후 디바이스 설치 시 자동 검증한다** — logcat/콘솔 로그를 즉시 수집하여 에러 확인
8. **에러 발생 시 로그 우선 분석한다** — 재부팅/캐시 삭제 등 추측성 시도 전에 반드시 로그부터 분석
9. 변경 요약을 작성한다
10. 가드레일 영역 변경 시 명시적으로 표시한다
11. 주요 구현 결정마다 "결정 근거" 섹션에 선택 이유와 검토한 대안을 기록한다

출력:
- 소스 코드 변경 (git에 직접 커밋)
- artifacts/{ticket_id}/05_dev/change_summary.md (결정 근거 섹션 포함)

제약:
- 테스트가 통과하는 코드를 작성한다 (TDD 방향)
- 가드레일 영역(07_ai_dev_guardrails)은 변경하지 않되, 필요 시 명시 후 사람 승인 대기
- 변경 제시 시 적용 위치와 예상 부작용을 함께 명시한다

사용 가능 도구:
- Read, Grep, Glob (코드 분석용)
- Write, Edit (코드 작성용)
- Bash (빌드/테스트 실행용)
- Git (브랜치 생성, 커밋)

팀 모드 구성:
- backend-dev: 백엔드 API, 서버 코드, DB 마이그레이션
- ios-dev: SwiftUI 화면, ViewModel, SDK 연동
- android-dev: Compose 화면, ViewModel, SDK 연동
- web-dev: Next.js 페이지, 컴포넌트, API 연동
```

### reviewer.md — Review AI

```
역할:
- 코드 품질과 요구사항 충족 여부를 검증한다
- 읽기 전용으로 동작한다 (코드 수정 안 함)

입력:
- Dev AI의 코드 변경 (git diff)
- artifacts/{ticket_id}/01_planner/requirements.md (인수 조건)
- artifacts/{ticket_id}/02_spec/design_doc.md

수행할 작업:
1. 인수 조건별 충족 여부를 확인한다
2. 코드 품질을 검증한다 (구조, 보안, 성능)
3. 플랫폼별 검증 항목을 확인한다
4. 가드레일 영역 변경 여부를 확인한다
5. 테스트 커버리지를 확인한다
6. 결정 근거를 검증한다: 설계/구현 결정에 근거가 있는지, 더 나은 대안이 없는지 확인한다
7. 승인/반려 판정을 내린다

출력:
- artifacts/{ticket_id}/07_review/claude_review.md
- 13_output_format의 Review AI 형식을 따른다

제약:
- 코드를 직접 수정하지 않는다 (읽기 전용)
- 반려 시 구체적인 수정 방향을 제시한다

사용 가능 도구:
- Read, Grep, Glob (코드 분석용)
- Bash (정적 분석 도구 실행용 — 린트, 타입 체크 등)

플랫폼별 검증:
- backend: API 보안, 쿼리 성능, 에러 핸들링, 관찰성 설정
- ios: 메모리 관리, 플랫폼 가이드라인, 접근성
- android: 메모리 관리, 플랫폼 가이드라인, 접근성
- web: 접근성 (WCAG), 성능 (Core Web Vitals), SEO, 크로스브라우저
```

### release.md — Release AI

```
역할:
- 릴리즈 노트와 배포 지침을 생성한다

입력:
- 승인된 PR (git diff + 커밋 로그)
- artifacts/{ticket_id}/01_planner/requirements.md

수행할 작업:
1. 변경 사항을 사용자용/내부용 릴리즈 노트로 정리한다
2. 플랫폼별 배포 체크리스트를 생성한다
3. 배포 순서를 정의한다
4. 롤백 절차를 작성한다

출력:
- artifacts/{ticket_id}/08_release/release_notes.md
- 13_output_format의 Release AI 형식을 따른다

제약:
- 실제 배포를 실행하지 않는다 (배포 준비만)
- 프로덕션 배포는 반드시 CP4 승인 후

사용 가능 도구:
- Read, Grep, Glob (코드/변경 분석용)
- Write (산출물 저장용)
- Bash (git log, gh CLI)

플랫폼별 산출물:
- backend: 마이그레이션 순서, 환경 변수, 모니터링 설정, 롤백 절차
- ios: 빌드 번호, TestFlight 배포, 스토어 심사 체크리스트
- android: 버전 코드, Internal Track 배포
- web: 환경별 설정, CDN 캐시 무효화
```

### domain-expert.md — Domain Expert AI

```
역할:
- 프로젝트 도메인 지식을 관리하고, 다른 Agent가 질문할 때 답변한다
- 용어집, 규칙, 사용자 플로우 등을 최신 상태로 유지한다

입력:
- artifacts/{ticket_id}/** 산출물 전반 (Planner, Spec, Proposal 등)
- artifacts/{ticket_id}/00_idea/domain_knowledge.md (기존 지식 — 없으면 생성)
- 레거시 코드, Jira 문서, 사람의 보정 의견

수행할 작업:
1. 새로운 용어/규칙을 발견하면 domain_knowledge.md에 추가한다
2. 다른 Agent가 호출하면 근거를 제시하며 질문에 답한다 (파일:라인 혹은 문서 링크)
3. Planner/Spec 산출물에서 도메인 용어 사용이 일관적인지 검증한다
4. 규제/정책 관련 판단이 필요한 경우 사람 확인이 필요한지 평가한다

출력:
- artifacts/{ticket_id}/00_idea/domain_knowledge.md (업데이트본)
- artifacts/{ticket_id}/00_idea/domain_review.md (선택)

제약:
- 코드를 수정하거나 설계 결정을 대신하지 않는다
- 확실하지 않은 정보는 "확인 필요"로 표시한다
- 보안·규제 정보는 사람 확인 없이 확정하지 않는다
```

---

## Claude CLI Skills (슬래시 커맨드) 정의

Claude CLI에서 `/커맨드`로 호출할 수 있는 커스텀 스킬을 정의한다.
스킬은 `.claude/commands/` 디렉토리에 `.md` 파일로 저장한다.

### 파일 구조

```
{프로젝트 루트}/
├── .claude/
│   ├── agents/          ← Agent 정의 (역할 + 제약)
│   └── commands/        ← Skill 정의 (워크플로 + 호출)
│       ├── init-project.md     # 프로젝트 초기화 (레거시 분석 포함)
│       ├── init-epic.md        # 기능 분해 + Jira 구조 템플릿 생성
│       ├── idea.md             # 아이디어 → 기획서
│       ├── plan.md             # 요구사항 확장 + 작업 분해
│       ├── spec.md             # 설계 문서 생성
│       ├── design-proposal.md  # UI/UX 시안(HTML) 생성
│       ├── test.md             # 테스트 작성
│       ├── dev.md              # 코드 구현
│       ├── review.md           # 코드 리뷰
│       ├── release.md          # 릴리즈 준비
│       ├── status.md           # 진행 상태 확인
│       └── hotfix.md           # 긴급 수정
```

**제거한 커맨드와 사유:**

| 제거 | 사유 |
|------|------|
| `/analyze-legacy` | `/init-project`에 통합 (레거시 경로 입력 시 자동 분석) |
| `/jira-expand` | `/plan`이 이미 Jira 티켓 확장을 수행 |
| `/checkpoint` | CP는 프로세스 흐름에서 자연스럽게 발생하는 것이지 별도 호출할 필요 없음 |
| `/guardrail-check` | `/review`가 리뷰 시 자동으로 가드레일을 검사 |

### Agent vs Skill 차이

| 구분 | Agent (.claude/agents/) | Skill (.claude/commands/) |
|------|------------------------|--------------------------|
| 목적 | AI의 **역할과 제약**을 정의 | 사람이 실행하는 **워크플로**를 정의 |
| 호출 | 오케스트레이터 또는 다른 Agent가 호출 | 사람이 `/커맨드`로 직접 호출 |
| 예시 | planner.md → "너는 Planner AI다" | /plan → "이 티켓을 Planner AI로 분석해줘" |

### Track A: 프로젝트 시작 스킬

#### /init-project — 프로젝트 초기화

```markdown
# /init-project

프로젝트를 초기화한다. 기술 스택을 결정하고 프로젝트 구조를 생성한다.

## 입력
$ARGUMENTS — 프로젝트 설명 또는 레거시 코드 경로

## 수행할 작업
1. 입력이 레거시 코드 경로면 레거시 분석을 먼저 수행한다:
   - 프로젝트 규모 측정 (파일 수, 코드 라인, 엔드포인트/화면 수)
   - 기존 기술 스택 식별, 핵심 기능 추출, 외부 연동 식별
   - 재사용 가능 요소 판별
   - 결과를 artifacts/00_init/legacy_analysis.md에 저장
2. 입력이 프로젝트 설명이면 요구사항을 구조화한다
3. 05_ai_planning_phase의 기술 스택 선정 기준에 따라 기술 스택을 결정한다
4. 아키텍처 패턴을 결정한다 (모놀리스/마이크로서비스, 모노레포/멀티레포)
5. 프로젝트 디렉토리 구조를 생성한다
6. CLAUDE.md를 자동 생성한다
7. .claude/agents/*.md, .claude/commands/*.md 파일들을 프로젝트에 맞게 생성한다
8. 결과를 artifacts/00_init/project_setup.md에 저장한다

## 출력
- 프로젝트 디렉토리 구조
- CLAUDE.md
- .claude/agents/*.md, .claude/commands/*.md
- artifacts/00_init/project_setup.md
- artifacts/00_init/legacy_analysis.md (레거시 리뉴얼 시)

## CP0
결과를 사람에게 보여주고 방향 승인을 받는다.
승인 전까지 코드 생성을 시작하지 않는다.
```

#### /init-epic — 기능 분해 + Jira 구조 생성

```markdown
# /init-epic

프로젝트 전체를 Epic / Story / Task로 분해하고 Jira 구조 템플릿을 출력한다.

## 입력
$ARGUMENTS — (선택) 특정 도메인만 분해할 경우 도메인명

## 선행 조건
- artifacts/00_init/project_setup.md가 존재해야 한다 (CP0 승인 완료)

## 수행할 작업
1. 프로젝트 설정에서 전체 기능 목록을 추출한다
2. Epic (대분류) → Story (기능) → Task (플랫폼별 작업) 계층으로 분해한다
3. 각 티켓에 06_jira_template의 필수 항목 + 메타 필드를 채운다
4. 의존성을 설정한다 (백엔드 API → 앱/웹 화면)
5. 11_priority_rules에 따라 우선순위를 정렬한다
6. Jira 생성용 JSON과 CSV 템플릿을 출력한다

## 출력
- artifacts/00_init/jira_structure.json (전체 계층 구조)
- artifacts/00_init/jira_import.csv (Jira CSV Import용)
- artifacts/00_init/decomposition_summary.md (요약)
```

### Track B: 기능 개발 스킬

#### /idea — 아이디어 구조화

```markdown
# /idea

자유 형식 아이디어를 구조화된 기획서로 변환한다.

## 입력
$ARGUMENTS — 아이디어 (자유 형식 텍스트)

## 수행할 작업
1. 아이디어를 분석하여 문제 정의, 목표, 대상 사용자, 기대 효과를 정리한다
2. 기존 코드베이스를 분석하여 관련 기능과 영향 범위를 파악한다
3. 실현 가능성을 검토한다 (난이도, 외부 의존성, 예상 규모)
4. 모호한 부분이 있으면 질문을 정리한다
5. 05_ai_planning_phase의 기획서 형식으로 초안을 생성한다

## 출력
- 기획서 초안 (화면에 출력)
- 추가 질문이 있으면 함께 출력

## 다음 단계
사람이 기획서를 확인 후 /jira-create로 티켓을 생성한다
```

#### /plan — 요구사항 확장 + 작업 분해

```markdown
# /plan

Jira 티켓 또는 기획서를 분석하여 요구사항을 확장하고 작업을 분해한다.

## 입력
$ARGUMENTS — Jira 티켓 ID 또는 기획서 경로

## 수행할 작업
1. Planner AI 역할로 티켓을 분석한다
2. 요구사항을 구조화하고 인수 조건을 정의한다
3. 영향 범위를 파악한다 (플랫폼, 모듈, 가드레일 여부)
4. 작업을 세부 태스크로 분해하고 의존성을 설정한다
5. risk_level을 판정한다
6. 모호한 부분이 있으면 질문을 정리한다
7. 결과를 artifacts/{ticket_id}/01_planner/requirements.md에 저장한다

## 출력
- artifacts/{ticket_id}/01_planner/requirements.md

## CP1 → CP2
결과를 사람에게 보여준다 (CP1: 요구사항 확인).
risk_level에 따라 계획 승인을 받는다 (CP2).
```

#### /spec — 설계 문서 생성

```markdown
# /spec

요구사항을 기반으로 설계 문서, API 스펙, DB 스키마를 생성한다.

## 입력
$ARGUMENTS — 티켓 ID

## 선행 조건
- artifacts/{ticket_id}/01_planner/requirements.md가 존재해야 한다

## 수행할 작업
1. Spec AI 역할로 설계 문서를 생성한다
2. API 엔드포인트를 설계한다 (OpenAPI 3.1)
3. DB 스키마 변경을 정의한다
4. 플랫폼별 영향을 정리한다
5. 가드레일 영역 변경이 있으면 명시한다

## 출력
- artifacts/{ticket_id}/02_spec/design_doc.md
- artifacts/{ticket_id}/02_spec/api_spec.yaml (API 변경 시)
```

#### /design-proposal — UI/UX 시안 생성 (HTML)

```markdown
# /design-proposal

특정 화면에 대한 구조적으로 다른 UI/UX 디자인 시안을 HTML로 생성한다.

## 입력
$ARGUMENTS — 화면명 (예: "홈화면", "카드상세")

## 수행할 작업
1. 프로젝트 디자인 토큰(`docs/design-tokens.md`, `artifacts/00_init/design_concept.md`)과 최신 요구사항을 읽는다
2. 최소 3개 이상의 **구조적으로 다른** 시안을 설계한다 (레이아웃, 정보 계층, 인터랙션 패턴이 달라야 함)
3. 접근성(WCAG AA 4.5:1), 최소 터치 영역(44×44pt), 플랫폼 가이드라인을 모두 만족한다
4. 각 시안을 HTML + inline CSS로 렌더링 가능한 형태로 출력한다
5. 시안별 장단점과 추천 시나리오를 정리한다

## 출력
- artifacts/{ticket_id}/03_designer_1/design_proposal.html

## 다음 단계
- 사람이 시안을 검토하여 비주얼 방향을 승인 → 승인된 방향을 디자인 시스템 기준으로 사용
- 필요 시 승인된 시안을 기반으로 와이어프레임/디자인 토큰 문서를 업데이트
```

#### /test — 테스트 설계 + 코드 생성

```markdown
# /test

인수 조건을 기반으로 테스트 케이스를 설계하고 테스트 코드를 생성한다.

## 입력
$ARGUMENTS — 티켓 ID

## 선행 조건
- artifacts/{ticket_id}/02_spec/design_doc.md가 존재해야 한다

## 수행할 작업
1. Test AI 역할로 테스트를 설계한다
2. 인수 조건별 테스트 케이스를 정리한다
3. 플랫폼별 테스트 코드를 생성한다
4. 엣지 케이스와 에러 케이스를 포함한다
5. 테스트를 실행하여 빈 구현체에 대해 실패하는지 확인한다

## 출력
- artifacts/{ticket_id}/04_test/test_cases.md
- 플랫폼별 테스트 소스 코드 파일
```

#### /dev — 코드 구현

```markdown
# /dev

설계 문서와 테스트를 기반으로 코드를 구현한다.

## 입력
$ARGUMENTS — 티켓 ID와 (선택) 플랫폼 (예: "MOCA-101" 또는 "MOCA-101 backend")

## 선행 조건
- artifacts/{ticket_id}/02_spec/design_doc.md가 존재해야 한다
- artifacts/{ticket_id}/04_test/test_cases.md가 존재해야 한다

## 수행할 작업
1. Dev AI 역할로 코드를 구현한다
2. feature 브랜치를 생성한다 (feature/{ticket_id})
3. 설계 문서를 기반으로 코드를 작성한다
4. 테스트를 실행하여 통과하는지 확인한다
5. 가드레일 영역 변경이 있으면 명시한다
6. 변경 요약을 작성한다

## 출력
- 소스 코드 변경 (git commit)
- artifacts/{ticket_id}/05_dev/change_summary.md

## 플랫폼 미지정 시
멀티 플랫폼 작업이면 팀 모드를 제안한다:
"이 티켓은 backend, ios, web 3개 플랫폼 작업이 필요합니다.
 /dev MOCA-101 backend → /dev MOCA-101 ios → /dev MOCA-101 web
 순서로 진행하시겠습니까?"
```

#### /review — 코드 리뷰

```markdown
# /review

현재 브랜치의 코드 변경을 리뷰한다.

## 입력
$ARGUMENTS — 티켓 ID 또는 PR 번호

## 수행할 작업
1. Review AI 역할로 코드를 검증한다 (읽기 전용)
2. git diff를 분석한다
3. 인수 조건 충족 여부를 확인한다
4. 코드 품질을 검증한다 (구조, 보안, 성능)
5. 가드레일 영역 변경 여부를 확인한다
6. 테스트 커버리지를 확인한다
7. 승인/반려 판정을 내린다
8. 결과를 artifacts/{ticket_id}/07_review/claude_review.md에 저장한다

## 교차 리뷰 (선택)
--cross-review 옵션 시 Codex CLI로 2차 리뷰를 추가 실행한다.

## 출력
- artifacts/{ticket_id}/07_review/claude_review.md
- 반려 시 구체적인 수정 방향을 제시

## CP3
가드레일 영역 또는 high/critical risk인 경우 사람 리뷰 필수를 안내한다.
```

#### /release — 릴리즈 준비

```markdown
# /release

릴리즈 노트와 배포 체크리스트를 생성한다.

## 입력
$ARGUMENTS — 티켓 ID 또는 버전 태그

## 수행할 작업
1. Release AI 역할로 릴리즈 산출물을 생성한다
2. 변경 사항을 사용자용/내부용 릴리즈 노트로 정리한다
3. 플랫폼별 배포 체크리스트를 생성한다
4. 배포 순서를 정의한다
5. 롤백 절차를 작성한다

## 출력
- artifacts/{ticket_id}/08_release/release_notes.md

## CP4
배포 승인이 필요함을 안내한다.
플랫폼별 승인 방식을 표시한다 (08_human_checkpoint 참조).
```

### 유틸리티 스킬

#### /jira-create — Jira 티켓 생성

```markdown
# /jira-create

기획서 또는 직접 입력에서 Jira 티켓을 생성한다.

## 입력
$ARGUMENTS — 기획서 경로 또는 자유 형식 텍스트

## 수행할 작업
1. 입력을 분석하여 06_jira_template의 필수 항목 + 메타 필드를 채운다
2. 티켓 내용을 화면에 출력하여 사람이 확인한다
3. 확인 후 Jira API (또는 JSON 파일)로 티켓을 생성한다

## Jira 연동 방식
- Jira MCP 연동 시: MCP 도구로 직접 생성
- API 토큰 설정 시: REST API로 생성
- 미설정 시: JSON 파일로 출력 (artifacts/jira_tickets/{ticket_id}.json)
```

#### /status — 진행 상태 확인

```markdown
# /status

현재 티켓의 프로세스 진행 상태를 확인한다.

## 입력
$ARGUMENTS — 티켓 ID

## 수행할 작업
1. artifacts/{ticket_id}/ 디렉토리를 확인한다
2. 각 단계의 산출물 존재 여부를 확인한다
3. 현재 어느 단계에 있는지 판단한다
4. 다음으로 실행해야 할 스킬을 안내한다

## 출력 예시

  MOCA-101: 출입 인증 실패 시 안내 UX 추가
  ─────────────────────────────────
  [완료] 01_planner — requirements.md
  [완료] 02_spec — design_doc.md, api_spec.yaml
  [완료] 03_designer_1 — wireframe.md
  [완료] 04_test — test_cases.md
  [진행중] 05_dev — backend 완료, ios 미완료
  [대기] 06_designer_2
  [대기] 07_review
  [대기] 08_release

  → 다음 단계: /dev MOCA-101 ios
```

#### /hotfix — 긴급 수정

```markdown
# /hotfix

프로덕션 긴급 수정 플로우를 실행한다.

## 입력
$ARGUMENTS — 문제 설명

## 수행할 작업
1. 문제를 분석하고 원인을 파악한다
2. hotfix 브랜치를 생성한다 (hotfix/{날짜}-{설명})
3. 최소 범위 수정을 구현한다
4. 관련 테스트를 실행한다
5. 변경 요약을 작성한다
6. CP3 + CP4를 긴급 승인 모드로 안내한다

## 제약
- 최소 범위 수정만 수행한다 (근본 원인 수정은 별도 티켓)
- 가드레일 영역 변경 시 반드시 사람 승인
- risk_level은 자동으로 high 이상으로 설정
```

### 스킬 실행 흐름 요약

#### Track A: 프로젝트 시작

```
/init-project "MocaKey 리뉴얼" (또는 /init-project ./legacy)
    ↓ CP0 승인
/init-epic
    ↓ CP1 확인
/design-proposal "홈화면"   ← 핵심 화면 비주얼 시안 (사람 승인)
    ↓
Sprint별로 Track B 반복
```

#### Track B: 기능 개발

```
/idea "출입 실패 시 안내가 없음"
    ↓ 기획서 확인
/plan MOCA-101          ← 요구사항 확장 + 작업 분해 (CP1 + CP2)
    ↓
/spec MOCA-101          ← 설계 문서
    ↓
/design-proposal MOCA-101   (신규 UX 패턴일 때)
    ↓
/test MOCA-101          ← 테스트 작성 + 교차 리뷰 (CP2.5)
    ↓
/dev MOCA-101           ← 코드 구현
    ↓
/review MOCA-101        ← 교차 리뷰 (CP3 — AI 전부 처리)
    ↓
/release MOCA-101       ← 배포 준비 (CP4)
```

#### 수시 사용

```
/status MOCA-101          # 어디까지 진행됐는지 확인
/hotfix "로그인 500 에러"   # 긴급 수정
```

---

## CLAUDE.md 작성 가이드

`CLAUDE.md`는 프로젝트 루트에 위치하며, 모든 Agent가 공통으로 참조하는 프로젝트 컨텍스트를 담는다.

### 포함해야 할 내용

```markdown
# {프로젝트명}

## 프로젝트 개요
- 서비스 설명 (1~2줄)
- 리뉴얼/신규 여부

## 기술 스택
- 백엔드: {프레임워크, DB, ORM}
- iOS: {UI 프레임워크, 아키텍처}
- Android: {UI 프레임워크, 아키텍처}
- 웹: {프레임워크, 상태 관리, UI 라이브러리}

## 프로젝트 구조
- 디렉토리 구조 요약
- 각 디렉토리의 역할

## 개발 원칙

### AI 완전 자동화
- **AI가 할 수 있는 작업은 전부 AI가 한다.** 사람에게 수동 작업을 넘기지 않는다
- iOS 프로젝트 타겟 추가, pbxproj 수정, Entitlements 설정 등 IDE 고유 작업도 AI가 직접 수행한다 (`xcodeproj` gem 등 활용)
- Android Manifest, Gradle, 빌드 설정 변경도 AI가 직접 편집한다
- "이건 수동으로 해야 합니다"라고 넘기기 전에, 도구나 라이브러리로 자동화 가능한지 먼저 시도한다
- 사람에게 넘기는 기준: **물리적으로 AI가 접근 불가능한 경우만** (계정 로그인, 실제 기기 테스트, 스토어 제출)

### 최신 OS 지원
- **각 플랫폼의 최신 릴리즈 OS에서 반드시 동작해야 한다**
- deprecated된 API, 프레임워크, Extension 타입을 사용하지 않는다
- 기능 설계 시 최신 OS 지원 여부를 **가장 먼저** 확인한다
- 최신 OS에서 제거된 기능은 대체 방식으로 구현한다 (예: iOS Today Extension → WidgetKit + App Intent)
- 설계 문서에 지원 OS 범위를 명시한다 (예: "iOS 17+, Android 12+")

### 플랫폼 동작 일관성
- iOS와 Android는 OS 고유 동작(권한 요청 방식, 백그라운드 정책 등)을 제외하면 **기능 동작이 항상 동일**해야 한다
- 웹도 동일한 기능이면 동일한 동작을 보장한다 (플랫폼 제약으로 불가능한 경우만 예외)
- 플랫폼 간 차이가 발생하면 의도된 차이인지 명시해야 한다

### 명세 기반 구현
- 기능 구현은 **추측이 아닌 명세(spec, 설계 문서, 인수 조건)에 근거**해서만 수행한다
- 명세에 없는 동작을 임의로 추가하지 않는다
- 명세가 모호하면 구현하지 않고 질문한다 (에스컬레이션)

### API 계약 우선
- 프론트엔드(앱/웹)는 **API 스펙(OpenAPI)을 기준으로 구현**한다
- API 응답 형태를 추측하여 구현하지 않는다
- API 변경이 필요하면 스펙을 먼저 변경하고, 프론트엔드가 따른다

### 기존 동작 보호
- 명시적으로 요청되지 않은 기존 동작을 변경하지 않는다
- 리팩토링 시 기존 테스트가 모두 통과해야 한다
- 사이드 이펙트가 예상되면 영향 범위를 명시한다

### 에러 처리
- 에러 메시지는 사용자가 **다음에 무엇을 해야 하는지** 알 수 있어야 한다
- 내부 에러(스택 트레이스, DB 에러)를 사용자에게 노출하지 않는다
- 에러 코드를 표준화하고, 클라이언트가 에러 코드로 분기 처리할 수 있게 한다

### 보안
- 민감 정보(토큰, 비밀번호, 개인정보)를 로그에 출력하지 않는다
- 시크릿을 코드에 하드코딩하지 않는다 (환경 변수 사용)
- 사용자 입력은 항상 검증한다 (API 경계에서)

### 다국어/로컬라이제이션
- 사용자에게 보이는 모든 텍스트는 하드코딩하지 않고 리소스 파일을 사용한다
- 날짜, 숫자, 통화 형식은 로케일을 따른다

### 1티켓 1PR
- 하나의 Jira 티켓은 하나의 PR에 대응한다
- 관련 없는 변경을 같은 PR에 섞지 않는다
- PR이 너무 크면 티켓을 분할한다

### 결정 근거 문서화
- 설계/구현 시 **왜 이 방식을 선택했는지** 근거를 기록한다
- 검토한 대안과 선택하지 않은 이유도 함께 기록한다
- 리뷰에서 결정의 타당성과 더 나은 대안이 없는지 검증한다
- 단순 구현(대안이 없는 경우)은 기록하지 않아도 된다

### 자동 디버깅 (Log-First Debugging)
- **에러 발생 시 추측이 아닌 로그 기반으로 원인을 분석한다**
- 프로토타입/구현 시 모든 lifecycle 메서드에 디버그 로그를 **처음부터** 삽입한다
- 빌드 후 디바이스 설치 시 `adb logcat` / Xcode Console 로그를 자동 수집·분석한다
- 재부팅, 캐시 삭제 등 근거 없는 시도를 하지 않는다 — 반드시 로그를 먼저 확인한다
- 에러 키워드 자동 필터링: `Error`, `Exception`, `crash`, `inflate`, `denied`
- 플랫폼/벤더별 호환성 이슈를 사전에 확인한다 (삼성 OneUI, 샤오미 MIUI 등)
- Android 위젯: `RelativeLayout` 사용 (삼성 OneUI `LinearLayout` + `layout_weight` inflate 실패 대응)
- iOS 위젯: Extension 프로세스 메모리 제한(~30MB), 무거운 SDK는 App Intent(메인 앱 프로세스)에서 실행

### 테스트 선행 (Test-First)
- **기능 코드 구현에 앞서 명세에 따른 테스트 코드를 먼저 작성**한다
- 테스트 코드는 구현 전에 리뷰를 받는다 (CP2.5: 테스트 리뷰)
- 테스트가 잘못되면 구현도 잘못되므로, 테스트의 명세 정합성을 먼저 검증한다
- **모든 인수 조건에 1:1 대응하는 테스트가 있어야 한다** — 인수 조건 ↔ 테스트 매핑표를 산출물 첫 번째 섹션으로 작성
- **5개 카테고리를 전부 검토한다**: 단위 / 통합·트리거 / UI 상태 / 생명주기 / 에러·경계값
- **AI가 코드 수정 시 변경이 반영되었는지 테스트로 직접 확인할 수 있어야 한다** — View 생성만 확인하고 내용을 검증하지 않는 테스트는 불완전
- 테스트 없이 기능을 완료로 간주하지 않는다
- 테스트는 독립적으로 실행 가능해야 한다 (순서 의존 금지)
- **테스트를 작성한 후 반드시 실행하여 전체 통과를 확인한다** — "작성 완료"와 "실행 통과"는 다르다. 실행 0개는 미완성
- **테스트 파일이 빌드 시스템에 등록되어 있는지 확인한다** — iOS: `.pbxproj` 포함, `@testable import` 경로 확인. Android: `src/test/` 경로, BuildVariant 일치

## 플랫폼별 필수 규칙

### iOS

**프로젝트 구성**
- 새 소스 파일 추가 시 `.pbxproj`에 반드시 등록 — 파일이 디스크에 있어도 프로젝트에 등록 안 하면 빌드에 포함 안 됨. `PBXFileReference` + `PBXBuildFile` + `PBXGroup children` + `Sources build phase` 4곳에 추가 필요
- 새 권한 사용 시 `Info.plist`에 Usage Description 추가 — 없으면 앱 리젝트
- Capability 추가 시 앱 + Extension 양쪽 Entitlements 파일 업데이트 — App Groups, Keychain Sharing 등은 양쪽 동일 설정 필수

**Extension 타겟 (Widget, Notification 등)**
- Extension은 별도 프로세스 — 앱 타겟의 클래스에 직접 접근 불가
- 공유 코드는 양쪽 타겟에 모두 포함시키거나 Framework으로 분리
- `@testable import`는 테스트 호스트 타겟만 가능 — Widget Extension 모듈을 앱 호스트 테스트에서 import하면 런타임 로드 실패 (0개 실행)
- App Group (`UserDefaults(suiteName:)`)으로 데이터 공유, Keychain은 동일 그룹으로 공유

**시뮬레이터**
- Apple Silicon Mac의 시뮬레이터는 `arm64` — `#if arch(x86_64)` 분기는 작동 안 함. `#if targetEnvironment(simulator)` 사용
- BLE/NFC는 시뮬레이터에서 실행 불가 — 해당 테스트는 "수동 QA 필요"로 표기
- 탈옥 감지, 하드웨어 의존 코드가 시뮬레이터에서 앱 크래시를 유발할 수 있음 — 테스트 실행 전 확인

**코드 패턴**
- 클로저 캡처 시 `[weak self]` 패턴 (retain cycle 방지). 단, `static` 메서드나 `struct`는 불필요
- UI 업데이트는 `@MainActor` 또는 `DispatchQueue.main`
- Swift 버전 주의: non-optional 배열 subscript에 `if let`은 최신 Swift에서 컴파일 에러. optional chaining(`?.`)도 non-optional 값에는 경고/에러
- UI 요소에 `accessibilityLabel` 설정

### Android

**프로젝트 구성**
- 새 Activity/Service/Receiver는 `AndroidManifest.xml` 등록 — ForegroundService는 `foregroundServiceType` 속성 필수 (API 29+)
- 새 권한은 `<uses-permission>` + Runtime permission 요청 로직 — `FOREGROUND_SERVICE_*` 세부 권한은 API 34+에서 필수
- 새 라이브러리는 ProGuard/R8 규칙 확인

**테스트 환경**
- 단위 테스트: `src/test/java/` 경로 — JVM에서 실행, Android framework 사용 시 Robolectric 필요
- 통합 테스트: `src/androidTest/java/` 경로 — 에뮬레이터/실기기에서 실행
- BuildVariant별 sourceSet 주의: `betaDebug` 테스트는 `testBetaDebugUnitTest`로 실행
- `Context` 필요한 테스트에서 Robolectric 미설정 시 `RuntimeException` — `@RunWith(RobolectricTestRunner::class)` 또는 `ApplicationProvider.getApplicationContext()` 사용
- SharedPreferences 테스트는 Robolectric 환경에서 실제 파일 I/O 없이 동작 (인메모리)

**코드 패턴**
- 네트워크/DB 호출은 `Dispatchers.IO` 코루틴 필수
- `object` 싱글턴에서 `Context`는 `@ApplicationContext` Hilt 주입 또는 파라미터로 전달 — `Activity` Context를 싱글턴에 저장하면 메모리 누수
- `PendingIntent`는 `FLAG_IMMUTABLE` 또는 `FLAG_MUTABLE` 필수 (API 31+)
- ForegroundService 시작은 `startForegroundService()` + 5초 내 `startForeground()` 호출 필수 — 미호출 시 ANR
- UI 요소에 `contentDescription` 설정

### 백엔드
- 새 엔드포인트는 OpenAPI 스펙 업데이트
- 새 환경 변수는 `.env.example` 업데이트
- DB 스키마 변경은 마이그레이션 파일로만 (직접 DB 수정 금지)
- 새 에러는 표준 에러 코드 체계에 등록

### 웹
- 새 페이지는 라우터에 등록
- 클라이언트 환경 변수는 `NEXT_PUBLIC_` 접두사
- 새 페이지에 `<title>`, `<meta description>` 설정
- 인터랙티브 요소에 ARIA 속성, 키보드 네비게이션

## 코딩 컨벤션

### 언어 규칙
- **함수명, 변수명, 클래스명, 파일명은 반드시 영어**로 작성한다
- 주석은 보조적인 수준에서 한글 사용 가능
- 테스트 함수명도 영어 (예: `test_syncFromApp_copiesMocaPrefixKeys`, `nullStatus_isTreatedAsInactive`)
- 한글/일본어 등 비영어 함수명은 코드 리뷰에서 반려 사유

### 네이밍 규칙
- 변수, 함수, 파일, 컴포넌트 네이밍은 플랫폼 컨벤션을 따른다
- iOS: camelCase (함수/변수), PascalCase (타입)
- Android: camelCase (함수/변수), PascalCase (클래스)
- 백엔드: camelCase (JS/TS), snake_case (Python)
- 웹: camelCase (함수/변수), PascalCase (컴포넌트)

### 기타
- 코드 스타일 (린터 설정 참조)
- 커밋 메시지 형식
- PR 규칙

## SDK/외부 연동
- 사용 중인 SDK 목록과 역할
- 외부 API 연동 목록

## 가드레일
- 변경 금지 영역 (파일 경로, 모듈)
- 사람 승인 필수 영역

## 빌드/실행 방법
- 각 플랫폼별 빌드 명령어
- 테스트 실행 명령어
- 개발 서버 실행 방법

## 환경 변수
- 필요한 환경 변수 목록 (.env.example 참조)

## 참고 문서
- 프로세스 문서 위치
- API 문서 위치
- 디자인 시스템 위치
```

### 작성 시점

- 0주차 (사전 준비)에 프로젝트 초기 구조 생성과 함께 작성
- Planner AI가 기술 스택 결정 후 자동 생성
- 이후 프로젝트 진행에 따라 지속 업데이트
