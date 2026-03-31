# Git 브랜치 & 버전 관리 전략

## 목적

AI Agent(Claude, Codex)가 브랜치 생성, 커밋, PR, 머지까지 일관된 규칙으로 수행하기 위한 Git 운영 전략을 정의한다.

---

## 1. 브랜치 모델

**Trunk-Based Development** 기반으로 운영한다. `main`이 항상 배포 가능한 상태를 유지한다.

### 브랜치 종류

| 브랜치 | 네이밍 규칙 | 수명 | 용도 |
|--------|------------|------|------|
| main | `main` | 영구 | 배포 가능한 단일 trunk |
| feature | `feature/{ticket-id}-description` | 최대 3일 | 기능 개발 |
| hotfix | `hotfix/{ticket-id}` | 최대 1일 | 프로덕션 긴급 수정 |
| release | `release/v{x.y.z}` | 최대 3일 | 릴리즈 준비 및 QA |

### 네이밍 예시

```
feature/MOC-142-widget-card-sync
feature/MOC-203-ble-reconnect-logic
hotfix/MOC-301
release/v2.1.0
```

### 브랜치 수명 규칙

- feature 브랜치가 **3일을 초과**하면 반드시 분할한다.
- 분할 기준: 독립적으로 리뷰/테스트 가능한 단위.
- 3일 초과 브랜치는 CI에서 경고를 발생시킨다.

---

## 2. 커밋 컨벤션

**Conventional Commits** 사양을 따른다.

### 형식

```
type(scope): description

[optional body]

[optional footer]
Co-Authored-By: Claude <noreply@anthropic.com>
```

### type 목록

| type | 용도 | 예시 |
|------|------|------|
| `feat` | 새 기능 추가 | `feat(widget): add card count sync trigger` |
| `fix` | 버그 수정 | `fix(ble): handle disconnection timeout` |
| `refactor` | 기능 변경 없는 코드 개선 | `refactor(auth): extract token refresh logic` |
| `test` | 테스트 추가/수정 | `test(home): add snapshot test for card list` |
| `docs` | 문서 변경 | `docs(readme): update build instructions` |
| `chore` | 빌드, CI, 의존성 등 | `chore(deps): bump Alamofire to 5.9` |
| `style` | 포맷팅, 세미콜론 등 | `style(widget): fix indentation` |
| `perf` | 성능 개선 | `perf(home): lazy load card images` |

### scope 목록 (프로젝트별 정의)

| scope | 대상 모듈 |
|-------|----------|
| `widget` | 위젯 Extension |
| `auth` | 인증/로그인 |
| `ble` | BLE 통신 |
| `home` | 홈 화면 |
| `card` | 카드 관리 |
| `push` | 푸시 알림 |
| `infra` | CI/CD, 빌드 설정 |
| `api` | 네트워크/API 계층 |

> scope는 프로젝트 초기 설정 시 CLAUDE.md에 등록하고, 필요 시 추가한다.

### 커밋 규칙

1. **한 커밋에 한 가지 변경만** 포함한다.
2. description은 **영문 소문자**로 시작, 마침표 없이 작성한다.
3. AI Agent가 작성한 커밋에는 반드시 `Co-Authored-By: Claude <noreply@anthropic.com>`을 포함한다.
4. WIP 커밋 금지 -- 의미 있는 단위로만 커밋한다.

---

## 3. PR 규칙

### PR 제목

```
[MOC-142] Add card count sync trigger for widget
```

- 형식: `[TICKET-ID] 간결한 설명`
- **70자 이내**로 작성한다.
- 영문으로 작성하되, 한글 설명이 더 명확하면 한글 허용.

### PR 본문 템플릿

```markdown
## Summary
- 위젯에서 카드 개수 변경 시 실시간 동기화 트리거 추가
- AppGroup UserDefaults를 통한 데이터 공유 구현

## Test Plan
- [ ] 카드 추가 후 위젯 갱신 확인
- [ ] 백그라운드 상태에서 동기화 동작 확인
- [ ] 네트워크 오프라인 시 fallback 확인

## Screenshots
(UI 변경이 있는 경우 첨부)

---
Generated with AI (Claude) | Review required before merge
```

### PR 크기 제한

| 항목 | 기준 | 초과 시 |
|------|------|--------|
| 변경 파일 수 | 10개 | 분할 권장 |
| 변경 줄 수 | 300줄 | 분할 권장 |
| 리뷰 소요 시간 | 30분 | 분할 필수 |

### 리뷰어 지정 규칙

| 변경 대상 | 리뷰어 |
|----------|--------|
| iOS 코드 | iOS 담당 + AI Review Agent |
| Android 코드 | Android 담당 + AI Review Agent |
| Backend API | Backend 담당 + AI Review Agent |
| CI/CD, 인프라 | 테크 리드 |
| 공통 모듈 (BLE, Auth) | 플랫폼 담당 전원 |

> AI가 생성한 PR은 반드시 **사람 리뷰어 1명 이상** 승인을 받아야 머지 가능하다.

---

## 4. 머지 전략

| 머지 경로 | 전략 | 이유 |
|----------|------|------|
| feature → main | **Squash Merge** | 깔끔한 히스토리, 1 PR = 1 커밋 |
| hotfix → main | **Regular Merge** | 핫픽스 이력 추적 용이 |
| release → main | **Regular Merge + Tag** | 릴리즈 포인트 명확화 |

### 머지 전 체크리스트

- [ ] CI 전체 통과 (빌드 + 테스트 + lint)
- [ ] 리뷰어 최소 1명 승인
- [ ] 컨플릭트 해소 완료
- [ ] PR 크기 기준 충족

### 머지 후 작업

- feature 브랜치: 머지 후 **자동 삭제**.
- hotfix 브랜치: 머지 후 자동 삭제.
- release 브랜치: 태그 생성 후 삭제.

---

## 5. 릴리즈 태깅

### Semantic Versioning

```
v{major}.{minor}.{patch}
```

| 변경 유형 | 버전 증가 | 예시 |
|----------|----------|------|
| 하위 호환 깨지는 변경 | major | v1.0.0 → v2.0.0 |
| 새 기능 추가 | minor | v1.0.0 → v1.1.0 |
| 버그 수정 | patch | v1.0.0 → v1.0.1 |

### 태그 생성

```bash
git tag -a v1.2.3 -m "Release v1.2.3"
git push origin v1.2.3
```

### 릴리즈 노트 자동 생성

커밋 로그 기반으로 `gh release create` 또는 CI 스크립트를 사용한다.

```bash
gh release create v1.2.3 --generate-notes --title "v1.2.3"
```

릴리즈 노트에는 다음 섹션이 자동 포함된다:
- **Features**: `feat` 타입 커밋
- **Bug Fixes**: `fix` 타입 커밋
- **Breaking Changes**: footer에 `BREAKING CHANGE` 포함된 커밋

---

## 6. AI Agent 연동 규칙

### AI가 반드시 지켜야 할 규칙

| 규칙 | 설명 |
|------|------|
| force push 금지 | `--force`, `--force-with-lease` 사용 금지 |
| 자동 머지 금지 | PR 생성까지만 허용, 머지는 사람이 승인 후 실행 |
| main 직접 커밋 금지 | 반드시 feature 브랜치를 통해 작업 |
| 브랜치 삭제 금지 | 머지 후 자동 삭제 규칙에 위임 |
| 기존 커밋 수정 금지 | `--amend`, `rebase -i` 사용 금지 |

### AI Agent의 Git 작업 흐름

```
1. Jira 티켓 ID 확인
2. feature/{ticket-id}-description 브랜치 생성
3. 커밋 컨벤션에 맞춰 작업 (Co-Authored-By 포함)
4. PR 생성 (템플릿 준수, AI 생성 명시)
5. CI 통과 확인
6. 리뷰어 지정 → 사람 리뷰 대기
7. 승인 후 머지 (사람이 실행)
```

### Branch Protection 설정 (GitHub)

```yaml
main:
  required_reviews: 1
  dismiss_stale_reviews: true
  require_status_checks: true
  required_checks:
    - build-ios
    - build-android
    - test
    - lint
  restrict_pushes: true
  allow_force_pushes: false
  allow_deletions: false
```

---

## 요약

| 항목 | 규칙 |
|------|------|
| 브랜치 모델 | Trunk-based (main + short-lived branches) |
| 커밋 형식 | `type(scope): description` + Co-Authored-By |
| PR 크기 | 파일 10개 / 300줄 이하 |
| 머지 전략 | feature=Squash, hotfix/release=Regular |
| 버전 관리 | Semantic Versioning (vX.Y.Z) |
| AI 제약 | force push 금지, 자동 머지 금지, main 직접 커밋 금지 |
