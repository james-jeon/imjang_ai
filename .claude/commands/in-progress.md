---
description: Jira 티켓의 개발 플로우를 순차 실행합니다
argument-hint: [ticket-id]
---

# /in-progress — 개발 플로우 실행 (오케스트레이터)

Jira 티켓 하나를 받아 테스트 → 구현 → 리뷰까지 순차 실행한다.
**각 역할(Test, Dev, Review)을 별도 Agent(subagent)로 분리 실행한다.**

## 입력

- $ARGUMENTS — Jira 티켓 키 (예: PCZJ-626)
  - **에픽 키**를 입력하면 하위 스토리를 자동 조회하여 순차 진행한다
  - **스토리 키**를 입력하면 해당 스토리만 진행한다

## 참조 문서

- **03_ai_dev_process.md** — 전체 프로세스 흐름
- **04_ai_agent_architecture.md** — Agent 역할 및 산출물 구조
- **08_human_checkpoint.md** — 체크포인트 승인 기준
- **14_tool_integration.md** — Agent 실행 절차

## 실행 원칙

| 원칙 | 설명 |
|------|------|
| **에이전트 분리** | 각 역할은 `Agent` 도구(subagent)로 분리 실행한다 |
| **산출물 기반 전달** | Agent 간 데이터 전달은 `artifacts/` 파일을 통한다 |
| **병렬 실행** | 멀티 플랫폼 Dev는 동시에 실행한다 (예: Dev iOS + Dev Android) |
| **tmux 시각화** | 병렬 Agent 실행 시 tmux split pane으로 진행 상황을 표시한다 |
| **게이트 검증** | 각 Agent 완료 후 오케스트레이터가 산출물을 읽어 게이트를 검증한다 |
| **risk_level별 경량화** | 모든 스토리에 풀 프로세스를 적용하지 않는다. risk_level에 따라 단계를 줄인다 |

## risk_level별 프로세스 분기

0단계에서 티켓 조회 시 risk_level (Jira description 메타 필드)을 확인하여 프로세스를 분기한다.

### Low (버그 수정, 문자열 변경, 단순 UI 수정) — 예상 ~150K/story

```
1단계 (준비) → 2단계 (테스트) → 3단계 (구현) → 4단계 (리뷰 1라운드)
```

| 단계 | 실행 내용 | 생략 항목 |
|------|----------|----------|
| 테스트 | Test Agent 실행 | Validator 생략, 교차 리뷰 생략 |
| 구현 | Dev Agent 실행 | - |
| 리뷰 | Review Agent **1개만** (통합 리뷰) | 1차+2차 분리 안 함 |

**Agent 모델 지정:**
- Jira 조회: `model: "haiku"`
- 테스트: `model: "sonnet"`
- 구현: `model: "sonnet"`
- 리뷰: `model: "sonnet"`

### Medium (기존 패턴 기능 추가) — 예상 ~400K/story

```
1단계 → 2단계 (테스트 + Validator) → 3단계 (구현) → 4단계 (리뷰)
```

| 단계 | 실행 내용 | 생략 항목 |
|------|----------|----------|
| 테스트 | Test Agent + **Test Validator** | 교차 리뷰는 **1개 Agent로 통합** |
| 구현 | Dev Agent 실행 | - |
| 리뷰 | Review Agent **1개** (통합 리뷰) | 1차+2차 분리 안 함 |

**Agent 모델 지정:**
- Jira 조회: `model: "haiku"`
- 테스트: `model: "sonnet"`
- Test Validator: `model: "sonnet"`
- 교차 리뷰: `model: "sonnet"`
- 구현: Opus (기본)
- 리뷰: `model: "sonnet"`

### High / Critical (새 기술, 양 플랫폼, 하드웨어, 인증/결제) — 예상 ~800K/story

```
1단계 → 2단계 (테스트 + Validator + 교차 리뷰 1차+2차) → 3단계 (구현) → 4단계 (리뷰 1차+2차)
```

| 단계 | 실행 내용 | 비고 |
|------|----------|------|
| 테스트 | Test Agent + Validator + **교차 리뷰 2개** | 풀 프로세스 |
| 구현 | Dev Agent 실행 | - |
| 리뷰 | Review Agent **1차 + 2차 분리** | 풀 프로세스 |

**Agent 모델 지정:**
- Jira 조회: `model: "haiku"`
- Test Validator: `model: "sonnet"`
- 테스트 교차 리뷰: `model: "sonnet"`
- 구현, 리뷰 1차: Opus (기본)
- 리뷰 2차: `model: "sonnet"`

### risk_level 판별 기준

| risk_level | 조건 |
|-----------|------|
| low | 기존 파일 수정만, 신규 파일 없음, DB/API/인증 변경 없음 |
| medium | 신규 파일 있으나 기존 패턴 반복, 단일 플랫폼, DB/API 변경 없음 |
| high | 멀티 플랫폼, 새 SDK/API 사용, DB 변경, 또는 사람이 지정 |
| critical | 인증/결제/보안 관련, 인프라 변경, 사람 승인 필수 |

Jira description에 `risk_level` 메타 필드가 없으면 **medium**을 기본값으로 사용한다.

## 선행 조건

- 해당 티켓이 `/idea`를 통해 생성되었거나, 상세 기획이 Jira에 기록되어 있어야 한다
- 대상 레포가 CLAUDE.md 레지스트리에 등록되어 있어야 한다

---

## 수행할 작업

### 0단계: 에픽/스토리 판별 + 티켓 조회 (오케스트레이터가 직접 수행)

> **토큰 최적화**: 0단계와 1단계의 Jira 조회를 **단일 Agent**로 통합한다. 에픽 조회, 하위 스토리 조회, 상세 정보 조회를 한 번에 수행한다.

1. **단일 Agent**로 다음을 모두 수행한다:
   - 입력된 키의 이슈 타입 조회 (에픽/스토리 판별)
   - 에픽이면 하위 스토리 전체 조회 (JQL 검색)
   - 각 스토리의 상세 정보 조회 (description, 인수 조건)
   - 모든 결과를 한 번에 반환
2. **스토리이면:** 바로 1단계로 진행한다

### 1단계: 상태 변경 + 레포 준비 (오케스트레이터가 직접 수행)

> **토큰 최적화**: 레포 구조를 미리 스캔하여 이후 Agent 프롬프트에 주요 파일 경로를 포함한다.

1. 티켓 상태를 **"In Progress"**로 변경한다 (0단계에서 조회한 정보 활용)
2. 티켓 담당자를 현재 사용자로 할당한다
3. 대상 레포를 확인하고 로컬에 clone/pull 한다
4. 작업 브랜치를 생성한다 (예: feature/PCZJ-626-android-widget)
5. **레포 구조 사전 스캔**: 주요 파일 경로, 기존 테스트 패턴, SDK API 파일 위치를 파악하여 이후 Test/Dev Agent 프롬프트에 포함한다

---

### 2단계: Test Agent 실행

`.claude/agents/tester.md`의 역할 정의에 따라 subagent를 실행한다.

**실행 방법:**
```
Agent(
    description: "Test AI — 테스트 설계 + 코드 생성",
    subagent_type: "general-purpose",
    prompt: "
        You are Test AI. [.claude/agents/tester.md 전문을 읽어서 프롬프트에 포함]

        ## 티켓 정보
        {Jira에서 조회한 티켓 내용}

        ## 이전 단계 산출물
        [artifacts/$ARGUMENTS/02_spec/design_doc.md 내용]
        [artifacts/$ARGUMENTS/01_planner/requirements.md 내용]

        ## 대상 레포 경로
        {레포 레지스트리의 로컬 경로}

        산출물을 artifacts/$ARGUMENTS/04_test/ 에 저장하라.
    "
)
```

**멀티 플랫폼 테스트:**
플랫폼이 2개 이상일 때 플랫폼별 Agent를 **동시에** 실행할 수 있다:
```
Agent(description: "Test AI — Android 테스트", subagent_type: "general-purpose", run_in_background: true, prompt: "...")
Agent(description: "Test AI — iOS 테스트", subagent_type: "general-purpose", run_in_background: true, prompt: "...")
```

#### 2단계 완료 후: Test Validator 자동 검증

테스트 코드 생성 후 **먼저 Test Validator를 실행**하여 구조적 품질을 사전 검증한다.
Validator가 통과해야 교차 리뷰로 넘어간다. 반려 시 Test AI를 재실행한다.

```
Agent(
    description: "Test Validator — 자동 검증",
    subagent_type: "Explore",
    prompt: "
        You are Test Validator AI. [.claude/agents/test-validator.md 전문 포함]
        V-1~V-12 체크리스트를 검증하라.
        산출물을 artifacts/{ticket_id}/04_test/validation_result.md 에 저장하라.
    "
)
```

**Validator 통과 후:** CP2.5 교차 리뷰를 실행한다.

#### CP2.5 테스트 교차 리뷰

**별도 Agent로** 교차 리뷰를 실행한다:

```
# 1차 리뷰어
Agent(
    description: "테스트 1차 리뷰",
    subagent_type: "Explore",
    prompt: "테스트 설계 검증: 인수 조건 매핑, 엣지케이스, 플랫폼 일관성 ..."
)

# 2차 리뷰어 (다른 모델 우선)
Agent(
    description: "테스트 2차 리뷰",
    subagent_type: "Explore",
    prompt: "테스트 코드 품질 검증: 버그, mock/stub 정합성, flaky test 위험 ..."
)
```

산출물:
- `artifacts/$ARGUMENTS/04_test/test_cases.md`
- `artifacts/$ARGUMENTS/04_test/primary_test_review.md`
- `artifacts/$ARGUMENTS/04_test/secondary_test_review.md`

#### ✅ 2단계 게이트 — risk_level별 분기

**Low:**
- [ ] 인수 조건 ↔ 테스트 1:1 매핑표가 작성되었다
- [ ] 테스트가 실행되어 빈 구현체에 대해 실패하는 것을 확인했다
- [ ] 산출물 파일이 모두 저장되었다

**Medium:**
- [ ] 인수 조건 ↔ 테스트 1:1 매핑표가 작성되었다
- [ ] 5개 카테고리 테스트가 포함되었다
- [ ] **Test Validator (V-1~V-12)가 통과**했다
- [ ] 교차 리뷰(통합 1개 Agent)가 실행되었다
- [ ] 산출물 파일이 모두 저장되었다

**High / Critical:**
- [ ] 인수 조건 ↔ 테스트 1:1 매핑표가 작성되었다
- [ ] 5개 카테고리 테스트가 포함되었다
- [ ] **Test Validator (V-1~V-12)가 통과**했다
- [ ] 교차 리뷰(1차 + 2차)가 **별도 Agent**로 실행되었다
- [ ] 교차 리뷰에서 발견된 이슈가 모두 반영되었다
- [ ] 산출물 파일이 모두 저장되었다

> **하나라도 미충족이면 보완 후 재검증한다.**

---

### 3단계: Dev Agent 실행

`.claude/agents/developer.md`의 역할 정의에 따라 subagent를 실행한다.

**단일 플랫폼:**
```
Agent(
    description: "Dev AI — {platform} 코드 구현",
    subagent_type: "general-purpose",
    prompt: "
        You are Dev AI. [.claude/agents/developer.md 전문을 읽어서 프롬프트에 포함]

        ## 티켓 정보
        {Jira 티켓 내용}

        ## 이전 단계 산출물
        [design_doc.md 내용]
        [test_cases.md 내용]

        ## 대상 레포 경로
        {로컬 경로}

        구현 후 artifacts/$ARGUMENTS/05_dev/change_summary_{platform}.md 에 변경 요약을 저장하라.
    "
)
```

**멀티 플랫폼 병렬 실행:**
```
# 단일 메시지에서 동시 실행 + tmux 시각화
Agent(description: "Dev iOS", subagent_type: "general-purpose", run_in_background: true, isolation: "worktree", prompt: "...")
Agent(description: "Dev Android", subagent_type: "general-purpose", run_in_background: true, isolation: "worktree", prompt: "...")

# tmux split pane으로 진행 상황 표시
```

#### 3.5단계: 디바이스 검증 (앱 프로젝트만 해당)

> **모바일 앱(Android/iOS) 프로젝트는 빌드 성공만으로 불충분하다. 실기기 또는 에뮬레이터에서 동작을 확인한다.**

**Android:**
```bash
# 1. 연결된 디바이스 확인
adb devices

# 2. Debug APK 빌드 + 설치
./gradlew app:assembleProductDebug
adb install -r app/build/outputs/apk/product/debug/app-product-debug.apk

# 3. 앱 실행
adb shell am start -n {패키지명}/{메인 액티비티}
```

**iOS:**
```bash
# 1. 시뮬레이터 확인
xcrun simctl list devices available

# 2. 빌드 + 시뮬레이터 실행
xcodebuild -workspace {}.xcworkspace -scheme {} -destination 'platform=iOS Simulator,name=iPhone 16' build
xcrun simctl install booted {앱경로}
xcrun simctl launch booted {번들ID}
```

**검증 항목:**
- [ ] APK/IPA가 정상 빌드되었다
- [ ] 기기/에뮬레이터에 설치되었다
- [ ] 앱이 크래시 없이 실행되었다
- [ ] 변경된 기능의 기본 동작이 확인되었다 (화면 진입, UI 표시 등)
- [ ] 하드웨어 의존 기능(BLE, NFC 등)은 가능한 범위까지만 확인하고 한계를 기록한다

> **디바이스 없거나 에뮬레이터 미설치 시:** 해당 사실을 기록하고, 사람에게 수동 확인을 요청한다.
> **백엔드/웹/라이브러리 프로젝트:** 이 단계를 건너뛴다.

#### ✅ 3단계 게이트 — 오케스트레이터가 검증

- [ ] SDK/라이브러리 API가 실제 소스 코드에서 확인되었다
- [ ] 테스트 실행 결과가 기재되었다 (실행 개수 / 통과 개수)
- [ ] 빌드가 성공했다
- [ ] **앱 프로젝트: 디바이스/에뮬레이터에서 실행 확인되었다** (3.5단계)
- [ ] 가드레일 영역 변경이 있는 경우 명시되었다
- [ ] Decision Record가 작성되었다
- [ ] `change_summary_{platform}.md`가 저장되었다

> **하나라도 미충족이면 Dev Agent를 재실행하여 보완한다.**

---

### 4단계: Review Agent 실행

`.claude/agents/reviewer.md`의 역할 정의에 따라 **1차 + 2차 리뷰를 별도 Agent로** 실행한다.

**실행 방법:**
```
# 1차 리뷰 — 요구사항·구조·플랫폼 검증
Agent(
    description: "Review 1차 — 요구사항·구조 검증",
    subagent_type: "Explore",
    prompt: "
        You are Review AI (1차 리뷰어). [.claude/agents/reviewer.md 전문 포함]
        1차 리뷰를 수행하라: 인수 조건 충족, 코드 구조, SDK API 실존, 플랫폼 일관성, 가드레일, Decision Record 검증, 근본 설계 방향 도전.

        ## 코드 변경
        [git diff 또는 change_summary 내용]

        ## 인수 조건
        [requirements.md 내용]

        ## 설계 문서
        [design_doc.md 내용]

        산출물을 artifacts/$ARGUMENTS/07_review/primary_review.md 에 저장하라.
    "
)
```

1차 리뷰 완료 후:

```
# 2차 리뷰 — 보안·성능·엣지케이스 검증 (다른 모델 우선)
Agent(
    description: "Review 2차 — 보안·성능 검증",
    subagent_type: "Explore",
    prompt: "
        You are Review AI (2차 리뷰어). 1차 리뷰와 독립적으로 검증하라.
        보안 취약점, 성능 문제, 엣지 케이스 누락, 코드 스타일을 확인하라.

        [코드 변경 + 인수 조건 포함]

        산출물을 artifacts/$ARGUMENTS/07_review/secondary_review.md 에 저장하라.
    "
)
```

#### 종합 판정 (오케스트레이터가 수행)

- 둘 다 승인 → **통과**
- 하나라도 반려 → Dev Agent 재실행 (반려 사유 전달, 최대 3회)
- "사람 확인 필요" 항목 → 해당 항목만 사람에게 전달

산출물: `artifacts/$ARGUMENTS/07_review/review_summary.md`

#### 후속 태스크 자동 생성

리뷰에서 발견된 후속 항목(메인 앱 통합 지점, 미구현 연동, 하위 호환성, 문서 업데이트)은 Jira Sub-task로 자동 생성한다.

---

### 5단계: 완료 처리 (오케스트레이터가 직접 수행)

1. PR 생성 완료
2. Jira 티켓 상태를 **"Review"** 또는 **"Done"**으로 변경한다
3. 실행 결과를 사람에게 보고한다

## 중단 및 재개

- 각 단계에서 사람의 승인이 필요한 경우 중단하고 대기한다
- 에러 발생 시 해당 단계에서 중단하고 사람에게 보고한다
- `/in-progress {ticket-id}`를 다시 실행하면 마지막 완료 단계 이후부터 재개한다

## 다음 단계

PR 머지 후 `/release`로 릴리즈를 진행한다.
