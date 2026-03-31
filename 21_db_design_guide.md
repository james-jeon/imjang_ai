# DB 설계 가이드

## 목적

AFS2 백엔드(MySQL + MongoDB 듀얼)와 모바일 로컬 DB(Android Room + SQLCipher)의 스키마 설계 규칙을 정의한다.
AI Agent가 스키마를 변경할 때도 이 가이드를 기준으로 일관성을 유지한다.

> **기준 코드베이스**: `legacy/afs2/scripts/mysql/` (서버), `legacy/mobile_moca_mocakey_android` (Android Room)
> **iOS**: Realm 사용하지 않음. CoreData 또는 SwiftData로 전환 예정.

---

## 1. 스키마 설계 원칙

### 정규화

- 기본적으로 제3정규형(3NF)을 따른다
- 읽기 성능이 중요한 경우 의도적 비정규화를 허용한다
- 비정규화 시 반드시 근거를 주석 또는 문서에 기록한다

### 단일 책임

- 테이블 하나는 하나의 엔티티만 표현한다
- 관계는 외래키 또는 중간 테이블로 분리한다

### JSON 확장 필드

AFS2는 대부분의 테이블에 `properties JSON NULL` 컬럼을 두어 커스텀 데이터를 저장한다.
SearchDto의 `json_filters` / `json_array_filters`로 검색 가능.

---

## 2. 네이밍 컨벤션

### 백엔드 (MySQL — AFS2 기준)

| 대상 | 규칙 | 예시 |
|------|------|------|
| 데이터베이스 | snake_case | `afs2_credential` |
| 테이블 | snake_case, **단수형** | `user`, `site`, `device`, `access_level` |
| 컬럼 | snake_case | `created_at`, `site_id`, `is_active` |
| 인덱스 | `{table_abbr}_{column}_idx` | `u_site_id_idx`, `d_serial_idx` |
| 유니크 제약 | `{description}_UNIQUE` | `full_name_UNIQUE`, `login_id_UNIQUE` |
| 외래키 | `{table_abbr}_{column}` | `u_site_id`, `u_mobile_id` |

> **주의**: AFS2는 테이블명이 **단수형**(`user`, `site`, `device`)이다. 이 규칙을 따른다.

### 모바일 (Room / CoreData)

| 대상 | 규칙 | 예시 |
|------|------|------|
| 모델 클래스 | PascalCase, 단수형 | `UserModel`, `SiteModel`, `DeviceModel` |
| 프로퍼티 | camelCase | `createdAt`, `siteId`, `isActive` |
| Room 테이블명 | snake_case (서버와 통일) | `@Entity(tableName = "user")` |
| DAO | PascalCase + Dao 접미사 | `UserDao`, `AccessLevelDao` |
| Room 컬럼명 | snake_case | `@ColumnInfo(name = "site_id")` |

---

## 3. 필수 컬럼 (AFS2 기준)

모든 테이블에 아래 컬럼을 반드시 포함한다.

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | `BIGINT NOT NULL AUTO_INCREMENT` | 기본키 |
| `created_at` | `DATETIME DEFAULT CURRENT_TIMESTAMP` | 생성 시각 |
| `updated_at` | `DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | 수정 시각 |
| `properties` | `JSON NULL` | 커스텀 확장 데이터 (선택이지만 AFS2 표준) |

```sql
CREATE TABLE IF NOT EXISTS `afs2_credential`.`user` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `site_id` BIGINT NOT NULL,
  `status` ENUM('inactive','activating','activated','updating_access',
                'updating_credential','revoking','revoked','suspending',
                'suspended','deleting','expired') NOT NULL DEFAULT 'inactive',
  `properties` JSON NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `u_site_id_idx` (`site_id`),
  CONSTRAINT `u_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`)
    ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB;
```

---

## 4. ENUM 상태 관리

AFS2는 MySQL `ENUM` 타입으로 상태를 관리한다. 주요 상태 머신:

### User 상태 (11종)

```
inactive → activating → activated → updating_access
                                   → updating_credential
                                   → revoking → revoked
                                   → suspending → suspended
                                   → deleting
                                   → expired
```

### Site 상태

```
inactive → activating → activated → suspended → expired
```

### Account 상태

```
inactive → activating → activated → suspended
```

### 규칙

- Enum 값은 **소문자 snake_case** 문자열
- 상태 전이(transition) 로직은 서비스 레이어에서 관리
- DB에는 현재 상태만 저장, 전이 이력은 audit_trail(MongoDB)에 기록

---

## 5. 관계 & 삭제 정책

AFS2의 FK 삭제 정책 기준:

| 관계 | 삭제 정책 | 예시 |
|------|----------|------|
| 부모 → 자식 (종속) | `CASCADE` | site 삭제 → user, device 삭제 |
| 참조 (독립적) | `SET NULL` | mobile 삭제 → user.mobile_id = NULL |
| 보호 | `RESTRICT` | role 삭제 시 account 있으면 거부 |

### 계층 구조 (Self-Reference)

```sql
-- site 테이블: parent_id로 트리 구조 지원 (연합 사이트)
`parent_id` BIGINT NULL,
CONSTRAINT `s_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `site` (`id`)
  ON DELETE SET NULL ON UPDATE NO ACTION
```

---

## 6. JSON 필드 활용

| 컬럼 | 용도 | 테이블 |
|------|------|--------|
| `properties` | 커스텀 키-값 확장 데이터 | 거의 모든 테이블 |
| `settings` | 디바이스별 설정 | `device` |
| `status` | 디바이스 런타임 상태 | `device` |

### SearchDto에서 JSON 검색

```json
{
  "json_filters": [
    { "field": "properties", "property": "department", "equals": "engineering" }
  ],
  "json_array_filters": [
    { "field": "tags", "contains": "vip" }
  ]
}
```

---

## 7. 마이그레이션 전략

### 공통 원칙

- 스키마 변경은 반드시 마이그레이션 파일로만 수행한다 (직접 DB 수정 금지)
- 데이터 손실 없는 변경을 우선한다

### 안전한 변경 순서

```
1단계: nullable 컬럼 추가
2단계: 기존 데이터 채우기 (backfill)
3단계: 애플리케이션 코드 배포
4단계: NOT NULL 제약 추가
```

### 백엔드 (MySQL)

AFS2는 `scripts/mysql/` 디렉토리에 스키마 SQL을 관리한다:

```
scripts/mysql/
├── 00_admin.sql      # Distributor
├── 01_mobile.sql     # 모바일/MOCA 사용자
├── 02_site.sql       # 사이트, 키, 정책, 메시지 템플릿
├── 03_device.sql     # 디바이스 그룹, 디바이스
├── 04_user.sql       # 유저 그룹, 유저, 멤버십
├── 05_access.sql     # 출입 레벨, 스케줄
├── 06_account.sql    # 계정, 로컬 인증, API 키
├── 07_credit.sql     # 크레딧
└── 08_visitor.sql    # 방문자
```

### Room (Android) — SQLCipher 암호화 적용

Android SDK의 MocaDataBase는 **버전 9**까지 마이그레이션 이력이 있다 (MIGRATION_1_2 ~ MIGRATION_8_9).

```kotlin
// 마이그레이션 예시 (실제 AFS2 Android 패턴)
val MIGRATION_1_2 = object : Migration(1, 2) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("ALTER TABLE access_level ADD COLUMN schedule TEXT")
    }
}

// Database 빌드 시 SQLCipher 암호화 적용
Room.databaseBuilder(context, MocaDataBase::class.java, DB_NAME)
    .openHelperFactory(SupportFactory(encryptionKey))  // SQLCipher
    .addMigrations(MIGRATION_1_2, MIGRATION_2_3, /* ... */ MIGRATION_8_9)
    .build()
```

- `@Database`의 `version`을 증가시킨다
- `Migration` 객체를 작성하여 `addMigrations()`에 등록한다
- **암호화 키**: RSA-2048 공개키의 SHA-256 해시에서 파생

### iOS — CoreData / SwiftData

> **Realm 사용하지 않음**. 기존 레거시는 Realm이었으나 신규 개발에서는 CoreData 또는 SwiftData를 사용한다.

```swift
// CoreData Lightweight Migration
let container = NSPersistentContainer(name: "Mocakey")
let description = container.persistentStoreDescriptions.first
description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
```

- 단순 컬럼 추가/삭제는 Lightweight Migration 자동 처리
- 복잡한 변환(컬럼 타입 변경, 관계 변경)은 Mapping Model 작성
- 암호화: NSPersistentStoreFileProtectionKey 또는 SQLCipher 연동

---

## 8. 듀얼 DB 전략 (MySQL + MongoDB)

AFS2는 MySQL(주 데이터) + MongoDB(감사 로그)를 함께 사용한다.

| 저장소 | 용도 | 예시 |
|--------|------|------|
| MySQL (Sequelize) | 비즈니스 엔티티, 관계 데이터 | user, site, device, account |
| MongoDB (Mongoose) | 감사 로그, 이벤트 로그 | audit_trail, event_log |

### 규칙

- 비즈니스 데이터는 MySQL에만 저장
- 감사/이벤트 로그는 MongoDB에 저장 (대량 쓰기, 유연한 스키마)
- 두 DB 간 JOIN 불가 → application 레벨에서 조합

---

## 9. 인덱스 전략

### AFS2 인덱스 패턴

| 유형 | 네이밍 | 예시 |
|------|--------|------|
| 단일 필드 | `{abbr}_{column}_idx` | `u_site_id_idx` |
| 유니크 | `{description}_UNIQUE` | `serial_UNIQUE`, `login_id_UNIQUE` |
| INVISIBLE | 향후 최적화용 (즉시 사용 안 함) | `unique name INVISIBLE` |

### 인덱스 추가 기준

- 외래키 컬럼 (FK)에는 반드시 인덱스
- `WHERE`/`ORDER BY`에 자주 사용되는 컬럼
- 유니크 비즈니스 키 (`serial`, `uuid`, `login_id`)

### 모바일 DB 인덱스

- 데이터 규모가 작으므로 인덱스를 최소화한다
- PK 외에는 자주 검색하는 FK(`site_id`)에만 적용

---

## 10. 데이터 타입 규칙

| 분류 | MySQL (AFS2) | Android Room | iOS CoreData |
|------|-------------|-------------|-------------|
| PK | `BIGINT AUTO_INCREMENT` | `Long` / `String` | `Int64` / `UUID` |
| 날짜/시간 | `DATETIME` | `Long` (epoch ms) | `Date` |
| Boolean | `TINYINT` | `Boolean` | `Bool` |
| Enum | `ENUM(...)` | `String` (`@TypeConverter`) | `String` (RawValue) |
| 금액 | `DECIMAL(10,2)` | `BigDecimal` | `NSDecimalNumber` |
| UUID | `VARCHAR(255)` | `String` | `UUID` |
| JSON | `JSON` | Moshi `@TypeConverter` | `Transformable` |

### 암호화 키 저장 (AFS2 site_key 패턴)

```sql
CREATE TABLE `site_key` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `site_id` BIGINT NOT NULL,
  `public_key` TEXT NOT NULL,
  `private_key` TEXT NOT NULL,
  `ecdh_curve` ENUM('prime256v1', 'secp160r1') NOT NULL,
  `use_type` ENUM('site', 'mobile') NOT NULL,
  -- ...
);
```

---

## 11. 모바일 로컬 DB

### Room (Android) — 앱 레벨

```kotlin
@Entity(tableName = "user")
data class UserModel(
    @PrimaryKey val id: Long,
    @ColumnInfo(name = "name") val name: String,
    @ColumnInfo(name = "site_id") val siteId: Long,
    @ColumnInfo(name = "status") val status: String,
    @ColumnInfo(name = "properties") val properties: UserProperties?,
    @ColumnInfo(name = "created_at") val createdAt: Long = System.currentTimeMillis(),
    @ColumnInfo(name = "updated_at") val updatedAt: Long = System.currentTimeMillis()
)

@Dao
interface UserDao {
    @Query("SELECT * FROM user WHERE site_id = :siteId")
    fun getUsersBySite(siteId: Long): Flow<List<UserModel>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(users: List<UserModel>)
}
```

- **DI**: Hilt `@Module` + `@Provides`로 Database/DAO 싱글톤 제공
- **TypeConverter**: Moshi 기반 JSON 직렬화 (`UserProperties`, `Schedule`, `Holiday` 등)
- **암호화**: SDK 레벨에서 SQLCipher 적용 (비디버그 빌드)

### 저장소 선택 기준

| 기준 | SharedPreferences / UserDefaults | 로컬 DB (Room / CoreData) |
|------|----------------------------------|--------------------------|
| 데이터 형태 | 단순 키-값 (토큰, 설정값) | 구조화된 엔티티 |
| 데이터 양 | 소량 (수십 건 이하) | 대량 또는 관계 있는 데이터 |
| 검색/필터 | 불필요 | 필요 |
| 예시 | 로그인 토큰, 위젯 데이터, 다크모드 | 카드 목록, 사이트, 디바이스, 출입 레벨 |

---

## 12. AI Agent 규칙

### 가드레일

- AI가 스키마를 변경할 때는 `07_ai_dev_guardrails`의 체크포인트를 반드시 적용한다
- DB 마이그레이션 파일은 제한 영역으로, 사람 승인이 필요하다

### 일관성 유지

- AI는 스키마 변경 전에 기존 테이블의 네이밍 패턴을 분석한다
- 새 테이블 생성 시 필수 컬럼(id, created_at, updated_at, properties)을 자동으로 포함한다
- AFS2 단수형 테이블명 규칙을 따른다

### iOS 관련

- **Realm 코드 작성 금지** — CoreData 또는 SwiftData만 사용
- 기존 Realm 레거시를 수정할 때는 마이그레이션 계획 수립 후 사람 승인

### 마이그레이션 자동 생성

- 데이터 손실 가능성이 있는 변경(컬럼 삭제, 타입 변환)은 경고를 출력하고 사람 승인을 대기한다
- Room 마이그레이션은 버전 번호를 확인하고 순차적으로 작성한다

---

## 체크리스트

스키마 변경 시 아래 항목을 확인한다.

- [ ] 네이밍 컨벤션을 준수하는가 (단수형 테이블, snake_case)
- [ ] 필수 컬럼(`id`, `created_at`, `updated_at`, `properties`)이 포함되어 있는가
- [ ] ENUM 상태값이 소문자 snake_case인가
- [ ] FK에 적절한 삭제 정책(CASCADE/SET NULL/RESTRICT)이 있는가
- [ ] FK 컬럼에 인덱스가 있는가
- [ ] 마이그레이션 파일이 순차적 버전 번호를 따르는가
- [ ] 데이터 손실 없는 변경 순서를 따르는가
- [ ] 모바일 모델이 서버 스키마와 필드 매핑이 일치하는가
- [ ] iOS에 Realm 코드가 포함되어 있지 않은가
