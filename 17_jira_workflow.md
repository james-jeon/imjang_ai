# Jira 워크플로 및 생성 방법

06_jira_template.md에서 정의한 티켓 구조를 실제 Jira에 생성하고 운영하는 방법을 정의한다.
이 문서는 **Layer 2 (실행 엔진)** 영역으로, 도구별 구체적 실행 방법을 다룬다.

---

## Jira 티켓 생성 방법

AI가 구조화한 티켓을 실제 Jira에 생성하는 방법을 정의한다.
Track A(일괄 생성)와 Track B(단건 생성)에 따라 적합한 방식이 다르다.

### 방법 1: Jira REST API 직접 호출

AI(Planner AI)가 Bash 도구를 통해 Jira REST API를 직접 호출한다.

```bash
# 이슈 생성
curl -X POST https://{domain}.atlassian.net/rest/api/3/issue \
  -H "Authorization: Basic {base64(email:api_token)}" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "project": {"key": "{PROJECT_KEY}"},
      "issuetype": {"name": "Story"},
      "summary": "출입 인증 실패 시 안내 UX 추가",
      "description": {...},
      "labels": ["ai-generated", "app"],
      "customfield_risk_level": "low",
      "customfield_requires_ui_change": "yes"
    }
  }'

# 이슈 간 링크 (의존성) 설정
curl -X POST https://{domain}.atlassian.net/rest/api/3/issueLink \
  -H "Authorization: Basic {base64(email:api_token)}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": {"name": "Blocks"},
    "inwardIssue": {"key": "{PROJECT_KEY}-101"},
    "outwardIssue": {"key": "{PROJECT_KEY}-102"}
  }'
```

| 장점 | 단점 |
|------|------|
| 완전 자동화 가능 | 초기 세팅 필요 (API 토큰, 프로젝트 키, 커스텀 필드 ID) |
| 의존성/링크 자동 설정 | 커스텀 필드 ID를 사전에 매핑해야 함 |
| Track A 일괄 생성에 적합 | API 호출 제한(rate limit) 고려 필요 |

### 방법 2: Jira MCP Server

CLI에 Jira MCP 서버를 연동하여 Agent가 Jira를 도구로 직접 사용한다.

```jsonc
// .claude/settings.json (예시)
{
  "mcpServers": {
    "jira": {
      "command": "npx",
      "args": ["@anthropic/mcp-jira"],
      "env": {
        "JIRA_URL": "https://{domain}.atlassian.net",
        "JIRA_EMAIL": "...",
        "JIRA_API_TOKEN": "..."
      }
    }
  }
}
```

Agent가 MCP 도구로 직접 Jira 조작:

```
도구: jira_create_issue
도구: jira_search (JQL 쿼리)
도구: jira_update_issue
도구: jira_add_comment
도구: jira_create_link
```

| 장점 | 단점 |
|------|------|
| CLI와 자연스럽게 통합 | MCP 서버 설치/설정 필요 |
| Agent가 JQL로 기존 이슈 검색 가능 | MCP 서버의 안정성에 의존 |
| 커스텀 필드 매핑을 MCP 서버가 처리 | 지원하지 않는 Jira 기능이 있을 수 있음 |

### 방법 3: JSON/CSV 출력 → Jira 임포트

AI가 구조화된 파일을 출력하고, 사람이 Jira에 임포트한다.

```json
// artifacts/jira_import.json (AI 생성)
[
  {
    "project": "{PROJECT_KEY}",
    "type": "Epic",
    "summary": "인증 시스템",
    "description": "...",
    "children": [
      {
        "type": "Story",
        "summary": "로그인 기능",
        "labels": ["backend", "app"],
        "risk_level": "medium",
        "children": [
          {"type": "Task", "summary": "[backend] 로그인 API 구현", "labels": ["backend"]},
          {"type": "Task", "summary": "[ios] 로그인 화면 구현", "labels": ["ios"]},
          {"type": "Task", "summary": "[android] 로그인 화면 구현", "labels": ["android"]}
        ]
      }
    ]
  }
]
```

```csv
# artifacts/jira_import.csv (Jira CSV Import 형식)
Summary,Issue Type,Parent,Labels,Risk Level
인증 시스템,Epic,,,,
로그인 기능,Story,인증 시스템,"backend,app",medium
[backend] 로그인 API 구현,Task,로그인 기능,backend,medium
[ios] 로그인 화면 구현,Task,로그인 기능,ios,medium
```

임포트 경로: Jira → Projects → Import Issues → CSV

| 장점 | 단점 |
|------|------|
| 가장 간단, 별도 세팅 불필요 | 반자동 (사람이 임포트 실행) |
| AI 결과를 사람이 파일에서 직접 검토 가능 | 의존성/링크는 임포트 후 수동 설정 |
| Jira API 토큰 불필요 | 커스텀 필드 매핑이 제한적 |

### 방법 4: 스크립트 기반 일괄 생성

AI가 JSON을 생성하고, 별도 스크립트가 Jira API로 일괄 생성한다.

```bash
# AI가 JSON 생성
# (실행 도구는 프로젝트 환경에 따라 다름)

# 스크립트가 JSON을 읽어 Jira API로 생성
node scripts/jira-import.js artifacts/jira_structure.json
```

```javascript
// scripts/jira-import.js (사전 구현 필요)
// - JSON 파일을 읽어 Epic → Story → Task 순서로 생성
// - 각 이슈의 key를 받아 부모-자식 링크 자동 설정
// - 커스텀 필드(risk_level 등)를 Jira 필드 ID로 매핑
// - 생성 결과를 로그로 출력
```

| 장점 | 단점 |
|------|------|
| Track A 대량 생성에 최적 | 스크립트 사전 구현 필요 |
| 계층 구조 + 의존성 자동 설정 | Jira 프로젝트별 필드 매핑 유지 보수 |
| 재실행 가능 (멱등성 설계 가능) | 초기 개발 비용 |

---

## Track별 권장 방식

| Track | 권장 방식 | 이유 |
|:-----:|----------|------|
| Track A (일괄) | 방법 4 (스크립트) 또는 방법 1 (REST API) | 수십~수백 개 티켓을 계층 구조로 생성해야 하므로 자동화 필수 |
| Track B (단건) | 방법 2 (MCP) 또는 방법 1 (REST API) | 1~3개 티켓 생성이므로 Agent가 직접 호출하는 것이 효율적 |
| 도입 초기 | 방법 3 (CSV/JSON) | 세팅 없이 바로 시작 가능. AI 결과물 품질을 먼저 검증 |

---

## 도입 단계별 로드맵

```
1단계 (즉시): 방법 3 — AI가 JSON/CSV 출력, 사람이 Jira 임포트
    ↓ AI 산출물 품질 검증 후
2단계 (세팅 완료 후): 방법 1 또는 2 — API 직접 호출로 자동화
    ↓ Track A 대량 생성 필요 시
3단계 (스크립트 구현 후): 방법 4 — 스크립트 기반 일괄 생성
```

---

---

## 현재 운영 설정 (2026-03 기준)

### 연동 방식

**REST API 직접 호출** (방법 1)을 기본으로 사용한다.
Jira MCP Server는 연결은 되나 실제 조작이 동작하지 않음.

### 인증

```bash
# 환경변수 또는 .claude/settings.json에서 가져옴
JIRA_EMAIL="your-email@example.com"
JIRA_API_TOKEN="your-api-token"

# Basic Auth 헤더
AUTH=$(echo -n "$JIRA_EMAIL:$JIRA_API_TOKEN" | base64)
curl -H "Authorization: Basic $AUTH" \
     -H "Content-Type: application/json" \
     https://supremaio.atlassian.net/rest/api/3/myself
```

### 프로젝트별 설정

프로젝트 키, 이슈 타입 ID, 상태 전이 ID는 **CLAUDE.md**에 기록한다.
이 값들은 Jira 프로젝트마다 다르므로, 새 프로젝트 도입 시 조회하여 기록해야 한다.

```bash
# 이슈 타입 조회
curl -u email:token https://supremaio.atlassian.net/rest/api/3/project/{KEY}

# 상태 전이 조회
curl -u email:token https://supremaio.atlassian.net/rest/api/3/issue/{ISSUE-KEY}/transitions
```

### Description 형식

Jira REST API v3는 description에 ADF(Atlassian Document Format) JSON을 사용한다:

```json
{
  "description": {
    "version": 1,
    "type": "doc",
    "content": [
      {
        "type": "paragraph",
        "content": [{"type": "text", "text": "내용"}]
      }
    ]
  }
}
```

### 새 컴퓨터 셋업 체크리스트

1. Jira API 토큰 발급
2. `.claude/settings.json`에 MCP 서버 환경변수로 `JIRA_EMAIL`, `JIRA_API_TOKEN` 설정
3. `curl` 테스트로 연결 확인
4. CLAUDE.md의 프로젝트 설정 확인 (키, 이슈 타입 ID, 전이 ID)
5. 현재 사용자 accountId 확인 (`/rest/api/3/myself`)

---

## 참조 문서

- 06_jira_template.md — 티켓 구조, 필수 항목, 메타 필드 정의 (Layer 1)
- 14_tool_integration.md — 에이전트 실행 도구 연동 (Layer 2)
