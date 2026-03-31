---
description: 레포/프로젝트 단위 초기 설정을 수행합니다
argument-hint: [org/repo 또는 로컬 경로]
---

# /init-project — 프로젝트 초기 설정

레포 하나에 대해 AI 개발 프로세스 환경을 세팅한다.
이 스킬을 실행하면 이후 `/idea`, `/plan`, `/spec` 등이 프로젝트 컨텍스트를 자동 참조한다.

## 입력

- $ARGUMENTS — GitHub repo 이름 (`org/repo`) 또는 로컬 경로
  - 예: `{org}/{repo}` (GitHub)
  - 예: `{로컬경로}` (로컬)
  - 생략 시 현재 디렉토리

## 참조 문서

- **03_ai_dev_process.md** — 전체 프로세스 흐름
- **06_jira_template.md** — Jira 템플릿 형식
- **04_ai_agent_architecture.md** — Agent 역할 및 산출물 구조
- **14_tool_integration.md** — 도구 연동 상세

## 수행할 작업

### 1단계: 레포 위치 확인

입력이 `org/repo` 형식이면 GitHub MCP로 처리한다.

1. **GitHub MCP**로 레포 정보를 조회한다 (존재 확인, 기본 브랜치, 설명 등)
2. 로컬에 이미 clone되어 있는지 탐색한다:
   - 현재 디렉토리 하위에서 `git remote -v`가 해당 repo URL과 매칭되는 디렉토리를 찾는다
   - 일반적인 경로도 확인: `~/Desktop/`, `~/Projects/`, `~/dev/` 등
3. 로컬에 없으면 clone 위치를 사람에게 확인한다:
   ```
   {org/repo}가 로컬에 없습니다.
   clone할 경로를 지정해주세요. (기본: ./repos/{repo})
   ```
4. `git clone`을 실행한다 (사람 승인 후)

입력이 로컬 경로면:
1. 해당 경로가 git repo인지 확인한다
2. `git remote -v`로 GitHub URL을 자동 파악한다

### 2단계: 프로젝트 분석

1. 기술 스택을 자동 감지한다:
   - 언어: package.json, build.gradle, Podfile, Package.swift 등
   - 프레임워크: Spring, NestJS, SwiftUI, Jetpack Compose 등
   - 빌드 도구: Gradle, Xcode, npm/yarn/pnpm 등
   - 테스트 프레임워크: JUnit, XCTest, Jest 등
2. 플랫폼을 판별한다: backend / ios / android / web / firmware
3. 기존 프로젝트 구조와 패턴을 파악한다 (아키텍처, DI, 상태관리 등)

### 3단계: Jira 연동 확인

1. Jira 프로젝트 키를 사람에게 확인한다 (예: PCZJ, APPS, POR)
2. Jira REST API로 프로젝트 접근을 검증한다
3. 사용 가능한 이슈 타입을 조회한다 (에픽, 스토리, 작업, 버그 등)

### 4단계: 프로젝트 CLAUDE.md 생성

프로젝트 루트에 `CLAUDE.md`를 생성한다. 이 파일은 해당 레포에서 스킬 실행 시 자동 참조되는 프로젝트 컨텍스트다.

```markdown
# 프로젝트 컨텍스트

## 기본 정보
- 프로젝트명: {name}
- GitHub: {org/repo}
- 플랫폼: {platform}
- Jira 프로젝트 키: {key}
- Jira 이슈 타입 ID: 에픽={id}, 스토리={id}, 작업={id}, 버그={id}

## 기술 스택
- 언어: {language}
- 프레임워크: {framework}
- 빌드 도구: {build_tool}
- 테스트 프레임워크: {test_framework}
- 의존성 관리: {dependency_manager}

## 프로젝트 구조
- 소스 경로: {src_path}
- 테스트 경로: {test_path}
- 설정 파일: {config_files}

## 아키텍처
- 패턴: {pattern} (예: MVVM, Clean Architecture)
- DI: {di} (예: Hilt, Swinject)
- 상태관리: {state} (예: RxSwift, Coroutines Flow)

## Jira API
- URL: https://supremaio.atlassian.net
- 인증: REST API (Basic Auth)
```

### 5단계: 중앙 CLAUDE.md에 레포 등록

프로세스 문서 레포의 `CLAUDE.md`에 레포 레지스트리 행을 추가한다.
이 테이블이 없으면 새로 생성하고, 이미 있으면 행만 추가한다.

```markdown
## 레포 레지스트리
| 레포 | GitHub | 플랫폼 | Jira 키 | 역할 | 주요 기능 |
|------|--------|--------|---------|------|----------|
| {name} | {org/repo} | {platform} | {jira_key} | {역할 요약} | {주요 기능 키워드} |
```

- **레포**: 짧은 이름 (예: {repo-name})
- **GitHub**: org/repo (예: {org}/{repo}). 모든 스킬이 이 경로로 GitHub MCP를 통해 코드에 접근한다
- **역할**: 이 레포가 시스템에서 하는 일 (예: 모바일 출입통제 앱, 출입통제 백엔드 서버)
- **주요 기능**: 핵심 기능 키워드 (예: BLE 도어 개폐, 사용자 인증, 모바일 카드 관리)

이 테이블을 `/idea`, `/init-epic` 등 모든 스킬이 자동 참조한다.
`/idea`는 아이디어의 키워드와 레지스트리의 **역할/주요 기능**을 매칭하여 대상 레포를 결정한다.

### 6단계: 디렉토리 준비

```
artifacts/          ← 티켓별 산출물 저장소 (없으면 생성)
```

### 7단계: 검증

1. 프로젝트 CLAUDE.md가 정상 생성되었는지 확인
2. 중앙 CLAUDE.md에 레포가 등록되었는지 확인
3. GitHub MCP로 레포 접근 가능 확인
4. Jira API로 이슈 조회 테스트
5. 결과를 사람에게 보고

## 출력

- `CLAUDE.md` (프로젝트 루트)
- 중앙 CLAUDE.md 레포 레지스트리 업데이트
- 초기 설정 결과 보고 (화면 출력)

## 다음 단계

- 단일 레포 작업: `/idea` 또는 `/plan [ticket-id]`로 시작
- 멀티 레포 작업: `/init-epic`으로 에픽 단위 설정
