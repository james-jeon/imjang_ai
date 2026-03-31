---
description: 구현된 코드를 CP3 교차 리뷰합니다
argument-hint: [ticket-id] [platform]
---

# /review — 코드 리뷰 CP3 (오케스트레이터)

구현된 코드가 명세를 충족하고 품질 기준을 통과하는지 교차 리뷰한다.
**1차/2차 리뷰를 각각 별도 Agent(subagent)로 독립 실행한다.**

## 입력

- 티켓 ID: $ARGUMENTS[0] (예: WIDGET-001)
- 플랫폼 (선택): $ARGUMENTS[1] (예: android, ios)

## 선행 조건 확인 (오케스트레이터가 직접 수행)

1. `artifacts/$ARGUMENTS[0]/05_dev/change_summary*.md`가 존재해야 한다
2. 선행 조건이 없으면 사용자에게 알리고 중단한다

## 프로젝트 디렉토리

대상 레포의 로컬 경로는 CLAUDE.md **레포 레지스트리**에서 조회한다. 하드코딩하지 않는다.

---

## 수행할 작업

### 1단계: 1차 리뷰 Agent 실행

`.claude/agents/reviewer.md`의 역할 정의에 따라 subagent를 실행한다.

**실행 방법:**
```
Agent(
    description: "Review 1차 — 요구사항·구조 검증",
    subagent_type: "Explore",
    prompt: "
        You are Review AI (1차 리뷰어). [.claude/agents/reviewer.md 전문을 읽어서 프롬프트에 포함]

        ## 검증 항목
        - 인수 조건 충족 여부
        - 코드 구조 / 설계 패턴
        - SDK/라이브러리 API 실존 확인 (코드로 확인, 추측 금지)
        - iOS/Android 동일 구현 여부 (플랫폼 일관성)
        - 가드레일 영역 변경 감지
        - 테스트 커버리지
        - 플랫폼별 필수 규칙:
          - Android: Manifest, 권한, ProGuard, contentDescription, Dispatchers.IO
          - iOS: xcodeproj, Info.plist, Entitlements, [weak self], accessibilityLabel
        - Decision Record 검증: 대안 충분성, 기각 사유 코드 근거
        - **근본 설계 방향 도전**: 더 단순하거나 더 나은 대안은 없는가?

        ## 코드 변경
        [change_summary 내용 + git diff]

        ## 인수 조건
        [requirements.md 내용]

        ## 설계 문서
        [design_doc.md 내용]

        ## 대상 레포 경로
        {로컬 경로}

        산출물을 artifacts/$ARGUMENTS[0]/07_review/primary_review.md 에 저장하라.
        승인/반려/에스컬레이션 판정을 명시하라.
    "
)
```

#### ✅ 1단계 게이트 — 오케스트레이터가 검증

- [ ] 인수 조건 전체 항목의 충족 여부가 하나씩 확인되었다
- [ ] 코드 구조 검토가 실제 파일 경로:라인 기준으로 수행되었다
- [ ] SDK/라이브러리 API가 실제 소스 코드에서 확인되었다
- [ ] 플랫폼 일관성이 대조되었다
- [ ] 가드레일 영역 변경 여부가 확인되었다
- [ ] 플랫폼별 필수 규칙이 확인되었다
- [ ] Decision Record가 검증되었다
- [ ] 1차 리뷰가 **별도 Agent**로 실행되었다
- [ ] `primary_review.md`가 생성되었다

> **하나라도 미충족이면 보완 후 재검증한다.**

---

### 2단계: 2차 리뷰 Agent 실행

**모델 우선순위**: Codex > 다른 외부 AI > Sonnet

**Codex CLI 사용 시:**
```bash
codex --approval-mode full-auto "아래 코드 변경을 리뷰하라: [git diff]"
```

**별도 Agent 사용 시:**
```
Agent(
    description: "Review 2차 — 보안·성능 검증",
    subagent_type: "Explore",
    prompt: "
        You are Review AI (2차 리뷰어). 1차 리뷰와 **독립적으로** 검증하라.

        ## 검증 항목
        - 보안 취약점 (SQL 인젝션, XSS, 인증 우회, 민감 정보 로그 노출)
        - 성능 문제 (N+1 쿼리, 메모리 누수, 불필요한 반복)
        - 엣지 케이스 누락 (null, 빈 배열, 동시성)
        - 코드 스타일 / 컨벤션

        ## 코드 변경
        [change_summary 내용 + git diff]

        ## 대상 레포 경로
        {로컬 경로}

        산출물을 artifacts/$ARGUMENTS[0]/07_review/secondary_review.md 에 저장하라.
        승인/반려 판정을 명시하라.
    "
)
```

#### ✅ 2단계 게이트

- [ ] 보안 취약점이 코드에서 직접 확인되었다
- [ ] 성능 문제가 실제 파일 경로:라인 기준으로 점검되었다
- [ ] 엣지 케이스 누락 여부가 확인되었다
- [ ] 2차 리뷰가 1차와 **다른 Agent**로 독립 실행되었다
- [ ] `secondary_review.md`가 생성되었다

---

### 3단계: 종합 판정 (오케스트레이터가 수행)

두 리뷰 결과를 종합한다:

- **둘 다 승인** → 통과 (사람 확인 불필요)
- **하나라도 반려** → 반려 사유를 통합하여 수정 방향 제시
- **"사람 확인 필요"** 항목 → 해당 항목만 사람에게 전달

산출물: `artifacts/$ARGUMENTS[0]/07_review/review_summary.md`

---

### 반려 시 자동 수정 흐름

1. 반려 사유를 포함하여 Dev Agent를 재실행한다:
```
Agent(
    description: "Dev AI — 반려 사유 수정",
    subagent_type: "general-purpose",
    prompt: "반려 사유를 수정하라: [반려 내용] ..."
)
```
2. 수정 후 변경 부분만 재리뷰한다
3. 최대 3회 반복, 이후 에스컬레이션

---

### "사람 확인 필요" 기준

1. 가드레일 영역 변경 (DB, 인증, 결제, 보안, 인프라)
2. AI가 판단하기 어려운 비즈니스 로직 정확성
3. iOS/Android 간 동작 차이가 감지되었으나 의도 여부를 모를 때
4. 아키텍처에 큰 영향을 미치는 설계 변경

---

### 후속 태스크 자동 생성

리뷰에서 발견된 후속 항목은 Jira Sub-task로 자동 생성한다:

1. **메인 앱 통합 지점** — 새 모듈이 메인 앱에서 호출되어야 하는 지점
2. **미구현 연동** — 다른 모듈/레포에서 연결이 필요한 항목
3. **하위 호환성 보완** — API level별 분기, deprecated API 대체
4. **문서 업데이트** — README, API 문서 등 갱신

생성 형식: Sub-task (parent = 현재 스토리), 제목 `[후속] {요약}`, 설명에 사유 + 작업 내용

---

## 출력

- `artifacts/$ARGUMENTS[0]/07_review/primary_review.md`
- `artifacts/$ARGUMENTS[0]/07_review/secondary_review.md`
- `artifacts/$ARGUMENTS[0]/07_review/review_summary.md`

## 다음 단계

리뷰 승인 후 `/release $ARGUMENTS[0]` 실행을 안내한다.
