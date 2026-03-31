---
description: 요구사항을 기반으로 설계 문서를 생성합니다
argument-hint: [ticket-id]
---

# /spec — 설계 문서 생성 (오케스트레이터)

요구사항을 기반으로 설계 문서, API 스펙, DB 스키마를 생성한다.
**Spec AI를 별도 Agent(subagent)로 실행한다.**

## 입력

- 티켓 ID: $ARGUMENTS (예: WIDGET-001)

## 선행 조건

- `artifacts/$ARGUMENTS/01_planner/requirements.md`가 존재해야 한다

#### ✅ 0단계 게이트 — 선행 조건 확인

- [ ] `artifacts/$ARGUMENTS/01_planner/requirements.md` 파일이 존재하고 내용이 비어 있지 않다
- [ ] 요구사항 문서에 기능 범위, 인수 조건, 플랫폼 정보가 포함되어 있다

> **미충족이면 `/plan $ARGUMENTS`를 먼저 실행하도록 안내한다.**

---

## 수행할 작업

### 1단계: Spec Agent 실행

`.claude/agents/spec.md`의 역할 정의에 따라 subagent를 실행한다.

**실행 방법:**
```
Agent(
    description: "Spec — 설계 문서 생성",
    subagent_type: "Explore",
    prompt: "
        You are Spec AI. [.claude/agents/spec.md 전문을 읽어서 프롬프트에 포함]

        ## 이전 단계 산출물
        [artifacts/$ARGUMENTS/01_planner/requirements.md 내용]

        ## 대상 레포 경로
        {레포 레지스트리의 로컬 경로}

        ## 수행할 작업
        1. API 엔드포인트 설계 (API 변경 시, OpenAPI 3.1)
        2. DB 스키마 변경 정의 (DB 변경 시)
        3. 플랫폼별 영향 정리
        4. 사용 API/프레임워크 최신 OS 지원 확인
        5. 지원 OS 범위 명시
        6. 주요 설계 결정마다 Decision Record 작성 (대안 최소 2개)
        7. 가드레일 영역 변경 시 명시적 표시

        산출물:
        - artifacts/$ARGUMENTS/02_spec/design_doc.md (결정 근거 섹션 포함)
        - artifacts/$ARGUMENTS/02_spec/api_spec.yaml (API 변경 시)
    "
)
```

#### ✅ 1단계 게이트 — 오케스트레이터가 검증

Agent 완료 후 산출물을 읽어 다음을 확인한다:

- [ ] `design_doc.md`가 생성되었고, requirements.md의 모든 기능 항목이 반영되었다
- [ ] API 변경이 있는 경우: `api_spec.yaml`이 OpenAPI 3.1 형식으로 존재한다
- [ ] DB 변경이 있는 경우: 스키마 변경이 정의되었다
- [ ] 가드레일 영역 변경이 표시되었다
- [ ] 영향받는 모든 플랫폼이 명시되었다
- [ ] API/프레임워크별 최신 OS 지원 여부가 **공식 문서 URL 또는 코드 경로:라인**으로 확인되었다
- [ ] 지원 OS 범위가 명시되었다
- [ ] 기술 제약 주장에 **WebSearch 검증 결과** 또는 **코드 라인 근거**가 첨부되었다 (없으면 "미확인")
- [ ] **근거 실제 검증**: 사전학습 지식만으로 적은 근거는 "미확인"으로 되어 있다. 검증 불확실 시 "미확인 — PoC 필요"로 판정되어 있다
- [ ] **Decision Record**가 작성되었고 주요 결정마다 대안 최소 2개가 검토되었다
- [ ] 기각 사유가 코드/문서 근거 기반이다
- [ ] 기존 코드에서 재사용 가능한 컴포넌트가 확인되었다

> **하나라도 미충족이면 Agent를 재실행하여 보완한다.**

---

### 2단계: 교차 리뷰 (별도 Agent로 실행)

**모델 우선순위**: Codex > 다른 외부 AI > Sonnet

```
Agent(
    description: "Spec 교차 리뷰",
    subagent_type: "Explore",
    prompt: "
        독립적으로 설계 문서를 검증하라.
        - **근본 설계 방향 도전**: 대안 아키텍처 최소 1개 제시
        - Decision Record 검증: 대안 충분성, 기각 사유 납득 여부
        - 기술 실현 가능성, 코드 분석 정합성
        - 설계 방향 타당성, 기존 코드 패턴 일관성

        [design_doc.md 내용]
        [requirements.md 내용]
    "
)
```

#### ✅ 2단계 게이트

- [ ] 교차 리뷰가 **다른 모델 또는 별개 에이전트**로 실행되었다
- [ ] 교차 리뷰에서 제기된 문제가 모두 반영/기각(사유 기록) 처리되었다

---

### 3단계: 사람 리뷰 (오케스트레이터가 직접 수행)

설계 문서를 사람에게 보여주고 승인을 받는다.

> **가드레일 영역 변경이 있는 경우 사람의 명시적 승인 필수.**

## 출력

- `artifacts/$ARGUMENTS/02_spec/design_doc.md` (결정 근거 섹션 포함)
- `artifacts/$ARGUMENTS/02_spec/api_spec.yaml` (API 변경 시)

## 다음 단계

설계 승인 후:
- 새 UX 패턴이면 → 프로토타입 또는 `/design $ARGUMENTS wireframe`
- 기존 패턴이면 → `/test $ARGUMENTS`
