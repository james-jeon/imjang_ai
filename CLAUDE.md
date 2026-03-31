# AI Dev Process — 프로젝트 컨텍스트

## 핵심 원칙 (모든 커맨드/에이전트 공통)

> 이 원칙은 `/idea`, `/plan`, `/spec`, `/test`, `/dev`, `/review`, `/in-progress` 등 **모든 단계에서** 적용된다.
> 개별 커맨드/에이전트 파일에 상세 규칙이 있으며, 여기서는 절대 빠지면 안 되는 핵심만 정리한다.

### 1. 코드 분석 깊이

- 관련 기능의 **실행 흐름을 끝까지 추적**한다 (트리거 → 로직 → 결과 → 서버 연동)
- 관련 **데이터 모델**을 파악한다 (엔티티, 저장소, 조회 방식)
- 기존 **서버 API 호출 지점**을 확인하여 백엔드 변경 필요 여부를 판단한다
- **재사용 가능한 코드**를 찾아 활용한다
- SDK/라이브러리 API는 **실제 소스 코드를 읽고 확인**한 후 사용한다 — 추측 금지

### 2. 기술 판단 근거 + 설계 결정 기록 (Decision Record)

- "~할 수 없다"고 판단하기 전에 **최신 OS 대안 API**를 확인한다
- 기술 제약을 주장할 때 **공식 문서 또는 코드 근거**를 반드시 제시한다
- 확인 없이 기술적 불가능을 단정하지 않는다
- **근거는 실제 검증된 것만 인정한다** — "~라고 알려져 있다", "일반적으로 ~이다" 같은 추론은 근거가 아니다. 공식 문서는 실제 URL을 열어 내용을 확인해야 하고, 코드 근거는 실제 파일:라인을 읽어야 한다. 검증하지 못한 항목은 "미확인"으로 적는다
- **"X에서 Y가 불가능하다" → 즉시 "Z를 통해 우회할 수 있는가?" 질문한다**
  - 예: "위젯에서 BLE 불가" → "ForegroundService, 백그라운드 프로세스, Darwin notification 등 우회 가능한가?"
  - 기존 코드에 관련 백그라운드/서비스 인프라가 이미 있는지 반드시 확인한다
  - **최소 2가지 이상 대안을 검토**한 후에야 차선책(앱 실행 등)을 채택한다
- **기술 제약 검증 필수**: 기술 제약은 WebSearch + 코드 확인으로 검증한다. 사전학습 지식만으로 "불가능"을 확정하지 않는다. 검증 불확실 시 "미확인 — PoC 필요"로 판정하고 가능성을 열어둔다

#### 설계 결정 기록 (Decision Record) — 모든 단계 필수

모든 주요 기술 결정에 대해 **Decision Record**를 작성한다. 이것은 기획(/idea), 설계(/spec), 구현(/dev) 모든 단계에서 적용된다.

**Decision Record 필수 항목:**

| 항목 | 설명 |
|------|------|
| 결정 사항 | 무엇을 결정했는가 |
| 검토한 대안들 | 최소 2개 이상. 각 대안의 방식을 구체적으로 기술 |
| 각 대안의 장단점 | 기술적 실현성, 복잡도, UX, 성능, 유지보수 관점 |
| 채택 사유 | 왜 이 방안을 선택했는가 (코드 근거 포함) |
| 기각 사유 | 왜 다른 방안을 선택하지 않았는가 (구체적 이유 필수) |
| 제약/한계 | 채택한 방안의 알려진 한계점 |

**산출물:** `artifacts/{ticket}/00_idea/decision_record.md` 또는 각 단계 산출물 내 `## Decision Records` 섹션

**체크포인트:** 교차 리뷰(2차 AI) + 사람 리뷰(CP) 시 Decision Record를 반드시 검증한다:
- 대안이 충분히 검토되었는가 (최소 2개)
- 기각 사유가 납득 가능한가 (코드/문서 근거)
- 누락된 대안이 없는가 (리뷰어가 추가 대안 제시)

### 3. 질문 전 원칙

- **코드에서 답할 수 있는 것은 질문하지 않는다**
- 질문 작성 전 "이 답이 코드에 있는가?"를 먼저 확인한다
- 사람에게 질문하는 것은: 비즈니스 의사결정, UX 선호도, 우선순위 등 **코드에 없는 판단**만

### 4. 자체 검증 + 교차 리뷰

- 사람에게 산출물을 보여주기 전에 **자체 검증 체크리스트**를 통과해야 한다
- 기획(CP1~2), 테스트(CP2.5), 코드(CP3) 각 단계에서 **2차 AI가 독립 검증**한다
- 교차 리뷰 없이 사람에게 바로 제출하지 않는다
- **교차 리뷰 모델 우선순위**: Codex(OpenAI) > 다른 외부 AI > Sonnet (Sonnet은 최후 수단)
- **교차 리뷰는 세부 오류 검증뿐 아니라 근본적 설계 방향 자체를 도전**해야 한다
  - "이 설계가 유일한 방안인가? 대안 아키텍처는 없는가?"
  - "기술 제약으로 불가능하다고 했는데, 우회 방법이 정말 없는가?"
  - 대안을 **최소 1개 이상** 제시하도록 요구한다

### 5. 실행 방식

- 병렬 작업 시 **Agent 도구(subagent)**로 분리 실행한다
- 병렬 Agent 실행 시 **tmux split pane**으로 진행 상황을 실시간 표시한다
- Agent 간 데이터 전달은 **artifacts/ 파일 기반**으로 한다
- 상세: `14_tool_integration.md` 참조

### 6. 가드레일

- DB 마이그레이션, 결제, 인증, 보안, 인프라 변경은 **사람 승인 필수**
- SDK 변경은 **별도 PR** + 영향도 분석 필수
- 상세: `07_ai_dev_guardrails.md` 참조

---

## Agent 권한

agent(subagent)가 코드 구현 작업을 수행할 때 다음을 허용한다:
- 레포 레지스트리에 등록된 로컬 레포 경로(~/Desktop/dev/ 하위)의 파일 읽기/쓰기/생성
- artifacts/ 하위 파일 읽기/쓰기/생성
- git 명령 (branch, add, commit, status, diff, stash — push 제외)
- gradle, xcodebuild 등 빌드/테스트 명령 실행
- mkdir, ls 등 파일시스템 탐색 명령

agent 실행 시 `mode: "bypassPermissions"` 를 사용한다.

## 조직

- GitHub: MOCASYSTEM
- Jira: https://supremaio.atlassian.net

## Jira 프로젝트 설정

| 항목 | 값 |
|------|-----|
| 프로젝트 키 | PCZJ |
| Jira URL | https://supremaio.atlassian.net |
| 연동 방식 | REST API (MCP는 연결되나 동작하지 않음 — 2026-03 기준) |

### 이슈 타입 ID

| 이슈 타입 | ID |
|----------|-----|
| 에픽 | 10230 |
| 스토리 | 10233 |
| 작업 | 10229 |
| 버그 | 10232 |
| Subtask | 10231 |
| 개선 | 10234 |

### 상태 전이 ID

| 전이 | ID |
|------|-----|
| In Progress | 2 |
| 해야 할 일 | 11 |
| 완료 | 31 |

### 인증 설정

Jira REST API 인증은 `.claude/settings.json`의 MCP 서버 환경변수에서 가져온다:
- `JIRA_EMAIL` — Jira 계정 이메일
- `JIRA_API_TOKEN` — Jira API 토큰
- Basic Auth: `base64(email:token)`

새 컴퓨터 세팅 시 `.claude/settings.json`에 Jira MCP 서버 환경변수를 설정해야 한다.

## 서비스 목록

| 서비스 | 서버 | 설명 |
|--------|------|------|
| 에어팝 (Airfob) | afs1 | 모바일 출입 크리덴셜 |
| 모카키 (Mocakey) | afs2 (branch: mocakey) | 모바일 출입통제 앱 |
| 모카키 Pro | afs2 | 모바일 출입통제 프로 |
| BioStar Air | afs2 | 클라우드 출입통제 |
| Revian (Guard) | afs2 | 경비 순찰 앱 |

## 레포 레지스트리

> **로컬 경로는 예시입니다.** 각 개발자의 환경에 따라 다릅니다. `/init-project`로 레포를 등록하면 실제 로컬 경로가 자동 반영됩니다.

| 레포 | GitHub | 로컬 경로 (예시) | 플랫폼 | 서비스 | 역할 |
|------|--------|-----------------|--------|--------|------|
| afs2 | MOCASYSTEM/afs2 | ~/Desktop/dev/afs2 | backend (Node) | 모카키, 모카키Pro, BioStarAir, Revian | 출입통제 백엔드 서버 |
| mobile_moca_mocakey_android | MOCASYSTEM/mobile_moca_mocakey_android | ~/Desktop/dev/mobile_moca_mocakey_android | android | 모카키 | 모카키 앱 (Android) |
| mobile_moca_mocakey_ios | MOCASYSTEM/mobile_moca_mocakey_ios | ~/Desktop/dev/mobile_moca_mocakey_ios | ios | 모카키 | 모카키 앱 (iOS) |
| mobile_moca_sdk_android | MOCASYSTEM/mobile_moca_sdk_android | (submodule) | android (SDK) | 공통 | MOCA SDK (Android) |
| mobile_moca_sdk_ios | MOCASYSTEM/mobile_moca_sdk_ios | (submodule) | ios (SDK) | 공통 | MOCA SDK (iOS) |
| wellcomhome_web_client | MOCASYSTEM/wellcomhome_web_client | ~/Desktop/dev/wellcomhome_web_client | web | 모카키 | 모카키 포탈 |
| mobile_mocakey_pro | MOCASYSTEM/mobile_mocakey_pro | ~/Desktop/dev/mobile_mocakey_pro | RN | 모카키Pro | 모카키 프로 앱 |
| mobile_mocakey_pro_admin | MOCASYSTEM/mobile_mocakey_pro_admin | ~/Desktop/dev/mobile_mocakey_pro_admin | RN | 모카키Pro | 모카키 프로 관리자 앱 |
| mobile_biostarair | MOCASYSTEM/mobile_biostarair | ~/Desktop/dev/mobile_biostar_air | RN | BioStarAir | BioStar Air 앱 |
| mobile_suprema_pass | MOCASYSTEM/mobile_suprema_pass | ~/Desktop/dev/mobile_suprema_pass | RN | BioStarAir | Suprema Pass 앱 |
| mobile_biostar_guard_ios | MOCASYSTEM/mobile_biostar_guard_ios | ~/Desktop/dev/mobile_biostar_guard_ios | ios | Revian | Guard 앱 (iOS) |
| mobile_biostar_guard_android | MOCASYSTEM/mobile_biostar_guard_android | ~/Desktop/dev/mobile_biostar_guard_android | android | Revian | Guard 앱 (Android) |
| mobile_credential_android | MOCASYSTEM/mobile_credential_android | ~/Desktop/dev/mobile_credential_android | android | 에어팝 | 에어팝 앱 (Android) |
| mobile_credential_ios | MOCASYSTEM/mobile_credential_ios | ~/Desktop/dev/mobile_credential_ios | ios | 에어팝 | 에어팝 앱 (iOS) |
| mobile_sdk_ios | MOCASYSTEM/mobile_sdk_ios | (submodule) | ios (SDK) | 에어팝 | 에어팝 SDK (iOS) |
| mobile_moca_admin | MOCASYSTEM/mobile_moca_admin | ~/Desktop/dev/mobile_moca_admin | RN | 에어팝 | 에어팝 관리자 앱 |
| mobile_udc_android | MOCASYSTEM/mobile_udc_android | ~/Desktop/dev/mobile_udc_android | android | 에어팝 | UDC 앱 (Android) |
| mobile_udc_ios | MOCASYSTEM/mobile_udc_ios | ~/Desktop/dev/mobile_udc_ios | ios | 에어팝 | UDC 앱 (iOS) |
