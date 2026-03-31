# IMJANG-MVP Sprint 1 테스트 케이스

> 작성일: 2026-03-31
> 범위: S1 (CORE-01~04, AUTH-01~02)
> 방식: TDD — 빈 구현에 대해 FAIL하도록 설계

---

## 1. 인수조건 ↔ 테스트 1:1 매핑 테이블

### FR-AUTH-01 (회원가입)

| # | 인수조건 | 테스트 ID | 테스트 파일 | 테스트 레이어 |
|---|---------|-----------|------------|-------------|
| 1 | 유효한 이메일 + 비밀번호 8자 이상 → 회원가입 성공, 홈 이동 | TC-AUTH-001 | auth_controller_test.dart | Unit (Provider) |
| 2 | 이미 가입된 이메일 → "이미 가입된 이메일입니다" 에러 | TC-AUTH-002 | auth_controller_test.dart | Unit (Provider) |
| 2a | 이미 가입된 이메일 → UI에 에러 메시지 표시 | TC-AUTH-002a | signup_screen_test.dart | Widget |
| 3 | 잘못된 이메일 형식 → "올바른 이메일 형식이 아닙니다" 에러 | TC-AUTH-003 | validators_test.dart | Unit (Utils) |
| 3a | 잘못된 이메일 형식 → UI 폼 검증 에러 표시 | TC-AUTH-003a | signup_screen_test.dart | Widget |
| 4 | 비밀번호 8자 미만 → "비밀번호는 8자 이상이어야 합니다" 에러 | TC-AUTH-004 | validators_test.dart | Unit (Utils) |
| 4a | 비밀번호 8자 미만 → UI 폼 검증 에러 표시 | TC-AUTH-004a | signup_screen_test.dart | Widget |
| 5 | 비밀번호 확인 불일치 → "비밀번호가 일치하지 않습니다" 에러 | TC-AUTH-005 | validators_test.dart | Unit (Utils) |
| 5a | 비밀번호 확인 불일치 → UI 폼 검증 에러 표시 | TC-AUTH-005a | signup_screen_test.dart | Widget |

### FR-AUTH-02 (로그인)

| # | 인수조건 | 테스트 ID | 테스트 파일 | 테스트 레이어 |
|---|---------|-----------|------------|-------------|
| 6 | 올바른 이메일/비밀번호 → 로그인 성공, 홈 이동 | TC-AUTH-006 | auth_controller_test.dart | Unit (Provider) |
| 7 | 잘못된 자격증명 → "이메일 또는 비밀번호가 일치하지 않습니다" 에러 | TC-AUTH-007 | auth_controller_test.dart | Unit (Provider) |
| 7a | 잘못된 자격증명 → UI에 에러 메시지 표시 | TC-AUTH-007a | login_screen_test.dart | Widget |
| 8 | 앱 재시작 후 로그인 상태 유지 | TC-AUTH-008 | auth_repository_test.dart | Unit (Repository) |

### CORE 레이어 테스트

| # | 테스트 목적 | 테스트 ID | 테스트 파일 | 테스트 레이어 |
|---|-----------|-----------|------------|-------------|
| 9 | 라우터: 미인증 상태 → /login 리디렉션 | TC-CORE-001 | router_test.dart | Widget (Integration) |
| 10 | 라우터: 인증 상태 → /home 접근 허용 | TC-CORE-002 | router_test.dart | Widget (Integration) |
| 11 | 라우터: 인증 상태에서 /login 접근 → /home 리디렉션 | TC-CORE-003 | router_test.dart | Widget (Integration) |
| 12 | AuthRepository: 이메일 회원가입 성공 → UserEntity 반환 | TC-CORE-004 | auth_repository_test.dart | Unit (Repository) |
| 13 | AuthRepository: 로그아웃 성공 | TC-CORE-005 | auth_repository_test.dart | Unit (Repository) |

---

## 2. 테스트 카테고리

### 2.1 Unit Tests — Validators (validators_test.dart)

**대상:** `lib/core/utils/validators.dart`

| 테스트 ID | 입력 | 기대 결과 |
|-----------|------|---------|
| TC-VAL-001 | `user@example.com` (유효) | null (에러 없음) |
| TC-VAL-002 | `invalid-email` (형식 오류) | "올바른 이메일 형식이 아닙니다" |
| TC-VAL-003 | `user@` (불완전한 이메일) | "올바른 이메일 형식이 아닙니다" |
| TC-VAL-004 | `@domain.com` (로컬파트 없음) | "올바른 이메일 형식이 아닙니다" |
| TC-VAL-005 | `` (빈 이메일) | "이메일을 입력해 주세요" |
| TC-VAL-006 | `password123` (8자 이상) | null |
| TC-VAL-007 | `short` (7자, 8자 미만) | "비밀번호는 8자 이상이어야 합니다" |
| TC-VAL-008 | `` (빈 비밀번호) | "비밀번호를 입력해 주세요" |
| TC-VAL-009 | password==confirm | null |
| TC-VAL-010 | password!=confirm | "비밀번호가 일치하지 않습니다" |

### 2.2 Unit Tests — AuthRepository (auth_repository_test.dart)

**대상:** `lib/features/auth/data/repositories/auth_repository_impl.dart`
**목 대상:** `FirebaseAuth`, `FirebaseFirestore`

| 테스트 ID | 시나리오 | 기대 동작 |
|-----------|---------|---------|
| TC-REPO-001 | 신규 이메일 회원가입 성공 | UserEntity 반환, Firestore users 문서 생성 |
| TC-REPO-002 | 이미 등록된 이메일 회원가입 | AuthException(code: 'email-already-in-use') throw |
| TC-REPO-003 | 올바른 자격증명 로그인 성공 | UserEntity 반환 |
| TC-REPO-004 | 잘못된 비밀번호 로그인 | AuthException(code: 'wrong-password') throw |
| TC-REPO-005 | 로그아웃 성공 | FirebaseAuth.signOut() 호출 확인 |
| TC-REPO-006 | authStateChanges 스트림 | User? 스트림 emit 확인 |

### 2.3 Unit Tests — AuthController (auth_controller_test.dart)

**대상:** `lib/features/auth/presentation/providers/auth_controller.dart`
**목 대상:** `AuthRepository`

| 테스트 ID | 시나리오 | 기대 상태 |
|-----------|---------|---------|
| TC-CTRL-001 | 회원가입 성공 | state = AsyncData(UserEntity) |
| TC-CTRL-002 | 이미 가입된 이메일 회원가입 | state = AsyncError("이미 가입된 이메일입니다") |
| TC-CTRL-003 | 로그인 성공 | state = AsyncData(UserEntity) |
| TC-CTRL-004 | 잘못된 자격증명 로그인 | state = AsyncError("이메일 또는 비밀번호가 일치하지 않습니다") |
| TC-CTRL-005 | 로그아웃 | state = AsyncData(null) |

### 2.4 Widget Tests — LoginScreen (login_screen_test.dart)

**대상:** `lib/features/auth/presentation/screens/login_screen.dart`

| 테스트 ID | 시나리오 | 기대 UI |
|-----------|---------|--------|
| TC-UI-LOGIN-001 | 화면 렌더링 | 이메일/비밀번호 입력 필드, 로그인 버튼, 회원가입 링크 존재 |
| TC-UI-LOGIN-002 | 빈 폼 제출 | 이메일 필드 에러 메시지 표시 |
| TC-UI-LOGIN-003 | 잘못된 이메일 형식 입력 후 제출 | "올바른 이메일 형식이 아닙니다" 표시 |
| TC-UI-LOGIN-004 | 올바른 입력으로 로그인 버튼 탭 | AuthController.signIn 호출 |
| TC-UI-LOGIN-005 | 로그인 중 로딩 상태 | 로딩 인디케이터 표시, 버튼 비활성화 |
| TC-UI-LOGIN-006 | 로그인 실패 | "이메일 또는 비밀번호가 일치하지 않습니다" SnackBar/에러 표시 |

### 2.5 Widget Tests — SignupScreen (signup_screen_test.dart)

**대상:** `lib/features/auth/presentation/screens/signup_screen.dart`

| 테스트 ID | 시나리오 | 기대 UI |
|-----------|---------|--------|
| TC-UI-SIGNUP-001 | 화면 렌더링 | 이메일/비밀번호/비밀번호확인 입력 필드, 가입 버튼 존재 |
| TC-UI-SIGNUP-002 | 잘못된 이메일 형식 입력 후 제출 | "올바른 이메일 형식이 아닙니다" 표시 |
| TC-UI-SIGNUP-003 | 비밀번호 7자 입력 후 제출 | "비밀번호는 8자 이상이어야 합니다" 표시 |
| TC-UI-SIGNUP-004 | 비밀번호 불일치 입력 후 제출 | "비밀번호가 일치하지 않습니다" 표시 |
| TC-UI-SIGNUP-005 | 올바른 입력으로 가입 버튼 탭 | AuthController.signUp 호출 |
| TC-UI-SIGNUP-006 | 이미 가입된 이메일 에러 | "이미 가입된 이메일입니다" 에러 메시지 표시 |

### 2.6 Widget/Integration Tests — Router (router_test.dart)

**대상:** `lib/app/router.dart`

| 테스트 ID | 시나리오 | 기대 라우팅 |
|-----------|---------|-----------|
| TC-ROUTER-001 | 미인증 상태에서 앱 시작 | /login 화면 표시 |
| TC-ROUTER-002 | 인증된 상태에서 앱 시작 | /home 화면 표시 |
| TC-ROUTER-003 | 인증된 상태에서 /login 직접 접근 | /home으로 리디렉션 |
| TC-ROUTER-004 | 미인증 상태에서 /home 직접 접근 | /login으로 리디렉션 |

---

## 3. 테스트 실행 방법

```bash
# 전체 테스트 실행
flutter test

# 특정 파일만 실행
flutter test test/core/utils/validators_test.dart
flutter test test/features/auth/

# 커버리지 포함
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 4. Mock 생성 명령

```bash
# mockito 코드 생성
dart run build_runner build --delete-conflicting-outputs
```

## 5. 주요 의존성 (pubspec.yaml에 추가 필요)

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.3.5
  go_router: ^14.8.1
  firebase_core: ^3.9.0
  firebase_auth: ^5.4.1
  cloud_firestore: ^5.6.2

dev_dependencies:
  mockito: ^5.4.4
  build_runner: ^2.4.13
  riverpod_generator: ^2.4.3
  custom_lint: ^0.7.5
  riverpod_lint: ^2.6.5
```
