---
description: 에픽 단위 멀티 레포 설정을 수행합니다
argument-hint: [에픽 제목 또는 Jira 키]
---

# /init-epic — 에픽 단위 멀티 레포 설정

하나의 에픽이 여러 레포(서버/iOS/Android/웹/펌웨어)에 걸칠 때, 전체를 하나의 워크플로우로 구성한다.

## 입력

- $ARGUMENTS — 에픽 제목 또는 기존 Jira 에픽 키 (예: PCZJ-621)

## 선행 조건

- 관련 레포별로 `/init-project`가 완료되어 CLAUDE.md가 존재해야 한다
- 완료되지 않은 레포가 있으면 안내하고 `/init-project`를 먼저 실행하도록 유도한다

## 참조 문서

- **03_ai_dev_process.md** — 전체 프로세스 흐름
- **06_jira_template.md** — Jira 템플릿 형식
- **04_ai_agent_architecture.md** — Agent 역할 및 멀티 플랫폼 태스크 분리

## 수행할 작업

### 1단계: 레포 목록 구성

1. 에픽에 관련된 레포를 사람에게 확인한다
2. 각 레포의 CLAUDE.md를 읽어 프로젝트 컨텍스트를 파악한다
3. 레포별 플랫폼/기술 스택을 정리한다

CLAUDE.md **레포 레지스트리**에서 관련 레포를 조회하여 테이블을 구성한다:
```
| 레포 | 플랫폼 | Jira 키 | 경로 |
|------|--------|---------|------|
| {레포명} | {platform} | {jira_key} | {레지스트리의 로컬 경로} |
| ... | ... | ... | ... |
```

### 2단계: 레포 간 의존성 분석

1. 에픽의 기능을 분석하여 레포 간 의존성을 파악한다
2. 실행 순서를 결정한다:
   - 보통: 백엔드 API 먼저 → 프론트엔드(앱/웹) 병렬
   - API 변경 없으면: 레포 간 병렬 가능

예시:
```
backend (API 설계/구현)
  ↓ API 스펙 확정 후
  ├── android (병렬)
  └── ios (병렬)
```

### 3단계: Jira 에픽 생성/연결

1. 에픽이 없으면 Jira에 생성한다 (06_jira_template.md 형식)
2. 레포별 스토리를 하위에 생성한다
3. 스토리 간 의존성(blocks/blocked by)을 설정한다

### 4단계: 워크플로우 설정 파일 생성

프로세스 문서 레포에 에픽 워크플로우 파일을 생성한다:

```markdown
# Epic Workflow: {에픽 제목}

## Jira
- 에픽: {EPIC_KEY}
- 스토리: {STORY_KEY_1} (backend), {STORY_KEY_2} (android), {STORY_KEY_3} (ios)

## 레포 목록
| 레포 | 플랫폼 | 경로 | CLAUDE.md |
|------|--------|------|-----------|
| ... | ... | ... | 확인 완료 |

## 실행 순서
1. [backend] /plan → /spec → /test → /dev → /review
2. [android, ios 병렬] /plan → /spec → /test → /dev → /review
3. [공통] /release

## 의존성
- android, ios는 backend의 API 스펙 완료 후 시작
- android, ios는 서로 독립 (병렬 가능)
```

### 5단계: 검증 및 보고

1. 모든 레포의 CLAUDE.md 존재 확인
2. Jira 에픽/스토리 생성 확인
3. 워크플로우 파일 생성 확인
4. 결과를 사람에게 보고

## 출력

- `artifacts/{EPIC_KEY}/00_workflow/epic_workflow.md`
- Jira 에픽 + 스토리 카드 (생성한 경우)
- 설정 결과 보고 (화면 출력)

## 다음 단계

워크플로우의 실행 순서에 따라:
- 첫 번째 레포에서 `/plan {STORY_KEY}`로 시작
- 또는 `/idea`로 기능을 더 구체화
