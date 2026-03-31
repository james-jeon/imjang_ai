# 28. 서드파티 연동 가이드 (Third-party Integration)

> 외부 서비스(API, SDK, SaaS)를 연동할 때의 설계 원칙, 장애 대응, 테스트 전략.

---

## 1. 원칙

1. **격리**: 서드파티 호출을 래퍼/어댑터로 감싼다. 비즈니스 로직에 직접 노출 금지
2. **장애 내성**: 외부 서비스 장애가 앱 전체를 다운시키지 않도록 방어
3. **교체 가능**: 인터페이스 뒤에 숨겨서 서드파티 변경 시 영향 최소화
4. **비밀 분리**: API 키, 시크릿은 코드에 포함하지 않음

### 현재 주요 서드파티 의존성

| 서비스 | 용도 | 플랫폼 |
|--------|------|--------|
| **MocaSDK / MocaBLESDK** | BLE 통신, 암호화, 크리덴셜 | iOS/Android (내부 SDK) |
| **MocaNetworkSDK** | API 통신, 인증서 피닝 | iOS (내부 SDK) |
| **Firebase** | FCM 푸시, Crashlytics, DynamicLinks | iOS/Android |
| **RabbitMQ** | 마이크로서비스 간 메시지 브로커 | Backend (AFS2) |
| **etcd3** | 서비스 레지스트리/디스커버리 | Backend (AFS2) |
| **AWS SNS** | SMS 발송 | Backend |
| **Nodemailer** | 이메일 발송 | Backend |

> **내부 SDK(MocaSDK 등)**: 교체 가능성이 낮으므로 어댑터 패턴보다 직접 사용 허용. 단, 테스트 시 프로토콜/인터페이스로 목 가능하게 설계.

---

## 2. 아키텍처 패턴

### 2.1 어댑터 패턴 (Adapter/Wrapper)

```kotlin
// ❌ Bad — 비즈니스 로직에서 직접 호출
class CardService {
    fun getCards() = FirebaseFirestore.getInstance()
        .collection("cards").get()
}

// ✅ Good — 인터페이스 + 어댑터
interface CardRepository {
    suspend fun getCards(): List<Card>
}

class FirestoreCardRepository : CardRepository {
    override suspend fun getCards(): List<Card> {
        return FirebaseFirestore.getInstance()
            .collection("cards").get()
            .await().toCards()
    }
}

// 테스트 시
class FakeCardRepository : CardRepository {
    override suspend fun getCards() = listOf(Card("test"))
}
```

### 2.2 Anti-Corruption Layer (ACL)

외부 API의 데이터 모델을 내부 모델로 변환:

```kotlin
// 외부 API 응답 모델 (서드파티 형식 그대로)
data class ExternalCardResponse(
    val card_id: String,      // snake_case
    val is_active: Boolean,
    val expire_date: String   // "20240131" 형식
)

// 내부 도메인 모델
data class Card(
    val id: String,            // 내부 네이밍
    val isActive: Boolean,
    val expiresAt: LocalDate   // 표준 타입
)

// 변환기
fun ExternalCardResponse.toDomain() = Card(
    id = card_id,
    isActive = is_active,
    expiresAt = LocalDate.parse(expire_date, DateTimeFormatter.ofPattern("yyyyMMdd"))
)
```

---

## 3. 장애 대응 패턴

### 3.1 타임아웃

| 항목 | 기본값 | 비고 |
|------|--------|------|
| Connection Timeout | 5초 | 연결 수립까지 |
| Read Timeout | 10초 | 응답 수신까지 |
| 전체 Timeout | 30초 | 요청 시작~완료 |

```kotlin
val client = OkHttpClient.Builder()
    .connectTimeout(5, TimeUnit.SECONDS)
    .readTimeout(10, TimeUnit.SECONDS)
    .callTimeout(30, TimeUnit.SECONDS)
    .build()
```

### 3.2 재시도 (Retry)

| 항목 | 기준 |
|------|------|
| 재시도 대상 | 5xx, 타임아웃, 네트워크 에러 |
| 재시도 불가 | 4xx (클라이언트 오류) |
| 최대 횟수 | 3회 |
| 백오프 | Exponential (1초, 2초, 4초) + Jitter |

```kotlin
suspend fun <T> retryWithBackoff(
    maxRetries: Int = 3,
    initialDelay: Long = 1000,
    block: suspend () -> T
): T {
    var currentDelay = initialDelay
    repeat(maxRetries - 1) {
        try { return block() }
        catch (e: IOException) {
            delay(currentDelay + Random.nextLong(500))
            currentDelay *= 2
        }
    }
    return block() // 마지막 시도
}
```

### 3.3 서킷 브레이커 (Circuit Breaker)

```
CLOSED → (실패 5회 연속) → OPEN → (30초 대기) → HALF_OPEN → (성공) → CLOSED
                                                            → (실패) → OPEN
```

| 상태 | 동작 |
|------|------|
| CLOSED | 정상 호출 |
| OPEN | 즉시 실패 반환 (외부 호출 차단) |
| HALF_OPEN | 1건만 시도하여 복구 확인 |

### 3.4 폴백 (Fallback)

외부 서비스 실패 시 대체 동작:

| 전략 | 예시 |
|------|------|
| 캐시 반환 | 마지막 성공 응답 반환 |
| 기본값 | 카드 수 = 0 (빈 상태) |
| 부분 기능 제공 | 문열기 불가, 카드 목록만 표시 |
| 사용자 알림 | "일시적 오류. 잠시 후 다시 시도해주세요" |

---

## 4. 인증 & 시크릿

### 4.1 API 키 관리

| 환경 | 저장 방식 |
|------|----------|
| 로컬 개발 | `.env` 파일 (`.gitignore`에 포함) |
| CI/CD | 환경 변수 / Secret Manager |
| 서버 | AWS Secrets Manager / HashiCorp Vault |
| 모바일 | 빌드 시 주입 (BuildConfig / xcconfig) |

### 4.2 금지 사항

- 소스 코드에 API 키 하드코딩 ❌
- Git 히스토리에 시크릿 커밋 ❌ (실수 시 즉시 키 로테이션)
- 로그에 인증 토큰 출력 ❌

---

## 5. 테스트 전략

### 5.1 단위 테스트 — 어댑터 격리

```kotlin
@Test
fun `adapter converts external response to domain model`() {
    val external = ExternalCardResponse("C001", true, "20240131")
    val card = external.toDomain()

    assertEquals("C001", card.id)
    assertTrue(card.isActive)
    assertEquals(LocalDate.of(2024, 1, 31), card.expiresAt)
}
```

### 5.2 통합 테스트 — MockWebServer

```kotlin
@Test
fun `fetches cards from API successfully`() {
    server.enqueue(MockResponse()
        .setBody(readFixture("card_list_response.json"))
        .setResponseCode(200))

    val cards = repository.getCards()

    assertEquals(3, cards.size)
}

@Test
fun `returns empty list on 500 error after retries`() {
    repeat(3) {
        server.enqueue(MockResponse().setResponseCode(500))
    }

    val cards = repository.getCards()
    assertEquals(emptyList<Card>(), cards)
}
```

### 5.3 계약 테스트 (Contract Test)

외부 API의 응답 형식이 변경되지 않았는지 확인:

```kotlin
@Test
fun `API response matches expected schema`() {
    // 실제 API 스키마와 fixture가 일치하는지 검증
    val schema = readSchema("card_api_schema.json")
    val fixture = readFixture("card_list_response.json")
    assertTrue(schema.validate(fixture).isValid)
}
```

---

## 6. 메시지 브로커 연동 (RabbitMQ)

AFS2 마이크로서비스 간 통신에 사용.

| 항목 | 기준 |
|------|------|
| 메시지 포맷 | JSON + correlation_id 포함 |
| 에러 처리 | Dead Letter Queue(DLQ)로 실패 메시지 격리 |
| 재시도 | 최대 3회, exponential backoff |
| 멱등성 | 동일 메시지 중복 처리 방지 (message_id 기반) |
| 모니터링 | 큐 길이, 소비 지연 메트릭 수집 |

## 7. 버전 관리

| 항목 | 기준 |
|------|------|
| API 버전 | URL에 명시 (`/v1/`, `/v2/`) |
| SDK 버전 | 정확한 버전 고정 (§ 25_dependency_management.md) |
| Breaking Change | 최소 1개 버전 하위 호환 유지 |
| Deprecation | 6개월 전 공지 → migration guide 제공 |

---

## 8. 연동 체크리스트

새 서드파티 연동 시 아래 항목 확인:

| 항목 | 확인 |
|------|------|
| 어댑터/래퍼로 격리했는가? | ☐ |
| 타임아웃 설정했는가? | ☐ |
| 재시도 로직 있는가? (멱등 API만) | ☐ |
| 폴백 동작 정의했는가? | ☐ |
| API 키를 코드 밖에서 관리하는가? | ☐ |
| 에러 응답별 처리가 있는가? (4xx, 5xx) | ☐ |
| 모델 변환기(ACL)가 있는가? | ☐ |
| 단위 테스트 + MockServer 테스트 작성했는가? | ☐ |
| 모니터링/로깅 추가했는가? (§ 23_monitoring.md) | ☐ |
| Rate limit 확인했는가? | ☐ |

---

## 9. AI 에이전트 규칙

1. **외부 API 직접 호출 금지** → 반드시 어댑터/래퍼 경유
2. **타임아웃 필수** → 외부 호출에 타임아웃 없으면 리뷰 반려
3. **에러 처리 필수** → try-catch 없는 외부 호출 금지. 실패 시 폴백 또는 적절한 에러 전파
4. **API 키 코드 내 금지** → BuildConfig/xcconfig/환경 변수로 주입
5. **새 SDK 추가 시** → § 25_dependency_management.md 체크리스트 통과 필수
6. **외부 모델 내부 전파 금지** → ACL로 변환 후 도메인 모델만 사용
