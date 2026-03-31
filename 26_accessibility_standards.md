# 26. 접근성 표준 (Accessibility Standards)

> 모바일 앱의 접근성(A11y) 기준. AI 에이전트가 UI 코드 생성 시 준수해야 할 최소 요구사항.

---

## 1. 적용 기준

- **WCAG 2.1 Level AA** 준수
- **iOS**: Apple Accessibility Programming Guide
- **Android**: Android Accessibility Developer Guide

---

## 2. 필수 항목

### 2.1 시각 접근성

| 항목 | 기준 | 검증 방법 |
|------|------|----------|
| 색상 대비 | 텍스트 4.5:1 이상, 대형 텍스트 3:1 이상 | Accessibility Inspector / Contrast Checker |
| 색상만으로 정보 전달 금지 | 에러 표시에 빨간색 + 아이콘/텍스트 병행 | 육안 검사 |
| 최소 터치 영역 | 44×44pt (iOS) / 48×48dp (Android) | Layout Inspector |
| 텍스트 크기 조절 | Dynamic Type (iOS) / sp 단위 (Android) 지원 | 설정에서 최대 글꼴 적용 후 확인 |

### 2.2 스크린 리더 지원

| 항목 | iOS | Android |
|------|-----|---------|
| 대체 텍스트 | `accessibilityLabel` | `contentDescription` |
| 역할 지정 | `accessibilityTraits` | `AccessibilityNodeInfo` / `roleDescription` |
| 상태 전달 | `accessibilityValue` | `stateDescription` |
| 읽기 순서 | `accessibilityElements` 배열 | `android:importantForAccessibility` |
| 동적 알림 | `UIAccessibility.post(.announcement)` | `AccessibilityEvent.TYPE_ANNOUNCEMENT` |

### 2.3 입력/상호작용

| 항목 | 기준 |
|------|------|
| 키보드 접근 | 모든 인터랙티브 요소 키보드로 접근 가능 |
| 포커스 관리 | 모달/다이얼로그 열릴 때 포커스 이동. 닫힐 때 원래 위치로 복귀 |
| 제스처 대안 | 스와이프/핀치 등 복잡한 제스처에 버튼 대안 제공 |
| 시간 제한 | 자동 타임아웃에 연장 옵션 제공 |

### 2.4 모션 & 애니메이션

| 항목 | 기준 |
|------|------|
| Reduce Motion | `UIAccessibility.isReduceMotionEnabled` (iOS) / `ANIMATOR_DURATION_SCALE` (Android) 확인 후 애니메이션 축소 |
| 자동 재생 금지 | 5초 이상 자동 애니메이션 금지. 일시정지 제공 |
| 깜빡임 | 초당 3회 이상 깜빡이는 콘텐츠 금지 |

---

## 3. 플랫폼별 구현 패턴

### 3.1 iOS — VoiceOver 지원

```swift
// 이미지 버튼 접근성
doorButton.accessibilityLabel = "문 열기"
doorButton.accessibilityHint = "BLE 스캔을 시작하여 근처 문을 엽니다"
doorButton.accessibilityTraits = .button

// 상태 변경 알림
UIAccessibility.post(notification: .announcement, argument: "카드 3장이 활성 상태입니다")

// 그룹핑
cardView.isAccessibilityElement = true
cardView.accessibilityLabel = "모카키 카드, 활성 상태, 만료일 2024년 12월 31일"
```

### 3.2 Android — TalkBack 지원

```xml
<!-- 이미지 버튼 -->
<ImageButton
    android:contentDescription="@string/open_door"
    android:importantForAccessibility="yes" />

<!-- 장식용 이미지 -->
<ImageView
    android:importantForAccessibility="no"
    android:contentDescription="@null" />
```

```kotlin
// 동적 알림
ViewCompat.setAccessibilityLiveRegion(cardCountView, ACCESSIBILITY_LIVE_REGION_POLITE)

// 커스텀 액션
ViewCompat.addAccessibilityAction(cardView, "카드 삭제") { _, _ ->
    deleteCard()
    true
}
```

### 3.3 위젯 접근성 (MocaKey 특화)

```kotlin
// RemoteViews 접근성
remoteViews.setContentDescription(R.id.widget_card_count, "활성 카드 ${count}장")
remoteViews.setContentDescription(R.id.widget_open_door, "문 열기 버튼")
```

```swift
// iOS Widget (WidgetKit)
Text("카드 \(count)장")
    .accessibilityLabel("활성 카드 \(count)장")
```

---

## 4. 테스트 체크리스트

### 4.1 자동화 검사

| 도구 | 플랫폼 | 검사 항목 |
|------|--------|----------|
| Accessibility Inspector | iOS | 라벨 누락, 대비, 터치 영역 |
| Accessibility Scanner | Android | 라벨 누락, 대비, 터치 영역 |
| XCTest `performAccessibilityAudit` | iOS | 자동화 테스트에서 접근성 감사 |
| Espresso AccessibilityChecks | Android | UI 테스트에서 자동 접근성 검사 |

### 4.2 수동 검사

| 항목 | 방법 |
|------|------|
| VoiceOver/TalkBack 전체 탐색 | 스크린 리더 켜고 모든 화면 순회 |
| 최대 글꼴 크기 | 시스템 설정 → 최대 크기 후 레이아웃 깨짐 확인 |
| 고대비 모드 | 시스템 설정 → 고대비 활성화 후 UI 확인 |
| 축소 모션 | Reduce Motion 켜고 애니메이션 확인 |

---

## 5. AI 에이전트 규칙

1. **이미지/아이콘에 대체 텍스트 필수** → `contentDescription` (Android) / `accessibilityLabel` (iOS) 없으면 리뷰 반려
2. **장식용 이미지는 명시적 제외** → `importantForAccessibility="no"` 또는 `isAccessibilityElement = false`
3. **하드코딩 크기 금지** → 텍스트는 `sp` (Android) / Dynamic Type (iOS). 고정 `px`/`pt` 금지
4. **터치 영역 최소 크기** → 44pt / 48dp 미만이면 패딩으로 보정
5. **색상만으로 상태 표현 금지** → 에러/성공/경고에 아이콘 또는 텍스트 병행
6. **위젯 UI 변경 시** → RemoteViews에 contentDescription 포함 확인
