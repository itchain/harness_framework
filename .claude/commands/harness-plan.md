이 프로젝트는 Harness 프레임워크를 사용한다. 이 명령은 **Stage 1 (Discovery)**를 담당한다.

다음 Stage(Planning, `/harness {mode}`)가 돌기 전에 `docs/`와 `phases/{task}/INTAKE.md`를 준비하는 것이 이 명령의 유일한 책임이다.

---

## Usage

```
/harness-plan {mode}
```

`{mode}` ∈ `{mvp, feature, refactor, patch}`

인자가 없으면 사용자에게 모드를 되묻는다.

**원칙**:
- 개발자는 **의도와 판단**만 제공 (Phase A)
- Claude는 **코드베이스 분석과 초안**을 담당 (Phase B)
- Claude의 제안은 개발자가 **검증·승인** (Phase C 직전)

---

## 실행 흐름

### 0. 상태 판단

먼저 인자에 `--reset` 플래그가 있는지 확인.

#### --reset 분기

사용자가 `/harness-plan {mode} --reset`으로 실행한 경우:

1. 진행 중인 `phases/{task}/`가 있는지 찾는다 (status=pending 또는 step이 pending)
2. 있으면 현재 KST 타임스탬프로 archive:
   ```
   phases/{task}/ → phases/.archived-{YYYY-MM-DDTHH:MM:SS+0900}-{task}/
   ```
3. `phases/index.json`의 해당 엔트리도 `archived_at` 타임스탬프 추가 + `status: archived`
4. Archive 완료 후 안내:
   ```
   ✓ 이전 phase를 phases/.archived-<timestamp>-<task>/로 옮겼습니다.
   이제 새 Discovery를 시작합니다.
   ```
5. Phase A부터 정상 수행 (아래 "신규 phase 모드"와 동일)

--reset이 없으면 아래 표의 일반 분기 적용.

| 상태 | 분기 |
|------|------|
| `phases/` 없음 | **첫 phase** 안내 (mvp 모드 추천). 사용자에게 mode 확인. |
| 진행 중 phase 존재 (status=pending이거나 어떤 step이 pending) | **Iterate 모드**로 진입 (아래 섹션 참조). |
| 모든 phase 완료 | **신규 phase 모드**. 아래 Phase A부터 수행. |

### Phase A — 의도 면담

**mode별 질문지**를 순차 제시한다. 개발자의 답변이 추상적이면 되묻는다 (예: "'더 빠르다'는 측정 불가. 어떤 지표로 측정?").

#### Patch 모드 (3 질문)

```
Q1. 버그의 정확한 재현 조건? (단계별로)
    예: "/todos 페이지에서 TodoForm에 빈 문자열 입력 → Submit 클릭 → TypeError"

Q2. 기대 동작?
    예: "빈 문자열은 validation 에러 표시, submit 막음"

Q3. 영향 범위 추정? (개발자의 느낌)
    예: "TodoForm 한 파일로 추정, 다른 곳 영향 없을 것 같음"
```

답이 모호하면 되묻는다. 특히 Q1의 재현 조건은 **에러 메시지, 스택 트레이스, 실행 경로**를 최대한 구체화하도록 유도.

#### Feature 모드 (4 질문)

```
Q1. 이 기능이 해결하는 구체적 문제? (추상 금지: "편해진다"/"더 좋아진다" X)
    예: "혼자 보던 할 일을 친구와 함께 처리하고 싶다"

Q2. 구체적 사용자 시나리오? (누가, 언제, 무엇을 하는가)
    예: "여행 계획을 만든 사람이 친구 이메일로 초대 → 둘 다 추가/체크 가능"

Q3. 성공 기준? (테스트 가능한 형태)
    모호하면 되묻기. 예: "리스트에 👥 아이콘? 체크 반영 속도? 공유 취소 방법?"
    최종적으로 AC를 3-5개 명시적 항목으로 정리해 사용자에게 확인.

Q4. 명시적 비목표? (최소 3개, 스코프 폭발 방지 핵심)
    예: "실시간 동기화, 알림, N:N 공유, 권한 세분화 모두 다음 phase"
```

Q3은 사용자 답변이 "공유가 보인다" 수준이면 Claude가 5초 내 반영? UI 아이콘? 취소 권한? 등 측정 가능한 형태로 정제하도록 되묻는다.

#### MVP 모드 (4 질문)

```
Q1. 제품의 핵심 목적? (한 줄로. 누구에게 왜 필요한지)
    예: "여행 계획 할 일을 친구와 공유하며 관리하는 간단 앱 — 여행 자주 가는 사용자용"

Q2. 주요 사용자와 사용 맥락? (구체적 페르소나, 사용 시점)
    예: "20-30대, 주말 스마트폰으로 계획 세우고 평일엔 체크인. 친구 1-2명과 같이 사용"

Q3. MVP "출시 가능" 기준? (무엇이 동작하면 "끝"인가, 테스트 가능 형태)
    모호하면 되묻기. 최종적으로 AC 3-5개로 정리.
    예: AC-1 "회원가입→로그인→Todo 생성→완료 체크가 끊김 없이 된다"

Q4. MVP에서 명시적으로 제외할 기능? (최소 3개. 스코프 폭발 방지)
    예: "실시간 동기화, 알림, 첨부파일, 카테고리 분류, 반복 일정"
```

MVP는 **출시 기준**이 가장 중요하다. Q3이 막연하면 반드시 구체 AC로 정제시킬 것.

#### Refactor 모드 (4 질문)

```
Q1. 리팩터 이유? (기술 부채/유지보수성/성능/확장성 중 무엇이 핵심인가)
    예: "AuthMiddleware 클래스가 세 가지 책임을 가져 테스트하기 어렵다"

Q2. 현재 구조의 구체적 문제? (측정 가능하면 더 좋음)
    예: "인증 관련 수정 시 평균 15곳 동시 수정 필요", "테스트 작성 어려움"

Q3. 목표 구조? (어떻게 되어야 하는가, 참고 패턴/레퍼런스가 있으면 첨부)
    예: "함수 기반 미들웨어로 분리. Next.js 공식 미들웨어 패턴 참고"

Q4. 동작 보존 범위? (무엇이 그대로 작동해야 하는가 — 리팩터의 핵심)
    최대한 구체적으로. 단순 "지금과 같음" 금지.
    예: "1) 기존 API 응답 스키마 동일, 2) 인증 실패 시 401+동일 에러 형식,
         3) 세션 만료 재발급 흐름 유지, 4) 기존 감사로그 유지"
```

Q4가 모호하면 **반드시** 구체화하도록 되묻는다. 동작 보존 범위가 불명확하면 리팩터의 성공을 판단할 수 없다.

### Phase B — 코드베이스 분석

**반드시 Plan Mode로 진입**해 read-only 탐색을 수행하라. 작업 중 코드를 실수로 변경하지 않도록.

모드마다 분석 초점과 깊이가 다르다.

#### Patch 모드

Explore 에이전트 병렬 2-3개 권장:
- Agent 1: Q1의 에러 메시지/증상 키워드로 grep → 관련 코드 후보 추적
- Agent 2: 영향 파일 주변의 기존 테스트 찾기 (TDD 위치 결정용)
- Agent 3 (선택): 관련 기존 ADR/ARCHITECTURE 섹션 확인

분석 결과 출력 형식:

```
━━━ 코드베이스 분석 결과 ━━━

1) 에러 발생 지점 (추정)
   📍 <파일 경로>:<라인 번호 또는 범위>

   관련 코드 스니펫:
   <함수명>() {
     <관련 라인들>
   }

   원인 가설: <1-2문장>

2) 실패 테스트 추가 위치 (TDD step 0용)
   📁 <기존 테스트 디렉토리 또는 새 파일 경로>
   기존 테스트 패턴 참고: <파일 경로>

3) 수정 대상 (step 1용)
   ✏ <파일 경로 1개>
   수정 범위: <최소 수정 전략>

4) 수정 금지 (근거 포함)
   🚫 <파일 경로 1>  (이유: <왜 건드리면 안 되는지>)
   🚫 <파일 경로 2>  (이유: ...)

5) 예상 step 구조
   step 0: reproduce — <파일>에 실패 테스트 추가
   step 1: fix — <파일>에 최소 수정

6) 리스크 (있을 경우만)
   ⚠ <리스크 설명>
      Option A: <대안 1>
      Option B: <대안 2>
      어느 쪽으로 가시겠습니까?

이 분석이 맞습니까? 수정할 부분이 있으면 알려주세요.
```

개발자가 확인하거나 수정 요청을 하면 반영. 승인 후에만 Phase C로 진행.

#### Feature 모드

Explore 에이전트 병렬 3개 권장:
- Agent 1: 관련 도메인 타입/모델 및 API 레이어 스캔
- Agent 2: 관련 UI 컴포넌트 및 기존 테스트 패턴 스캔
- Agent 3: `docs/ADR.md` 파싱 → 기존 결정과 충돌 가능성 있는 것 추출

분석 결과 출력 형식:

```
━━━ 코드베이스 분석 결과 (feature 모드) ━━━

1) 영향받는 파일

   수정:
   ✏ <기존 파일 경로 1>
     → <어떤 변경이 필요한지, 1-2줄>
   ✏ <기존 파일 경로 2>
     → ...

   신규:
   ✨ <새 파일 경로 1>
     → <이 파일의 역할>
   ✨ <새 파일 경로 2>

2) 수정 금지 (근거 포함)

   🚫 <파일 경로 1>  (이유: <왜 건드리면 안 되는지 — 회귀 위험/스코프 이탈/비목표 등>)
   🚫 <파일 경로 2>  (이유: ...)

3) 필요한 새 ADR (초안)

   ADR-<다음번호>: <결정 요약>
     결정: <무엇을>
     이유: <왜>
     트레이드오프: <무엇을 포기>

   (ADR이 불필요한 기능이면 이 섹션을 생략하고 "새 ADR 불필요"만 표기)

4) 예상 step 구조

   step 0: types-extension    (<타입 파일 확장>)
   step 1: api-endpoint       (<신규 엔드포인트>)
   step 2: ui                 (<UI 변경/신규 컴포넌트>)
   step 3: regression-tests   (<새 AC 테스트 + 기존 회귀>)

   (케이스에 따라 3 step으로 줄이거나 5 step으로 쪼갤 수 있음)

5) 리스크 (있을 경우만)

   ⚠ <리스크 설명 — 예: 기존 API가 수정 금지인데 신규 기능이 그 API를 건드려야 함>
      Option A: <대안 1 — 수정 허용 쪽으로>
      Option B: <대안 2 — 신규 엔드포인트 분리 쪽으로>
      어느 쪽으로 가시겠습니까?

이 분석이 맞습니까? 수정할 부분이 있으면 알려주세요.
```

개발자가 확인/수정하면 반영. 승인 후 Phase C로 진행.

#### MVP 모드

MVP는 **분석할 기존 코드가 없다**. Phase B의 역할은 "스택 선정 + 초기 아키텍처 제안"이다.

읽어볼 것:
- `CLAUDE.md` — 기존 기술 제약·선호가 있는지 (프레임워크 지정 등)
- (있다면) `docs/UI_GUIDE.md` — 디자인 방향 제약

분석 결과 출력 형식:

```
━━━ 초기 설계 제안 (mvp 모드) ━━━

1) 스택 제안
   - 프레임워크: <추천, 근거>
   - 언어: <추천, 근거 — TypeScript strict 등>
   - DB: <개발/운영 분리 여부 포함>
   - 스타일링: <>
   - 테스트: <단위/E2E 프레임워크>

   (CLAUDE.md에 이미 명시된 스택이 있으면 그대로 사용. 금지되지 않은 한 재검토 금지)

2) 핵심 도메인 모델 (3-5개)
   - <Model 1> { id, ... }
     역할: <...>
   - <Model 2> { ... }
     역할: <...>

3) 예상 디렉토리 구조 (ARCHITECTURE.md 초안)
   ```
   src/
   ├── app/
   ├── components/
   ├── types/
   ├── lib/
   └── ...
   ```

4) 초기 ADR 초안 (3-5개)
   ADR-001: <프레임워크 선택>
     결정 / 이유 / 트레이드오프
   ADR-002: <DB 선택>
     ...
   ADR-003: <...>

5) 예상 step 구조 (표준 7 step)
   step 0: project-setup
   step 1: core-types
   step 2: db-layer
   step 3: api-layer
   step 4: ui-layer
   step 5: auth
   step 6: e2e-tests

   (인증 불필요하면 6 step, DB 불필요하면 5 step으로 조정)

6) 리스크 (있을 경우만)
   ⚠ <예: 선택된 DB가 운영 요구사항에 부족할 수 있음>
     Option A / B / ...

이 제안이 맞습니까?
```

개발자 승인 후 Phase C로.

#### Refactor 모드

**가장 무거운 Phase B**. 호출처 전수 조사와 의존 그래프 분석이 핵심.

Explore 에이전트 병렬 3개 권장:
- Agent 1: 리팩터 대상 식별 + 호출처 전수 grep (모든 import/참조)
- Agent 2: 의존 그래프 (대상이 의존하는 것들, 대상에 의존하는 것들)
- Agent 3: 기존 테스트 커버리지 분석 — 어떤 시나리오가 테스트되어 있고 무엇이 비어있는지

분석 결과 출력 형식:

```
━━━ 코드베이스 분석 결과 (refactor 모드) ━━━

1) 리팩터 대상
   📍 <파일 경로 또는 모듈명>
   현재 구조: <클래스/함수 시그니처>
   목표 구조: <Phase A Q3 요약>

2) 호출처 전수 (N곳)
   • <파일1>:라인 (3곳)
   • <파일2>:라인 (2곳)
   • <파일3>:라인 (5곳)
   ...
   총 N개 참조.

3) 의존 그래프
   <리팩터 대상>
     ├─ 의존하는 것: <A>, <B>, <C>
     └─ 의존받는 것: <위 호출처들>

   외부 의존 중 리팩터 범위 밖인 것: <명시>

4) 동작 보존 테스트 커버리지
   ✓ <시나리오 A>: 기존 테스트 있음 (경로)
   ✗ <시나리오 B>: 테스트 없음 → step1에서 추가 필요
   ✗ <시나리오 C>: 테스트 없음 → 추가 필요

5) 마이그레이션 순서 (의존성 기반 배치)
   Batch 1: <가장 단순한 호출처 N곳>
   Batch 2: <중간 복잡도 N곳>
   Batch 3: <가장 의존 많은 곳 N곳>

   각 배치를 별도 커밋으로 → `git revert`로 롤백 가능.

6) 예상 step 구조
   step 0: propose-new-structure    (새 시그니처 문서화, 구현 X)
   step 1: add-regression-tests     (4)의 비어있는 테스트 추가 — 리팩터 전 안전망)
   step 2: migrate-batch-1
   step 3: migrate-batch-2
   step 4: migrate-batch-3           (선택, 배치가 많을 때)
   step 5: cleanup-old-code          (구 구조 제거)
   step 6: update-adr                (ADR 기록)

7) 리스크
   ⚠ <리스크 설명>
     Option A: <전체를 한 phase로>
     Option B: <"테스트 확충"을 별도 phase로 분리한 뒤 리팩터>

이 분석이 맞습니까? Batch 분할이나 step 수 조정이 필요하면 알려주세요.
```

### Phase C — 문서 갱신 및 phase 폴더 생성

Phase A + B의 확정된 내용을 바탕으로 파일을 갱신/생성하라.

#### C-1. `docs/PRD.md` 교체

현재 `docs/PRD.md`를 통째로 새 PRD로 **덮어쓴다**. 이전 내용은 `phases/{N}-{name}/PRD.md`에 스냅샷된다 (C-3 참조).

**Patch 모드 PRD 포맷**:
```markdown
# PRD: <프로젝트명> — Bug Fix: <간단 요약>

## 문제
<Phase A Q1의 재현 조건>

## 기대 동작
<Phase A Q2>

## Acceptance Criteria

1. 재현 테스트가 통과한다
   ```bash
   <프로젝트의 테스트 커맨드>
   ```
2. 기존 테스트가 모두 통과한다 (회귀 없음)

## 영향 범위
<Phase B 3) 수정 대상 파일 요약>

## 비목표 (이번 phase에서 하지 않는 것)
- 무관한 리팩터
- <Phase B의 수정 금지 영역>
```

**Feature 모드 PRD 포맷**:
```markdown
# PRD: <프로젝트명> — <기능명>

## 목표
<Phase A Q1의 문제를 해결하는 구체적 기능 설명 (1-2 문장)>

## 사용자 시나리오
<Phase A Q2의 구체 시나리오. 필요하면 여러 단계로 서술>

## 핵심 기능
1. <기능 항목 1>
2. <기능 항목 2>
3. <기능 항목 3>

## Acceptance Criteria

AC-1: <조건 1>
  검증:
  ```bash
  <실행 가능한 테스트 커맨드 또는 수동 체크 설명>
  ```

AC-2: <조건 2>
  검증: <...>

AC-3: <...>

## 비목표 (이번 phase에서 하지 않는 것 — 최소 3개)
- <비목표 1 — 명시적으로 다음 phase 후보로 남김>
- <비목표 2>
- <비목표 3>

## 영향 범위
- 수정 파일: <Phase B 1)의 수정 목록>
- 신규 파일: <Phase B 1)의 신규 목록>
- 수정 금지: <Phase B 2)의 금지 목록 요약>
- 새 ADR: <Phase B 3)의 ADR 번호와 요약>
```

**MVP 모드 PRD 포맷**:
```markdown
# PRD: <프로젝트명>

## 목표
<Phase A Q1 — 제품이 해결하는 문제와 대상 사용자>

## 사용자
<Phase A Q2 — 구체 페르소나와 사용 맥락>

## 핵심 기능
1. <필수 기능 1>
2. <필수 기능 2>
3. <필수 기능 3>
4. <필수 기능 4 (있으면)>

## 출시 가능 기준 (Acceptance Criteria)

AC-1: <핵심 플로우가 끊김 없이 동작>
  검증:
  ```bash
  <E2E 테스트 커맨드 또는 수동 시나리오>
  ```

AC-2: <데이터 지속성 — 재시작 후 데이터 유지>
AC-3: <...>

## MVP 제외 사항 (명시적으로 안 만드는 것)
- <제외 1 — 폭발 방지 핵심>
- <제외 2>
- <제외 3>

## 디자인 방향
<색상 톤, 스타일, 참고 레퍼런스 — UI_GUIDE.md가 별도로 있으면 거기로 링크>

## 기술 스택 요약
<Phase B 1)에서 확정된 스택>
```

**Refactor 모드 PRD 포맷**:
```markdown
# PRD: <프로젝트명> — Refactor: <영역>

## 리팩터 이유
<Phase A Q1 — 기술 부채/유지보수성/성능 중 무엇이 핵심인지>

## 현재 구조의 문제
<Phase A Q2 — 측정 가능하게 서술>

## 목표 구조
**Before**:
<현재 구조 요약 (코드 스니펫 or 다이어그램)>

**After**:
<목표 구조 요약>

## 동작 보존 범위 (핵심)
리팩터 전후로 다음이 **그대로 작동**해야 한다:
1. <Phase A Q4 항목 1>
2. <항목 2>
3. <항목 3>
4. <항목 4>

## Acceptance Criteria

AC-1: 기존 테스트 전체 통과 (회귀 없음)
  검증:
  ```bash
  <전체 테스트 커맨드>
  ```

AC-2: 동작 변경 없음 — 새 기능/API 추가 없음
  검증: PR diff에 새 엔드포인트/기능 추가가 없어야 함

AC-3: 마이그레이션 배치가 별도 커밋으로 분리됨 (롤백 가능성)
  검증: `git log`에서 각 batch 커밋이 독립적으로 revert 가능

## 비목표
- 새 기능 추가 (별도 phase에서)
- 무관한 구역의 정리 (스코프 이탈 금지)
- 성능 최적화 (본 목적 아님 — 명시적 성능 목표라면 Q1에 적혀있어야 함)

## 영향 범위
- 리팩터 대상: <Phase B 1)>
- 호출처 수: <Phase B 2) 총 N곳>
- 마이그레이션 배치: <Phase B 5) N개 batch>
- 새 ADR: <ADR-번호 — 이 리팩터 결정 기록>
```

#### C-2. `docs/ADR.md` 증분 또는 초기 생성

모드별 경향:
- **Patch**: 대개 ADR 불필요. 버그 원인이 **설계 결정 변경**을 요구할 때만 append.
- **Feature**: Phase B 3)에서 식별한 새 ADR을 append. "결정 / 이유 / 트레이드오프" 3요소 필수.
- **MVP**: `docs/ADR.md`가 없으면 **신규 생성**. Phase B 4)의 초기 ADR 3-5개를 기록. 스택 선택 근거를 모두 담는다.
- **Refactor**: 이 리팩터의 결정을 append. 번복된 결정이 있으면 "supersedes ADR-XXX" 명시.

불필요하면 건드리지 않는다. 필요 없는 ADR을 억지로 만들지 말 것.

#### C-2b. `docs/ARCHITECTURE.md` — MVP 특수 처리

MVP 모드는 `docs/ARCHITECTURE.md`가 없거나 템플릿 상태일 수 있다. Phase B 3)의 디렉토리 구조 제안과 패턴을 바탕으로 **신규 작성**하라.

다른 모드는 기존 ARCHITECTURE.md를 증분 수정만 (변경 없으면 건드리지 않음).

#### C-3. `phases/{N}-{name}/` 디렉토리 생성

`N`은 기존 phases의 다음 번호. `{name}`은 kebab-case 짧은 요약 (예: `2-login-timeout-fix`).

생성할 파일:

**`phases/{N}-{name}/PRD.md`** — `docs/PRD.md`의 **스냅샷** (복사본). 이 파일은 phase가 끝난 뒤에도 영구 보존되어 과거 의도를 남긴다.

**`phases/{N}-{name}/INTAKE.md`** — Phase A + B의 원본 기록. 섹션 수와 내용은 mode에 따라 다르다.

**Patch 모드 INTAKE 포맷**:
```markdown
# INTAKE: {N}-{name}

Generated at: <ISO timestamp>
Mode: patch

## Phase A — 의도 면담

### Q1: 재현 조건
<답변 원본>

### Q2: 기대 동작
<답변 원본>

### Q3: 영향 범위 추정
<답변 원본>

## Phase B — 코드베이스 분석 결과

### 에러 발생 지점
<파일:라인, 원인 가설>

### 실패 테스트 추가 위치
<경로>

### 수정 대상
<경로>

### 수정 금지
- <경로 1> (이유: ...)
- <경로 2> (이유: ...)

### 예상 step 구조
step 0: reproduce
step 1: fix

### 선택된 옵션 (리스크가 있었다면)
<Option A / B / ...>
```

**Feature 모드 INTAKE 포맷**:
```markdown
# INTAKE: {N}-{name}

Generated at: <ISO timestamp>
Mode: feature

## Phase A — 의도 면담

### Q1: 해결할 문제
<답변 원본>

### Q2: 사용자 시나리오
<답변 원본>

### Q3: 성공 기준 (AC 확정본)
AC-1: <조건>
AC-2: <조건>
...

### Q4: 비목표
- <...>
- <...>

## Phase B — 코드베이스 분석 결과

### 영향 파일 (수정)
- <경로 1> — <왜 수정>
- <경로 2> — <...>

### 영향 파일 (신규)
- <경로 1> — <역할>
- <경로 2> — <...>

### 수정 금지
- <경로 1> (이유: ...)
- <경로 2> (이유: ...)

### 새 ADR (있을 경우)
- ADR-<번호>: <요약>

### 예상 step 구조
step 0: types-extension
step 1: api-endpoint
step 2: ui
step 3: regression-tests

### 선택된 옵션 (리스크가 있었다면)
<Option A / B / C 중 선택>
```

**MVP 모드 INTAKE 포맷**:
```markdown
# INTAKE: {N}-{name}

Generated at: <ISO timestamp>
Mode: mvp

## Phase A — 의도 면담

### Q1: 제품 핵심 목적
<답변 원본>

### Q2: 주요 사용자와 사용 맥락
<답변 원본>

### Q3: 출시 가능 기준 (AC 확정본)
AC-1: <조건>
AC-2: <조건>
...

### Q4: MVP 제외 사항
- <...>
- <...>
- <...>

## Phase B — 초기 설계 제안

### 스택
- 프레임워크: <>
- 언어: <>
- DB: <>
- 스타일링: <>
- 테스트: <>

### 핵심 도메인 모델
- <Model 1>: { fields }
- <Model 2>: { fields }

### 예상 디렉토리 구조
<트리>

### 초기 ADR
- ADR-001: <결정>
- ADR-002: <결정>
- ADR-003: <결정>

### 예상 step 구조 (7 step 표준)
step 0: project-setup
step 1: core-types
step 2: db-layer
step 3: api-layer
step 4: ui-layer
step 5: auth
step 6: e2e-tests

### 선택된 옵션 (리스크가 있었다면)
<...>
```

**Refactor 모드 INTAKE 포맷**:
```markdown
# INTAKE: {N}-{name}

Generated at: <ISO timestamp>
Mode: refactor

## Phase A — 의도 면담

### Q1: 리팩터 이유
<답변 원본>

### Q2: 현재 구조의 문제
<답변 원본>

### Q3: 목표 구조
Before: <현재>
After: <목표>

### Q4: 동작 보존 범위
1. <...>
2. <...>
3. <...>

## Phase B — 코드베이스 분석 결과

### 리팩터 대상
<파일 경로 또는 모듈명>
현재 시그니처: <...>
목표 시그니처: <...>

### 호출처 전수 (총 N곳)
- <파일1>:라인 (N곳)
- <파일2>:라인 (N곳)
...

### 의존 그래프
- 의존하는 것: <A>, <B>
- 의존받는 것: <위 호출처>

### 테스트 커버리지
- ✓ <시나리오 A>: <경로>
- ✗ <시나리오 B>: 없음 → step1에서 추가
- ✗ <시나리오 C>: 없음 → step1에서 추가

### 마이그레이션 배치
Batch 1: <호출처 목록>
Batch 2: <호출처 목록>
Batch 3: <호출처 목록>

### 예상 step 구조
step 0: propose-new-structure
step 1: add-regression-tests
step 2: migrate-batch-1
step 3: migrate-batch-2
step 4: migrate-batch-3 (있을 경우)
step 5: cleanup-old-code
step 6: update-adr

### 선택된 옵션 (리스크가 있었다면)
<...>
```

#### C-4. `docs/ARCHITECTURE.md` 증분

Patch는 대개 구조를 바꾸지 않으니 건드리지 않는다. **예외**: 수정이 공개 API/인터페이스를 바꿀 때만 해당 섹션 증분 수정.

### 6. Stage-end 자동 커밋

파일 생성이 끝나면 `git`으로 Stage 1의 변경을 단일 커밋으로 남긴다.

```bash
git add -A
git commit -m "chore({phase}): stage 1 discovery outputs"
```

이미 있는 pre-commit 훅이 있다면 따른다. 변경사항이 없으면 커밋을 건너뛴다 (예: iterate 모드에서 실제 변경이 없었을 때).

커밋 후 `git diff HEAD~1`로 전체 Stage 변경을 한 번에 볼 수 있다.

### 7. 검토 안내 출력

커밋 후:

```
✓ Stage 1 (Discovery) 완료. 커밋됨: chore({phase}): stage 1 discovery outputs

Mode: {mode}
Phase: {N}-{name}

생성/갱신된 파일:
  📄 docs/PRD.md                          (교체됨)
  📄 docs/ADR.md                          (변경 없음 / append: <내용>)
  📄 docs/ARCHITECTURE.md                 (mvp면 신규, 아니면 증분)
  📄 phases/{N}-{name}/PRD.md             (스냅샷)
  📄 phases/{N}-{name}/INTAKE.md          (면담 + 분석 기록)

변경 요약:
  - <한 줄 요약>
  - 예상 step 수: <N>

검토 후:
  ▸ 작은 수정:       파일 직접 편집
  ▸ 의도/분석 수정:  /harness-plan {mode} (iterate 모드)
  ▸ 완전 재시작:     /harness-plan {mode} --reset
  ▸ 다음 단계:      /harness {mode}
```

---

## Iterate Mode

기존 phase 중 진행 중인 것이 있을 때 이 명령이 재실행되면 이 모드로 진입한다.

### 출력 형식

```
━━━ Iterate Mode (Stage 1) ━━━
Phase: phases/{N}-{name}/
Mode: {mode}

현재 상태:
  📄 docs/PRD.md                      (현재 phase의 의도)
  📄 phases/{N}-{name}/PRD.md         (스냅샷)
  📄 phases/{N}-{name}/INTAKE.md      (면담 기록)

어떤 부분을 수정할까요? (자연어로 지시)
  예: "AC-3을 더 엄격하게"
  예: "Phase B의 수정 금지 목록에 lib/db.ts 추가"
  예: "재현 조건이 더 있다: <추가 내용>"
```

### 수정 처리

1. **영향 분석**:
   - 어떤 파일의 어떤 섹션이 바뀌는지 식별
   - 관련 파일 간 정합성 (PRD ↔ INTAKE) 체크
2. **설계 원칙 위반 체크**:
   - 모드 원칙 위배? (예: patch 모드에서 대형 리팩터 요청)
   - `docs/PRD.md`의 비목표와 충돌?
   - `docs/ADR.md`의 기존 결정과 충돌?
3. **파급 효과 경고**:
   - 이미 생성된 step 파일도 재생성 필요한가?
   - 새 ADR 필요?
4. **위반/충돌 발견 시**: Option A/B/C 대안 제시, 사용자 판단 요청. 단순 순종 금지.
5. **동의 후 델타 수정**: 전체 재생성 X. 변경된 파일만.
6. 변경 파일 목록 안내로 마무리.

---

## 금지사항 (이 명령의 규약)

- 이 명령은 **Stage 1 (Discovery) 전용**. step 파일 생성은 `/harness {mode}`의 몫.
- Phase B에서 **코드를 수정하지 마라**. Plan Mode 유지 필수.
- 개발자가 답하기 어려운 질문("어느 파일이 영향받나")을 Phase A에서 묻지 마라. 그건 Phase B에서 Claude가 분석할 일.
- Phase B 결과가 불확실하면 추측하지 말고 "분석 실패, 개발자 확인 필요" 명시.
- `docs/ARCHITECTURE.md`를 무분별하게 바꾸지 마라. 실제 구조 변경이 있을 때만.
