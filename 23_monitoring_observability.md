# 23. 모니터링 & 관측성 (Monitoring & Observability)

> AI 에이전트가 코드를 생성할 때 로깅·메트릭·알림 기준을 일관되게 적용하기 위한 가이드.

---

## 1. 로깅 (Logging)

### 1.1 로그 레벨 정의

| 레벨 | 용도 | 예시 |
|------|------|------|
| **ERROR** | 즉시 대응 필요한 장애 | DB 연결 실패, 결제 실패, 인증 토큰 갱신 실패 |
| **WARN** | 잠재적 문제, 즉시 장애는 아님 | API 응답 지연 > 3초, 재시도 발생, deprecated API 호출 |
| **INFO** | 비즈니스 이벤트, 상태 변경 | 사용자 로그인, 카드 등록, 위젯 갱신 |
| **DEBUG** | 개발/디버깅용 상세 정보 | 요청/응답 페이로드, 내부 상태값 |

### 1.2 로그 포맷

AFS2는 `nest-winston`을 사용한다.

```
[LEVEL] [timestamp] [service_name] [correlation_id] message {structured_data}
```

- **timestamp**: ISO 8601 (`2024-01-15T09:30:00.123Z`)
- **correlation_id**: 요청 추적용 UUID (API Gateway → 마이크로서비스 → DB 전체 추적)
- **service_name**: 마이크로서비스 이름 (`afs2-auth`, `afs2-user` 등)
- **structured_data**: JSON 형태의 컨텍스트 정보

### 1.3 로깅 금지 항목

- 비밀번호, 토큰, API 키
- 개인정보 (주민번호, 카드번호 전체)
- 민감 헤더 (Authorization, Cookie)

### 1.4 모바일 로깅

| 항목 | iOS | Android |
|------|-----|---------|
| 프레임워크 | OSLog / os_log | Timber |
| Release 빌드 | DEBUG/INFO 제거 | Timber.DebugTree 미등록 |
| Crash 수집 | Firebase Crashlytics | Firebase Crashlytics |

---

## 2. 메트릭 (Metrics)

### 2.1 필수 수집 메트릭

#### 서버

| 메트릭 | 타입 | 설명 |
|--------|------|------|
| `http_request_duration_ms` | Histogram | API 응답 시간 |
| `http_request_total` | Counter | 요청 수 (status_code, method, path) |
| `http_error_rate` | Gauge | 5xx 비율 |
| `db_query_duration_ms` | Histogram | DB 쿼리 시간 |
| `active_connections` | Gauge | DB 커넥션 풀 사용량 |

#### 모바일

| 메트릭 | 설명 |
|--------|------|
| 앱 시작 시간 (Cold/Warm) | 첫 화면 렌더링까지 |
| 화면 전환 시간 | 탭 → 화면 완전 로드 |
| API 호출 성공/실패율 | 네트워크 에러 포함 |
| BLE 스캔 성공/실패율 | 문열기 핵심 지표 |
| 위젯 갱신 소요 시간 | SharedPreferences/UserDefaults 저장까지 |
| 메모리 사용량 | 앱 생명주기별 |

### 2.2 SLI/SLO 기준

| 서비스 | SLI | SLO |
|--------|-----|-----|
| API 응답 시간 | p95 latency | < 500ms |
| API 가용성 | 성공률 (2xx+3xx) | > 99.5% |
| BLE 문열기 | 스캔→완료 시간 | < 3초 |
| 위젯 갱신 | 포그라운드 복귀 → 반영 | < 1초 |

---

## 3. 알림 (Alerting)

### 3.1 알림 등급

| 등급 | 조건 | 대응 |
|------|------|------|
| **P1 - Critical** | 서비스 전체 장애, 5xx > 10% | 즉시 대응 (15분 내) |
| **P2 - High** | 주요 기능 장애, 5xx > 5% | 1시간 내 대응 |
| **P3 - Medium** | 성능 저하, p95 > 2초 | 업무 시간 내 확인 |
| **P4 - Low** | 경고 임계치 초과 | 다음 스프린트 검토 |

### 3.2 알림 채널

| 등급 | 채널 |
|------|------|
| P1 | Slack #incident + PagerDuty + 전화 |
| P2 | Slack #incident + PagerDuty |
| P3 | Slack #monitoring |
| P4 | Jira 자동 생성 |

---

## 4. 분산 추적 (Distributed Tracing)

AFS2는 18개 마이크로서비스 + RabbitMQ 메시지 브로커 구조이므로 분산 추적이 필수.

- 모든 API 요청에 `X-Request-Id` 헤더 전파
- RabbitMQ 메시지에 correlation_id 포함
- 마이크로서비스 간 RPC 호출 시 correlation_id 유지
- 모바일 → API Gateway → 마이크로서비스 전체 추적
- 모바일 요청 시 `moca-mobile-id` 헤더로 디바이스 식별 (Android)

---

## 5. 헬스체크 (Health Check)

### 5.1 엔드포인트

```
GET /health          → 200 OK (단순 alive 확인)
GET /health/ready    → 200 OK (DB, 캐시 등 의존성 확인)
```

### 5.2 응답 포맷

```json
{
  "status": "healthy",
  "version": "1.2.3",
  "checks": {
    "mysql": "healthy",
    "mongodb": "healthy",
    "rabbitmq": "healthy",
    "etcd": "healthy"
  }
}
```

---

## 6. AI 에이전트 규칙

1. **새 API 엔드포인트 작성 시** → 요청/응답 로깅(INFO), 에러 로깅(ERROR), 응답 시간 메트릭 포함
2. **외부 API 호출 시** → 타임아웃 설정 + 실패 시 WARN 로그 + 재시도 메트릭
3. **DB 쿼리 추가 시** → 슬로우 쿼리 기준(500ms) 초과 시 WARN 로그
4. **민감 데이터** → 로그에 절대 포함하지 않음. 마스킹 처리 (`card_no: "****1234"`)
5. **모바일 BLE 관련 코드** → 스캔 시작/성공/실패/타임아웃 각각 로그
6. **헬스체크** → 새 외부 의존성 추가 시 `/health/ready`에 체크 항목 추가
7. **감사 로그** → 사용자 접근/권한 변경 등 보안 이벤트는 MongoDB audit_trail에 별도 기록 (§ 21_db_design_guide.md)
8. **마이크로서비스 간 통신** → RabbitMQ 메시지 발행/소비에 correlation_id 포함
