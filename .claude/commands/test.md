---
description: 인수 조건 기반으로 테스트를 설계하고 코드를 생성합니다
argument-hint: [ticket-id]
---

# /test — 테스트 설계 + 코드 생성 (오케스트레이터)

인수 조건을 기반으로 테스트 케이스를 설계하고 테스트 코드를 생성한다.
**Test AI를 별도 Agent(subagent)로 실행하고, 교차 리뷰도 별도 Agent로 수행한다.**

## 입력

- 티켓 ID: $ARGUMENTS (예: WIDGET-001)

## 선행 조건

- `artifacts/$ARGUMENTS/02_spec/design_doc.md`가 존재해야 한다

---

## 수행할 작업

### 1단계: Test Agent 실행

`.claude/agents/tester.md`의 역할 정의에 따라 subagent를 실행한다.

**실행 방법:**
```
Agent(
    description: "Test AI — 테스트 설계 + 코드 생성",
    subagent_type: "general-purpose",
    prompt: "
        You are Test AI. [.claude/agents/tester.md 전문을 읽어서 프롬프트에 포함]

        ## 이전 단계 산출물
        [artifacts/$ARGUMENTS/02_spec/design_doc.md 내용]
        [artifacts/$ARGUMENTS/01_planner/requirements.md 내용]

        ## 대상 레포 경로
        {레포 레지스트리의 로컬 경로}

        ## 테스트 환경 셋업
        대상 레포의 프로젝트 CLAUDE.md에서 테스트 프레임워크, 빌드 도구, 플랫폼 정보를 읽어 환경을 구성한다.
        - Android: Application 클래스에서 네이티브 라이브러리를 로드하는 경우 빈 TestApplication 사용을 검토한다
        - Android: Product flavor가 있으면 반드시 flavor를 지정하여 빌드/테스트한다
        - Android: JNI 의존성(Realm, SQLCipher 등)이 있으면 mock 처리한다
        - iOS: 네이티브 SDK 의존성이 있는 경우 별도 mock scheme을 검토한다
        - 프로젝트별 고유 셋업은 대상 레포의 CLAUDE.md 또는 기존 테스트 코드 패턴을 따른다

        산출물:
        - artifacts/$ARGUMENTS/04_test/test_cases.md (인수 조건 매핑표 포함)
        - 플랫폼별 테스트 소스 코드 파일
    "
)
```

**멀티 플랫폼 병렬 실행:**
플랫폼이 2개 이상일 때 플랫폼별 Agent를 **동시에** 실행할 수 있다:
```
Agent(description: "Test AI — Android", subagent_type: "general-purpose", run_in_background: true, prompt: "...")
Agent(description: "Test AI — iOS", subagent_type: "general-purpose", run_in_background: true, prompt: "...")
```

#### ✅ 1단계 게이트 — 오케스트레이터가 검증

- [ ] 인수 조건 ↔ 테스트 케이스 1:1 매핑표가 작성되었다
- [ ] 대상 레포의 실제 코드를 읽어 테스트 대상 클래스/메서드가 확인되었다
- [ ] 5개 카테고리 테스트가 포함되었다 (단위 / 통합 / UI 상태 / 생명주기 / 에러·경계값)
- [ ] 엣지 케이스와 에러 케이스가 포함되었다
- [ ] 플랫폼 간 테스트 시나리오 일관성이 확인되었다
- [ ] 테스트가 실행되어 빈 구현체에 대해 실패하는 것을 확인했다
- [ ] 자체 검증 체크리스트가 통과되었다
- [ ] 프로젝트별 테스트 환경 셋업이 대상 레포의 CLAUDE.md 및 기존 테스트 패턴에 맞게 구성되었다

> **하나라도 미충족이면 Agent를 재실행하여 보완한다.**

---

### 2단계: CP2.5 교차 리뷰 (각각 별도 Agent로 실행)

#### 1차 리뷰어 — 테스트 설계 검증
```
Agent(
    description: "테스트 1차 리뷰",
    subagent_type: "Explore",
    prompt: "
        테스트 설계를 독립적으로 검증하라:
        - 인수 조건별 테스트 존재 여부
        - 엣지 케이스 / 에러 케이스 누락
        - 플랫폼 간 테스트 시나리오 일관성
        - 테스트가 검증하는 동작이 명세와 일치하는지

        [test_cases.md 내용]
        [design_doc.md 내용]

        산출물을 artifacts/$ARGUMENTS/04_test/primary_test_review.md 에 저장하라.
    "
)
```

#### 2차 리뷰어 — 테스트 코드 품질 검증
```
Agent(
    description: "테스트 2차 리뷰",
    subagent_type: "Explore",
    prompt: "
        테스트 코드 품질을 독립적으로 검증하라:
        - 테스트 코드 자체의 버그
        - 모킹/스텁 설정이 실제 동작과 괴리가 없는지
        - 비결정적 테스트 (flaky test) 위험
        - 테스트 성능

        [테스트 소스 코드]
        [대상 레포의 실제 코드]

        산출물을 artifacts/$ARGUMENTS/04_test/secondary_test_review.md 에 저장하라.
    "
)
```

1차와 2차는 독립적이므로 **동시에 실행**할 수 있다.

#### ✅ 2단계 게이트

- [ ] 1차 리뷰어가 **별개 에이전트**로 실행되었다
- [ ] 2차 리뷰어가 **별개 에이전트**로 실행되었다
- [ ] 리뷰에서 발견된 이슈가 모두 반영되었다
- [ ] `primary_test_review.md`와 `secondary_test_review.md`가 저장되었다

> **하나라도 미충족이면 보완 후 재검증한다.**

---

## 출력

- `artifacts/$ARGUMENTS/04_test/test_cases.md`
- `artifacts/$ARGUMENTS/04_test/primary_test_review.md`
- `artifacts/$ARGUMENTS/04_test/secondary_test_review.md`
- 플랫폼별 테스트 소스 코드 파일

## 다음 단계

테스트 리뷰 승인 후 `/dev $ARGUMENTS [platform]` 실행을 안내한다.
