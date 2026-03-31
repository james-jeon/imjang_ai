---
description: 설계 문서와 테스트를 기반으로 코드를 구현합니다
argument-hint: [ticket-id] [platform]
---

# /dev — 코드 구현 (오케스트레이터)

설계 문서와 테스트를 기반으로 코드를 구현한다.
**Dev AI를 별도 Agent(subagent)로 실행하며, 멀티 플랫폼은 병렬 실행한다.**

## 입력

- 티켓 ID: $ARGUMENTS[0] (예: WIDGET-001)
- 플랫폼 (선택): $ARGUMENTS[1] (예: android, ios, backend, web)

## 선행 조건 확인 (오케스트레이터가 직접 수행)

1. `artifacts/$ARGUMENTS[0]/02_spec/design_doc.md`가 존재해야 한다
2. `artifacts/$ARGUMENTS[0]/04_test/test_cases.md`가 존재해야 한다
3. 선행 조건이 없으면 사용자에게 알리고 중단한다

## 플랫폼 결정 (오케스트레이터가 직접 수행)

- 플랫폼이 지정되면 해당 플랫폼만 구현한다
- 플랫폼이 미지정이면 설계 문서에서 영향 플랫폼을 파악한다

## 프로젝트 디렉토리

대상 레포의 로컬 경로는 CLAUDE.md **레포 레지스트리**에서 조회한다. 하드코딩하지 않는다.

---

## 수행할 작업

### 1단계: Dev Agent 실행

`.claude/agents/developer.md`의 역할 정의에 따라 subagent를 실행한다.

**단일 플랫폼:**
```
Agent(
    description: "Dev AI — {platform} 코드 구현",
    subagent_type: "general-purpose",
    prompt: "
        You are Dev AI. [.claude/agents/developer.md 전문을 읽어서 프롬프트에 포함]

        ## 이전 단계 산출물
        [artifacts/$ARGUMENTS[0]/02_spec/design_doc.md 내용]
        [artifacts/$ARGUMENTS[0]/04_test/test_cases.md 내용]

        ## 구현 계획 (있는 경우)
        [artifacts/$ARGUMENTS[0]/05_dev/implementation_plan_{platform}.md 내용]

        ## 대상 레포 경로
        {레포 레지스트리의 로컬 경로}

        ## 수행할 작업
        1. 설계 문서와 테스트 기반으로 코드를 구현한다
        2. SDK/라이브러리 API는 반드시 실제 소스 코드를 읽고 확인한 후 사용한다
        3. 기존 코드 패턴과 컨벤션을 따른다
        4. 디버그 로그를 선행 삽입한다
        5. 테스트를 실행하여 통과하는지 확인한다 (실행 개수 / 통과 개수 기재)
        6. 빌드 성공을 확인한다
        7. 가드레일 영역 변경이 있으면 명시한다
        8. 주요 구현 결정마다 Decision Record를 작성한다
        9. 변경 요약을 작성한다

        산출물:
        - 소스 코드 변경 (git commit)
        - artifacts/$ARGUMENTS[0]/05_dev/change_summary_{platform}.md
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

#### ✅ 1단계 게이트 — 오케스트레이터가 검증

Agent 완료 후 `change_summary_{platform}.md`를 읽어 다음을 확인한다:

- [ ] SDK/라이브러리 API가 실제 소스 코드에서 확인되었다 (파일 경로:라인)
- [ ] 기술 제약 주장에 WebSearch 검증 결과 또는 코드 근거가 첨부되었다. 사전학습 지식만으로 "불가능" 확정 금지
- [ ] 기존 코드 실행 흐름을 끝까지 추적하여 구현에 반영했다
- [ ] 재사용 가능한 기존 코드를 탐색하고 활용했다
- [ ] 디버그 로그가 삽입되었다
- [ ] 테스트 실행 결과가 기재되었다 (실행 개수 / 통과 개수)
- [ ] 빌드 성공이 확인되었다
- [ ] 가드레일 영역 변경이 있는 경우 명시되었고, 사람 승인을 요청했다
- [ ] 구현 범위가 설계 문서 범위를 벗어나지 않았다
- [ ] Decision Record가 작성되었다
- [ ] 하드코딩 데이터가 남아 있지 않다
- [ ] `change_summary_{platform}.md`가 저장되었다

> **하나라도 미충족이면 Dev Agent를 재실행하여 보완한다.**

---

## 규칙

- 구현 계획 또는 설계 문서에 명시된 범위만 작업한다. 범위 밖 수정 금지
- 기존 코드 스타일/패턴을 따른다
- 하드코딩 데이터가 있으면 실데이터 연동으로 전환한다
- 다른 플랫폼 구현이 이미 완료된 경우, 플랫폼 일관성을 유지한다
- 에러 발생 시 추측이 아닌 로그 기반으로 원인을 분석한다

## 출력

- 소스 코드 변경
- `artifacts/$ARGUMENTS[0]/05_dev/change_summary_$ARGUMENTS[1].md`

## 다음 단계

구현 완료 후 `/review $ARGUMENTS[0]` 실행을 안내한다.
