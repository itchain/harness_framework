# Harness Framework — 개발자 가이드

Claude Code 기반으로 **설계 → 계획 → 구현 → 검증**을 자동화하는 프레임워크. 개발자는 **의도 전달과 검증·승인**만 하고, 나머지는 하네스가 규율 있게 수행한다.

---

## 왜 쓰는가

일반 Claude Code 세션은 자유로워서 다음 문제가 생긴다:

1. **엉성한 스펙이 엉성한 코드를 만든다** — "할 일 공유 기능 추가해줘" 같은 모호한 지시는 예측 불가한 결과
2. **작업 성격에 따른 규율 차이가 없다** — MVP 구축과 버그 픽스가 같은 강도로 진행되면 한쪽은 답답하고 한쪽은 위험
3. **개발자/AI 역할 분담이 흐릿하다** — 개발자가 코드 분석까지 떠안거나, AI가 임의로 설계 결정을 내림

하네스는 이 셋을 **4-Stage 워크플로우 × 4-Mode 분기**로 강제한다.

---

## 한눈에 — 전체 구조

```
개발자 의도
    ↓
/harness-plan {mode}    [Stage 1 Discovery]
    ├─ Phase A: 모드별 질문 3-4개
    ├─ Phase B: Claude가 코드베이스 분석
    └─ Phase C: docs/ 자동 갱신
    ↓
/harness {mode}          [Stage 2 Planning]
    ├─ Validation Gate (docs 품질 검증)
    └─ phases/{N}-{name}/ 생성 (index.json + step*.md)
    ↓
execute.py {task}        [Stage 3 Execution]
    ├─ 각 step 자동 실행 (서브 Claude)
    ├─ 실패 시 자가교정 (모드별 retry)
    └─ feat/fix/refactor 브랜치에 커밋
    ↓
/review                  [Stage 4 Review]
    ├─ 모드별 AC 검증
    └─ PR 초안
```

각 Stage는 **파일을 남긴다** — 대화 아니라 파일로 검토한다.

---

## 빠른 시작

### 지금 상태에 맞는 모드 고르기

| 현재 상태 | 시작 모드 | 이유 |
|----------|----------|------|
| 빈 레포, 새 프로젝트 | **mvp** | 코드가 없으니 0부터 빌드 |
| MVP가 이미 있고 기능 추가 | **feature** | 기존 코드 위에 수평으로 붙임 |
| 기존 코드에 버그 발견 | **patch** | 기존 코드가 전제. 없으면 패치할 대상이 없음 |
| 동작은 그대로, 구조만 개선 | **refactor** | 기존 코드가 전제 |

**핵심**: patch/feature/refactor는 **기존 코드베이스가 있어야 의미가 있다**. 빈 레포에서는 반드시 `mvp`부터 시작.

### 자연스러운 프로젝트 진행 순서

```
0. 빈 레포
   │
   ├─ /harness-plan mvp   →  /harness mvp  →  execute.py 0-mvp  →  /review
   │                                                    │
   ↓                                                    ↓
1. MVP 완성 (phases/0-mvp/)                      머지
   │
   ├─ /harness-plan feature   →  /harness feature  →  execute.py 1-...
   │                                                            │
   ↓                                                            ↓
2. 첫 기능 추가 (phases/1-xxx/)                            머지
   │
   ├─ (버그 발견) /harness-plan patch  → ... →  머지
   ├─ (구조 문제) /harness-plan refactor  → ... →  머지
   └─ (다음 기능) /harness-plan feature  → ... →  머지
```

### 시나리오 A — 새 프로젝트 시작 (MVP)

가장 먼저 해야 할 것. 빈 레포에서 출발.

```bash
# 0) 레포 초기화
git init
cp -r {이-하네스-레포}/.claude {이-하네스-레포}/scripts .
mkdir docs phases
# CLAUDE.md, docs/PRD.md 등은 /harness-plan mvp가 생성해 준다

# 1) Discovery — 제품 기획 면담 (4개 질문: 목적/사용자/출시기준/제외사항)
/harness-plan mvp

# 2) Planning — 스택·도메인·초기 ADR·7 step 생성
/harness mvp

# 3) 파일 검토 (에디터에서 열어봄)
#    docs/PRD.md, docs/ARCHITECTURE.md, docs/ADR.md
#    phases/0-mvp/step0.md ~ step6.md

# 4) 실행 — 프로젝트를 처음부터 빌드
python3 scripts/execute.py 0-mvp
# → feat-0-mvp 브랜치에서 setup → types → db → api → ui → auth → e2e

# 5) 리뷰 & 머지
/review
# → AC 검증, PR 초안 → 승인
```

예상 시간: Phase A 답변 15-30분 + 자동 실행 20-60분 (프로젝트 크기에 따라).

### 시나리오 B — 기존 코드에 버그 픽스 (Patch)

**전제**: 시나리오 A 완료 상태 (또는 이미 있는 코드베이스).

```bash
# 1) Discovery — 3개 질문 (재현 조건 / 기대 동작 / 영향 범위)
/harness-plan patch

# 2) Planning — 2 step (reproduce → fix) 생성
/harness patch

# 3) 파일 검토
#    phases/N-{bug-name}/step0.md (실패 테스트 작성 지시)
#    phases/N-{bug-name}/step1.md (최소 수정 지시)

# 4) 실행
python3 scripts/execute.py N-{bug-name}
# → fix-N-{bug-name} 브랜치, TDD 순서로 진행

# 5) 리뷰 & 머지
/review
```

예상 시간: Phase A 답변 2-3분 + 자동 실행 3-10분.

### 시나리오 C — 기존 코드에 기능 추가 (Feature)

시나리오 A와 B 사이 복잡도. 대부분의 실전 개발이 여기에 속함.

```bash
/harness-plan feature        # 4개 질문 (문제/시나리오/AC/비목표)
/harness feature             # 3-5 step 생성 (types→api→ui→tests)
python3 scripts/execute.py N-{feature-name}
/review
```

예상 시간: Phase A 답변 5-10분 + 자동 실행 10-30분.

### 시나리오 D — 구조 리팩터 (Refactor)

가장 신중한 모드. 동작 보존이 전부.

```bash
/harness-plan refactor       # 4개 질문 (이유/문제/목표/동작보존범위)
/harness refactor            # 5-7 step (propose→tests→migrate×N→cleanup→adr)
python3 scripts/execute.py N-{refactor-name}
/review                      # "동작 변경 없음" 검증이 핵심
```

예상 시간: Phase A 답변 10-15분 + 자동 실행 15-45분.

---

## 4 모드 — 무엇을 고를까

| 모드 | 언제 | Step 수 | 성격 |
|------|------|---------|------|
| **mvp** | 빈 레포, 처음 빌드 | 7 (수직 레이어) | setup→types→db→api→ui→auth→e2e |
| **feature** | 기능 추가 | 3-5 (수평 절단) | types→api→ui→regression |
| **refactor** | 구조 변경, 동작 보존 | 5-7 (배치 이관) | propose→tests→migrate×N→cleanup→adr |
| **patch** | 버그 픽스, 소수정 | 1-3 (TDD) | reproduce→fix |

### 고르는 방법

```
변경 규모가 어떤가?
├─ 빈 프로젝트 → mvp
├─ 새 기능 추가 → feature
├─ 동작 그대로, 구조만 바꿈 → refactor
└─ 버그/작은 수정 → patch
```

잘못 골라도 iterate 모드로 바꿀 수 있다 (뒤에서 설명).

### 모드별 엄격도

| 항목 | mvp | feature | refactor | patch |
|------|:---:|:---:|:---:|:---:|
| 브랜치 prefix | `feat-` | `feat-` | `refactor-` | `fix-` |
| 커밋 prefix | `feat:` | `feat:` | `refactor:` | `fix:` |
| Retry | 3 | 3 | 2 | 2 |
| 금지사항 엄격도 | 낮음 | 중간 | 높음 | **매우 높음** |
| 핵심 AC | 기능 동작 | 기능 + 회귀 | **동작 보존** | 테스트 통과 + 회귀 |

---

## 4 Stage — 무엇을 하는가

### Stage 1: Discovery (`/harness-plan {mode}`)

**역할**: 개발자 머릿속 의도를 실행 가능한 스펙(docs)으로 변환.

**Phase A — 의도 면담**
- 모드별로 3-4개 질문
- 답이 추상적이면 Claude가 구체화 요구 ("'편해진다'는 측정 불가")

**Phase B — 코드베이스 분석** (Claude 자동, Plan Mode)
- Explore 에이전트 병렬로 영향 파일/금지 영역/새 ADR 식별
- 리스크 있으면 Option A/B/C로 개발자 판단 요청

**Phase C — 문서 갱신** (Claude 자동)
- `docs/PRD.md` 교체 (이전은 `phases/{N}/PRD.md`로 스냅샷)
- `docs/ARCHITECTURE.md`, `docs/ADR.md` 증분
- `phases/{N}/INTAKE.md` (면담+분석 기록)

**개발자 할 일**: 의도 답변 (4개) + Claude 제안 검증/수정

### Stage 2: Planning (`/harness {mode}`)

**역할**: docs를 읽고 실행 가능한 step 파일로 분해.

**0. Validation Gate**
- `docs/PRD.md`에 placeholder 남아있으면 FAIL
- 핵심 섹션 비었으면 FAIL → Stage 1으로 돌려보냄

**1. Phase 분해**
- 모드별 step 템플릿으로 `phases/{N}/step*.md` 생성
- 각 step은 "읽어야 할 파일 / 작업 / AC / 수정 금지" 포함

**개발자 할 일**: 계획 검토 + 승인 (또는 iterate로 수정)

### Stage 3: Execution (`python3 scripts/execute.py {task}`)

**역할**: 각 step을 독립 Claude 세션에서 순차 실행.

- `{prefix}-{task}` 브랜치 자동 생성
- 매 step마다 서브 Claude가 step.md 지시대로 코드 작성
- AC 실행 (Stop 훅이 `lint && build && test`)
- 실패 시 에러를 다음 프롬프트에 피드백하며 재시도 (모드별 2~3회)
- 성공 시 `{commit_type}:` + `chore:` 2단계 커밋

**개발자 할 일**: 실행 감독 (문제 보이면 Ctrl+C)

### Stage 4: Review (`/review`)

**역할**: 완료된 phase의 변경을 AC 대비 검증하고 PR 만들기.

- 공통 체크리스트 (아키텍처·스택·CRITICAL·빌드) + **모드별 체크리스트**
- 이슈 분류 (🔴 Blocker / 🟡 Non-blocker / ℹ️ Nit)
- Blocker 있으면 PR 생성 중단
- OK면 PR 제목/본문 초안 → 승인 → `gh pr create`

**개발자 할 일**: 리뷰 확인 + PR 승인

---

## 슬래시 명령 레퍼런스

| 명령 | 단계 | 주요 동작 |
|------|------|---------|
| `/harness-plan {mode}` | Stage 1 | 면담 + 분석 → docs 갱신 |
| `/harness-plan {mode} --reset` | Stage 1 | 기존 phase 아카이브 후 신규 시작 |
| `/harness {mode}` | Stage 2 | Validation + phase/step 파일 생성 |
| `python3 scripts/execute.py {task}` | Stage 3 | step 순차 실행 (내부 서브 Claude) |
| `python3 scripts/execute.py {task} --push` | Stage 3 | 완료 후 origin 푸시 |
| `/review` | Stage 4 | AC 검증 + PR 초안 |

**재실행 시 자동 iterate 모드**: `/harness-plan` / `/harness`를 phase가 이미 있는 상태에서 다시 부르면, 자동으로 대화형 수정 모드 진입.

---

## 파일 레이아웃

```
your-project/
├── CLAUDE.md                     # 프로젝트 규칙 (모든 세션에 주입됨)
├── docs/                         # 글로벌 가드레일 (매 step 프롬프트에 포함)
│   ├── PRD.md                    # 현재 phase의 의도 (phase마다 교체)
│   ├── ARCHITECTURE.md           # 현재 구조 (증분 수정)
│   ├── ADR.md                    # 결정 이력 (append only)
│   └── UI_GUIDE.md               # 스타일 규격 (거의 불변)
│
├── phases/                       # 모든 phase 영구 보존 (공식 changelog)
│   ├── index.json                # 전체 phase 목록 + 상태
│   ├── 0-mvp/                    # 완료된 MVP
│   │   ├── PRD.md                # 당시 PRD 스냅샷
│   │   ├── INTAKE.md             # Phase A+B 기록
│   │   ├── index.json            # step 상태
│   │   ├── step0.md              # step 지시문
│   │   ├── step0-output.json     # 서브 Claude의 실행 결과
│   │   ├── step1.md
│   │   └── ...
│   ├── 1-todo-sharing/           # 완료된 feature phase
│   └── 2-login-bug-fix/          # 진행 중인 patch phase
│
├── scripts/
│   └── execute.py                # Stage 3 오케스트레이터
│
└── .claude/
    ├── settings.json             # hooks (Stop: lint+build+test, PreToolUse: 위험 명령 차단)
    └── commands/
        ├── harness-plan.md       # Stage 1 슬래시 명령
        ├── harness.md            # Stage 2
        └── review.md             # Stage 4
```

---

## 수정하고 반복하기 (Iterate)

실수나 변경이 생기면 **슬래시 명령을 그냥 재실행**한다. 자동으로 iterate 모드 진입.

```
개발자> /harness-plan feature

Claude> (이미 phases/2-sharing/이 있음 → iterate 모드)
        현재 파일 상태를 보여드립니다:
          📄 docs/PRD.md
          📄 phases/2-sharing/INTAKE.md
          ...
        어떤 부분을 수정할까요?

개발자> AC-3을 "5초 내 반영"으로 강화

Claude> 영향 분석:
        - PRD.md의 AC-3 수정 필요
        - 실시간 동기화가 비목표였음 → 충돌
        Option A: 비목표에서 제거 (스코프 확장)
        Option B: AC-3 원상복구

개발자> B

Claude> ✓ 원상복구. 변경 없음.
```

**iterate 모드의 브레이크**: Claude가 단순 순종이 아니라 **설계 원칙 위반을 감지해 되묻는다**. 사용자가 잘못된 지시를 내리면 Option 제시.

### 완전 재시작

```
/harness-plan {mode} --reset
```
기존 phase를 `phases/.archived-{timestamp}-{name}/`로 옮기고 새로 시작.

---

## 에러 복구

### Stage 3 실패 시

execute.py가 step N에서 재시도 소진:

```bash
/harness {mode}
# → 자동으로 에러 복구 모드
# → Claude가 에러 분석, 3가지 옵션 제시:
#   A) step.md 지시 보강 (대부분)
#   B) Phase B 재분석 필요 (/harness-plan 권장)
#   C) blocked 처리 (외부 입력 대기)
```

### Blocker (외부 의존)

API 키, 수동 승인, 외부 시스템 접근이 필요하면:
- `phases/{task}/index.json`의 해당 step을 `status: blocked`로 변경
- `blocked_reason` 기록
- 해결 후 `status: pending`으로 리셋 후 execute.py 재실행

---

## 하네스를 쓰지 말아야 할 때

하네스는 **규율 강화 장치**지 만능은 아니다. 다음은 일반 Claude Code 세션이 낫다:

- **1-2 파일 수정** (한 줄 버그, 문구 변경)
- **대화형 탐색** ("이 함수 어떻게 동작해?")
- **실험적 프로토타입** (어떻게 될지 모르고 해보는 것)
- **긴급 핫픽스** (규율보다 속도가 우선)

**판단 기준**: step이 3개 이상 나올 것 같으면 하네스, 아니면 그냥 세션.

단, 일반 세션에서도 **Stop 훅(lint+build+test)**과 **CLAUDE.md 규칙 주입**은 똑같이 작동한다. 하네스가 더 주는 것은 **멀티스텝 조율 + 강제 문서화 + 자가교정**.

---

## Phase 라이프사이클

```
새 기능 시작:
  /harness-plan {mode}
  └─ Claude가 phases/ 상태 확인
      ├─ 진행 중 phase 있음 → iterate
      ├─ 모두 완료 → 새 phase 번호 부여해 시작
      └─ phases/ 없음 → 첫 phase (mvp 추천)

진행 중 phase가 완료되면:
  docs/PRD.md = 여전히 해당 phase 내용
  phases/{N}/PRD.md = 스냅샷 보존

다음 phase 시작:
  /harness-plan {mode}
  └─ 자동으로 다음 번호로 새 phase 생성
  └─ Phase C에서 docs/PRD.md 교체
      (이전 PRD는 phases/{N}/PRD.md에 이미 보존됨)
```

**docs/ 파일별 주기**:
| 파일 | 주기 |
|------|------|
| PRD.md | phase마다 **교체** (volatile) |
| ARCHITECTURE.md | **증분 수정** (living) |
| ADR.md | **append only** (누적) |
| UI_GUIDE.md | 거의 불변 |

---

## 개발자가 실제로 하는 일 — 요약

하나의 phase를 끝까지 가는 동안 개발자가 하는 일은 **4가지**뿐:

1. **의도 전달** (Phase A 질문 답변)
2. **검증** (Phase B 분석 확인)
3. **감독** (Stage 3 실행 관찰)
4. **승인** (Stage 4 PR OK)

**전체 입력**: 슬래시 명령 4회 + 자연어 답변 몇 개 + y 승인 2-3회.

나머지는 전부 하네스 또는 훅이 처리한다.

---

## FAQ

**Q. 하네스를 새 프로젝트에 도입하려면?**
A. 이 레포의 `.claude/`와 `scripts/`를 복사, `docs/`는 템플릿으로 초기화, `CLAUDE.md`만 프로젝트 규칙에 맞게 수정.

**Q. 여러 개발자가 협업하면?**
A. `phases/{N}/`는 git에 커밋되니 공유됨. 동시에 같은 phase를 만지면 병합 충돌 가능 — phase 번호·이름을 달리해 분리 작업.

**Q. 하네스가 만든 PR을 사람이 머지해도 되나?**
A. 당연히 사람이 머지. `/review`는 초안을 만들 뿐, 실제 머지는 GitHub UI/정책에 따름.

**Q. Stop 훅의 `lint && build && test`가 내 프로젝트에 안 맞으면?**
A. `.claude/settings.json`의 훅 커맨드를 프로젝트에 맞게 수정. `npm`이 아니면 `pnpm`, `yarn`, `cargo test`, `pytest` 등.

**Q. ADR이 너무 쌓이면?**
A. 2-3년짜리 SaaS 스케일이 아니면 하나의 `docs/ADR.md` 파일로 충분 (보통 20-50개까지). 넘어가면 `docs/adrs/{topic}.md`로 분할하고 step 파일의 "읽어야 할 파일"에 명시적으로 지목.

**Q. 실패 시 내가 직접 파일 고쳐도 되나?**
A. 된다. 파일 직접 편집은 언제나 옵션. 단, 여러 파일 간 정합성(PRD ↔ step ↔ index.json)을 사람이 맞추기 어려우니 구조 변경은 iterate 추천.

---

## 다음 읽을 것

- `.claude/commands/harness-plan.md` — Stage 1 상세 프롬프트
- `.claude/commands/harness.md` — Stage 2 상세 + 모드별 step 템플릿
- `.claude/commands/review.md` — Stage 4 체크리스트
- `scripts/execute.py` — Stage 3 오케스트레이터 소스
- `docs/` — 각 문서의 역할 이해

문제나 제안은 이슈로.
