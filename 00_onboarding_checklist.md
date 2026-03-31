# 00. 온보딩 체크리스트 (Onboarding Checklist)

> 새 팀원이 AI 기반 개발 프로세스에 합류할 때 필요한 환경 설정과 확인 사항.
> 이 문서만 따라하면 첫 커맨드 실행까지 도달할 수 있다.

---

## 퀵스타트 — 처음부터 시작하기

### Step 1: 프로세스 킷 받기 + 도구 설치

```bash
# 1. 프로세스 킷 받기
#    GitHub에서 clone하거나, 팀에서 공유받은 경로에서 복사한다
git clone {프로세스 킷 GitHub URL}
cd ai_dev_process_kit

# 2. Claude Code CLI 설치
npm install -g @anthropic-ai/claude-code

# 3. Claude Code 인증
claude auth

# 4. GitHub CLI 설치 (PR 생성에 필요)
brew install gh
gh auth login

# 5. tmux 설치 (병렬 Agent 시각화에 필요)
brew install tmux

# 6. Codex CLI 설치 (2차 리뷰용)
#    팀 드라이브(또는 사내 패키지 저장소)의 `codex-cli-{os}.tar.gz`를 내려받아 설치한다
mkdir -p ~/tools
tar -xzf ~/Downloads/codex-cli-macos.tar.gz -C ~/tools
echo 'export PATH="$HOME/tools/codex-cli:$PATH"' >> ~/.zshrc
source ~/.zshrc
codex --version

# 7. Codex 인증
#    DevOps 팀에서 발급받은 API 키를 사용한다
codex auth login --api-key {발급받은_토큰}
#    인증이 완료되면 `codex whoami` 로 계정 정보를 확인한다
```

### Step 2: Jira 연동

CLAUDE.md의 **Jira 프로젝트 설정** 섹션에서 Jira URL과 프로젝트 키를 확인한다.

```bash
# 1. Jira API 토큰 발급
#    https://id.atlassian.com/manage-profile/security/api-tokens

# 2. .claude/settings.json 생성 (개인별 — git에 포함되지 않음)
#    CLAUDE.md의 Jira URL을 확인하여 아래에 입력한다
cat > .claude/settings.json << 'EOF'
{
  "mcpServers": {
    "jira": {
      "command": "/opt/homebrew/bin/uvx",
      "args": [
        "mcp-atlassian",
        "--jira-url", "{CLAUDE.md에서 확인한 Jira URL}",
        "--jira-username", "your-email@example.com",
        "--jira-token", "your-api-token-here"
      ]
    }
  }
}
EOF

# 3. 연결 테스트 (Jira URL은 CLAUDE.md에서 확인)
curl -s -u "your-email:your-token" \
  "{Jira URL}/rest/api/3/myself" | python3 -m json.tool
# → accountId를 기록해둔다
```

### Step 3: 작업 대상 레포 clone

CLAUDE.md의 **레포 레지스트리**에서 작업할 레포를 확인하고 clone한다.
로컬 경로는 자유롭게 정하되, CLAUDE.md의 레포 레지스트리에 **실제 경로를 반영**한다.

```bash
# 레지스트리에서 작업할 레포의 GitHub 경로를 확인한 후 clone
mkdir -p ~/Desktop/dev
cd ~/Desktop/dev
git clone git@github.com:{org}/{repo}.git
cd {repo}
git submodule update --init --recursive
```

> **CLAUDE.md 레포 레지스트리의 로컬 경로는 예시**이다.
> clone 후 실제 경로가 다르면 CLAUDE.md의 해당 행을 수정한다.
> 또는 `/init-project`로 레포를 등록하면 자동 반영된다.

### Step 4: 빌드 확인

clone한 레포가 빌드되는지 확인한다. 대상 레포의 **프로젝트 CLAUDE.md** (또는 README)에서 빌드 방법을 확인한다.

| 플랫폼 | 일반적인 빌드 명령 | 주의 |
|--------|-------------------|------|
| Android | `./gradlew app:assemble{Flavor}Debug` | Product Flavor가 있으면 **반드시 지정** — 생략 시 실패할 수 있음 |
| iOS | Xcode → ⌘B | `.xcworkspace`로 열기, `pod install` 선행 |
| Backend (Node) | `npm install && npm test` | `.nvmrc` 버전 일치 확인 |
| RN | `npm install && npx react-native run-android` | Metro 서버 실행 필요 |
| Web | `npm install && npm run dev` | 환경변수 설정 확인 |

> 프로젝트별 빌드 상세는 대상 레포의 CLAUDE.md 또는 README를 참조한다.

### Step 5: 실행

```bash
# 프로세스 킷 디렉토리에서 Claude Code 실행
cd {프로세스 킷 경로}
claude

# 아이디어부터 시작하려면
> /idea {아이디어 설명}

# Jira 카드가 이미 있으면
> /in-progress {티켓키}
```

---

## 필요한 것 전체 목록

### 계정 및 접근 권한

| 항목 | 발급처 | 용도 |
|------|--------|------|
| GitHub 계정 + 조직 접근 | 관리자에게 요청 | 코드 접근, PR 생성 |
| SSH 키 등록 | GitHub Settings | git clone/push |
| Jira 계정 + 프로젝트 접근 | 관리자에게 요청 | 티켓 관리 |
| Jira API 토큰 | https://id.atlassian.com/manage-profile/security/api-tokens | AI의 Jira 연동 |
| Anthropic 계정 (Claude) | https://console.anthropic.com | Claude Code CLI 인증 |
| Apple Developer 팀 멤버 | 관리자에게 요청 | iOS 빌드/배포 (iOS 작업 시) |
| Firebase 프로젝트 접근 | 관리자에게 요청 | Android 빌드 (`google-services.json`, 해당 시) |
| Slack 채널 | 자동 참여 또는 요청 | 개발/인시던트/모니터링 채널 |

### 설치할 도구

| 도구 | 설치 | 용도 |
|------|------|------|
| **Claude Code CLI** | `npm install -g @anthropic-ai/claude-code` | AI 에이전트 실행 |
| **GitHub CLI (gh)** | `brew install gh` | PR 생성, 레포 관리 |
| **tmux** | `brew install tmux` | 병렬 Agent 진행 상황 시각화 |
| Git | 기본 설치 | 버전 관리 |
| Node.js | `nvm install` (프로젝트 `.nvmrc` 참조) | Backend/RN/Web 빌드 |
| Android Studio | https://developer.android.com/studio | Android 빌드 (Android 작업 시) |
| Xcode | App Store | iOS 빌드 (iOS 작업 시) |
| CocoaPods | `sudo gem install cocoapods` | iOS 의존성 (iOS 작업 시) |

### 생성할 파일 (개인별)

| 파일 | 위치 | 내용 | git 포함 |
|------|------|------|:--------:|
| `.claude/settings.json` | 프로세스 킷 루트 | Jira MCP 서버 설정 (API 토큰 포함) | **X** (.gitignore) |

---

## 핵심 커맨드 요약

| 커맨드 | 용도 | 실행 시점 |
|--------|------|----------|
| `/idea` | 아이디어 → 기획서 → Jira 카드 자동 생성 | 기획 단계 |
| `/in-progress {티켓}` | 테스트 → 구현 → 리뷰 전체 자동 | 개발 단계 |
| `/plan {티켓}` | 요구사항 확장 + 작업 분해 | 기획 상세화 |
| `/spec {티켓}` | 설계 문서 생성 | 설계 단계 |
| `/test {티켓}` | 테스트 설계 + 코드 생성 | 테스트 단계 |
| `/dev {티켓}` | 코드 구현 | 구현 단계 |
| `/review {티켓}` | CP3 교차 리뷰 | 리뷰 단계 |
| `/release {티켓}` | 릴리즈 노트 + 배포 체크리스트 | 릴리즈 단계 |
| `/status {티켓}` | 진행 상태 확인 | 아무때나 |
| `/init-project` | 레포 초기 설정 + 레지스트리 등록 | 새 레포 추가 시 |
| `/design-proposal` | UI/UX 디자인 시안 생성 (HTML) | 설계 단계 |
| `/init-epic` | 에픽 단위 멀티 레포 설정 | 에픽 시작 시 |
| `/hotfix` | 프로덕션 긴급 수정 | 긴급 시 |

---

## 필수 읽기 문서 (순서대로)

| 순서 | 문서 | 핵심 내용 |
|:----:|------|----------|
| 1 | `CLAUDE.md` | **핵심 원칙 6개** + 조직, 레포, Jira 설정 — AI가 자동 로드하는 전체 컨텍스트 |
| 2 | `02_three_layer_architecture.md` | 3-Layer 구조: 프로세스(규칙) / 실행 엔진(도구) / 인터페이스(커맨드) |
| 3 | `03_ai_dev_process.md` | CP0~CP5 체크포인트 기반 품질 게이트, 자동 디버깅 원칙 |
| 4 | `04_ai_agent_architecture.md` | AI 에이전트 역할 + 데이터 흐름 + 커맨드 매핑 |
| 5 | `14_tool_integration.md` | Agent 실행 방법, tmux 시각화, 병렬 실행, 교차 리뷰 구조 |

나머지 문서(01~28)는 AI가 필요할 때 참조한다. 사람이 전부 읽을 필요 없다.

---

## 두 가지 트랙

| 트랙 | 시작점 | 흐름 | 커맨드 |
|------|--------|------|--------|
| **Track A** (아이디어→개발) | 아이디어 | `/idea` → 기획서 + Jira 생성 → `/in-progress` | `/idea` |
| **Track B** (티켓→개발) | Jira 카드 | `/in-progress` (또는 `/plan`→`/spec`→`/test`→`/dev`→`/review` 수동) | `/in-progress` |

---

## 첫 번째 태스크 가이드

#### 가장 쉬운 방법 (Track B)

1. Jira에서 기획이 완료된 Story 티켓 하나를 선택한다
2. `claude` 실행 후 `/in-progress {티켓키}` 입력
3. AI가 자동으로: 테스트 설계 → 코드 구현 → 빌드 확인 → 리뷰 실행
4. 결과 확인 후 PR 머지

#### 아이디어부터 시작 (Track A)

1. `claude` 실행 후 `/idea {아이디어 설명}` 입력
2. AI가 코드 분석 → 기획서 작성 → 자체 검증 → 교차 리뷰 → 사람에게 제시
3. 승인하면 Jira 에픽/스토리 자동 생성
4. `/in-progress {에픽키}`로 개발 플로우 시작

---

## 상세 체크리스트

위 퀵스타트를 마쳤다면, 아래 체크리스트로 빠진 것이 없는지 확인한다.

### 1. 개발 환경 설정

#### 1.1 공통

| 항목 | 확인 |
|------|------|
| Git 설치 + 계정 설정 (`user.name`, `user.email`) | ☐ |
| GitHub 접근 권한 확인 (CLAUDE.md에 명시된 조직) | ☐ |
| SSH 키 등록 | ☐ |
| `.env` / 시크릿 파일 수령 (1Password, Vault 등) | ☐ |
| CI/CD 대시보드 접근 권한 | ☐ |
| Jira 계정 + 담당 프로젝트 접근 | ☐ |
| Slack 채널 참여 | ☐ |

#### 1.2 Android (Android 레포 작업 시)

| 항목 | 확인 |
|------|------|
| Android Studio 최신 안정 버전 설치 | ☐ |
| JDK 버전 확인 (`java -version`) — 프로젝트 요구사항 일치 | ☐ |
| SDK Manager → 필요한 SDK/Build Tools 설치 | ☐ |
| `local.properties` 설정 (SDK 경로) | ☐ |
| 빌드 성공 확인 — Product Flavor가 있으면 **반드시 지정** | ☐ |
| 단위 테스트 실행 + 통과 | ☐ |
| 에뮬레이터 또는 실기기 연결 + 앱 실행 확인 | ☐ |
| Firebase 등 외부 서비스 설정 파일 배치 (해당 시) | ☐ |

#### 1.3 iOS (iOS 레포 작업 시)

| 항목 | 확인 |
|------|------|
| Xcode 최신 안정 버전 설치 | ☐ |
| CocoaPods / SPM 의존성 설치 (`pod install`) | ☐ |
| 개발 인증서 + 프로비저닝 프로파일 설정 | ☐ |
| `.xcworkspace`로 프로젝트 열기 (`.xcodeproj` 아님) | ☐ |
| 빌드 성공 (⌘B) | ☐ |
| 테스트 실행 성공 (⌘U) — **테스트 0개가 아닌지 확인** | ☐ |
| 시뮬레이터 또는 실기기에서 앱 실행 확인 | ☐ |
| Apple Developer 팀 멤버 추가 | ☐ |

#### 1.4 Backend (백엔드 레포 작업 시)

| 항목 | 확인 |
|------|------|
| Node.js 설치 — 프로젝트 `.nvmrc` 버전 일치 | ☐ |
| `npm install` 의존성 설치 | ☐ |
| 로컬 DB 설치 (MySQL, MongoDB 등) 또는 Docker Compose | ☐ |
| 로컬 실행 + 헬스체크 응답 확인 | ☐ |
| `npm test` 테스트 스위트 실행 + 통과 | ☐ |
| API 문서 접근 확인 (Swagger 등) | ☐ |

#### 1.5 React Native (RN 레포 작업 시)

| 항목 | 확인 |
|------|------|
| Node.js 설치 — `.nvmrc` 버전 일치 | ☐ |
| `npm install` 의존성 설치 | ☐ |
| iOS: `cd ios && pod install` | ☐ |
| Android 에뮬레이터 또는 iOS 시뮬레이터에서 실행 확인 | ☐ |

#### 1.6 Web (웹 레포 작업 시)

| 항목 | 확인 |
|------|------|
| Node.js 설치 — `.nvmrc` 버전 일치 | ☐ |
| `npm install` 의존성 설치 | ☐ |
| `npm run dev` 로컬 실행 확인 | ☐ |
| 환경변수 설정 확인 (`.env.local` 등) | ☐ |

---

### 2. AI 에이전트 환경 설정

#### 2.1 Claude Code CLI

| 항목 | 확인 |
|------|------|
| Claude Code CLI 설치 (`npm install -g @anthropic-ai/claude-code`) | ☐ |
| Claude Code 인증 (`claude auth`) | ☐ |
| `CLAUDE.md` 파일 프로세스 킷 루트에 존재 확인 | ☐ |
| CLAUDE.md **핵심 원칙 6개** 읽기 | ☐ |
| `.claude/commands/` 슬래시 커맨드 목록 확인 | ☐ |
| `.claude/agents/` 에이전트 역할 정의 확인 (ideator, planner, spec, designer, tester, **test-validator**, developer, reviewer, release, domain-expert) | ☐ |

#### 2.2 GitHub CLI

| 항목 | 확인 |
|------|------|
| `gh` 설치 (`brew install gh`) | ☐ |
| `gh auth login` 인증 | ☐ |

#### 2.3 tmux

| 항목 | 확인 |
|------|------|
| `tmux` 설치 (`brew install tmux`) | ☐ |
| 기본 사용법 확인: `tmux`, `Ctrl-b %` (수직 분할), `Ctrl-b "` (수평 분할) | ☐ |

#### 2.4 Jira 연동 설정

| 항목 | 확인 |
|------|------|
| Jira API 토큰 발급 | ☐ |
| `.claude/settings.json` 생성 — MCP `args` 형식 (Step 2 참조) | ☐ |
| CLAUDE.md의 Jira 프로젝트 설정 확인 (프로젝트 키, 이슈 타입 ID, 전이 ID) | ☐ |
| Jira REST API 테스트: `curl -u email:token {Jira URL}/rest/api/3/myself` | ☐ |
| 현재 사용자 accountId 확인 및 기록 | ☐ |

> **참고**: Jira MCP Server는 연결은 되나 동작하지 않을 수 있음. REST API 직접 호출 방식을 기본으로 사용한다. 상세: `17_jira_workflow.md`

#### 2.5 레포 등록

| 항목 | 확인 |
|------|------|
| 작업 대상 레포 clone + 빌드 확인 | ☐ |
| CLAUDE.md 레포 레지스트리에 **실제 로컬 경로** 반영 | ☐ |
| (또는 `/init-project`로 자동 등록) | ☐ |

---

### 3. 프로세스 이해

#### 3.1 핵심 개념

| 항목 | 확인 |
|------|------|
| CLAUDE.md 핵심 원칙 6개 이해 (코드 분석 깊이, 기술 판단 근거, 질문 전 원칙, 자체 검증+교차 리뷰, 실행 방식, 가드레일) | ☐ |
| 3-Layer 구조 이해 (프로세스 / 실행 엔진 / 인터페이스) | ☐ |
| CP0~CP5 체크포인트 기반 품질 게이트 이해 | ☐ |
| 테스트 선행 원칙 이해 (테스트 설계 → 구현 → 테스트 실행) | ☐ |
| 인간 리뷰 시점 이해 (risk_level에 따라 차등) | ☐ |
| Agent 병렬 실행 + tmux 시각화 이해 | ☐ |
| **복잡도 vs risk_level 구분** 이해: `/idea`는 복잡도(단순/보통/복잡)로 기획 프로세스 분기, `/in-progress`는 risk_level(low/medium/high/critical)로 개발 프로세스 분기 | ☐ |
| **Test Validator** 이해: 테스트 코드의 구조적 품질을 자동 검증(V-1~V-12)하여 교차 리뷰 전에 품질 미달 사전 차단 | ☐ |
| **Traceability** 이해: AC→테스트→코드→리뷰가 양방향 추적 가능해야 함 (13_output_format.md 참조) | ☐ |
| **프로토타입 판정** 이해: 교차 리뷰에서 기술 리스크→PoC, UX 리스크→디자인 시안을 자동 판정 | ☐ |

#### 3.2 두 가지 트랙

| 트랙 | 시작점 | 흐름 | 커맨드 |
|------|--------|------|--------|
| **Track A** (아이디어→개발) | 아이디어 | `/idea` → Jira 생성 → `/in-progress` | `/idea` |
| **Track B** (티켓→개발) | Jira 카드 | `/in-progress` (또는 단계별 수동) | `/in-progress` |

---

## 프로세스 킷 접근 방법

이 프로세스 킷은 GitHub에서 관리된다. 팀원은 GitHub에서 직접 문서를 확인하고, 로컬에 clone하여 사용한다.

### GitHub에서 문서 확인

- 프로세스 킷 레포에서 커맨드(`.claude/commands/`), 에이전트(`.claude/agents/`), 프로세스 규칙(`01~28_*.md`)을 바로 열람할 수 있다
- Jira에 배포하기 전에 GitHub에서 기획서, 설계 문서 등 산출물을 리뷰할 수 있다
- `CLAUDE.md`에서 조직 설정, 레포 레지스트리, Jira 프로젝트 설정을 확인한다

### 새 프로젝트에 적용할 때

1. 프로세스 킷을 clone한다
2. `CLAUDE.md`의 **레포 레지스트리**에 대상 레포를 추가한다 (또는 `/init-project`로 자동 등록)
3. 담당 Jira 프로젝트 키가 CLAUDE.md에 없으면 **Jira 프로젝트 설정** 섹션에 추가한다
4. `.claude/settings.json`에 본인의 Jira 인증 정보를 설정한다
5. `/idea` 또는 `/in-progress`로 작업을 시작한다

> 커맨드와 에이전트는 프로젝트에 무관하게 동일하게 동작한다.
> 프로젝트별 차이(경로, 빌드 방법, 기술 스택)는 레포 레지스트리와 각 레포의 프로젝트 CLAUDE.md에서 관리한다.

---

## 트러블슈팅 FAQ

| 증상 | 해결 |
|------|------|
| Jira MCP 연결됐으나 동작 안 함 | REST API 직접 호출로 대체 (`17_jira_workflow.md` 참조) |
| `.claude/settings.json` 위치를 모르겠음 | 프로세스 킷 루트의 `.claude/` 디렉토리 안에 생성 |
| Android 빌드 실패 — flavor 관련 | Product Flavor가 있으면 반드시 지정. 대상 레포 README/CLAUDE.md 참조 |
| Android 테스트 `UnsatisfiedLinkError` | 네이티브 라이브러리(Realm, SQLCipher 등) 문제 → TestApplication 분리 (`test.md` 참조) |
| iOS 빌드 실패 — Pod 관련 | `pod deintegrate && pod install` |
| Android 빌드 실패 — Gradle 캐시 | `./gradlew clean` + File → Invalidate Caches |
| iOS 테스트 0개 실행 | `.pbxproj`에 테스트 파일 등록 확인 |
| `@testable import` 실패 | 테스트 타겟의 Host Application 설정 확인 |
| Android 테스트 0개 실행 | `src/test` vs `src/androidTest` 경로 확인, BuildVariant 일치 확인 |
| SDK API 메서드명이 다름 | 추측하지 말고 실제 SDK 소스 코드를 읽고 확인 |
| tmux split pane이 안 보임 | `brew install tmux` 후 `tmux` 실행 상태에서 Claude Code 시작 |
| 레포가 레지스트리에 없음 | `/init-project {레포경로}`로 등록 |

---

## 문서 구조 전체 맵

```
ai_dev_process_kit/
├── CLAUDE.md                    ← 핵심 원칙 + 조직/레포/Jira 설정 (AI 자동 로드)
├── .claude/
│   ├── settings.json            ← 개인별 생성 (Jira 토큰) — git 제외
│   ├── commands/                ← 슬래시 커맨드 (오케스트레이터 — agents/를 subagent로 실행)
│   │   ├── idea.md             ← /idea (Ideator→Planner→Spec subagent 순차 실행)
│   │   ├── in-progress.md      ← /in-progress (Test→Dev→Review subagent 순차 실행)
│   │   ├── plan.md ~ review.md ← 단계별 커맨드 (각각 해당 agent를 subagent로 실행)
│   │   ├── design-proposal.md  ← /design-proposal (UI/UX 디자인 시안)
│   │   ├── init-project.md     ← /init-project (레포 등록)
│   │   ├── init-epic.md        ← /init-epic (에픽 단위 멀티 레포 설정)
│   │   └── ...
│   └── agents/                  ← AI 에이전트 역할 정의 (각 Agent의 역할·입출력·제약)
│       ├── ideator.md           ← 아이디어 분석 + 코드 심층 분석
│       ├── planner.md           ← 요구사항 확장 + 작업 분해
│       ├── spec.md              ← 설계 문서 + API/DB 스펙
│       ├── designer.md          ← UI/UX 와이어프레임 + 비주얼
│       ├── tester.md            ← 테스트 설계 + 코드 생성
│       ├── developer.md         ← 코드 구현
│       ├── test-validator.md     ← 테스트 자동 검증 (V-1~V-12)
│       ├── reviewer.md          ← 코드 리뷰 (읽기 전용)
│       ├── release.md           ← 릴리즈 산출물
│       └── domain-expert.md     ← 도메인 지식 관리
├── 00_onboarding_checklist.md   ← 이 문서 (온보딩)
├── 01~13: 프로세스 규칙 (Layer 1)
│   ├── 03_ai_dev_process.md     ← CP 기반 품질 게이트
│   ├── 04_ai_agent_architecture.md ← 에이전트 역할 + 데이터 흐름
│   ├── 07_가드레일, 08_체크포인트, 09_에스컬레이션 ...
│   └── 13_output_format.md      ← 산출물 형식
├── 14~17: 실행 엔진 (Layer 2)
│   ├── 14_tool_integration.md   ← Agent 실행, tmux, 병렬 실행
│   └── 17_jira_workflow.md      ← Jira REST API 운영 방법
├── 18~28: 기술 표준 (AI가 필요할 때 참조)
│   ├── 19_git_branch_strategy.md
│   ├── 20_api_design_guide.md ~ 28_third_party_integration.md
│   └── ...
├── artifacts/                    ← 실행 산출물 (개인별 생성) — git 제외
│   └── {ticket-id}/00_idea/ ~ 08_release/
└── .gitignore                   ← settings.json, artifacts/ 제외
```

---

## 넘겨받을 때 포함/제외 목록

| 구분 | 파일 | 포함 |
|------|------|:----:|
| 프로세스 문서 | `CLAUDE.md`, `00~28_*.md` | O |
| 커맨드/에이전트 | `.claude/commands/`, `.claude/agents/` | O |
| 개인 설정 | `.claude/settings.json` | **X** (각자 생성) |
| 작업 산출물 | `artifacts/` | **X** (각자 생성) |
