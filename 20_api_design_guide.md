# API 설계 가이드라인

## 목적

AFS2(Airfob Space 2) 백엔드 API 규칙을 기준으로, 모바일 앱(iOS/Android)과 Backend 전 플랫폼에서 일관된 API를 설계하고 운영하기 위한 표준을 정의한다.
AI Agent가 API를 설계하거나 수정할 때 이 가이드를 기준으로 검증하며, Review AI가 준수 여부를 확인한다.

> **기준 코드베이스**: `legacy/afs2` (NestJS + Sequelize 마이크로서비스 아키텍처)

---

## 1. API 버저닝

URL path 방식으로 버전을 관리한다.

```
# 환경별 Base URL
Product:  https://afs-api.airfob.com/v1
Beta:     https://ob-api.airfob.com/v2
ODemo:    https://odemo-api.airfob.com/v2
```

### 버전 운영 규칙

| 항목 | 규칙 |
|------|------|
| 버전 위치 | URL path (`/v{N}/`) |
| 새 버전 생성 시점 | Breaking change 발생 시 |
| 기존 버전 유지 기간 | 최소 6개월 (deprecation 기간) |
| Deprecation 알림 | 응답 헤더 `Deprecation: true`, `Sunset: {date}` 포함 |
| Non-breaking change | 기존 버전에 하위 호환으로 추가 |

### Breaking Change 기준

- 필수 요청 파라미터 추가
- 응답 필드 삭제 또는 타입 변경
- URL 경로 변경
- 에러 코드 체계 변경

---

## 2. URL / 리소스 설계

RESTful 원칙을 따른다. 리소스는 **복수 명사**로 표현하고, 계층 관계를 URL path로 나타낸다.

### 설계 규칙

| 규칙 | 올바른 예 | 잘못된 예 |
|------|----------|----------|
| 복수 명사 사용 | `/v1/cards` | `/v1/card` |
| 계층 구조 표현 | `/v1/sites/{siteId}/users` | `/v1/getSiteUsers` |
| 동사 금지 | `POST /v1/cards` | `/v1/createCard` |
| 소문자 + 언더스코어 | `/v1/access_levels` | `/v1/accessLevels` |
| 리소스 ID | `/v1/cards/{cardId}` | `/v1/cards?id=123` |
| 중첩 관계 | `/v1/users/{userId}/access_levels` | 별도 최상위 리소스 |

> **참고**: AFS2 레거시는 URL에 snake_case(`access_levels`)를 사용한다. 신규 API도 이 컨벤션을 따른다.

### URL 패턴 예시 (AFS2 기준)

```
GET    /v1/sites                              # 사이트 목록
GET    /v1/sites/{siteId}                     # 사이트 상세
GET    /v1/sites/{siteId}/users               # 사이트 소속 사용자 목록
POST   /v1/users                              # 사용자 생성
PATCH  /v1/users/{userId}                     # 사용자 수정
DELETE /v1/users/{userId}                     # 사용자 삭제
POST   /v1/users/search                      # 고급 검색 (SearchDto)
GET    /v1/users/{userId}/access_levels       # 사용자 출입 권한
GET    /v1/users/{userId}/rfcards             # 사용자 RF카드
POST   /v1/users/groups/{groupId}/users       # 그룹에 사용자 추가
```

---

## 3. HTTP 메서드 규칙

| 메서드 | 용도 | Idempotent | 요청 Body |
|--------|------|:----------:|:---------:|
| GET | 리소스 조회 | O | X |
| POST | 리소스 생성, **고급 검색** | X | O |
| PATCH | 리소스 부분 수정 | X | O |
| DELETE | 리소스 삭제 | O | X |

### 사용 시 주의사항

- **GET**: 서버 상태를 변경하지 않는다. 필터/정렬은 query parameter로 전달한다.
- **POST /search**: 복잡한 필터링은 GET query parameter 대신 `POST /resource/search` + body 사용 (AFS2 패턴).
- **POST 생성**: `@HttpCode(200)` 또는 `201` 반환. AFS2는 signup/login 등에 200을 사용한다.
- **PATCH**: AFS2는 PUT 대신 PATCH를 주로 사용한다 (부분 수정).
- **DELETE**: 이미 삭제된 리소스에 대해 다시 DELETE를 보내면 `204 No Content`를 반환한다.

---

## 4. 고급 검색 패턴 (SearchDto)

AFS2는 `POST /resource/search`로 고급 검색을 수행한다. 모든 목록 리소스에 적용.

### 요청 구조

```json
{
  "page": 1,
  "size": 100,
  "sort": "created_at",
  "order": "desc",
  "filters": {
    "status": { "equals": "activated" },
    "site_id": { "equals": 42 },
    "created_at": { "gte": "2024-01-01", "lte": "2024-12-31" }
  },
  "json_filters": [
    { "field": "properties", "property": "department", "equals": "engineering" }
  ],
  "json_array_filters": [
    { "field": "tags", "contains": "vip" }
  ]
}
```

### 필터 타입

| 필터 | 용도 | 예시 |
|------|------|------|
| `equals` | 정확한 값 매칭 (단일 또는 배열) | `"status": { "equals": ["activated", "suspended"] }` |
| `gte` / `lte` | 범위 필터 | `"created_at": { "gte": "2024-01-01" }` |
| `json_filters` | JSON 컬럼 내 속성 검색 | `properties.department == "engineering"` |
| `json_array_filters` | JSON 배열 포함 여부 | `tags contains "vip"` |

### DTO 검증 (NestJS class-validator)

```typescript
export class SearchDto {
  @IsOptional() @Min(1) page?: number;
  @IsOptional() @Min(1) @Max(1000) size?: number;
  @IsOptional() sort?: string;
  @IsOptional() @IsIn(['asc', 'desc']) order?: string;
  @IsOptional() @ValidateNested() @Type(() => FilterDto) filters?: FilterDto;
}
```

---

## 5. 요청/응답 형식

### 공통 규칙

| 항목 | 규칙 |
|------|------|
| Content-Type | `application/json` |
| 필드 네이밍 | snake_case (서버 ↔ 클라이언트 통일) |
| 날짜/시간 | ISO 8601 (`2026-03-26T09:00:00+09:00`) |
| 빈 값 | `null` 사용 (빈 문자열 `""` 금지) |
| Boolean | `true` / `false` (문자열 `"true"` 금지) |

### 성공 응답

```json
{
  "id": 42,
  "name": "홍길동",
  "status": "activated",
  "site_id": 1,
  "properties": { "department": "engineering" },
  "created_at": "2026-03-26T09:00:00+09:00",
  "updated_at": "2026-03-26T09:00:00+09:00"
}
```

### 목록 응답 (페이지네이션)

```json
{
  "total": 1234,
  "users": [
    { "id": 1, "name": "홍길동", "status": "activated" },
    { "id": 2, "name": "김철수", "status": "suspended" }
  ]
}
```

> AFS2 패턴: `{ total: N, {resource_plural}: [...] }`. 래퍼 객체 없이 직접 반환.

### 에러 응답 (NestJS 기본 형식)

```json
{
  "statusCode": 400,
  "message": ["email must be an email", "name should not be empty"],
  "error": "Bad Request"
}
```

---

## 6. 페이지네이션

AFS2는 **Offset 기반 페이지네이션**을 사용한다.

### 파라미터 규칙

| 파라미터 | 기본값 | 최대값 | 설명 |
|----------|--------|--------|------|
| `page` | 1 | - | 페이지 번호 |
| `size` | 100 | 1000 | 한 페이지당 항목 수 |
| `sort` | `created_at` | - | 정렬 기준 컬럼명 |
| `order` | `desc` | - | `asc` 또는 `desc` |

### 사용 예시

```
GET /v1/sites?page=2&size=50&sort=name&order=asc
POST /v1/users/search  (body에 page/size 포함)
```

---

## 7. 에러 응답

### HTTP 상태 코드 (AFS2 실사용 기준)

| 코드 | 의미 | 사용 상황 |
|------|------|----------|
| 200 | OK | 조회/수정 성공, 로그인/회원가입 성공 |
| 201 | Created | 리소스 생성 성공 |
| 204 | No Content | 삭제 성공 (응답 body 없음) |
| 400 | Bad Request | class-validator 검증 실패, 요청 형식 오류 |
| 401 | Unauthorized | 인증 실패 (토큰 없음/만료) |
| 403 | Forbidden | 권한 부족, 토큰 무효화(재로그인 감지) |
| 404 | Not Found | 리소스 없음 |
| 423 | Locked | 계정 잠김 (비밀번호 시도 횟수 초과) |
| 500 | Internal Server Error | 서버 내부 오류 |

### 마이크로서비스 간 RPC 에러

```json
{
  "status": "error",
  "message": "User not found"
}
```

---

## 8. 인증/인가

### Bearer Token (JWT)

```
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
```

### Token 관리 (AFS2 기준)

| 토큰 | 유효 기간 | 용도 |
|------|----------|------|
| Access Token | **1시간** (3600초) | API 요청 인증 |
| Invite Token | 30분 | 계정 생성/비밀번호 리셋 |
| Reset Password Token | 30분 | 비밀번호 재설정 |

### 세션 보안 (SecurityInterceptor)

AFS2는 매 요청마다 다음을 검증한다:

1. 계정 존재 여부 확인 (`account_id`로 DB 조회)
2. **마지막 로그인 시간 비교** — 새 로그인 발생 시 이전 토큰 자동 무효화
3. 계정 상태 확인 (LOCKED, INACTIVE, SUSPENDED → 거부)

```typescript
// AFS2 SecurityInterceptor 패턴
if (account.last_login_at.getTime() !== user.last_login_at) {
  throw new ForbiddenException('The auth token is invalid or expired');
}
```

### RBAC (Role-Based Access Control)

AFS2는 16개 역할을 4개 범위로 관리한다:

| 범위 | 역할 | 접근 범위 |
|------|------|----------|
| **MOCA_*** | MASTER, ADMIN, OPERATOR, OBSERVER | 전체 사이트 (플랫폼 레벨) |
| **FED_*** | MASTER, ADMIN, OPERATOR, OBSERVER | 연합 사이트 (자신 + 하위) |
| **SITE_*** | MASTER, ADMIN, OPERATOR, OBSERVER | 단일 사이트 |
| **기타** | MOBILE_USER, DEVICE_CREDENTIAL, DISTRIBUTOR_* | 특수 역할 |

```
권한 계층: OBSERVER < OPERATOR < ADMIN < MASTER
```

- `@Roles()` 데코레이터로 엔드포인트별 역할 제한
- `@ApiBearerAuth()` + `@UseGuards(JwtAuthGuard)` 조합

### API Key (서버간 통신)

서버-서버 간 통신에는 API Key를 사용한다.

```
X-API-Key: sk_live_abc123...
```

---

## 9. DTO 검증 (class-validator)

AFS2는 `class-validator` + `class-transformer`로 입력을 검증한다.

```typescript
export class CreateUserDto {
  @IsArray()
  @ArrayNotEmpty()
  @ValidateNested({ each: true })
  @Type(() => UserDto)
  users: UserDto[];
}

export class UserDto {
  @IsString() @IsNotEmpty() name: string;
  @IsEmail() email: string;
  @IsEnum(UserStatus) status: UserStatus;
  @IsOptional() @IsObject() properties?: Record<string, any>;
}
```

### 검증 규칙

| 규칙 | 설명 |
|------|------|
| 배열 입력 | `@IsArray()` + `@ValidateNested({ each: true })` |
| 중첩 객체 | `@Type(() => NestedDto)` 필수 (class-transformer) |
| 선택 필드 | `@IsOptional()` 명시 |
| Enum | `@IsEnum()` + TypeScript enum 정의 |
| JSON 확장 데이터 | `properties?: Record<string, any>` (자유 형식 JSON) |

---

## 10. API 문서화

### Swagger (NestJS @nestjs/swagger)

AFS2는 Swagger 데코레이터로 API 문서를 자동 생성한다.

| 데코레이터 | 용도 |
|-----------|------|
| `@ApiTags('users')` | 리소스 그룹핑 |
| `@ApiProperty()` | DTO 필드 문서화 |
| `@ApiBearerAuth()` | 인증 필요 표시 |
| 커스텀 데코레이터 | `@ApiCreate`, `@ApiPaginatedGet`, `@ApiSearch`, `@ApiDelete` |

### API 문서 위치

```
apps/afs2/doc/api.json       # Swagger JSON 스펙
```

---

## 11. AI Agent 규칙

### API 설계 시 AI 검증 항목

| 검증 항목 | 확인 내용 |
|----------|----------|
| URL 패턴 | 복수 명사, 소문자+언더스코어, 동사 미사용 |
| HTTP 메서드 | 용도에 맞는 메서드 사용 |
| 응답 형식 | AFS2 형식 준수 (`{ total, items }` / NestJS 에러) |
| 고급 검색 | `POST /resource/search` + SearchDto 패턴 |
| 페이지네이션 | page/size 기반, size 최대 1000 |
| 인증 | Bearer Token + JwtAuthGuard |
| RBAC | `@Roles()` 데코레이터 적용 |
| DTO 검증 | class-validator 적용 |
| Swagger | 데코레이터로 문서화 동시 작성 |

### AI Agent 작업 순서

1. **기존 API 패턴 분석**: 같은 마이크로서비스의 기존 컨트롤러를 먼저 확인
2. **가이드 준수 설계**: 이 문서의 규칙에 따라 API를 설계
3. **DTO + Swagger 동시 작성**: 컨트롤러 + DTO + Swagger 데코레이터 함께 생성
4. **SearchDto 지원**: 목록 리소스에는 `/search` 엔드포인트 추가
5. **RBAC 적용**: 적절한 `@Roles()` 설정

---

## 부록: 체크리스트

새 API 엔드포인트를 추가할 때 아래 항목을 확인한다.

- [ ] URL이 복수 명사 + 소문자 언더스코어 규칙을 따르는가
- [ ] 적절한 HTTP 메서드를 사용하는가
- [ ] 응답이 AFS2 형식(`{ total, items }` 또는 단일 객체)을 따르는가
- [ ] 목록 API에 페이지네이션(page/size)이 적용되었는가
- [ ] 고급 검색이 필요한 리소스에 `POST /search` + SearchDto가 있는가
- [ ] `@UseGuards(JwtAuthGuard)` + `@ApiBearerAuth()` 인증이 적용되었는가
- [ ] `@Roles()` RBAC 제한이 적절한가
- [ ] DTO에 class-validator 검증이 있는가
- [ ] Swagger 데코레이터(`@ApiTags`, `@ApiProperty`)가 적용되었는가
- [ ] Breaking change가 있다면 버전을 올렸는가
