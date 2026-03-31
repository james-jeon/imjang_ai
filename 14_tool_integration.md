# 도구 연동 및 실현 가능성

## 목적

AI Agent들이 실제로 어떤 도구를 통해 실행되고, 도구 간 어떻게 연동되는지를 정의한다.
또한 각 구성 요소의 실현 가능성을 평가하여 도입 시 예상되는 제약과 대응 방안을 명시한다.

---

## Agent별 실행 도구

| Agent | 실행 도구 | 호출 방식 |
|-------|----------|----------|
| Planner AI | Claude CLI (custom agent) | `claude --agent planner --print` |
| Spec AI | Claude CLI (custom agent) | `claude --agent spec --print` |
| Designer AI | Claude CLI (custom agent) | `claude --agent designer --print` |
| Test AI | Claude CLI (custom agent) | `claude --agent tester --print` |
| Dev AI | Claude CLI (team mode) | `claude --agent developer` (팀 모드로 병렬 작업) |
| Review AI (1차) | Claude CLI (custom agent) | `claude --agent reviewer --print` |
| Review AI (2차) | Codex CLI | `codex --approval-mode full-auto` |
| Release AI | Claude CLI (custom agent) | `claude --agent release --print` |
| Domain Expert AI | Claude CLI (custom agent) | `claude --agent domain-expert --print` (다른 Agent가 필요 시 호출) |

---

## Claude CLI Agent 정의

각 Agent는 `.claude/agents/` 디렉토리에 마크다운 파일로 정의한다.

```
.claude/agents/
├── planner.md      # Jira 분석, 요구사항 확장, 작업 분해
├── spec.md         # 설계 문서, API/DB 스펙 생성
├── designer.md     # UI/UX 와이어프레임, 비주얼 디자인 코드
├── tester.md       # 테스트 케이스, 테스트 코드 생성
├── developer.md    # 코드 구현 (팀 모드 지원)
├── reviewer.md      # 코드 리뷰 (읽기 전용)
├── release.md       # 릴리즈 산출물 생성
└── domain-expert.md # 도메인 지식 관리 (상시 에이전트)
```

### Agent별 도구 접근 권한

| Agent | Read | Write/Edit | Bash | Git | 외부 API |
|-------|:----:|:----------:|:----:|:---:|:-------:|
| Planner AI | O | O (산출물만) | X | X | Jira API |
| Spec AI | O | O (산출물만) | X | X | X |
| Designer AI | O | O | O (빌드 확인) | X | X |
| Test AI | O | O | O (테스트 실행) | X | X |
| Dev AI | O | O | O | O | X |
| Review AI | O | X | O (분석만) | X | X |
| Release AI | O | O | O | O | Jira API, GitHub API |
| Domain Expert AI | O | O (도메인 문서만) | X | X | X |

### Agent 프롬프트 구조

각 Agent의 `.md` 파일은 다음 구조를 따른다:

```markdown
# {Agent 이름}

## 역할
(이 Agent가 수행하는 작업 정의)

## 입력
(이전 Agent의 산출물 경로와 형식)

## 출력
(생성해야 하는 산출물과 저장 경로)

## 제약 조건
(변경하면 안 되는 영역, 가드레일 규칙)

## 출력 형식
(13_output_format에 정의된 형식 준수)
```

---

## Dev AI 팀 모드 구성

멀티 플랫폼 작업 시 Dev AI는 Claude CLI 팀 모드로 동작한다.

```
Dev AI (팀 리더)
├── backend-dev (teammate) → 백엔드 API, 서버 코드
├── web-dev (teammate) → 프론트엔드 코드
└── app-dev (teammate) → 네이티브 앱 코드
```

- 팀 리더가 Planner AI의 작업 분해를 기반으로 태스크를 분배한다
- 백엔드 API가 먼저 완료된 후 앱/웹 작업이 병렬 진행된다
- 각 teammate는 자신의 플랫폼 코드만 수정한다

---

## Review AI 교차 리뷰 구조

코드 리뷰는 두 단계로 진행하여 단일 모델의 맹점을 보완한다.

```
Dev AI 코드 완료
    ↓
1차 리뷰: Claude CLI (reviewer agent)
    - 구조, 로직, 요구사항 충족, 가드레일 위반 검사
    - 리뷰 결과를 artifacts/{ticket_id}/07_review/claude_review.md에 저장
    ↓
2차 리뷰: Codex CLI
    - 보안, 성능, 엣지 케이스, 코드 스타일 검사
    - 리뷰 결과를 artifacts/{ticket_id}/07_review/codex_review.md에 저장
    ↓
오케스트레이터가 두 리뷰 결과를 종합
    - 둘 다 승인 → 통과
    - 하나라도 반려 → 반려 사유를 Dev AI에 전달
```

### Codex CLI 활용 방식

- `codex` 명령어로 PR diff를 입력하여 리뷰를 수행한다
- `--approval-mode full-auto` 모드로 읽기 전용 분석을 실행한다
- 출력은 마크다운 형식으로 저장한다

---

## 오케스트레이터 ↔ 도구 연동

### 전체 연동 흐름

```
[Jira] ──webhook──→ [오케스트레이터 (상태 머신 + DB)]
                          │
                          ├── 단계 확인 → Agent 선택
                          │
                          ├── Claude CLI 호출 (해당 agent + 산출물 경로)
                          │   └── 결과 → artifacts/ 저장
                          │
                          ├── CP 지점 → Jira 코멘트 + Slack 알림 → 승인 대기
                          │
                          ├── Review 단계 → Claude CLI + Codex CLI 순차 호출
                          │
                          ├── CI/CD → GitHub Actions 트리거
                          │   └── 실패 시 → Claude CLI로 자동 수정 시도
                          │
                          └── 배포 완료 → 안정화 모니터링 활성화
```

### 오케스트레이터의 Agent 호출 방식

오케스트레이터는 CLI 도구를 프로그래매틱하게 호출한다.

```
# Claude CLI 호출 예시
claude --agent planner --print \
  --input "artifacts/{ticket_id}/jira_ticket.json" \
  > "artifacts/{ticket_id}/01_planner/requirements.md"

# Codex CLI 호출 예시
codex --approval-mode full-auto \
  "이 PR의 코드를 리뷰해주세요: {pr_diff}" \
  > "artifacts/{ticket_id}/07_review/codex_review.md"
```

### 상태 동기화

세 가지 상태를 일치시켜야 한다:

| 상태 소스 | 역할 | 동기화 방법 |
|----------|------|-----------|
| Jira 티켓 상태 | 사람이 보는 진행 상태 | 오케스트레이터가 단계 전이 시 Jira API로 업데이트 |
| 오케스트레이터 DB | 워크플로 실행 상태 | 중앙 진실 소스 (source of truth) |
| Git branch | 코드 변경 상태 | Dev AI가 branch 생성/커밋, 오케스트레이터가 PR 생성 |

---

## Claude Code 실행 가이드

Claude Code CLI에서 에이전트 파이프라인을 실행하는 표준 절차를 정의한다.
**모든 티켓은 이 절차에 따라 에이전트를 분리 실행한다.**

### 실행 원칙

| 원칙 | 설명 |
|------|------|
| **에이전트 분리** | 각 Agent는 `Agent` 도구(subagent)로 분리 실행한다. 하나의 세션에서 모든 역할을 수행하지 않는다 |
| **순차 의존성** | 이전 Agent의 산출물이 다음 Agent의 입력이 된다. 산출물 파일이 생성되어야 다음 단계로 진행한다 |
| **병렬 실행** | 의존성이 없는 Agent는 동시에 실행한다 (예: Dev iOS + Dev Android, 코드 분석 Android + iOS) |
| **tmux 시각화** | 병렬 Agent 실행 시 tmux split pane으로 진행 상황을 실시간 표시한다 |
| **산출물 검증** | 각 Agent 완료 시 산출물 파일 존재 여부를 확인한 후 다음 단계로 진행한다 |
| **교차 리뷰** | 기획(4.6단계) / 테스트(CP2.5) / 코드(CP3) 각 단계에서 2차 AI가 독립 검증한다 |

### 실행 도구: Agent (subagent)

Claude Code의 `Agent` 도구를 사용하여 subagent를 생성한다.

```
Agent(
    description: "Analyze Android BLE flow",
    subagent_type: "Explore",           # 분석: Explore / 구현: general-purpose
    prompt: "...",                       # Agent별 상세 프롬프트
    run_in_background: true             # 병렬 실행 시
)
```

| 파라미터 | 용도 |
|---------|------|
| `subagent_type: "Explore"` | 코드 분석, 탐색 (읽기 전용) — Planner, Spec, Reviewer 단계 |
| `subagent_type: "general-purpose"` | 코드 구현, 빌드, 테스트 실행 — Dev, Test 단계 |
| `run_in_background: true` | 병렬 실행 시 사용. 완료 시 자동 알림 |
| `isolation: "worktree"` | 병렬 구현 시 git worktree로 격리 (Dev iOS + Android 동시 작업) |

### tmux 시각화

병렬 Agent 실행 시 tmux split pane으로 진행 상황을 실시간 표시한다.
사용자가 각 Agent의 작업 진행을 시각적으로 확인할 수 있다.

#### tmux 레이아웃

```
# 병렬 분석 (예: Android + iOS 코드 분석)
┌──────────────────┬──────────────────┐
│ Claude Code      │  iOS 분석         │
│ (메인 세션)       │  tail -f output   │
├──────────────────┤                   │
│ Android 분석      │                   │
│ tail -f output   │                   │
└──────────────────┴──────────────────┘

# 병렬 구현 (예: Dev iOS + Dev Android)
┌──────────────────┬──────────────────┐
│ Claude Code      │  Dev Android      │
│ (메인 세션)       │  tail -f output   │
├──────────────────┤                   │
│ Dev iOS          │                   │
│ tail -f output   │                   │
└──────────────────┴──────────────────┘
```

#### tmux 명령어 패턴

```bash
# Agent 실행 후 output 파일 경로를 받아 tmux pane에 표시
tmux split-window -h "tail -f '{agent_output_file}'"
tmux select-pane -L
tmux split-window -v "tail -f '{agent_output_file}'"
tmux select-pane -U

# Agent 완료 후 pane 정리
tmux kill-pane -t {pane_id}
```

### 태스크 의존성 구조

```
#1 Planner AI
    ↓ (blocks #2)
#2 Spec AI
    ↓ (blocks #3)
#3 Test AI
    ↓ (blocks #4, #5)
#4 Dev AI (iOS)  ──┐
#5 Dev AI (Android)┤ (병렬, 둘 다 blocks #6)
                   ↓
#6 Review AI
```

Designer AI가 필요한 경우 (`requires_ui_change == yes`):
```
#1 Planner → #2 Spec → #2.5 Designer(와이어프레임) → #3 Test → #4/#5 Dev 병렬 → #5.5 Designer(비주얼) → #6 Review
```

### Agent 실행 절차

#### 1. 순차 실행 (의존성 있는 단계)

```
Agent(subagent_type: "Explore", prompt: "Planner 역할: ...")
    ↓ 완료 + 산출물 확인
Agent(subagent_type: "Explore", prompt: "Spec 역할: ...")
    ↓ 완료 + 산출물 확인
Agent(subagent_type: "general-purpose", prompt: "Test 역할: ...")
```

#### 2. 병렬 실행 (의존성 없는 단계)

하나의 메시지에서 여러 Agent를 동시에 호출한다:

```
# 단일 메시지에서 2개 Agent 동시 실행
Agent(description: "Dev iOS", run_in_background: true, prompt: "...")
Agent(description: "Dev Android", run_in_background: true, prompt: "...")

# tmux split pane으로 진행 상황 표시
tmux split-window -h "tail -f {ios_output}"
tmux split-window -v "tail -f {android_output}"

# 둘 다 완료 알림 수신 후 → Review AI 시작
```

#### 3. 교차 리뷰 실행

기획/테스트/코드 리뷰에서 2차 AI 검증을 수행한다:

```
# 1차: Claude Agent로 리뷰
Agent(subagent_type: "Explore", prompt: "1차 리뷰어 역할: ...")
    ↓
# 2차: 별도 Agent 또는 Codex CLI로 독립 리뷰
Agent(subagent_type: "Explore", prompt: "2차 리뷰어 역할: 1차 리뷰와 독립적으로 ...")
    ↓
# 두 리뷰 결과 종합 → 승인/반려 판정
```

### Agent별 프롬프트 구조

각 Agent 프롬프트에 반드시 포함해야 하는 항목:

| 항목 | 설명 |
|------|------|
| **역할 선언** | "You are {Agent명} for ticket {ticket_id}" |
| **입력 파일 경로** | 이전 Agent 산출물의 절대 경로 |
| **분석 대상** | 레포 로컬 경로, SDK 경로 등 |
| **수행할 작업** | 구체적인 체크리스트 |
| **출력 파일 경로** | 산출물을 저장할 절대 경로 |
| **출력 형식** | 13_output_format.md의 해당 Agent 형식 참조 |

### 산출물 경로 규칙

```
artifacts/{ticket_id}/
├── 01_planner/requirements.md          # Planner AI
├── 02_spec/design_doc.md               # Spec AI
├── 02.5_prototype/prototype_summary.md # 프로토타입 (조건부)
├── 03_designer_1/wireframe.md          # Designer AI 1차 (조건부)
├── 04_test/test_cases.md               # Test AI
├── 04_test/ios/                        # iOS 테스트 코드
├── 04_test/android/                    # Android 테스트 코드
├── 05_dev/change_summary_ios.md        # Dev AI (iOS)
├── 05_dev/change_summary_android.md    # Dev AI (Android)
├── 06_designer_2/visual_spec.md        # Designer AI 2차 (조건부)
├── 07_review/claude_review.md          # Review AI (1차)
├── 07_review/codex_review.md           # Review AI (2차)
├── 07_review/review_summary.md         # Review 종합
└── 08_release/release_notes.md         # Release AI
```

### 실행 예시 (Track A — /idea)

```
사람: /idea 모카키 앱에 위젯 기능을 추가할거야
    ↓
[자동] 대상 레포 결정 (mocakey-android + mocakey-ios)
    ↓
[자동] 코드 심층 분석 — Agent 2개 병렬 + tmux 시각화
       ┌─ Agent(Explore): Android 코드 분석 ─┐
       └─ Agent(Explore): iOS 코드 분석     ─┘
       tmux split-window로 양쪽 진행 상황 표시
    ↓
[자동] 분석 결과 종합 → 기획서 작성
    ↓
[자동] 4.5단계: 자체 검증 (체크리스트 7개 항목)
    ↓
[자동] 4.6단계: AI 교차 리뷰 → cross_review.md
    ↓
사람에게 완성된 기획서 제시 (CP 리뷰)
    ↓
승인 → Jira 카드 자동 생성
```

### 실행 예시 (Track B — /in-progress)

```
사람: /in-progress PCZJ-630
    ↓
[자동] Jira 티켓 조회 + 상태 변경
[자동] artifacts/PCZJ-630/ 디렉토리 생성
    ↓
[자동] Test AI 실행 (Agent, general-purpose)
       → test_cases.md + 테스트 코드 작성
       → CP2.5 교차 리뷰
       → 완료
    ↓
[자동] Dev AI iOS + Android 병렬 실행 + tmux 시각화
       ┌─ Agent(general-purpose): Dev iOS    ─┐  tmux pane 1
       └─ Agent(general-purpose): Dev Android ─┘  tmux pane 2
       → 코드 구현 + change_summary + 빌드 확인
       → 둘 다 완료
    ↓
[자동] Review AI 교차 리뷰 (1차 Claude + 2차 독립 Agent)
       → review_summary.md
       → 승인/반려 판정
    ↓
사람에게 결과 보고
```

### 주의사항

- **에이전트는 반드시 분리 실행한다.** 하나의 세션에서 Planner→Spec→Dev를 순차적으로 수행하면 컨텍스트가 오염되고, 역할 분리가 무너진다.
- **산출물 파일 기반 인터페이스.** Agent 간 데이터 전달은 반드시 파일(artifacts/)을 통한다. 인메모리 전달을 하지 않는다.
- **병렬 Agent 실행 시 tmux 시각화를 기본으로 한다.** 사용자가 진행 상황을 실시간 확인할 수 있어야 한다.
- **빌드 검증은 Dev AI가 수행한다.** 구현 후 xcodebuild/gradle로 빌드를 시도하고, 결과를 change_summary에 기록한다.
- **Review AI는 읽기 전용이다.** 코드를 수정하지 않고, 승인/반려만 판정한다.
- **반려 시 재작업 루프.** Review AI가 반려하면 Dev AI를 다시 생성하여 수정 사항을 전달한다 (최대 3회, 이후 에스컬레이션).

---

## 앱 CI/CD 구현 현황

### GitHub Actions 워크플로우

| 워크플로우 | 파일 | 트리거 | 역할 |
|-----------|------|--------|------|
| Android CI | `.github/workflows/ci.yml` | PR/push (main, develop) | lint → 단위 테스트 → APK 빌드 |
| Android Release | `.github/workflows/release.yml` | workflow_dispatch | AAB 빌드 → Play Store 업로드 (track 선택) |
| iOS CI | `.github/workflows/ci.yml` | PR/push (main, develop) | CocoaPods → Xcode 빌드 |
| iOS Release | `.github/workflows/release.yml` | workflow_dispatch | match 인증서 → 빌드 → TestFlight 업로드 |

### fastlane 직접 실행

| 플랫폼 | 명령 | 역할 |
|--------|------|------|
| Android | `fastlane fad` | Firebase App Distribution 배포 |
| Android | `fastlane playstore track:{track}` | Play Store 업로드 (internal/alpha/beta/production) |
| iOS | `fastlane fad` | 빌드 → TestFlight 업로드 |

### 필요한 시크릿 (GitHub Actions)

| 플랫폼 | 시크릿 | 용도 |
|--------|--------|------|
| Android | `KEYSTORE_BASE64` | 서명 키스토어 (base64 인코딩) |
| Android | `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` | 서명 정보 |
| Android | `PLAY_STORE_KEY_JSON` | Google Play Console 서비스 계정 키 |
| iOS | `APP_STORE_CONNECT_API_KEY_JSON` | App Store Connect API 키 |
| iOS | `MATCH_SSH_KEY` | fastlane match 인증서 저장소 SSH 키 |

---

## 실현 가능성 평가

### 바로 가능한 영역

| 구성 요소 | 가능 이유 | 신뢰도 |
|----------|----------|:------:|
| Planner AI | 텍스트 분석 + 구조화 — LLM의 강점 | 높음 |
| Spec AI | 설계 문서 생성 — 패턴화된 작업 | 높음 |
| Test AI | 테스트 코드 생성 — 이미 실용 수준 | 높음 |
| Dev AI (단일 플랫폼) | 코드 생성/수정 — Claude CLI로 검증됨 | 높음 |
| Review AI (Claude) | 코드 리뷰 — 정적 분석 + 로직 검증 | 높음 |
| Release AI | 문서 생성 — 패턴화된 텍스트 작업 | 높음 |
| Jira API 연동 | REST API — 표준 연동. 06_jira_template의 생성 방법 참조 | 높음 |
| Jira MCP Server | Claude CLI MCP 연동 — Agent가 Jira를 도구로 사용 | 높음 |
| GitHub Actions 연동 | webhook + API — 표준 연동 | 높음 |

### 가능하지만 엔지니어링 필요

| 구성 요소 | 필요한 작업 | 예상 난이도 |
|----------|-----------|:----------:|
| 오케스트레이터 (상태 머신) | 상태 전이 로직, DB 설계, webhook 수신, CLI 호출 래퍼 | 중간 |
| Dev AI (팀 모드) | 멀티 플랫폼 병렬 작업 시 태스크 분배 및 충돌 방지 | 중간 |
| Codex CLI 교차 리뷰 | 출력 형식 통일, 두 리뷰 결과 종합 로직 | 낮음 |
| 산출물 컨텍스트 주입 | Agent 호출 시 이전 산출물을 프롬프트에 포함, 컨텍스트 크기 관리 | 중간 |
| Human Checkpoint UX | Jira 코멘트 + Slack 버튼으로 승인/거부 수신 | 중간 |

### 주의가 필요한 영역

| 구성 요소 | 위험 요소 | 대응 방안 |
|----------|----------|----------|
| Designer AI | 코드 기반 UI 생성의 비주얼 품질 한계 | 기존 디자인 시스템/컴포넌트를 필수 입력으로 제공하여 일관성 확보. 새로운 UI 패턴은 사람 검토 필수 |
| 엔드투엔드 성공률 | Agent 체인이 길어 누적 실패 가능성 (7단계 × 90% = 약 48%) | 각 단계별 검증 + 재시도로 단계별 성공률을 95% 이상으로 올려야 함. 초기에는 사람이 자주 개입하면서 프롬프트를 개선 |
| 컨텍스트 크기 제한 | 누적 산출물이 컨텍스트 윈도우 초과 가능 | 단계별로 요약본만 전달, 전체 산출물은 파일 경로로 참조 |
| CI/CD 자동 수정 | 통합 테스트/부하 테스트 실패는 단순 코드 수정으로 해결 안 되는 경우 많음 | 단위 테스트/린트 실패만 자동 수정 대상으로 제한. 복잡한 실패는 바로 에스컬레이션 |
| 상태 동기화 | Jira/DB/Git 3개 상태 불일치 가능성 | 오케스트레이터 DB를 유일한 진실 소스로. Jira/Git은 DB 기반 단방향 업데이트 |

---

## 현실적 기대치

### 작업 유형별 자동화 수준 예측

| 작업 유형 | 자동화 예상 비율 | 사람 개입 빈도 |
|----------|:--------------:|:------------:|
| low risk + 단일 플랫폼 (예: 버그 수정) | 80~90% | CP1, CP4만 |
| medium risk + 단일 플랫폼 (예: 기능 추가) | 60~70% | CP1~CP4 + 간헐적 리뷰 |
| high risk + 멀티 플랫폼 (예: 결제 기능) | 30~40% | 거의 모든 CP + 수시 개입 |
| UI 변경 포함 작업 | 50~60% | 1차/2차 디자인 검토 필수 |

### 도입 초기 vs 안정화 후

- **도입 초기 (1~3개월)**: Agent 프롬프트 품질이 낮아 에스컬레이션이 잦을 것으로 예상. 사람이 결과를 자주 확인하면서 프롬프트를 반복 개선해야 한다. 이 기간의 핵심은 **프롬프트 튜닝과 산출물 형식 안정화**이다.
- **안정화 후 (3~6개월)**: 반복 작업 패턴이 학습되면서 low/medium risk 작업은 대부분 자동 처리 가능. 사람은 high risk 작업과 새로운 유형의 작업에만 집중하게 된다.

### 자동화가 어려워 사람이 계속 필요한 영역

- 비즈니스 요구사항 판단 (무엇을 만들지)
- 아키텍처 의사결정 (시스템 전체 구조 변경)
- 새로운 UX 패턴 도입 여부
- 프로덕션 배포 최종 승인
- 장애 대응 시 우선순위 판단

---

## 권장 도입 순서

현재 문서 체계가 갖춰진 상태에서 실제 구현 순서:

| 순서 | 내용 | 선행 조건 |
|:----:|------|----------|
| 1 | Claude CLI Agent 프롬프트 작성 (.claude/agents/*.md) | 프로젝트 코드베이스 존재 |
| 2 | Planner AI + Spec AI 단독 실행 테스트 | Agent 프롬프트 완성 |
| 3 | Test AI + Dev AI 단독 실행 테스트 | Agent 프롬프트 완성 |
| 4 | Review AI (Claude + Codex) 교차 리뷰 테스트 | Codex CLI 환경 구성 |
| 5 | 오케스트레이터 MVP 구현 (상태 머신 + DB) | 개별 Agent 검증 완료 |
| 6 | Jira 연동 (06_jira_template 생성 방법 기반: API/MCP/스크립트) | 오케스트레이터 MVP |
| 7 | CI/CD 연동 (GitHub Actions + 자동 수정) | 오케스트레이터 + Dev AI |
| 8 | Human Checkpoint 알림 연동 (Slack/Jira) | 오케스트레이터 |
| 9 | Dev AI 팀 모드 (멀티 플랫폼 병렬) | 단일 플랫폼 검증 완료 |
| 10 | Designer AI 연동 | 디자인 시스템 구축 완료 |
| 11 | 런칭 후 안정화 자동화 | 모니터링 인프라 구축 |
