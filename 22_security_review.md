# 보안 리뷰 및 가이드라인

## 목적

AI 주도 개발 프로세스에서 보안 품질을 체계적으로 확보한다.
모바일 앱(BLE 인증, 카드 크리덴셜, 결제성 기능)의 특성을 반영하며, AI Agent가 코드 리뷰 시 자동으로 검증하는 보안 기준을 정의한다.

> **기준 코드베이스**: `legacy/mobile_moca_mocakey_ios` (iOS), `legacy/mobile_moca_mocakey_android` (Android), `legacy/afs2` (서버)
> **보안 기준**: 모의해킹 점검 항목 + OWASP Mobile Top 10

---

## 1. 보안 리뷰 체크리스트 (OWASP Mobile Top 10 + 모의해킹)

AI가 CP3 구현 리뷰(03_ai_dev_process)에서 자동으로 검증하는 항목이다.

| 카테고리 | 확인 항목 | 위험도 | 검증 방법 |
|---------|----------|:-----:|----------|
| M1: 부적절한 크리덴셜 사용 | API Key, 토큰이 소스코드에 하드코딩되어 있지 않은가 | Critical | 정규식 스캔 (`AKIA`, `Bearer`, `sk-`, `password=`) |
| M1 | Keychain / EncryptedSharedPreferences 외 저장소에 크리덴셜을 저장하지 않는가 | Critical | 저장 API 호출 추적 |
| M2: 부적절한 공급망 보안 | 서드파티 라이브러리에 알려진 취약점(CVE)이 없는가 | High | `npm audit`, `pod audit`, Dependency Check |
| M3: 안전하지 않은 인증/인가 | JWT 만료 검증, refresh 흐름이 구현되어 있는가 | Critical | 토큰 처리 로직 리뷰 |
| M4: 입력/출력 검증 부족 | 서버·클라이언트 양쪽에서 입력을 검증하는가 | High | API 엔드포인트별 validation 확인 |
| M5: 안전하지 않은 통신 | TLS 1.2+ 사용, Certificate Pinning 적용 여부 | High | 네트워크 설정 파일 검증 |
| M6: 부적절한 개인정보 보호 | 로그에 민감 정보(카드번호, 개인정보)가 출력되지 않는가 | High | 로그 출력문 정규식 스캔 |
| M7: 불충분한 바이너리 보호 | 난독화(R8/ProGuard) 적용, 디버깅 방지 여부 | Medium | 빌드 설정 확인 |
| M8: 보안 설정 오류 | 디버그 모드가 릴리즈 빌드에서 비활성화되어 있는가 | High | 빌드 variant 설정 검증 |
| M9: 안전하지 않은 데이터 저장 | SQLite, UserDefaults에 평문 민감 데이터가 없는가 | Critical | 저장소 접근 코드 추적 |
| M10: 불충분한 암호화 | 커스텀 암호화 대신 표준 알고리즘(AES-256, ECC)을 사용하는가 | High | 암호화 API 호출 검증 |

---

## 2. 탈옥/루팅 감지 (모의해킹 필수 항목)

### iOS — 7단계 탈옥 감지 (JailBreakChecker 기준)

기존 코드베이스(`JailBreakChecker.swift`)에 구현된 7단계 검증:

| 단계 | 검증 항목 | 상세 |
|------|----------|------|
| 1 | **URL Scheme 검사** | `undecimus://`, `cydia://`, `sileo://`, `zbra://` 존재 확인 |
| 2 | **의심 파일 존재 검사** | 40+ 경로 확인: `/usr/sbin/frida-server`, `/Library/MobileSubstrate/MobileSubstrate.dylib`, `/Applications/Cydia.app` 등 |
| 3 | **파일 읽기 권한 검사** | 탈옥 관련 경로의 파일을 읽을 수 있는지 확인 |
| 4 | **제한 디렉토리 쓰기 검사** | `/`, `/root/`, `/private/`, `/jb/`에 파일 쓰기 시도 |
| 5 | **fork() 시스템 콜 검사** | 샌드박스 우회 여부 확인 (fork 성공 = 탈옥) |
| 6 | **심볼릭 링크 검사** | `/Applications`, `/usr/libexec`, `/usr/share` 등의 비정상 symlink |
| 7 | **DYLD 라이브러리 검사** | 런타임 주입 라이브러리 탐지: `SubstrateLoader`, `SSLKillSwitch2`, `TweakInject`, `CydiaSubstrate`, `PreferenceLoader` |

```swift
// 시뮬레이터 예외 처리 (Apple Silicon 대응)
func isJailbroken() -> Bool {
    #if targetEnvironment(simulator)
    return false  // ⚠️ arch(x86_64) 사용 금지 — Apple Silicon에서 오탐
    #else
    return !performChecks().passed
    #endif
}
```

### Android — 루팅 감지

| 검사 항목 | 상세 |
|----------|------|
| su 바이너리 존재 | `/system/bin/su`, `/system/xbin/su` 등 |
| Magisk 감지 | Magisk Manager 패키지, MagiskHide 상태 |
| 시스템 파티션 쓰기 | `/system` 마운트 상태 확인 |
| Play Integrity API | Google Play 서비스를 통한 디바이스 무결성 검증 |
| 빌드 태그 확인 | `Build.TAGS`에 `test-keys` 포함 여부 |

### 감지 시 동작

- **앱 강제 종료** (`Utils.isShouldExit()` → `exit(0)`)
- 서버에 탈옥/루팅 이벤트 로그 전송
- 민감 데이터(Keychain/Keystore) 접근 차단

---

## 3. 앱 무결성 검증 (모의해킹 필수 항목)

### 코드 서명 검증

| 플랫폼 | 방법 |
|--------|------|
| iOS | App Attest API — 앱 실행 환경 무결성 증명 |
| Android | Play Integrity API — APK 서명 + 디바이스 무결성 |

### 리소스 위변조 감지

| 항목 | iOS | Android |
|------|-----|---------|
| 바이너리 변조 | Code Signing + 런타임 체크섬 | APK 서명 검증 (v2/v3 signing) |
| 리소스 파일 변조 | Bundle 무결성 확인 | assets/res 해시 검증 |
| 설정 파일 변조 | Info.plist 변경 감지 | AndroidManifest 변조 감지 |
| 네이티브 라이브러리 | dylib 변조 감지 | .so 파일 해시 검증 |

### 서버 측 검증

- 앱 무결성 토큰을 서버에서 검증하여 **변조된 앱의 API 접근 차단**
- 앱 버전 + 빌드 번호를 서버 API 요청에 포함 (AFS2: `app_ver` 필드)

---

## 4. 메모리 보안 (모의해킹 필수 항목)

### 런타임 메모리 보호

| 위협 | 방어 | 플랫폼 |
|------|------|--------|
| **메모리 덤프** | 민감 데이터 사용 후 즉시 제로화 | 공통 |
| **프리다(Frida) 주입** | DYLD 라이브러리 검사 (iOS), frida-server 프로세스 감지 | 공통 |
| **디버거 연결** | `ptrace(PT_DENY_ATTACH)` (iOS), `Debug.isDebuggerConnected()` (Android) | 공통 |
| **후킹 감지** | 메서드 스위즐링 감지 (iOS), Xposed 프레임워크 감지 (Android) | 공통 |
| **키 노출** | AES 키를 메모리에 최소 시간만 유지, 사용 후 배열 제로화 | 공통 |

### 안전한 키 관리 패턴 (AFS2 Android 기준)

```java
// MocaCrypto — RSA-2048 키에서 AES 키 파생
// 키를 직접 저장하지 않고, Android Keystore의 RSA 키에서 동적으로 파생
byte[] publicKeyBytes = rsaPublicKey.getEncoded();
byte[] sha256 = MessageDigest.getInstance("SHA-256").digest(publicKeyBytes);
// 마지막 32바이트 → AES-256 키
// 바이트 32~48 → AES IV
```

### 네이티브 코드 보안

- 인증서 SHA-256 해시를 **네이티브 라이브러리**(`ExternalConstant.cpp`)에 저장
- JNI를 통해 로드 → 디컴파일 난이도 증가
- ECC 연산도 네이티브 C/C++ (`uEcc/`) 에서 수행

---

## 5. 인증서 피닝 (Certificate Pinning)

### Android (OkHttp CertificatePinner)

```kotlin
// AFS2 Android 패턴 — CertificateOkHttpClientFactory
val pinner = CertificatePinner.Builder()
    .add("*.airfob.com", "sha256/${ExternalConstant.getCertificateSHA256Key()}")
    .build()

val client = OkHttpClient.Builder()
    .certificatePinner(pinner)
    .build()
```

- SHA-256 해시를 **네이티브 라이브러리**에서 로드 (하드코딩 방지)
- 디버그 빌드에서는 피닝 비활성화 (Chucker/OkHttpProfiler 사용 시)

### iOS

- MocaNetworkSDK 내부에서 처리
- 커스텀 `URLSessionDelegate`의 `didReceiveChallenge`에서 인증서 검증

### 규칙

| 항목 | 기준 |
|------|------|
| 적용 범위 | 모든 API 통신에 적용 |
| 인증서 갱신 | 새 인증서 해시를 앱 업데이트로 배포 |
| 백업 핀 | 최소 2개 핀 (현재 + 백업) 유지 |
| 디버그 예외 | 릴리즈 빌드에서는 절대 비활성화 금지 |

---

## 6. 데이터 암호화

### 전송 중 (Data in Transit)

| 항목 | 기준 |
|------|------|
| TLS 버전 | **1.2 이상 필수**, 1.3 권장 |
| iOS ATS | `NSAppTransportSecurity` 예외 최소화. 전체 허용(`NSAllowsArbitraryLoads`) 금지 |
| Android | `network_security_config.xml`에서 cleartext 차단 |

### 저장 시 (Data at Rest)

| 데이터 | iOS | Android |
|--------|-----|---------|
| DB 전체 | CoreData + NSFileProtection | **Room + SQLCipher** (AES) |
| 카드 인증 정보 | Keychain (`kSecAttrAccessible`) | Android Keystore + EncryptedSharedPreferences |
| BLE 암호화 키 | Keychain | Android Keystore |
| 일반 설정 | UserDefaults | SharedPreferences |

### SQLCipher 암호화 (Android 실제 구현)

```java
// 암호화 키: RSA-2048 공개키의 SHA-256 해시
String encKey = MocaCrypto.getInstance().getEncryptionKey();
SupportFactory factory = new SupportFactory(encKey.getBytes());

Room.databaseBuilder(context, MocaDataBase.class, DB_NAME)
    .openHelperFactory(factory)  // SQLCipher 적용
    .build();
```

- 비디버그 빌드에서만 암호화 활성화 (`MLog.ENABLE == false`)
- 키는 Android Keystore의 RSA-2048 키에서 파생

### ECC 암호화 (BLE 통신)

| 항목 | 기준 |
|------|------|
| 알고리즘 | ECC — **prime256v1** (사이트 키), **secp160r1** (디바이스/BLE) |
| 키 교환 | ECDH (Elliptic Curve Diffie-Hellman) |
| 키 저장 | iOS: Keychain, Android: Android Keystore |
| 구현 | 네이티브 C/C++ (`uEcc/` 라이브러리) |
| 세션 키 | 통신 종료 시 즉시 폐기. 재사용 금지 |

### 사이트 키 관리 (AFS2 서버)

```sql
-- site_key 테이블: 사이트별 ECC 키 쌍 저장
`public_key` TEXT NOT NULL,
`private_key` TEXT NOT NULL,
`ecdh_curve` ENUM('prime256v1', 'secp160r1') NOT NULL,
`use_type` ENUM('site', 'mobile') NOT NULL
```

---

## 7. 인증/인가

### JWT 토큰 관리 (AFS2 기준)

| 항목 | 기준 |
|------|------|
| Access Token 유효기간 | **1시간** (3600초) |
| 저장 위치 (iOS) | Keychain (`kSecAttrAccessible = whenUnlockedThisDeviceOnly`) |
| 저장 위치 (Android) | EncryptedSharedPreferences / 메모리 |
| 세션 보안 | **마지막 로그인 시간 비교** — 새 로그인 시 이전 토큰 무효화 |
| 계정 잠금 | 비밀번호 N회 실패 → 423 Locked |
| 비밀번호 정책 | 사이트별 설정 (weak/medium/strong), 변경 주기 |

### RBAC (16 역할)

AFS2는 `@Roles()` 데코레이터로 엔드포인트별 접근을 제한한다.

```
MOCA_MASTER > MOCA_ADMIN > MOCA_OPERATOR > MOCA_OBSERVER
FED_MASTER  > FED_ADMIN  > FED_OPERATOR  > FED_OBSERVER
SITE_MASTER > SITE_ADMIN > SITE_OPERATOR > SITE_OBSERVER
+ MOBILE_USER, DEVICE_CREDENTIAL, DISTRIBUTOR_*
```

### API Key 관리

- 소스코드에 하드코딩 **절대 금지**
- 빌드 시 환경 변수에서 주입: iOS(`xcconfig`/`infoDictionary`), Android(`buildConfigField`)
- 모바일 API Key: `MocaAPIKey` (Info.plist / BuildConfig)
- Git 이력에 노출된 키는 **즉시 폐기 후 재발급**

---

## 8. 난독화 & 바이너리 보호

### Android (R8/ProGuard)

```groovy
// AFS2 Android 빌드 설정
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

**ProGuard 규칙 (실제 적용):**

| 규칙 | 목적 |
|------|------|
| `-dontoptimize` | R8 최적화 비활성화 (안정성 우선) |
| `-assumenosideeffects class android.util.Log` | 릴리즈에서 Log.d/v 호출 제거 |
| `keep class *.model.**` | Gson/Moshi 직렬화 클래스 보존 |
| `keep interface *.api.**` | Retrofit 인터페이스 보존 |
| Crashlytics mapping 업로드 | 난독화된 스택 트레이스 복원 |

### iOS

| 항목 | 설정 |
|------|------|
| Swift 최적화 | Release 빌드 `-O` 최적화 |
| Strip Symbols | `STRIP_INSTALLED_PRODUCT = YES` |
| Dead Code Stripping | `DEAD_CODE_STRIPPING = YES` |

---

## 9. 디버그 보호

### 릴리즈 빌드 검증 항목

| 항목 | iOS | Android |
|------|-----|---------|
| 디버그 가능 | `DEBUG` 매크로 미정의 | `debuggable = false` |
| 로그 제거 | `#if DEBUG` 가드 | ProGuard Log 제거 + Timber.DebugTree 미등록 |
| 디버거 감지 | `ptrace(PT_DENY_ATTACH)` | `Debug.isDebuggerConnected()` |
| 디버그 도구 | 프리다 감지 (DYLD 검사) | 프리다/Xposed 프로세스 검사 |
| 네트워크 디버그 | 프록시 감지 | Chucker/OkHttpProfiler 릴리즈 미포함 |

### 모바일 디바이스 식별 (AFS2)

```java
// Android — 비디버그 빌드에서 moca-mobile-id 헤더 추가
if (!MLog.ENABLE) {
    headers.put("moca-mobile-id", getSSID());  // 디바이스 고유 식별자
}
```

---

## 10. BLE 보안 (MocaKey 특화)

### 프로덕션 로깅 금지 항목

- BLE 디바이스 시리얼 번호
- BLE 암호화 키 / 세션 키
- 카드 크리덴셜 원본
- GATT Characteristic 원시 데이터

### Widget Extension BLE 정책

| 규칙 | 이유 |
|------|------|
| Extension에서 `MocaBackgroundScanFlag = false` 강제 | Extension 프로세스는 BLE 스캔 불가 |
| Extension에서 MocaBLESDK 직접 import 금지 | 메모리 제한(~30MB) 초과 위험 |
| BLE 작업은 메인 앱 프로세스에서만 수행 | App Intent를 통해 메인 앱에 위임 |

---

## 11. 시크릿 관리

### 소스코드 포함 금지 대상

- API Key / Secret Key
- 데이터베이스 비밀번호
- 인증서 파일 (`.p12`, `.pem`, `.cer`)
- JWT Signing Secret
- BLE 암호화 키 원본
- Firebase / AWS 크리덴셜

### 환경별 시크릿 저장소

| 환경 | 저장소 |
|------|--------|
| 로컬 개발 | `.env.local` (Git 미포함) |
| iOS 앱 | Keychain Services |
| Android 앱 | EncryptedSharedPreferences + Android Keystore |
| CI/CD | GitHub Secrets / AWS Secrets Manager |
| 서버 | AWS Secrets Manager / Vault |
| 네이티브 상수 | C++ 네이티브 라이브러리 (`ExternalConstant.cpp`) |

---

## 12. 입력 검증

### 서버 측 (AFS2 — NestJS class-validator)

| 공격 유형 | 방어 방법 |
|----------|----------|
| SQL Injection | Sequelize ORM + Parameterized Query |
| XSS | 출력 시 HTML Encoding. CSP 헤더 설정 |
| CSRF | CSRF Token 적용 (상태 변경 API) |
| Path Traversal | 허용 디렉토리 화이트리스트 |
| 입력 검증 | `class-validator` + `class-transformer` |

### 클라이언트 측

- UI에서 입력 형식 검증 (이메일, 전화번호, 길이 제한)
- 클라이언트 검증은 **UX 향상 목적**이며 보안 경계가 아님
- **서버 검증을 반드시 이중으로 적용**

---

## 13. 모의해킹 대응 체크리스트

모의해킹 점검 시 확인하는 전체 항목:

| 카테고리 | 점검 항목 | 현재 대응 |
|---------|----------|----------|
| **탈옥/루팅** | 탈옥·루팅 환경 감지 및 차단 | iOS 7단계 검증, Android su/Magisk 감지 |
| **앱 무결성** | 코드 서명 검증, 리패키징 감지 | App Attest, Play Integrity |
| **리소스 위변조** | 앱 바이너리·리소스 파일 변조 감지 | 서명 검증, 해시 체크 |
| **메모리 보호** | 런타임 메모리 덤프·조작 방어 | 키 제로화, 프리다 감지, 디버거 방지 |
| **동적 분석 방어** | 프리다·Xposed 등 후킹 도구 탐지 | DYLD 검사(iOS), 프로세스 감지(Android) |
| **인증서 피닝** | 중간자 공격(MITM) 방어 | OkHttp CertificatePinner, 네이티브 키 저장 |
| **데이터 암호화** | 저장 데이터 암호화 | SQLCipher(Android), Keychain(iOS) |
| **통신 암호화** | TLS 1.2+ 적용, 평문 통신 차단 | ATS(iOS), network_security_config(Android) |
| **난독화** | 코드 난독화 적용 | R8/ProGuard(Android), Strip Symbols(iOS) |
| **로그 보안** | 프로덕션 로그에 민감 정보 미노출 | DEBUG 가드, ProGuard Log 제거 |
| **세션 관리** | 토큰 무효화, 중복 로그인 감지 | last_login_at 비교, 계정 잠금 |
| **입력 검증** | 인젝션 공격 방어 | class-validator, Parameterized Query |

---

## 14. AI Agent 보안 규칙

### 시크릿 커밋 자동 차단

AI Agent가 커밋 또는 PR에 다음 패턴이 감지되면 **즉시 반려**한다:

```
[자동 차단 패턴]
- API Key 패턴: AKIA*, sk-*, AIza*
- 하드코딩된 비밀번호: password = "...", secret = "..."
- 인증서 파일: *.p12, *.pem, *.cer, *.key
- 토큰 문자열: Bearer eyJ*, ghp_*, gho_*
- 환경 변수 파일: .env, .env.local
```

### 가드레일 연동 (07_ai_dev_guardrails)

보안 관련 영역은 AI가 단독 변경할 수 없다. 다음 변경은 **사람 승인 필수**:

| 영역 | 경로 패턴 | 승인 필요 사유 |
|------|----------|---------------|
| 탈옥/루팅 감지 | `**/JailBreak*`, `**/RootDetect*` | 감지 로직 약화 위험 |
| 인증 시스템 | `**/auth/**`, `**/security/**` | 인증 우회 위험 |
| 암호화 로직 | `**/crypto/**`, `**/MocaCrypto*` | 암호화 약화 위험 |
| 인증서 피닝 | `**/CertificatePinner*`, `**/Certificate*` | MITM 공격 노출 |
| Keychain/Keystore | Keychain Services, Android Keystore 호출 | 크리덴셜 유출 위험 |
| 네트워크 보안 설정 | ATS 설정, `network_security_config.xml` | 통신 보안 약화 |
| BLE 인증 로직 | `**/ble/**`, MocaBLESDK 내부 | 디바이스 인증 무력화 |
| 네이티브 코드 | `**/cpp/**`, `**/jni/**`, `ExternalConstant*` | 보안 상수 노출 |
| ProGuard 규칙 | `proguard-rules.pro` | 난독화 약화 |

### Review AI 보안 자동 검증

CP3 구현 리뷰에서 Review AI가 본 문서의 체크리스트를 자동으로 적용한다:

| 리뷰 단계 | 검증 항목 |
|----------|----------|
| Claude (1차) | 시크릿 하드코딩, 가드레일 영역 변경, 인증 흐름 정합성, 탈옥/루팅 감지 |
| Codex (2차) | SQL Injection, XSS, 로그 민감 정보, 암호화 적절성, 메모리 보안 |
| CI 파이프라인 | `git-secrets` 스캔, 의존성 취약점 스캔, SAST |

보안 항목에서 **하나라도 위반이 발견되면 PR을 자동 반려**한다.

---

## 참조 문서

| 문서 | 연관 내용 |
|------|----------|
| 03_ai_dev_process | CP3 구현 리뷰에서 보안 체크리스트 적용 |
| 16_ai_dev_ci_cd | CI/CD 파이프라인에서 시크릿 스캔, SAST 실행 |
| 07_ai_dev_guardrails | 보안 영역 변경 시 사람 승인 워크플로 |
| 25_dependency_management | 의존성 보안 취약점 스캔 |
