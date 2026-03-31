---
description: 릴리즈 노트와 배포 체크리스트를 생성하고, 스토어 업로드를 실행합니다
argument-hint: [ticket-id] [platform?]
---

# /release — 릴리즈 준비 및 배포

릴리즈 노트 생성 + 스토어 업로드(TestFlight / Play Store)를 수행한다.

## 입력

- 티켓 ID: $ARGUMENTS의 첫 번째 인자 (예: WIDGET-001)
- 플랫폼: $ARGUMENTS의 두 번째 인자 (android / ios / all, 기본값: all)

## 선행 조건

- `artifacts/{ticket}/07_review/review_summary_{platform}.md`가 존재하고 "승인" 상태여야 한다

## 수행할 작업

### 1. 릴리즈 노트 생성

1. 변경 사항을 사용자용/내부용 릴리즈 노트로 정리한다
2. 플랫폼별 배포 체크리스트를 생성한다
3. 롤백 절차를 작성한다

### 2. 배포 방법 선택

사용자에게 배포 방법을 확인한다:

**A) 직접 업로드 (fastlane)**
- 대상 레포의 로컬 경로는 CLAUDE.md **레포 레지스트리**에서 조회한다
- 대상 레포의 프로젝트 CLAUDE.md에서 fastlane 명령어 및 배포 설정을 확인한다
- 예: `cd {레포경로} && fastlane {lane}`

**B) GitHub Actions CI/CD**
- 대상 레포의 `.github/workflows/release.yml` 존재 여부를 확인한다
- workflow_dispatch 파라미터(track, flavor, scheme 등)를 확인하여 실행한다

### 3. 시크릿 확인 체크리스트

배포 전 필요한 시크릿/키 파일이 있는지 안내한다:

**Android (직접 업로드 시):**
- `fastlane/play_store_key.json` — Google Play Console 서비스 계정 키

**Android (GitHub Actions 시):**
- `KEYSTORE_BASE64` — 서명 키스토어 (base64)
- `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` — 서명 정보
- `PLAY_STORE_KEY_JSON` — Play Console 서비스 계정 키 (JSON 문자열)

**iOS (직접 업로드 시):**
- `fastlane/appstore_connect_api_key.json` — App Store Connect API 키

**iOS (GitHub Actions 시):**
- `APP_STORE_CONNECT_API_KEY_JSON` — API 키 (JSON 문자열)
- `MATCH_SSH_KEY` — fastlane match 인증서 저장소 SSH 키

## 출력

- `artifacts/{ticket}/08_release/release_notes.md`

## CP4

배포 승인이 필요함을 안내한다. 스토어 심사 제출은 반드시 사람 승인 후 실행한다.
