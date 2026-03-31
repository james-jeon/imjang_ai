# S1 Code Review

> 리뷰어: Review AI (Claude Sonnet 4.6)
> 리뷰 대상: Sprint 1 구현 — 22개 파일 (lib/ 전체)
> 리뷰 일시: 2026-03-31

---

## 판정: CONDITIONAL PASS

핵심 AC는 대부분 충족되었으나, 두 가지 아키텍처 위반(domain→data 역방향 의존, AuthRemoteDataSource 미사용)과 NotoSansKR 폰트 미등록 문제가 머지 전 수정을 요한다. 보안 취약점은 없고, 테스트 구조와 Widget Key 계약은 양호하다.

---

## AC 충족 검증

### FR-AUTH-01 (회원가입)

| 인수조건 | 판정 | 근거 |
|---------|------|------|
| 유효한 이메일 형식 검증 | PASS | `Validators.validateEmail` — regex `^[^@\s]+@[^@\s]+\.[^@\s]+$` 구현, TC-VAL-001~005 커버 |
| 비밀번호 8자 이상 검증 | PASS | `Validators.validatePassword` — `value.length < 8` 조건, TC-VAL-006~008 커버 |
| 비밀번호 확인 일치 검증 | PASS | `Validators.validatePasswordConfirm`, `SignupScreen`에서 `_passwordController.text`와 비교, TC-VAL-009~010 커버 |
| 이미 가입된 이메일 에러 → "이미 가입된 이메일입니다" | PASS | `AuthRepositoryImpl._mapFirebaseAuthException` — `email-already-in-use` 매핑 구현 |
| 에러 메시지 UI 표시 (TC-AUTH-002a) | PASS | `SignupScreen`에서 `authState is AsyncError` 시 `authState.error.toString()` 렌더링 |

**경고 (non-blocking):** 회원가입 시 `displayName`은 `email.split('@').first`로 자동 생성된다. 사용자 입력 필드가 없다. AC 원문에 displayName 입력 요건이 명시되지 않았으므로 현재 MVP 범위에서는 허용되나, 실제 Firebase User의 `displayName`이 업데이트되지 않는다. `firebaseAuth.createUserWithEmailAndPassword` 호출 후 `user.updateDisplayName()`이 없어 Firebase 프로필과 앱 내부 모델이 불일치한다 (중요도: Low, S2 이전에 수정 권장).

### FR-AUTH-02 (로그인)

| 인수조건 | 판정 | 근거 |
|---------|------|------|
| 올바른 자격증명 → 로그인 성공 | PASS | `AuthRepositoryImpl.signInWithEmail` + `authControllerProvider` 통한 상태 전파, TC-CTRL-003 커버 |
| 잘못된 자격증명 → "이메일 또는 비밀번호가 일치하지 않습니다" 에러 | PASS | `wrong-password`, `user-not-found`, `invalid-credential` 3개 코드 → 동일 메시지 매핑 |
| 에러 메시지 UI 표시 (TC-AUTH-007a) | PASS | `LoginScreen`에서 `AsyncError` 시 에러 텍스트 렌더링 |
| 세션 지속성 (앱 재시작 후 로그인 유지) | PASS | `authStateChangesProvider` — `FirebaseAuth.authStateChanges()` 스트림 구독, `router.dart`에서 auth 상태에 따라 리다이렉트 |

**주의:** 홈 이동은 `authStateChangesProvider` 스트림 변경 → `routerProvider` 재평가 → redirect 로직으로 처리된다. `AuthController.signIn`이 성공해도 `authStateChangesProvider`가 별도 스트림이므로, Firebase가 실제로 auth state 변경을 emit해야 라우팅이 일어난다. Firebase 미설정 상태에서는 검증 불가. 단, 구조는 올바르다.

### CORE-01: 폴더 구조

| 항목 | 판정 | 비고 |
|------|------|------|
| `app/`, `core/`, `shared/`, `features/auth/` 기본 구조 | PASS | spec과 일치 |
| `core/constants/api_constants.dart` | ABSENT | spec에 명시되어 있으나 미생성. S1 범위 내 API 호출이 없으므로 non-blocking |
| `core/network/` (network_info, dio_client) | ABSENT | S1 범위 외 — non-blocking |
| `core/utils/date_utils.dart`, `xml_parser.dart` | ABSENT | S1 범위 외 — non-blocking |
| `shared/widgets/app_error_widget.dart`, `loading_widget.dart` | PASS | 구현됨 |
| 화면 전용 `widgets/` 서브폴더 | ABSENT | `features/auth/presentation/screens/widgets/` 미생성, 현재 화면 전용 위젯 없으므로 non-blocking |
| `AuthRemoteDataSource` 구현체 | **FAIL** | 인터페이스만 존재, 구현체 없음. 현재 `AuthRepositoryImpl`이 `FirebaseAuth`를 직접 사용하여 DataSource 레이어를 우회 |

### CORE-02: Riverpod 아키텍처

| 항목 | 판정 | 비고 |
|------|------|------|
| `ProviderScope` 루트 적용 | PASS | `main.dart` |
| `authStateChangesProvider` (StreamProvider) | PASS | `auth_provider.dart` |
| `authControllerProvider` (AutoDisposeNotifierProvider) | PASS | `auth_controller.dart` |
| `authRepositoryProvider`, `firebaseAuthProvider` 등 Provider 분리 | PASS | |
| Provider 네이밍 컨벤션 | PASS | `*Provider` / `*Notifier` 일관성 유지 |

### CORE-03: go_router 라우팅

| 항목 | 판정 | 비고 |
|------|------|------|
| `/`, `/login`, `/signup`, `/home` 라우트 정의 | PASS | |
| 미인증 → `/login` 리다이렉트 | PASS | redirect 로직 구현 |
| 인증 → `/home` 리다이렉트 | PASS | |
| 로딩 중 splash 유지 | PASS | `isLoading` 시 `return null` (현재 route 유지) |

### CORE-04: 테마

| 항목 | 판정 | 비고 |
|------|------|------|
| Material 3 + ColorScheme | PASS | `useMaterial3: true`, 녹색 시드 컬러 |
| TextTheme 정의 | PASS | headlineLarge~labelLarge 정의 |
| InputDecorationTheme | PASS | |
| ElevatedButtonTheme | PASS | |
| `fontFamily: 'NotoSansKR'` | **FAIL** | pubspec.yaml에 NotoSansKR 폰트 에셋이 등록되어 있지 않음. 빌드는 되지만 실제 폰트가 적용되지 않아 시스템 기본 폰트 사용 |

---

## 코드 품질

### 긍정적 사항

1. **Widget Key 계약 완비**: `login_email_field`, `login_password_field`, `login_submit_button`, `login_signup_link`, `signup_email_field`, `signup_password_field`, `signup_password_confirm_field`, `signup_submit_button` — Widget 테스트와 1:1 대응.

2. **에러 핸들링 체인**: `FirebaseAuthException` → `AuthAppException` (code + message) → `AsyncError` → UI 텍스트 렌더링으로 레이어 간 변환이 명확하다. 특히 `invalid-credential` 코드(Firebase 신버전 통합 오류 코드)까지 처리한 것은 좋다.

3. **TextEditingController dispose**: 모든 Screen에서 `dispose()`에서 컨트롤러를 해제하고 있다.

4. **Validators 순수성**: `Validators` 클래스는 정적 메서드만 가진 순수 유틸리티로, Flutter 의존성이 없다. 독립 단위 테스트 가능.

5. **AutoDispose 사용**: `authControllerProvider`가 `AutoDisposeNotifierProvider`로 선언되어 메모리 누수 위험을 줄인다.

### 문제점

#### [BLOCKER] domain 레이어가 data 레이어를 import — Clean Architecture 위반

**파일:** `lib/features/auth/domain/repositories/auth_repository.dart`
**코드:**
```dart
import 'package:imjang_app/features/auth/data/repositories/auth_repository_impl.dart';
```

domain 레이어(`auth_repository.dart`)가 data 레이어(`auth_repository_impl.dart`)를 직접 import하고 `authRepositoryProvider`를 정의하고 있다. Clean Architecture의 의존 방향(Presentation → Domain → Data)이 역전되어 있다. Domain은 Data를 알아서는 안 된다.

**영향:** 테스트에서 `authRepositoryProvider`를 domain 레이어에서 import하는 구조가 고착되고, 나중에 구현체 교체 시 domain 파일을 수정해야 하는 문제가 생긴다.

**수정 방향:** `authRepositoryProvider`를 별도 파일(`core/providers/auth_providers.dart` 또는 `features/auth/presentation/providers/`)로 이동하거나, data 레이어(`auth_repository_impl.dart`)에서 정의한다.

#### [BLOCKER] `AuthRemoteDataSource` 인터페이스가 구현되지 않음

**파일:** `lib/features/auth/data/datasources/auth_remote_datasource.dart`

인터페이스는 정의되어 있으나 구현체(`AuthRemoteDataSourceImpl`)가 없고, `AuthRepositoryImpl`이 DataSource를 전혀 사용하지 않는다. 즉 DataSource 레이어가 dead code이다. S1 범위에서 구조를 확정하는 것이 목적이라면, 둘 중 하나를 선택해야 한다:

- **Option A**: DataSource 구현체를 만들고 `AuthRepositoryImpl`이 DataSource를 주입받도록 수정 (spec 준수)
- **Option B**: S1에서는 DataSource 레이어를 제거하고 Repository가 직접 Firebase를 사용하도록 명시적으로 결정 (Decision Record 추가)

현재 상태는 spec과 구현이 불일치하며, 구조가 명확하지 않다.

#### [NON-BLOCKING] `main.dart`에 불필요한 레거시 코드

**파일:** `lib/main.dart` (17~76번째 줄)

`MyApp`, `MyHomePage`, `_MyHomePageState` 클래스가 남아있다. 주석에 "backward compatibility with widget_test.dart"라고 명시되어 있지만, 실제 `widget_test.dart`도 정리 대상이다. 프로덕션 코드에 Flutter 기본 카운터 앱 코드가 남아있는 것은 코드 가독성과 유지보수에 나쁜 영향을 준다.

#### [NON-BLOCKING] `TC-UI-LOGIN-005` 테스트의 이중 오버라이드

**파일:** `test/features/auth/presentation/screens/login_screen_test.dart` (122~130번째 줄)

```dart
overrides: [
  authControllerProvider.overrideWith(() {
    mockAuthController;  // 이 줄은 아무 효과 없음 (표현식만 있고 반환하지 않음)
    return mockAuthController;
  }),
],
```

불필요한 이중 오버라이드 블록이고, 내부의 `mockAuthController;`는 statement expression으로 아무 동작도 하지 않는다. Dart 분석기가 경고를 낼 수 있다. `buildSubject()` 기본 오버라이드가 이미 적용되므로 해당 `overrides: []` 블록 자체가 필요 없다.

#### [NON-BLOCKING] `routerProvider`가 auth state 변경 시 GoRouter 인스턴스 재생성

**파일:** `lib/app/router.dart`

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return GoRouter(...);
});
```

`authStateChangesProvider`를 watch하므로 인증 상태가 변경될 때마다 GoRouter 인스턴스 전체가 재생성된다. go_router 공식 권장 패턴은 `GoRouter`의 `refreshListenable`을 사용하거나, `redirect` 콜백 내에서 상태를 읽는 방식이다. 현재 구현은 기능은 동작하지만, 라우터 재생성 비용이 있고 GoRouter 상태(현재 위치 등)가 초기화될 수 있다.

---

## 보안

| 항목 | 판정 | 비고 |
|------|------|------|
| 비밀번호 평문 로깅 없음 | PASS | `_passwordController.text`가 로그에 출력되지 않음 |
| Firebase API 키 하드코딩 | N/A | Firebase 미설정 상태 — `google-services.json` / `GoogleService-Info.plist` 미포함 (정상, .gitignore 처리 예정) |
| 에러 메시지 정보 노출 | PARTIAL | `default` 케이스에서 `'인증 오류가 발생했습니다: ${e.message}'`로 Firebase 내부 메시지가 UI에 노출될 수 있다. MVP에서는 허용 수준이나, 프로덕션 전 generic 메시지로 교체 권장 |
| 비밀번호 필드 `obscureText` 적용 | PASS | 로그인/회원가입 모두 `obscureText: true` |
| XSS / 인젝션 | N/A | Flutter 네이티브 앱, 해당 없음 |

---

## 개선 권장사항 (non-blocking)

1. **NotoSansKR 폰트 등록**: `pubspec.yaml`에 font 에셋을 추가하거나, Google Fonts 패키지 (`google_fonts`)를 사용한다.

2. **Firebase displayName 동기화**: `signUpWithEmail` 성공 후 `user.updateDisplayName(displayName)` 호출을 추가하여 Firebase 프로필과 앱 내부 모델을 일치시킨다.

3. **`main.dart` 레거시 코드 제거**: `MyApp`, `MyHomePage` 제거 후 `widget_test.dart`도 `ImjangApp` 기반으로 갱신한다.

4. **`routerProvider` 리팩토링**: GoRouter를 상수 인스턴스로 유지하고 `refreshListenable`로 auth 상태를 구독하는 패턴으로 전환한다. 예:
   ```dart
   final routerProvider = Provider<GoRouter>((ref) {
     return GoRouter(
       refreshListenable: RouterNotifier(ref),
       redirect: (context, state) { ... },
       routes: [...],
     );
   });
   ```

5. **로그인 화면 AppBar 제목**: 현재 `'LoginScreen'` (영문)으로 되어 있다. UX 관점에서 `'로그인'` 또는 `'임장노트'`로 변경 권장. 마찬가지로 SignupScreen은 `'SignupScreen'` → `'회원가입'`.

6. **`validatePasswordConfirm` 빈 문자열 처리**: 현재 `confirm.isEmpty`에서 에러를 반환한다. 이는 "비밀번호 확인 필드를 비워둔 경우"와 "불일치"를 같은 메시지로 처리하는 것인데, 빈 경우 별도 메시지("비밀번호 확인을 입력해 주세요")를 반환하면 UX가 개선된다.

7. **`riverpod_lint` 미설치**: spec의 `pubspec.yaml` 예시에는 `custom_lint`, `riverpod_lint`가 포함되어 있으나 실제 `pubspec.yaml`에는 없다. Riverpod 코드 품질 lint 추가 권장.

---

## 블로커 이슈 (머지 전 수정 필수)

### BLOCKER-01: domain 레이어의 data 레이어 역방향 import

- **파일**: `lib/features/auth/domain/repositories/auth_repository.dart:3`
- **내용**: `authRepositoryProvider` 정의를 data 레이어 또는 별도 providers 파일로 이동
- **영향**: Clean Architecture 위반, 의존 방향 역전

### BLOCKER-02: `AuthRemoteDataSource` 구현체 없음 또는 사용되지 않는 인터페이스

- **파일**: `lib/features/auth/data/datasources/auth_remote_datasource.dart`
- **내용**: 구현체 추가 또는 S1 Decision Record에 "DataSource 레이어 S2로 연기" 명시
- **영향**: spec과 구현 불일치, dead code

### BLOCKER-03: `fontFamily: 'NotoSansKR'` 폰트 에셋 미등록

- **파일**: `lib/app/theme.dart:11`, `pubspec.yaml`
- **내용**: pubspec.yaml에 NotoSansKR 폰트 에셋 등록 또는 `google_fonts` 패키지 사용
- **영향**: 폰트가 적용되지 않아 디자인 스펙과 불일치

---

## riverpod pub-cache 패치 이슈 검토

`patches/riverpod_notifier_mock_fix.patch` 및 `tool/apply_patches.sh`는 riverpod 2.6.1의 `NotifierProviderElement`가 mockito 생성 mock에서 private method `_setElement`를 찾지 못해 `NoSuchMethodError`가 발생하는 문제를 우회하기 위해 pub-cache 소스를 직접 패치한다.

**평가: 주의 필요하나 MVP에서는 허용 수준**

- **장점**: 테스트 실행을 위한 실용적 해결책. 패치 내용이 단순하고(try-catch 추가) 런타임 동작에 영향 없음.
- **위험**: pub-cache 수정은 팀원별로 재적용이 필요하고, `flutter pub upgrade` 시 무효화된다. CI/CD 파이프라인에서 별도 step이 필요하다.
- **대안 (미검토)**: `overrideWith`로 Notifier mock 대신 실제 상태를 직접 주입하는 방식으로 테스트 구조를 변경하면 패치가 불필요할 수 있다. 또는 riverpod 최신 버전에서 수정되었는지 확인 필요.
- **권장**: S2 이전에 패치 없이 동작하는 테스트 패턴으로 전환 검토. CI 스크립트에 패치 자동 적용 step 추가(단기).

---

## 요약 체크리스트

| 항목 | 상태 |
|------|------|
| FR-AUTH-01 이메일 유효성 검증 | PASS |
| FR-AUTH-01 비밀번호 ≥8자 검증 | PASS |
| FR-AUTH-01 비밀번호 확인 검증 | PASS |
| FR-AUTH-01 중복 이메일 에러 처리 | PASS |
| FR-AUTH-02 올바른 로그인 → 홈 이동 | PASS (구조 올바름, Firebase 미설정으로 E2E 미확인) |
| FR-AUTH-02 잘못된 자격증명 → 에러 | PASS |
| FR-AUTH-02 세션 지속성 | PASS |
| CORE-01 폴더 구조 | CONDITIONAL (S1 범위 파일은 충족, DataSource 레이어 불일치) |
| CORE-02 Riverpod 아키텍처 | CONDITIONAL (domain→data 역방향 의존) |
| CORE-03 go_router 라우팅 | PASS |
| CORE-04 테마 | CONDITIONAL (NotoSansKR 미등록) |
| Widget Key 계약 | PASS |
| 에러 핸들링 체인 | PASS |
| 보안 취약점 | PASS (없음) |
| 테스트 커버리지 | PASS (모든 AC에 대응 테스트 존재) |
