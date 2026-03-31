# 24. 테스트 데이터 & 목 전략 (Test Data & Mock Strategy)

> 테스트의 신뢰성과 재현성을 보장하기 위한 데이터 관리 및 목/스텁 사용 기준.

---

## 1. 테스트 데이터 원칙

1. **자급자족**: 테스트는 외부 DB, 서버, 네트워크에 의존하지 않는다
2. **격리**: 각 테스트는 독립적 데이터를 사용하며 다른 테스트에 영향을 주지 않는다
3. **결정적**: 동일 입력 → 동일 결과. 랜덤, 현재 시간 등 비결정적 요소 제거
4. **최소 충분**: 테스트에 필요한 최소한의 데이터만 사용

---

## 2. 테스트 데이터 계층

### 2.1 인라인 데이터 (권장 — 단위 테스트)

테스트 메서드 안에서 직접 생성. 의도가 명확하고 변경 추적 쉬움.

```swift
// iOS
func test_activatedOnly_countsOne() {
    let statuses = ["activated"]
    XCTAssertEqual(WidgetDataManager.countActiveCards(statuses: statuses), 1)
}
```

```kotlin
// Android
@Test
fun `activated only counts one`() {
    val statuses = listOf("activated")
    assertEquals(1, WidgetDataManager.countActiveCards(statuses))
}
```

### 2.2 팩토리/빌더 (중규모 객체)

반복 생성되는 모델 객체는 팩토리 메서드 사용.

```kotlin
// Android
object TestUserFactory {
    fun create(
        status: String = "activated",
        name: String = "Test User",
        cardId: String = UUID.randomUUID().toString()
    ) = UserModel(cardId = cardId, name = name, status = status)
}

@Test
fun `mixed statuses count only active`() {
    val users = listOf(
        TestUserFactory.create(status = "activated"),
        TestUserFactory.create(status = "revoked"),
        TestUserFactory.create(status = "updating_access"),
    )
    assertEquals(2, WidgetDataManager.countActiveCards(users))
}
```

### 2.3 Fixture 파일 (대용량/복잡 JSON)

API 응답 목 데이터 등은 JSON 파일로 관리.

```
src/test/resources/fixtures/
├── card_list_response.json
├── login_success_response.json
└── error_401_response.json
```

- 파일명은 `{기능}_{시나리오}.json` 형식
- 각 fixture에 주석 또는 README로 용도 명시

---

## 3. 목(Mock) vs 스텁(Stub) vs 페이크(Fake)

| 종류 | 용도 | 예시 |
|------|------|------|
| **Stub** | 고정된 응답 반환 | API 클라이언트가 항상 성공 응답 반환 |
| **Mock** | 호출 여부·횟수·인자 검증 | `verify(widgetManager).updateWidgetData(...)` 호출 확인 |
| **Fake** | 간소화된 실제 구현 | 인메모리 DB, FakeSharedPreferences |

### 3.1 사용 기준

```
단위 테스트   → Stub/Mock (외부 의존성 격리)
통합 테스트   → Fake (인메모리 DB, TestServer)
E2E 테스트   → 실제 서비스 (staging 환경)
```

### 3.2 목 프레임워크

| 플랫폼 | 프레임워크 | 비고 |
|--------|-----------|------|
| Android | Mockito-Kotlin | `whenever`, `verify` 사용 |
| Android | MockK | Kotlin 전용, coroutine 지원 |
| iOS | 프로토콜 기반 수동 목 | Swift에서 Mockito 없음. 프로토콜 + 구현체 패턴 |

### 3.3 iOS 프로토콜 기반 목 패턴

```swift
protocol WidgetDataProviding {
    func getActiveCardCount() -> Int
    func isLoggedIn() -> Bool
}

class MockWidgetDataProvider: WidgetDataProviding {
    var activeCardCount = 0
    var loggedIn = false

    func getActiveCardCount() -> Int { activeCardCount }
    func isLoggedIn() -> Bool { loggedIn }
}
```

---

## 4. 네트워크 목 전략

### 4.1 Android

```kotlin
// OkHttp MockWebServer
val server = MockWebServer()
server.enqueue(MockResponse()
    .setBody(readFixture("card_list_response.json"))
    .setResponseCode(200))
server.start()

val baseUrl = server.url("/api/v1/")
```

### 4.2 iOS

```swift
// URLProtocol 서브클래스
class MockURLProtocol: URLProtocol {
    static var mockResponses: [String: (Data, Int)] = [:]

    override class func canInit(with request: URLRequest) -> Bool { true }
    override func startLoading() {
        // mockResponses에서 URL 매칭하여 응답 반환
    }
}
```

---

## 5. 시간 의존 테스트

### 5.1 현재 시간 주입

```kotlin
// ❌ Bad
val now = System.currentTimeMillis()

// ✅ Good
class WidgetDataManager(private val clock: Clock = Clock.systemDefaultZone()) {
    fun getLastUpdated(): String {
        return Instant.now(clock).toString()
    }
}

// 테스트
val fixedClock = Clock.fixed(Instant.parse("2024-01-15T09:00:00Z"), ZoneOffset.UTC)
val manager = WidgetDataManager(clock = fixedClock)
```

### 5.2 타이머/딜레이

- `Thread.sleep` 대신 가상 시간 사용 (Kotlin: `runTest`, iOS: `XCTestExpectation`)
- 불가피한 경우 최소 대기 시간 사용 + 타임아웃 설정

---

## 6. 경계값 테스트 데이터

모든 입력에 대해 아래 경계값을 테스트 데이터에 포함:

| 카테고리 | 데이터 |
|----------|--------|
| 빈 값 | `""`, `[]`, `null`, `0` |
| 최소/최대 | `Int.MIN_VALUE`, `Int.MAX_VALUE`, 문자열 길이 한계 |
| 특수 문자 | `<script>`, `'; DROP TABLE`, 이모지, 유니코드 |
| 대량 데이터 | 1,000건 이상 리스트 |
| 중복 | 동일 값 반복 입력 |

---

## 7. AI 에이전트 규칙

1. **단위 테스트 작성 시** → 인라인 데이터 우선. 팩토리는 3회 이상 반복 시 도입
2. **API 호출 코드 테스트** → MockWebServer(Android) / MockURLProtocol(iOS) 사용. 실제 서버 호출 금지
3. **DB 테스트** → 인메모리 DB 사용 (Room: `inMemoryDatabaseBuilder`, CoreData: `NSInMemoryStoreType`)
4. **시간 의존 코드** → Clock/TimeProvider 주입 패턴 사용. `Date()` 직접 호출 금지
5. **테스트 데이터에 민감 정보 금지** → 실제 이메일, 전화번호, 카드번호 사용하지 않음
6. **경계값 테스트** → 빈 배열, 대량 데이터, 음수 케이스 반드시 포함 (WIDGET-001 교훈)
