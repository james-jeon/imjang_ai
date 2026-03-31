---
description: 자유 형식 아이디어를 구조화된 기획서로 변환합니다
argument-hint: [아이디어 설명]
---

# /idea — 아이디어 → 기획 → 설계 → Jira 생성 (오케스트레이터)

자유 형식 아이디어를 받아 기획 + 설계까지 완료한 후, 상세한 Jira 카드를 생성한다.
**각 역할(Ideator, Planner, Spec)을 별도 Agent(subagent)로 분리 실행한다.**

## 입력

$ARGUMENTS — 아이디어 (자유 형식 텍스트)

## 참조 문서

- **06_jira_template.md** — Jira 티켓 필수 항목, 메타 필드, AI 확장 영역 형식
- **04_ai_agent_architecture.md** — Agent 역할 정의
- **14_tool_integration.md** — Agent 실행 절차, 산출물 경로

## 실행 원칙

| 원칙 | 설명 |
|------|------|
| **에이전트 분리** | 각 역할은 `Agent` 도구(subagent)로 분리 실행한다. 하나의 세션에서 모든 역할을 수행하지 않는다 |
| **산출물 기반 전달** | Agent 간 데이터 전달은 `artifacts/` 파일을 통한다 |
| **병렬 실행** | 의존성이 없는 Agent는 동시에 실행한다 (예: Android + iOS 코드 분석) |
| **tmux 시각화** | 병렬 Agent 실행 시 tmux split pane으로 진행 상황을 표시한다 |
| **게이트 검증** | 각 Agent 완료 후 오케스트레이터가 산출물을 읽어 게이트를 검증한다 |
| **복잡도별 경량화** | 아이디어 복잡도에 따라 Agent 수와 모델을 조절한다 |
| **부분 수정 원칙** | 피드백/리뷰 반영 시 산출물을 처음부터 다시 쓰지 않는다. 변경이 필요한 섹션만 수정한다 |
| **모델 최적화** | 코드 분석(Ideator)은 Sonnet으로 충분. Opus는 설계 결정(Spec)에만 사용한다 |

## 복잡도별 프로세스 분기

오케스트레이터가 아이디어 텍스트를 분석하여 복잡도를 판별하고, 프로세스를 분기한다.

### 복잡도 판별 기준

| 복잡도 | 조건 | 예시 |
|--------|------|------|
| **단순** | 단일 플랫폼 + 기존 화면 수정 + API/DB 변경 없음 | "로그인 화면에 비밀번호 찾기 링크 추가", "에러 메시지 문구 변경" |
| **보통** | 단일 플랫폼 신규 기능, 또는 API 변경 포함 | "트러블슈팅 가이드 화면 추가", "카드 만료 알림 기능" |
| **복잡** | 멀티 플랫폼 + 새 기술/SDK/하드웨어 + 미확인 항목 | "위젯에서 BLE로 문 열기 (Android+iOS)", "생체인증 2FA 추가" |

### 단순 (~100K) — Ideator+Planner 통합

```
Ideator+Planner (통합 1개 Agent) → Spec → Jira 생성
```

| 단계 | Agent | 모델 | 비고 |
|------|-------|------|------|
| 코드 분석 + 요구사항 | Ideator+Planner 통합 | `model: "sonnet"` | 1개 Agent로 분석+계획 동시 수행 |
| 설계 | Spec | `model: "sonnet"` | |
| 교차 리뷰 | 생략 | - | 단순 변경이므로 불필요 |
| 프로토타입 | 스킵 | - | |
| Jira 생성 | 오케스트레이터 | - | |

**생략 항목:** 교차 리뷰, 프로토타입, Decision Record (대안 검토 불필요한 수준)

### 보통 (~250K) — 표준 프로세스 (교차 리뷰 통합)

```
Ideator → Planner → Spec → 교차 리뷰 (통합 1개) → 프로토타입 (판정에 따라) → Jira 생성
```

| 단계 | Agent | 모델 | 비고 |
|------|-------|------|------|
| 코드 분석 | Ideator | `model: "sonnet"` | |
| 요구사항 | Planner | `model: "sonnet"` | |
| 설계 | Spec | Opus | Decision Record 포함 |
| 교차 리뷰 | **1개 Agent로 통합** | `model: "sonnet"` | 1차+2차 분리 안 함 |
| 프로토타입 | 판정에 따라 | `model: "sonnet"` | UX 리스크 → 디자인 시안 |
| Jira 생성 | 오케스트레이터 | - | |

### 복잡 (~400K) — 풀 프로세스

```
Ideator (멀티 레포 병렬) → Planner → Spec → 교차 리뷰 → 프로토타입 (PoC/시안) → 사람 확인 → Jira 생성
```

| 단계 | Agent | 모델 | 비고 |
|------|-------|------|------|
| 코드 분석 | Ideator (플랫폼별 병렬) | `model: "sonnet"` | 코드 분석은 Sonnet으로 충분 |
| 요구사항 | Planner | `model: "sonnet"` | |
| 설계 | Spec | Opus | Decision Record 필수. 설계 결정에만 Opus 사용 |
| 교차 리뷰 | 별도 Agent | `model: "sonnet"` | 프로토타입 판정 포함 |
| 프로토타입 | 기술 PoC / 디자인 시안 | Opus | 미확인 항목 검증 |
| 사람 확인 | - | - | 기획 리뷰 CP |
| Jira 생성 | 오케스트레이터 | - | |

---

## 수행할 작업

### 0단계: 복잡도 판별 (오케스트레이터가 직접 수행)

아이디어 텍스트를 분석하여 복잡도를 판별한다:

1. 키워드 분석: 플랫폼 수 (Android/iOS/Web/Backend), 새 기술 언급, 하드웨어 언급
2. 판별 결과를 사용자에게 확인: "이 아이디어는 **보통** 복잡도로 판별했습니다. 맞습니까?"
3. 사용자가 복잡도를 재지정할 수 있다

> **판별 후 해당 복잡도의 프로세스를 따른다.**

### 1단계: Ideator Agent 실행

`.claude/agents/ideator.md`의 역할 정의에 따라 subagent를 실행한다.

**실행 방법:**
```
Agent(
    description: "Ideator — 아이디어 분석 + 코드 분석",
    subagent_type: "Explore",
    prompt: "
        You are Ideator AI. [.claude/agents/ideator.md 전문을 읽어서 프롬프트에 포함]

        ## 아이디어
        {$ARGUMENTS}

        ## 레포 레지스트리
        {CLAUDE.md의 레포 레지스트리 내용}

        ## 에픽 키 (산출물 경로)
        artifacts/{임시키}/00_idea/

        산출물을 artifacts/{임시키}/00_idea/codebase_analysis.md 에 저장하라.
    "
)
```

**멀티 레포 병렬 분석:**
대상 레포가 2개 이상일 때 (예: Android + iOS), 레포별로 별도 Agent를 **동시에** 실행한다:
```
# 단일 메시지에서 2개 Agent 동시 실행
Agent(description: "Ideator — Android 코드 분석", subagent_type: "Explore", run_in_background: true, prompt: "...")
Agent(description: "Ideator — iOS 코드 분석", subagent_type: "Explore", run_in_background: true, prompt: "...")

# tmux split pane으로 진행 상황 표시
```
병렬 Agent 완료 후, 오케스트레이터가 결과를 통합하여 `codebase_analysis.md`에 저장한다.

#### ✅ 1단계 게이트 — 오케스트레이터가 검증

Agent 완료 후 `artifacts/{에픽키}/00_idea/codebase_analysis.md`를 읽어 다음을 확인한다:

- [ ] 대상 레포가 결정되었고, 레포가 로컬에 존재하는지 확인되었다
- [ ] 관련 핵심 기능의 실행 흐름이 **실제 코드 파일:라인**으로 추적되었다
- [ ] 관련 데이터 모델과 저장소가 파악되었다
- [ ] 서버 API 호출 지점이 확인되어 백엔드 변경 필요 여부가 **코드 근거로** 판단되었다
- [ ] 재사용 가능한 기존 코드가 목록화되었다
- [ ] 기술 제약 주장에 **WebSearch 검증 결과** 또는 **코드 라인 근거**가 명시되었다 (없으면 "미확인")
- [ ] **근거 실제 검증**: 사전학습 지식(통념)만으로 적은 근거는 "미확인"으로 되어 있다. "✅ 확인"은 WebSearch/코드 열람을 실제로 수행한 경우에만 허용
- [ ] **"불가능" 판정 검증**: "불가능"으로 판정된 항목이 있으면 오케스트레이터가 다음을 확인한다:
  - WebSearch로 검증했는가? (검색어와 결과가 기술 제약 테이블에 있는지)
  - 코드베이스에서 유사 패턴이 동작하고 있지 않은지 Grep으로 검색했는가?
  - 검증 불확실한 항목이 "미확인 — PoC 필요"로 표기되어 있는가? ("불가능" 확정이 아닌지)
  - 위 조건이 미충족이면 Agent를 재실행한다
- [ ] 사람에게 던지는 질문이 있다면, "코드에서 답할 수 있는가?"가 확인되었다

> **하나라도 미충족이면 Agent를 재실행하여 보완한다. 게이트를 통과하지 않고 2단계로 넘어가지 않는다.**

---

### 2단계: Planner Agent 실행

`.claude/agents/planner.md`의 역할 정의에 따라 subagent를 실행한다.

**실행 방법:**
```
Agent(
    description: "Planner — 요구사항 확장 + 작업 분해",
    subagent_type: "Explore",
    prompt: "
        You are Planner AI. [.claude/agents/planner.md 전문을 읽어서 프롬프트에 포함]

        ## 이전 단계 산출물
        [artifacts/{에픽키}/00_idea/codebase_analysis.md 내용을 읽어서 포함]

        ## 원본 아이디어
        {$ARGUMENTS}

        ## 수행할 작업
        1. 코드 분석 결과를 바탕으로 요구사항을 구체화한다
        2. 인수 조건을 상세하게 정의한다 (검증 가능한 형태)
        3. 작업을 플랫폼별 스토리로 분해한다
        4. 스토리 간 의존성을 설정한다
        5. risk_level을 판정한다 (06_jira_template.md 기준)

        산출물을 artifacts/{에픽키}/00_idea/plan.md 에 저장하라.
    "
)
```

#### ✅ 2단계 게이트 — 오케스트레이터가 검증

Agent 완료 후 `artifacts/{에픽키}/00_idea/plan.md`를 읽어 다음을 확인한다:

- [ ] 모든 요구사항이 1단계 코드 분석에 기반하고 있다 (추측 기반 요구사항 없음)
- [ ] 인수 조건이 전부 **객관적으로 검증 가능한 형태**이다
- [ ] 작업 분해가 플랫폼별로 되어 있고, 의존성이 명시되어 있다
- [ ] risk_level 판정에 06_jira_template.md 기준표를 적용했고, 해당하는 조건을 명시했다

> **하나라도 미충족이면 Agent를 재실행하여 보완한다. 게이트를 통과하지 않고 3단계로 넘어가지 않는다.**

---

### 3단계: Spec Agent 실행

`.claude/agents/spec.md`의 역할 정의에 따라 subagent를 실행한다.

**실행 방법:**
```
Agent(
    description: "Spec — 설계 방향 수립",
    subagent_type: "Explore",
    prompt: "
        You are Spec AI. [.claude/agents/spec.md 전문을 읽어서 프롬프트에 포함]

        ## 이전 단계 산출물
        [artifacts/{에픽키}/00_idea/codebase_analysis.md 내용]
        [artifacts/{에픽키}/00_idea/plan.md 내용]

        ## 수행할 작업
        1. 각 스토리별 설계 방향을 정의한다
        2. API 변경이 필요하면 API 스펙 초안
        3. DB 변경이 필요하면 스키마 변경 초안
        4. 플랫폼별 기술 제약사항을 정리한다 (근거 필수)
        5. 코드 분석 기반으로 영향 범위를 구체적으로 명시한다
        6. Decision Record를 작성한다 (주요 결정마다 대안 최소 2개 검토)

        산출물:
        - artifacts/{에픽키}/00_idea/spec.md
        - artifacts/{에픽키}/00_idea/decision_record.md
    "
)
```

#### ✅ 3단계 게이트 — 오케스트레이터가 검증

Agent 완료 후 산출물을 읽어 다음을 확인한다:

- [ ] 영향 범위의 모든 파일/클래스가 **실제 존재하는 경로**이다
- [ ] 기술 제약사항에 **공식 문서 URL 또는 실제 코드 근거**가 첨부되었다
- [ ] **근거 실제 검증**: 추론 기반 근거는 "미확인"으로 되어 있다
- [ ] 설계 방향이 기존 코드의 아키텍처 패턴과 일관된다
- [ ] 재사용 가능한 기존 코드를 설계에 반영했다
- [ ] **Decision Record가 작성되었고**, 모든 주요 결정에 대해 최소 2개 대안이 검토되었다
- [ ] Decision Record의 기각 사유가 **코드/문서 근거 기반**이다

> **하나라도 미충족이면 Agent를 재실행하여 보완한다. 게이트를 통과하지 않고 4단계로 넘어가지 않는다.**

---

### 4단계: 기획서 통합 출력

오케스트레이터가 1~3단계 산출물을 통합하여 기획서를 작성한다 (06_jira_template.md 형식).

**필수 항목:** 제목, 문제/배경, 범위, 기대 결과

**메타 필드:** type, system, risk_level, requires_db_change, requires_api_change, requires_ui_change

**AI 확장 영역:**
- 상세 요구사항 (Requirements)
- 비기능 요구사항 (Non Functional Requirements)
- 인수 조건 (Acceptance Criteria)
- 영향 범위 (Impact Scope)
- 설계 방향 (Design Direction)
- 테스트 전략 (Test Strategy) — 자동 테스트(AI/CI) + QA 테스트 시나리오(수동 검증) 모두 포함
- QA 테스트 시나리오 (QA Test Scenarios) — 사전 조건, 스텝(동작 → 기대 결과), 인수 조건 1:1 매핑
- 작업 분해 (Sub Tasks) — 플랫폼별 스토리 + 의존성
- 배포 참고사항 (Deployment Notes)

기획서를 `artifacts/{에픽키}/00_idea/proposal.md`에 저장한다.

---

### 4.5단계: 자체 검증 (오케스트레이터가 직접 수행)

기획서를 사람에게 보여주기 전에 다음을 **전부** 확인한다:

- [ ] 모든 영향 범위가 실제 파일/클래스 기반인가
- [ ] 기술 제약으로 "불가능"이라고 적은 항목에 **WebSearch 검증 결과**가 있는가
- [ ] **근거가 사전학습 지식이 아닌 실제 검증(WebSearch/코드 열람)인가**
- [ ] 검증 불확실한 항목이 "불가능" 확정이 아니라 "미확인 — PoC 필요"로 되어 있는가
- [ ] 기술 제약으로 "불가능"이라고 적은 항목에 대해 **최소 2가지 우회 방안**을 검토했는가
- [ ] 사람에게 던지는 질문 중 코드 분석으로 답할 수 있는 것이 없는가
- [ ] 인수 조건이 전부 검증 가능한 형태인가
- [ ] 기획서가 완성된 상태인가 (빈 섹션 없이)
- [ ] 기존 서버 API 변경 필요 여부를 코드 기반으로 판단했는가
- [ ] 재사용 가능한 기존 코드를 설계 방향에 반영했는가

> **하나라도 미충족이면 기획서를 보완한 후 다시 체크리스트를 확인한다.**

---

### 4.6단계: AI 교차 리뷰 (별도 Agent로 실행)

**교차 리뷰 실행 규칙:**
- **모델 우선순위**: Codex(OpenAI) > 다른 외부 AI > Sonnet (Sonnet은 최후 수단)
- 같은 모델의 서브에이전트는 독립 검증으로 인정하지 않는다
- 사용한 모델을 산출물에 반드시 명시한다

**실행 방법:**

Codex CLI가 설치되어 있으면:
```bash
codex --approval-mode full-auto "아래 기획서를 검증하라: [proposal.md 내용]"
```

설치되어 있지 않으면 별도 Agent로 실행:
```
Agent(
    description: "교차 리뷰 — 기획서 독립 검증",
    subagent_type: "Explore",
    prompt: "
        You are an independent reviewer. 아래 기획서를 **독립적으로** 검증하라.

        ## 검증 항목
        1. **근본 설계 방향 도전** (최우선): 대안 아키텍처 최소 1개 제시
        2. **Decision Record 검증**: 대안 충분성, 기각 사유 납득 여부, 누락 대안
        3. **기술 제약 검증** (필수): "불가능"으로 판정된 항목마다 WebSearch로 독립 검증한다. 사전학습 지식과 다른 결과가 나오면 FAIL 판정. "✅ 확인"으로 표기된 항목의 근거(URL/코드라인)가 실제로 유효한지 확인
        4. 코드 분석 정합성: 영향 범위 파일/클래스 실존 여부
        5. 설계 방향 타당성: 기존 코드 패턴 일관성
        6. 인수 조건 완전성: 누락 인수 조건
        7. 불필요한 질문: 코드에서 답할 수 있는 질문
        8. **프로토타입 필요성 판정**: 아래 기준으로 PoC/디자인 시안 필요 여부를 판정하라
           - 기술 리스크: '미확인' 항목이 있거나, 새 SDK/하드웨어/OS API 사용 → **기술 검증 PoC 필요**
           - UX 리스크: 새 화면/흐름이 있거나, 사용자 판단 경로가 복잡 → **디자인 시안 필요**
           - 둘 다 해당 → **둘 다 필요**
           - 둘 다 아님 (기존 패턴 반복) → **스킵 가능**
           반드시 [프로토타입 판정] 섹션에 결과를 명시하라

        ## 기획서
        [proposal.md 내용]

        ## 코드 분석
        [codebase_analysis.md 내용]

        산출물을 artifacts/{에픽키}/00_idea/cross_review.md 에 저장하라.
        각 검증 항목에 PASS/FAIL 판정을 명시하라.
    "
)
```

**반려 시:** 반려 사유를 기반으로 기획서를 **부분 수정** → 재리뷰 (최대 2회). FAIL 항목에 해당하는 섹션만 Edit으로 수정한다. 전체 재작성 금지.

#### ✅ 4.6단계 게이트

- [ ] 교차 리뷰를 **다른 모델 또는 별개 에이전트**로 실행했다
- [ ] 2차 리뷰어의 검증 항목에 대해 **각각 PASS/FAIL 결과**가 나왔다
- [ ] FAIL 항목이 있었다면, 기획서를 수정하고 **재리뷰를 통과**했다
- [ ] 교차 리뷰 결과가 `artifacts/{에픽키}/00_idea/cross_review.md`에 저장되었다
- [ ] **프로토타입 판정**이 명시되었다 (기술 PoC / 디자인 시안 / 둘 다 / 스킵)

> **하나라도 미충족이면 보완 후 재검증한다.**

---

### 4.7단계: 프로토타입 실행 (교차 리뷰 판정에 따라)

교차 리뷰의 `[프로토타입 판정]`에 따라 실행한다. **스킵 판정이면 5단계로 바로 넘어간다.**

#### 기술 검증 PoC (기술 리스크 있을 때)

미확인 항목을 **최소 코드**로 검증한다. 기능 구현이 아니라 "되는지/안 되는지"만 확인한다.

```
Agent(
    description: "기술 검증 PoC — 미확인 항목 검증",
    subagent_type: "general-purpose",
    prompt: "
        기획서의 미확인 항목을 최소 코드로 검증하라.

        ## 미확인 항목
        [codebase_analysis.md 또는 spec.md의 미확인 항목 목록]

        ## 대상 레포
        {로컬 경로}

        ## 규칙
        - 각 항목에 대해 최소 코드를 작성하여 빌드/실행한다
        - 결과: '검증됨 (코드 근거)' 또는 '불가 → 대안 제시'
        - PoC 코드는 별도 브랜치에 작성 (poc/{에픽키})
        - PoC 코드는 버린다 (본 개발에서 재작성)

        산출물을 artifacts/{에픽키}/00_idea/poc_result.md 에 저장하라.
    "
)
```

**PoC 결과 반영:**
- 검증됨 → 기획서 미확인 항목을 "확인됨"으로 업데이트
- 불가 → 대안으로 설계 방향 수정 + Decision Record 업데이트

#### 디자인 시안 (UX 리스크 있을 때)

새 화면/흐름에 대해 **구조가 다른 시안 2~3개**를 생성한다.

**도구 우선순위:**
1. **Google Stitch MCP** (1순위) — 토큰 절약 + 고퀄리티 UI
2. **Agent HTML 생성** (폴백) — Stitch MCP 미설정 시

##### 방법 1: Google Stitch MCP (권장)

Stitch MCP 서버가 `.claude/settings.json`에 설정되어 있으면 이 방법을 사용한다.

```
# Stitch MCP 도구로 시안 생성
# 프롬프트에 기획서의 UI 요구사항을 전달하여 2~3개 시안 요청

Stitch 프롬프트 예시:
"모바일 앱 위젯 디자인. 카드 상태 표시 + 문열기 버튼 1개.
상태별 UI: READY(파란색 버튼) / CONNECTING(로딩) / SUCCESS(초록 체크) / FAILURE(빨간 X).
특수 상태: 로그아웃('로그인 필요'), 카드 없음('등록된 카드 없음').
구조가 다른 시안 3개: A) 단일 버튼 집중형 B) 리스트형 C) 카드형.
Android 위젯 2x1 + iOS .systemSmall 크기. 다크모드 포함."
```

- Stitch가 생성한 시안을 `artifacts/{에픽키}/00_idea/design_proposal.html`로 내보내기
- 시안 설명을 `artifacts/{에픽키}/00_idea/design_proposal.md`에 작성

##### 방법 2: Agent HTML 생성 (폴백)

Stitch MCP가 설정되어 있지 않으면 기존 방식으로 Agent를 실행한다.

```
Agent(
    description: "디자인 시안 — UI/UX 시안 생성",
    subagent_type: "general-purpose",
    prompt: "
        기획서의 UI/UX를 HTML 시안으로 생성하라.

        ## 기획서
        [proposal.md 내용]

        ## 규칙
        - 색상 변형이 아닌 **레이아웃·정보계층·인터랙션이 다른** 시안 2~3개
        - 각 시안의 설계 의도와 장단점을 명시
        - 사람이 선택할 수 있도록 비교 가능한 형태

        산출물:
        - artifacts/{에픽키}/00_idea/design_proposal.html (시안)
        - artifacts/{에픽키}/00_idea/design_proposal.md (설명)
    "
)
```

**시안 선택:** 사람이 시안을 선택하면 기획서에 반영

#### ✅ 4.7단계 게이트

- [ ] 프로토타입 판정이 "스킵"이면 이 단계를 건너뛴다
- [ ] 기술 PoC 필요 시: 모든 미확인 항목이 "검증됨" 또는 "불가 → 대안 적용됨" 상태
- [ ] 디자인 시안 필요 시: 시안이 생성되고 사람의 선택을 받았다
- [ ] 프로토타입 결과가 기획서(proposal.md)와 설계(spec.md)에 반영되었다

> **미확인 항목이 남아있으면 5단계로 넘어가지 않는다.**

---

### 5단계: 기획 리뷰 (CP — 사람 확인)

교차 리뷰를 통과한 기획서를 화면에 출력하고 사람의 리뷰를 받는다.

리뷰 관점:
- 요구사항이 충분한가
- 인수 조건이 검증 가능한가
- 설계 방향이 적절한가
- 작업 분해와 의존성이 맞는가
- risk_level 판정이 적절한가
- **Decision Record**: 대안이 충분한가, 기각 사유가 납득 가능한가

기획서 출력 시 **Decision Record 요약**을 함께 출력한다.

**피드백 반영 시 부분 수정 원칙:**
사람이 수정 요청을 하면, 산출물을 처음부터 다시 작성하지 않는다.
1. 피드백의 영향 범위를 먼저 파악한다 (어떤 DR, 어떤 섹션이 변경되는지)
2. 해당 섹션만 Edit으로 수정한다 (spec.md의 시퀀스, decision_record.md의 해당 DR, proposal.md의 해당 섹션)
3. 변경하지 않는 섹션은 그대로 유지한다
4. 수정 후 교차 리뷰 재실행 시에도, 변경된 부분을 명시하여 전체 재검토가 아닌 변경 부분 중심 검토를 요청한다

> **사람의 명시적 승인 없이 6단계로 넘어가지 않는다.**

---

### 6단계: Jira 카드 생성

사람이 승인하면 Jira에 카드를 생성한다:
- 프로젝트 키를 사람에게 확인한다
- 에픽 + 하위 스토리 구조로 생성한다
- 에픽 description에 필수 항목 + 메타 필드 + AI 확장 영역을 전부 포함한다
- 각 스토리 description에 해당 플랫폼의 설계 방향 + 작업 내용을 포함한다
- labels에 "ai-generated"를 추가한다

**스토리 세분화 원칙:**
- **에픽 하위 스토리는 플랫폼별(Android/iOS/Backend/Web) 1개씩만 생성**한다
- 작업 분해(Sub Tasks) 항목을 별도 Jira 스토리로 만들지 않는다
- 세부 작업 내용은 스토리 description의 "작업 내용" 섹션에 bullet list로 포함한다
- 예: "위젯 추가" 에픽 → "[Android] 위젯 구현" 1개 + "[iOS] 위젯 구현" 1개

#### ✅ 6단계 게이트

- [ ] Jira 에픽이 생성되었고, 에픽 키를 확인했다
- [ ] 하위 스토리가 **플랫폼별 1개씩** 생성되었다 (작업 분해 항목별로 쪼개지 않았다)
- [ ] 에픽 description에 기획서 전체 내용이 포함되어 있다
- [ ] 각 스토리 description에 해당 플랫폼의 설계 방향 + 작업 내용이 포함되어 있다
- [ ] 모든 카드에 "ai-generated" 라벨이 추가되었다
- [ ] 산출물 파일이 모두 저장되었다

---

## 산출물

### 화면 출력
- 기획서 (06_jira_template.md 형식)
- 추가 질문이 있으면 함께 출력

### 파일
- `artifacts/{에픽키}/00_idea/codebase_analysis.md` — 코드 분석 결과 (Ideator Agent)
- `artifacts/{에픽키}/00_idea/plan.md` — 요구사항 + 작업 분해 (Planner Agent)
- `artifacts/{에픽키}/00_idea/spec.md` — 설계 방향 (Spec Agent)
- `artifacts/{에픽키}/00_idea/decision_record.md` — 설계 결정 기록 (Spec Agent)
- `artifacts/{에픽키}/00_idea/proposal.md` — 기획서 원문 (오케스트레이터 통합)
- `artifacts/{에픽키}/00_idea/cross_review.md` — AI 교차 리뷰 결과
- `artifacts/{에픽키}/00_idea/idea_report.md` — 실행 보고서

### Jira
- 에픽 + 스토리 카드 (상세한 상태로 생성)

## 다음 단계

개발자가 `/in-progress {스토리키}`로 개발 플로우를 시작한다.
