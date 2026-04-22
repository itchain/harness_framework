# 실전 사용 시나리오

이 문서는 **실제로 명령을 실행하면 어떤 대화가 오가는지** 구체적으로 보여줍니다. [README.md](README.md)로 개념을 잡으셨다면, 여기서 흐름을 손에 익히세요.

> 아래 예시의 `개발자>`는 당신이 입력하는 내용, `Claude>`는 Claude Code가 출력하는 내용입니다. 파일 생성·커밋은 Claude가 자동으로 수행합니다.

---

## 시나리오 1 — 빈 레포에서 새 프로젝트 시작 (MVP)

**상황**: "간단한 북마크 CLI"를 만들고 싶음. 빈 디렉토리.

### 준비

```bash
mkdir link-keeper && cd link-keeper
cp -r {하네스-레포}/.claude {하네스-레포}/scripts .
mkdir docs phases
git init
```

`CLAUDE.md`는 프로젝트 규칙을 직접 작성(언어, CRITICAL 규칙 등). 없어도 하네스는 동작하나 가드레일이 약해집니다.

### Stage 1 — Discovery

```
개발자> /harness-plan mvp
```

```
Claude> phases/ 비어있음. 첫 phase 시작합니다.
        MVP 모드 Discovery — 4개 질문에 답해주세요.

        Q1. 제품의 핵심 목적은? (한 줄, 누구에게 왜 필요한지)
```

```
개발자> 자주 방문하는 URL을 태그와 함께 저장·검색하는 CLI. 브라우저 북마크는
       계층 구조가 답답해서 평평한 태그 기반으로 관리하고 싶음. 개인용.
```

```
Claude> Q2. 주요 사용자와 사용 맥락?
```

```
개발자> 나 혼자. 터미널에서 일하다가 좋은 글·문서 보면 즉시 `link add <url> 
       --tags python,perf` 식으로 기록. 나중에 `link find python`으로 찾기.
```

```
Claude> Q3. MVP "출시 가능" 기준?
```

```
개발자> add/list/find/delete 네 명령 동작. 태그 기반 검색.
```

```
Claude> "동작"은 추상적입니다. 테스트 가능한 형태로 구체화:
        - 각 명령의 성공/실패 케이스 하나씩?
        - 검색 시 AND/OR 중 어느 쪽?
        - 데이터 영속성 범위?
```

```
개발자> AND. JSON 저장. AC:
       AC-1: `link add <url> --tags a,b` → JSON에 기록.
       AC-2: `link list` → 모든 북마크 표시.
       AC-3: `link find python,perf` → 둘 다 태그로 가진 것만 표시 (AND).
       AC-4: `link delete <id>` → 제거.
       AC-5: 파일 없으면 자동 생성.
       AC-6: pytest 전체 통과.
```

```
Claude> Q4. MVP 제외 사항? (최소 3개)
```

```
개발자> 웹 UI, 임포트/익스포트, 팀 공유, 검색 자동완성, URL 메타 자동 수집.
```

```
Claude> Phase A 완료. 코드베이스 분석 (Plan Mode)... 약 10초.

        ━━━ 초기 설계 제안 (mvp 모드) ━━━

        1) 스택
           - 언어: Python 3.9+ (CLAUDE.md 명시)
           - CLI: argparse
           - 저장: JSON (~/.link-keeper.json, LINK_KEEPER_PATH env 오버라이드)
           - 테스트: pytest

        2) 도메인 모델
           - Bookmark { id: int, url: str, tags: list[str], created_at: str }

        3) 디렉토리 구조 초안
           link_keeper/
           ├── __init__.py
           ├── __main__.py
           ├── models.py
           ├── storage.py
           └── cli.py
           tests/ ...

        4) 초기 ADR (3개)
           - ADR-001: 표준 라이브러리 우선
           - ADR-002: JSON 파일 저장
           - ADR-003: 레이어 분리

        5) 예상 step 구조 (5 step)
           step 0: project-setup
           step 1: core-types
           step 2: storage-layer
           step 3: cli-layer
           step 4: e2e-tests

        6) 리스크: 없음

        이 제안이 맞습니까?
```

```
개발자> 좋아. 진행.
```

```
Claude> 문서 갱신합니다:

        ▸ docs/PRD.md          (신규 — mvp 포맷)
        ▸ docs/ARCHITECTURE.md (신규)
        ▸ docs/ADR.md          (신규 — ADR-001~003)
        ▸ phases/0-mvp/PRD.md  (스냅샷)
        ▸ phases/0-mvp/INTAKE.md (면담+분석 기록)

        Stage-end 커밋: chore(0-mvp): stage 1 discovery outputs

        ✓ Stage 1 완료.

        검토할 파일:
          📄 docs/PRD.md
          📄 docs/ARCHITECTURE.md
          📄 docs/ADR.md
          📄 phases/0-mvp/INTAKE.md

        다음: /harness mvp
```

**개발자 할 일**: 파일을 에디터로 열어 검토. 수정 필요하면 직접 편집 또는 `/harness-plan mvp` 재실행(iterate 모드).

### Stage 2 — Planning

```
개발자> /harness mvp
```

```
Claude> ━━━ Validation Gate ━━━
        ✓ docs/PRD.md placeholder 없음
        ✓ 핵심 섹션 모두 채워짐
        ✓ AC가 실행 가능 커맨드 형태
        GATE PASS.

        Phase 번호: 0 (첫 phase)
        Phase 이름: mvp

        phases/0-mvp/index.json + step0~4.md 생성 중...

        Stage-end 커밋: chore(0-mvp): stage 2 planning outputs

        ✓ Stage 2 완료.

        검토할 파일:
          📄 phases/0-mvp/index.json
          📄 phases/0-mvp/step0.md  ← project-setup
          📄 phases/0-mvp/step1.md  ← core-types
          📄 phases/0-mvp/step2.md  ← storage-layer
          📄 phases/0-mvp/step3.md  ← cli-layer
          📄 phases/0-mvp/step4.md  ← e2e-tests

        다음: python3 scripts/execute.py 0-mvp
```

### Stage 3 — Execution

```
개발자> python3 scripts/execute.py 0-mvp
```

```
============================================================
  Harness Step Executor
  Phase: 0-mvp | Mode: mvp | Steps: 5
============================================================
  Branch: feat-0-mvp

  Step 0/4 (0 done): project-setup
  ◐ [12s]
  ✓ Step 0: project-setup [12s]
  Commit: feat(0-mvp): step 0 — project-setup

  Step 1/4 (1 done): core-types
  ◐ [18s]
  ✓ Step 1: core-types [18s]
  Commit: feat(0-mvp): step 1 — core-types

  Step 2/4 (2 done): storage-layer
  ◐ [24s]
  ✓ Step 2: storage-layer [24s]

  Step 3/4 (3 done): cli-layer
  ◐ [31s]
  ✓ Step 3: cli-layer [31s]

  Step 4/4 (4 done): e2e-tests
  ◐ [19s]
  ✓ Step 4: e2e-tests [19s]

  All steps completed!
============================================================
  Phase '0-mvp' completed!
============================================================
```

**개발자 할 일**: 지켜보기. 실패가 뜨면 Ctrl+C 가능. 3회 재시도 후에도 실패 시 자동 중단.

### Stage 4 — Review

```
개발자> /review
```

```
Claude> ━━━ Review: 0-mvp (Mode: mvp) ━━━

        ## 변경 요약
        - 커밋 수: 12 (feat: 6, chore: 6)
        - 변경 파일 수: 15 (신규 14, 수정 1)
        - 총 라인: +487 / -0

        ## 공통 체크리스트
        | 항목 | 결과 |
        |------|------|
        | 아키텍처 준수 | ✅ |
        | 기술 스택 준수 | ✅ |
        | CLAUDE.md CRITICAL | ✅ |
        | 빌드/테스트 | ✅ (24 passed) |
        | 커밋 prefix | ✅ (feat:) |

        ## Mode별 체크리스트 (mvp)
        | 항목 | 결과 |
        |------|------|
        | 출시 가능 기준 | ✅ AC-1~6 전부 통과 |
        | 5 step 순서 | ✅ |
        | 초기 ADR | ✅ (3개) |
        | MVP 비목표 미포함 | ✅ |

        🔴 Blocker: 없음

        ━━━ PR 초안 ━━━
        제목: feat: link-keeper MVP (0-mvp)

        ## Summary
        - Python 패키지 link_keeper (models/storage/cli/__main__)
        - 4개 명령 add/list/find/delete
        - 24개 테스트 (단위 + e2e)

        ## AC 검증
        - [x] AC-1~6

        ## Test Plan
        - [x] python -m pytest — 24 passed

        이 PR을 생성할까요? (y/n/수정)
```

```
개발자> y
```

```
Claude> gh pr create 실행... 
        ✓ PR 생성됨: https://github.com/<owner>/link-keeper/pull/1
```

---

## 시나리오 2 — 기존 MVP에 기능 추가 (Feature)

**상황**: 시나리오 1의 link-keeper 완성. 이제 "북마크에 메모 필드 추가" 기능을 붙이고 싶음.

### Stage 1 — Discovery

```
개발자> /harness-plan feature
```

```
Claude> phases/0-mvp/ 완료됨. 모든 phase 완료 상태 → 새 feature phase 시작.

        새 phase 이름은? (kebab-case, 예: "bookmark-notes")
```

```
개발자> bookmark-notes
```

```
Claude> phases/1-bookmark-notes/ 생성 예정.
        Feature 모드 Discovery — 4개 질문.

        Q1. 이 기능이 해결하는 구체적 문제?
```

```
개발자> 북마크에 "왜 저장했는지" 짧은 메모를 남기고 싶다. 1주일 뒤에
       보면 왜 저장했는지 기억 안 나는 경우가 많음.
```

```
Claude> Q2. 구체적 사용자 시나리오?
```

```
개발자> link add <url> --tags ... --note "백엔드 성능 개선 참고" 식으로 
       저장. list/find 결과에 메모 같이 표시.
```

```
Claude> Q3. 성공 기준?
```

```
개발자> AC-1: --note 플래그로 메모 저장됨.
       AC-2: 메모가 없는 북마크도 정상 동작 (기존 호환).
       AC-3: list/find 출력에 메모 있으면 같이 표시 (없으면 생략).
```

```
Claude> Q4. 명시적 비목표?
```

```
개발자> 메모 편집(update 명령) 추가, 메모 본문 검색, 마크다운 렌더링.
```

```
Claude> Phase A 완료. Plan Mode + Explore 병렬 3개 실행...

        ━━━ 코드베이스 분석 결과 (feature 모드) ━━━

        1) 영향받는 파일
           수정:
           ✏ link_keeper/models.py        → Bookmark에 note: Optional[str] 추가
           ✏ link_keeper/cli.py           → cmd_add에 --note 인자, 출력 포맷
           
           신규: (없음 — 기존 파일 확장)

        2) 수정 금지
           🚫 link_keeper/storage.py   (이유: 스키마는 models.py가 정의. 
                                         storage는 dict 그대로 직렬화.)

        3) 필요한 새 ADR
           불필요 (기존 ADR 범위 내 확장).

        4) 예상 step 구조 (3 step — UI 없으므로 축소)
           step 0: types-extension  (Bookmark.note 필드 추가)
           step 1: cli-layer        (--note 플래그 + 출력)
           step 2: regression-tests (3 AC + 기존 24 테스트)

        5) 리스크:
           ⚠ note 없는 기존 북마크 JSON이 로드 실패할 수 있음.
             Option A: note를 Optional[str] = None으로 → 기존 데이터 호환
             Option B: 마이그레이션 스크립트 추가 (과잉)
             어느 쪽?
```

```
개발자> A. 호환성 우선.
```

```
Claude> 반영합니다. docs 갱신 + phases/1-bookmark-notes/ 생성 중...
        ✓ Stage 1 완료. 검토할 파일 5개. 다음: /harness feature
```

이후 Stage 2→3→4는 시나리오 1과 동일한 흐름. 커밋 prefix는 `feat:`, 브랜치는 `feat-1-bookmark-notes`.

---

## 시나리오 3 — 버그 픽스 (Patch)

**상황**: 사용자가 제보. "`link delete 1`하고 `link add <url>` 했더니 id가 1로 되면서 이상해짐." (실제로는 재현 안 되지만 사용자 경험이 이상함)

### Stage 1 — Discovery

```
개발자> /harness-plan patch
```

```
Claude> phases/1-bookmark-notes/ 완료됨. 새 patch phase 시작.
        새 phase 이름은?
```

```
개발자> list-order-bug
```

```
Claude> Patch 모드 Discovery — 3개 질문.

        Q1. 버그의 정확한 재현 조건?
```

```
개발자> link add "a" → id 1
       link add "b" → id 2
       link add "c" → id 3
       link delete 2 → b 삭제
       link list 하면 [1, 3] 표시됨
       → "중간에 구멍이 나 있는 게 보기 싫다. 재정렬하고 싶다."
```

```
Claude> 사실관계 확인: 이게 실제 버그인가요, UX 불만인가요?
        PRD에서 id 연속성은 AC가 아닙니다. id는 "영구 참조용"으로
        설계됐을 가능성이 큽니다(delete 후 재사용하면 링크 깨짐).

        Option A: 버그로 취급 → id 재정렬 (기존 참조 깨짐)
        Option B: UX 개선으로 취급 → 별도 "list 시 0부터 번호 재부여" 옵션
        Option C: 이 phase 취소 — id 정책을 바꾸는 건 refactor 모드가 맞음
```

```
개발자> C. 맞네. ID 정책 변경은 patch 범위가 아니다. 취소.
```

```
Claude> /harness-plan patch 세션 종료. 아무 파일도 생성되지 않았습니다.
```

**교훈**: iterate 모드의 브레이크는 **사용자의 잘못된 분류**도 잡습니다.

### 실제 버그 시나리오 — done idempotency

**상황 변경**: 과거 누가 `cmd_done`을 toggle로 바꿨음. 사용자 제보 "done 두 번 누르니까 다시 안 된 걸로 됨."

```
개발자> /harness-plan patch
```

```
Claude> 새 patch phase 시작. 이름?
```

```
개발자> done-idempotency
```

```
Claude> Q1. 재현 조건?
개발자> link add "x" → link done 1 → link done 1 → list 하면 done=false
Claude> Q2. 기대 동작?
개발자> done은 idempotent해야 함. 두 번 호출해도 done=true 유지.
Claude> Q3. 영향 범위?
개발자> cmd_done 한 함수로 보임. 다른 명령은 무관할 듯.

Claude> Plan Mode + Explore로 확인... 5초.

        ━━━ 분석 ━━━
        1) 에러 발생: link_keeper/cli.py:44
           `t.done = not t.done  # "toggle" for convenience`
           원인: toggle 동작. idempotency 요구와 충돌.
        
        2) 실패 테스트 추가: tests/test_cli.py의 test_done_is_idempotent
        
        3) 수정 대상: link_keeper/cli.py (cmd_done 한 줄)
        
        4) 수정 금지:
           🚫 link_keeper/storage.py (storage 무관)
           🚫 link_keeper/models.py (타입 무관)
           🚫 기존 test_done_marks_completed (회귀 보호)
        
        5) step 구조:
           step 0: reproduce (실패 테스트)
           step 1: fix (한 줄 수정)

        이 분석이 맞습니까?
```

```
개발자> 맞다. 진행.
```

### Stage 2-4

이후 흐름은 간단:
- `/harness patch` → step0.md, step1.md 생성
- `python3 scripts/execute.py 2-done-idempotency` → `fix-` 브랜치에서 TDD
  - step0: 실패 테스트 작성 (`fix:` 커밋)
  - step1: 한 줄 수정, 전체 테스트 통과 (`fix:` 커밋)
- `/review` → patch 체크리스트 (변경 최소성, TDD 순서, 회귀 없음) → PR 초안

최종 diff: `+13 / -2` 라인. 커밋 5개.

---

## 시나리오 4 — Iterate 모드: 수정 반영

**상황**: 시나리오 2의 Stage 1이 끝났는데, 검토 중 "AC-3의 '메모 있으면 같이 표시'가 1줄로 표시되는지 여러 줄인지 모호하다"는 걸 발견.

```
개발자> /harness-plan feature
```

```
Claude> phases/1-bookmark-notes/가 이미 진행 중입니다. iterate 모드로 진입합니다.

        현재 파일:
          📄 docs/PRD.md                        (feature 내용)
          📄 phases/1-bookmark-notes/PRD.md     (스냅샷)
          📄 phases/1-bookmark-notes/INTAKE.md  (면담+분석)
        
        어떤 부분을 수정할까요?
```

```
개발자> AC-3을 "메모는 한 줄 생략해서 표시 (60자 초과시 ...)"로 구체화
```

```
Claude> 영향 분석:
        - docs/PRD.md와 phases/1-bookmark-notes/PRD.md의 AC-3 수정
        - 이미 Stage 2(phases/1-bookmark-notes/step*.md)가 생성된 상태라면
          step1(cli-layer)의 "작업" 섹션과 step2의 AC에도 반영 필요
        
        설계 원칙 체크:
        - ✅ 비목표 섹션과 충돌 없음
        - ✅ Feature 모드 원칙 위배 없음

        반영하겠습니다. 파일 수정 중...
        
        ✓ 다음 파일 수정됨:
          📄 docs/PRD.md (AC-3 문구 구체화)
          📄 phases/1-bookmark-notes/PRD.md (동일)
          📄 phases/1-bookmark-notes/INTAKE.md (Q3 답변 보강)
          📄 phases/1-bookmark-notes/step1.md (작업에 "60자 생략 로직" 추가)
          📄 phases/1-bookmark-notes/step2.md (AC에 생략 동작 테스트 추가)
        
        더 수정할 부분? (없으면 "끝")
```

```
개발자> 끝.
```

```
Claude> Stage-end 커밋: chore(1-bookmark-notes): iterate — AC-3 구체화
        
        ✓ iterate 완료. 변경 5개 파일.
        다음: /harness feature 재실행 (step 파일들이 수정됐으니 review 후 execute.py)
```

**핵심**: iterate는 **관련 파일 간 정합성**(PRD ↔ step 파일들)을 자동으로 맞춰줍니다.

---

## 시나리오 5 — Stage 3 에러 복구

**상황**: `execute.py` 실행 중 step 2(cli-layer)가 3회 재시도 후 실패.

```
(실행 로그 중략)
  Step 2/3 (2 done): cli-layer
  ↻ Step 2: retry 1/3 — AssertionError: expected note="..." in output
  ↻ Step 2: retry 2/3 — AssertionError: expected note="..." in output
  ↻ Step 2: retry 3/3 — AssertionError: expected note="..." in output
  ✗ Step 2: cli-layer failed after 3 attempts [123s]
    Error: 60자 생략 로직이 "60자 미만인 메모도 ..." 붙음
```

```
개발자> /harness feature
```

```
Claude> phases/1-bookmark-notes/에서 step 2가 status=error입니다.
        Stage 3 에러 복구 모드로 진입합니다.

        ━━━ 에러 분석 ━━━
        Phase: 1-bookmark-notes | Step: 2 (cli-layer)

        에러 유형: 테스트 실패 (AssertionError)
        에러 요약: 60자 미만 메모에도 "..." suffix가 붙음
        
        원인 가설: step2.md의 "60자 초과시 ..." 지시를 Claude 서브세션이
                   "무조건 ..." 붙이는 걸로 해석한 듯. 조건문 누락.
        
        step.md의 어디가 부족했나:
        - "60자 초과시" 조건이 알고리즘 수준이 아니라 자연어로만 표현됨
        - 경계 케이스(정확히 60자, 0자, None)에 대한 명세 없음

        Option A: step.md 지시 보강 (권장)
                  "len(note) <= 60이면 그대로, > 60이면 note[:57] + '...'
                  note가 None이면 표시 생략" 같이 명시적으로.
        Option B: Phase B 재분석 필요
        Option C: blocked 처리

        어느 쪽?
```

```
개발자> A로. 알고리즘 형태로 명시해줘.
```

```
Claude> step2.md 수정:
        
        기존:
        ## 작업
        ... 메모를 한 줄 생략해서 표시 (60자 초과시 ...)
        
        신규:
        ## 작업
        ...
        - note가 None이거나 빈 문자열이면 출력에서 생략
        - len(note) <= 60이면 그대로 출력
        - len(note) > 60이면 note[:57] + "..." 로 출력
        - 경계: note가 정확히 60자면 그대로 (생략 안 함)

        ✓ step2.md 수정 완료
        ✓ phases/1-bookmark-notes/index.json의 step 2 status를 pending으로 리셋
        
        이제 재실행:
          python3 scripts/execute.py 1-bookmark-notes
        (step 0, 1은 이미 completed이므로 step 2부터 재개됩니다)
```

```
개발자> python3 scripts/execute.py 1-bookmark-notes
```

```
  ...
  Step 2/2 (2 done): cli-layer   ← 재개
  ✓ Step 2: cli-layer [45s]
  Step 3/2 (3 done): regression-tests
  ✓ Step 3: regression-tests [21s]
  All steps completed!
```

**핵심**: 실패 시 대화형으로 step.md를 **정확하게 보강**한 뒤 재개. 전체 재시작 불필요.

---

## 시나리오 6 — 완전 재시작 (`--reset`)

**상황**: Phase 1 Discovery 중에 "사실 기능 범위를 완전히 잘못 잡았다"는 걸 깨달음.

```
개발자> /harness-plan feature --reset
```

```
Claude> --reset 감지. 진행 중 phase를 아카이브합니다.
        
        이동: phases/1-bookmark-notes/
          → phases/.archived-2026-04-22T13-45-22+0900-1-bookmark-notes/
        
        phases/index.json의 해당 엔트리에 archived_at 기록.
        
        새 Discovery를 시작합니다.

        새 phase 이름은? (kebab-case)
```

이후 Phase A부터 완전히 새로 진행. 이전 면담/분석은 archived 폴더에 보존되어 나중에 참고 가능.

---

## Tips — 답변 요령

### 좋은 Phase A 답변
- **구체적**: "편해진다" ❌ → "3번 클릭을 1번으로 줄임" ✅
- **측정 가능한 AC**: "동작한다" ❌ → "`pytest tests/X.py` 통과" ✅
- **비목표를 풍부하게**: 3개 이상 쓰면 스코프 폭발 방지에 큰 도움

### 좋은 iterate 지시
- **어느 파일/섹션**을 어떻게 바꿀지 명시하면 정확
  - "AC-3 문구 수정" ✅
  - "뭔가 이상한데" ❌ (Claude가 추측하게 됨)
- **이유 함께**: "X를 Y로 바꿔라. 이유: Z" — Claude가 파급 효과 정확히 분석

### 실행 감독 팁
- step이 30초 이상 멈춰있으면 서브 세션이 무한 루프에 빠졌을 가능성 — Ctrl+C 후 step.md 보강
- retry 2회째에도 같은 에러 패턴이면 step.md 지시 자체가 부족 — 취소 후 iterate
- 1 step이 너무 커 보이면 (15분+) Stage 2로 돌아가 step을 분할하는 게 나음

### 하네스를 쓰지 말아야 할 순간
- 로그 한 줄 수정, 변수명 rename — 그냥 Claude Code에 말하면 됨
- 긴급 핫픽스 (Stop 훅 + CLAUDE.md만으로 충분)
- "해보고 싶은 실험" — 구조화 오버헤드가 탐색을 방해

---

## 다음 단계

- 실제 프로젝트에 도입: `.claude/`·`scripts/`·`docs/` 복사, `CLAUDE.md` 프로젝트 규칙에 맞게 수정
- 첫 phase: **반드시 mvp 모드** (빈 레포) 또는 기존 코드 있으면 patch/feature로 시작
- 질문/개선 제안: 이슈로
