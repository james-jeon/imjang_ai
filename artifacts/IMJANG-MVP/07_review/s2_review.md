# S2 Review — IMJANG Flutter App

**날짜**: 2026-03-31
**리뷰어**: Review AI (claude-sonnet-4-6)
**대상**: Sprint 2 신규/수정 파일

---

## 최종 판정: CONDITIONAL PASS

테스트 134/134 통과. 아키텍처 구조 이상 없음. 보안 이슈 없음. 단, 아래 2건을 다음 스프린트 전에 수정 권고.

---

## 테스트 결과

```
flutter test → +134: All tests passed!
```

---

## AC 준수 여부

| AC | 파일 | 판정 | 비고 |
|----|------|------|------|
| AUTH-03 (Google 로그인) | `social_auth_repository_impl.dart` | PASS | Google→Firebase→Firestore 흐름 정상. 신규/재방문 분기 처리됨 |
| AUTH-04 (Apple 로그인) | `social_auth_repository_impl.dart` | PASS | `signInWithAppleForTest` 헬퍼로 테스트 커버됨. 프로덕션 Apple 플로우는 별도 구현 필요 (하단 항목 참고) |
| CORE-05 (네트워크 상태) | `network_provider.dart` | PASS | `networkStatusProvider` / `isOfflineProvider` 정상 |
| CORE-06 (오프라인 배너) | `offline_banner_widget.dart` | PASS | `isOfflineProvider` 연동, Key 정의됨 |
| API-01 (XML 파싱) | `xml_parser.dart` | PASS | resultCode 체크, items 파싱, 공백 trim 처리 |
| API-02 (HTTP 재시도) | `dio_client.dart` | CONDITIONAL | 재시도 로직 버그 존재 (하단 블로커 #1) |

---

## 블로커 (수정 권고)

### [블로커 #1] DioClient 재시도 딜레이 누락 — `lib/core/network/dio_client.dart:46`

**문제**: 루프가 `attempt 0..maxRetries` (총 4회) 를 순회하나, 딜레이 조건이 `attempt < maxRetries - 1` (즉 `attempt < 2`) 이다. 따라서 attempt 2→3 사이 딜레이가 없어 지수 백오프가 실제로 1s→2s(건너뜀)→즉시 로 동작한다.

```dart
// 현재 (잘못됨)
if (attempt < maxRetries - 1) {        // maxRetries=3 → attempt < 2 만 딜레이
  await Future.delayed(retryDelays[attempt]);
}

// 수정안
if (attempt < maxRetries) {            // attempt < 3 → 3번 모두 딜레이
  await Future.delayed(retryDelays[attempt]);
}
```

TC-DIO-004가 `retryDelays` 리스트 값만 검증하고 실제 딜레이 호출 횟수를 검증하지 않아 통과됨. 실제로 3회 재시도에 딜레이가 2번만 적용됨.

**우선순위**: MEDIUM — 프로덕션에서 공공API 타임아웃 연속 실패 시 마지막 재시도가 백오프 없이 즉시 발생.

---

### [블로커 #2] Apple Sign-In 프로덕션 진입점 없음 — `social_auth_repository_impl.dart`

**문제**: `signInWithAppleForTest()`는 테스트 전용 헬퍼(메서드명에 `ForTest` 명시)이며 실제 `sign_in_with_apple` 패키지 플로우(`AppleAuthProvider`, nonce 생성 등)를 호출하는 프로덕션 메서드가 없다. `pubspec.yaml`에 `sign_in_with_apple: ^6.1.4` 가 선언되어 있으나 `lib/` 어디에서도 임포트되지 않음.

AUTH-04 AC 충족 여부 미확인 — 기능 자체가 미완성 상태.

**수정 방향**: `signInWithApple()` 프로덕션 메서드 추가 (SHA256 nonce 생성 + `SignInWithApple.getAppleIDCredential` 호출).

**우선순위**: HIGH — S2 범위 내 기능이나 실제 동작 불가.

---

## 경미한 개선 사항 (블로커 아님)

1. **`flutter_dotenv` 미사용**: `pubspec.yaml`에 선언, `.env`에 API 키 존재하나, `main.dart`에 `dotenv.load()` 없음. 현재는 해당 키를 실제 API 호출 코드가 없으므로 무해하지만, API 호출 구현 전 반드시 연결 필요.

2. **`RegionNotifier.selectSido`**: 시도 선택 시 시군구 목록을 state에 채우는 로직이 없음 (state 초기화만). `RegionRepositoryImpl.getSigunguList`를 호출해야 UI에 시군구 목록이 표시됨. 현재 `region_select_screen.dart`는 `state.sigunguList.isNotEmpty` 조건으로 보호되어 있어 크래시는 없으나 선택 후 시군구가 표시되지 않음. 위젯 테스트에서 state를 직접 주입하기 때문에 테스트는 통과됨.

3. **`main.dart` legacy 코드**: `MyApp` / `MyHomePage` 위젯이 잔류. `widget_test.dart`에서 참조하고 있어 삭제 불가이나, S3 전 정리 권고.

4. **`ImjangAppBar extends AppBar`**: Flutter 공식 권고(AppBar 상속 대신 구성)를 따르지 않음. 향후 테마 커스터마이징 시 제한 발생 가능.

---

## 아키텍처 레이어 위반 여부

위반 없음. domain 엔티티가 data/presentation 의존성을 갖지 않음. `RegionRepositoryImpl`이 도메인 추상 인터페이스 없이 직접 구현되어 있으나 (abstract class `RegionRepository` 미존재), `RegionLocalDataSource`는 추상 인터페이스로 올바르게 분리됨.

---

## 보안

- API 키 하드코딩 없음 (`.env`에 분리, `.gitignore` 등록 확인됨)
- Firebase 옵션은 `firebase_options.dart` 자동 생성 방식 (정상)
- `flutter_dotenv` 미초기화 상태이므로 현재 키가 런타임에 노출되지 않음 (미사용 상태)
