---
description: Jira 티켓의 요구사항을 확장하고 작업을 분해합니다
argument-hint: [ticket-id]
---

# /plan — 요구사항 확장 + 작업 분해 (오케스트레이터)

Jira 티켓 또는 기획서를 분석하여 요구사항을 확장하고 작업을 분해한다.
**Planner AI를 별도 Agent(subagent)로 실행한다.**

## 입력

- 티켓 ID: $ARGUMENTS (예: WIDGET-001)

---

## 수행할 작업

### 0단계: 사전 준비 (오케스트레이터가 직접 수행)

1. Jira에서 $ARGUMENTS 티켓을 조회한다
2. `artifacts/$ARGUMENTS/` 디렉토리를 확인/생성한다
3. CLAUDE.md 레포 레지스트리에서 대상 레포를 파악한다

---

### 1단계: Planner Agent 실행

`.claude/agents/planner.md`의 역할 정의에 따라 subagent를 실행한다.

**실행 방법:**
```
Agent(
    description: "Planner — 요구사항 확장 + 작업 분해",
    subagent_type: "Explore",
    prompt: "
        You are Planner AI. [.claude/agents/planner.md 전문을 읽어서 프롬프트에 포함]

        ## Jira 티켓 내용
        {조회한 티켓 내용}

        ## 대상 레포 경로
        {레포 레지스트리의 로컬 경로}

        ## 수행할 작업
        1. 요구사항을 구조화하고 인수 조건을 정의한다
        2. 영향 범위를 파악한다 (플랫폼, 모듈, 가드레일 여부)
        3. 최신 OS 지원 여부를 확인한다
        4. 작업을 세부 태스크로 분해하고 의존성을 설정한다
        5. 플랫폼별 태스크를 분리한다
        6. risk_level을 판정한다 (06_jira_template.md 기준)
        7. 모호한 부분이 있으면 질문을 정리한다

        산출물을 artifacts/$ARGUMENTS/01_planner/requirements.md 에 저장하라.
    "
)
```

#### ✅ 1단계 게이트 — 오케스트레이터가 검증

Agent 완료 후 `artifacts/$ARGUMENTS/01_planner/requirements.md`를 읽어 다음을 확인한다:

- [ ] Jira 티켓을 실제로 조회했으며 내용이 반영되었다
- [ ] 요구사항이 구조화되고 인수 조건이 구체적으로 정의되었다
- [ ] 영향 받는 플랫폼 및 모듈이 명시되었다
- [ ] 가드레일 항목 해당 여부가 판단되었다
- [ ] 사용할 API/프레임워크 deprecated 여부가 확인되었다 (미확인 항목은 "미확인" 표기)
- [ ] 모든 요구사항이 세부 태스크로 분해되었다
- [ ] 태스크 간 의존성이 명시되었다
- [ ] 플랫폼별 태스크가 분리되었다
- [ ] 인수 조건과 태스크가 1:1 매핑 가능하다
- [ ] risk_level이 판정되었고 근거가 기술되었다

> **하나라도 미충족이면 Agent를 재실행하여 보완한다.**

---

### 2단계: 교차 리뷰 (별도 Agent로 실행)

**모델 우선순위**: Codex > 다른 외부 AI > Sonnet

```
Agent(
    description: "Plan 교차 리뷰",
    subagent_type: "Explore",
    prompt: "
        독립적으로 Planner 산출물을 검증하라.
        - 누락된 요구사항/인수 조건이 없는가
        - 기술 제약 주장에 WebSearch 검증 결과 또는 코드 근거가 있는가. "불가능" 판정에 WebSearch 없이 사전학습 지식만 사용했으면 FAIL
        - **근본 설계 방향 도전**: 대안 아키텍처, 기술 제약 우회 방안 검토
        - 대안을 최소 1개 이상 제시

        [requirements.md 내용]
    "
)
```

#### ✅ 2단계 게이트

- [ ] 교차 리뷰가 **별개 에이전트**로 실행되었다
- [ ] 교차 리뷰에서 제기된 문제가 모두 반영/기각(사유 기록) 처리되었다

---

### 3단계: CP1 → CP2 (오케스트레이터가 직접 수행)

결과를 사람에게 보여준다 (CP1: 요구사항 확인).
risk_level에 따라 계획 승인을 받는다 (CP2).

- [ ] 사람이 결과물을 검토하고 **명시적으로 승인**했다
- [ ] 수정 요청이 있었다면 수정 완료 후 **재승인**을 받았다
- [ ] 질문에 대한 답변이 수집되어 requirements.md에 반영되었다

> **사람의 명시적 승인 없이 다음 단계로 넘어가지 않는다.**

## 출력

- `artifacts/$ARGUMENTS/01_planner/requirements.md`

## 다음 단계

승인 후 `/spec $ARGUMENTS` 실행을 안내한다.
