---
description: 티켓의 프로세스 진행 상태를 확인합니다
argument-hint: [ticket-id]
---

# /status — 진행 상태 확인

현재 티켓의 프로세스 진행 상태를 확인한다.

## 입력

- 티켓 ID: $ARGUMENTS (예: WIDGET-001)

## 수행할 작업

1. `artifacts/$ARGUMENTS/` 디렉토리를 확인한다
2. 각 단계의 산출물 존재 여부를 확인한다
3. 현재 어느 단계에 있는지 판단한다
4. 플랫폼별 진행 상태를 구분한다
5. 다음으로 실행해야 할 커맨드를 안내한다

## 단계별 확인 항목

| 단계 | 디렉토리 | 확인 파일 |
|------|----------|----------|
| 요구사항 | 01_planner/ | requirements.md |
| 설계 | 02_spec/ | design_doc.md |
| 프로토타입 | 02.5_prototype/ | prototype_summary.md |
| 디자인 | 03_designer_1/ | wireframe.md |
| 테스트 | 04_test/ | test_cases.md |
| 구현 | 05_dev/ | change_summary*.md, implementation_plan*.md |
| 리뷰 | 07_review/ | review_summary.md |
| 릴리즈 | 08_release/ | release_notes.md |

## 출력 형식

```
{ticket_id}: {티켓 제목}
─────────────────────────
[완료] 01_planner — requirements.md
[완료] 02_spec — design_doc.md
[완료] 04_test — test_cases.md
[완료] 05_dev — android (change_summary_android.md)
[대기] 05_dev — ios (implementation_plan_ios.md 존재)
[완료] 07_review — android (승인)
[대기] 07_review — ios
[대기] 08_release

→ 다음 단계: /dev WIDGET-001 ios
```

## 플랫폼별 상태

- `change_summary_android.md` / `change_summary_ios.md` 존재 여부로 플랫폼별 구현 완료를 판단
- `implementation_plan_*.md` 존재 여부로 구현 준비 상태를 판단
- `review_summary.md` 내용에서 승인/반려 상태를 확인
