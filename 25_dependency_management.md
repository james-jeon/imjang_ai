# 25. 의존성 관리 (Dependency Management)

> 라이브러리 버전 관리, 업데이트 정책, 보안 취약점 대응 기준.

---

## 1. 원칙

1. **최소 의존성**: 표준 라이브러리로 가능하면 외부 의존성 추가하지 않는다
2. **버전 고정**: 빌드 재현성을 위해 정확한 버전을 명시한다 (범위 버전 지양)
3. **정기 업데이트**: 보안 패치는 즉시, 마이너/메이저 업데이트는 월 1회 검토
4. **라이선스 확인**: 추가 전 라이선스 호환성 확인 필수

---

## 2. 플랫폼별 도구

| 플랫폼 | 패키지 매니저 | 잠금 파일 | 비고 |
|--------|-------------|----------|------|
| Android | Gradle (Version Catalog) | `gradle.lockfile` | `libs.versions.toml` 사용 권장 |
| iOS | CocoaPods / SPM | `Podfile.lock` / `Package.resolved` | 신규 프로젝트는 SPM 우선 |
| Backend (AFS2) | npm (NestJS/Node.js) | `package-lock.json` | 잠금 파일 반드시 커밋 |

---

## 3. 버전 관리 전략

### 3.1 Android — Gradle 버전 관리

**현재 레거시**: `build.gradle`에서 `ext {}` 블록으로 버전 중앙 관리.

```groovy
// 프로젝트 루트 build.gradle
ext {
    room_version = "2.5.0"
    kotlin_version = "1.8.22"
}
```

**신규 프로젝트 권장**: Version Catalog (`libs.versions.toml`).

```toml
# gradle/libs.versions.toml
[versions]
kotlin = "1.9.22"
room = "2.6.1"

[libraries]
room-runtime = { group = "androidx.room", name = "room-runtime", version.ref = "room" }
```

- 멀티모듈 프로젝트에서 버전 불일치 방지
- 레거시 프로젝트는 기존 `ext {}` 패턴 유지 (마이그레이션 시 Version Catalog 전환)

### 3.2 iOS — Podfile 버전 고정

```ruby
# Podfile
pod 'Alamofire', '5.8.1'       # ✅ 정확한 버전
pod 'Alamofire', '~> 5.8'      # ⚠️ 마이너 범위 (필요 시만)
pod 'Alamofire'                 # ❌ 버전 미지정 금지
```

### 3.3 SPM — Package.resolved 커밋

```
// Package.resolved는 반드시 Git에 포함
// .gitignore에 추가하지 않음
```

---

## 4. 의존성 추가 기준

새 라이브러리 추가 시 아래 체크리스트 확인:

| 항목 | 기준 |
|------|------|
| 필요성 | 표준 라이브러리/기존 의존성으로 구현 불가능한가? |
| 유지보수 | 최근 6개월 내 커밋이 있는가? |
| 인기도 | GitHub Star 1,000+ 또는 공식 라이브러리인가? |
| 라이선스 | MIT, Apache 2.0, BSD 등 허용 라이선스인가? |
| 크기 | 앱 바이너리 크기 증가가 합리적인가? |
| 보안 | 알려진 취약점(CVE)이 없는가? |
| 대안 | 더 가볍거나 유지보수가 활발한 대안은 없는가? |

---

## 5. 업데이트 정책

### 5.1 우선순위

| 유형 | 대응 시한 | 예시 |
|------|----------|------|
| **보안 패치 (CVE)** | 24시간 내 | 취약점 공개된 라이브러리 |
| **버그 수정 (patch)** | 1주 내 | `1.2.3` → `1.2.4` |
| **기능 추가 (minor)** | 월 1회 검토 | `1.2.x` → `1.3.0` |
| **메이저 업그레이드** | 분기 1회 검토 | `1.x` → `2.0` (Breaking Changes) |

### 5.2 업데이트 프로세스

1. Dependabot / Renovate 알림 확인
2. CHANGELOG 확인 — Breaking Changes 유무
3. 로컬에서 버전 변경 + 빌드 + 테스트 실행
4. PR 생성 — 변경 사유, 테스트 결과 포함
5. CI 통과 확인 후 머지

---

## 6. 보안 취약점 스캔

### 6.1 자동 스캔 도구

| 도구 | 대상 | 주기 |
|------|------|------|
| GitHub Dependabot | 전체 | 자동 (PR 생성) |
| `./gradlew dependencyCheckAnalyze` | Android | CI 파이프라인 |
| `npm audit` | AFS2 Backend (NestJS) | CI 파이프라인 |
| `pod audit` | iOS | 수동 (월 1회) |

### 6.2 취약점 대응 기준

| 심각도 | CVSS | 대응 |
|--------|------|------|
| Critical | 9.0-10.0 | 즉시 패치, 핫픽스 배포 |
| High | 7.0-8.9 | 24시간 내 패치 |
| Medium | 4.0-6.9 | 다음 릴리스에 포함 |
| Low | 0.1-3.9 | 백로그 등록 |

---

## 7. 금지 패턴

| 패턴 | 이유 |
|------|------|
| `implementation 'com.example:lib:+'` | 빌드 비결정적, 호환성 문제 |
| 잠금 파일 `.gitignore` 등록 | 빌드 재현 불가 |
| 동일 기능 라이브러리 중복 | 바이너리 크기 증가, 충돌 위험 |
| Fork 의존 (개인 GitHub) | 유지보수 보장 없음 |
| 잠금 파일 수동 편집 | 무결성 깨짐. 패키지 매니저로만 변경 |

---

## 8. AI 에이전트 규칙

1. **새 라이브러리 추가 금지** → 기존 의존성 + 표준 라이브러리로 구현. 불가피 시 Review AI에게 보고
2. **버전 변경 시** → 정확한 버전 명시. 범위(`~>`, `+`) 사용 금지
3. **잠금 파일 수정** → 패키지 매니저 명령어로만 수정. 직접 편집 금지
4. **의존성 충돌 발생 시** → 자의적 해결 금지. 충돌 내용 보고 후 인간 판단 대기
5. **테스트 의존성** → `testImplementation` / `Test` 타겟에만 추가. 프로덕션 코드에 포함 금지
