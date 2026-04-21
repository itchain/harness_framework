이 프로젝트는 Harness 프레임워크를 사용한다. 이 명령은 **Stage 2 (Planning)**을 담당한다.

Discovery(docs 갱신)는 `/harness-plan {mode}`가 먼저 수행했어야 한다. Execution은 `python3 scripts/execute.py {task}`가 수행한다.

---

## Usage

```
/harness {mode}
```

`{mode}` ∈ `{mvp, feature, refactor, patch}`

인자가 없으면 사용자에게 모드를 되묻는다.

---

## 실행 흐름

아래 순서로 수행하라.

### 1. 상태 판단

`phases/` 디렉토리를 스캔한다.

- **진행 중인 phase 존재** (status가 `pending` 또는 어떤 step이 `pending`인 phase) → **iterate 모드**로 진입 (아래 "Iterate Mode" 섹션 참조).
- **모든 phase 완료 또는 phases/ 없음** → **신규 생성 모드**로 진행 (다음 단계).

### 2. Validation Gate (신규 생성 모드 전용)

`docs/PRD.md`의 품질을 검증한다. 하나라도 실패 시 즉시 중단하고 `/harness-plan {mode}` 재실행을 안내.

검증 항목:

1. `docs/PRD.md`가 존재하는가?
2. 파일 내에 `{...}` 형태의 플레이스홀더가 남아있지 않은가? (템플릿 미채움)
3. 핵심 섹션이 비어있지 않은가?
   - 목표 / 사용자 / 핵심 기능 / 비목표 (또는 MVP 제외 사항)
4. AC(Acceptance Criteria)가 실행 가능한 커맨드 형태인가? (예: `npm test`, `pytest` 등)

실패 출력 형식:
```
━━━ Validation Gate FAIL ━━━
docs/PRD.md가 불완전합니다:
  ✗ <실패 항목 1>
  ✗ <실패 항목 2>

먼저 `/harness-plan {mode}` 을 실행해 docs를 완성하세요.
```

통과 시:
```
✓ Validation Gate PASS
```

### 3. Phase 번호 결정

`phases/` 디렉토리를 스캔해 기존 최대 번호를 찾고, 그 다음 번호(N)를 새 phase에 부여한다. 예: 기존이 `0-mvp`, `1-sharing` 이면 새 phase는 `2-{name}`.

Phase 이름(`{name}`)은 `docs/PRD.md`의 내용에서 kebab-case로 추출하거나 사용자에게 확인한다.

### 4. Mode별 Step 분해

아래 **"Mode별 Step 템플릿"** 섹션을 참고해 해당 mode의 step 구조로 `phases/{N}-{name}/` 디렉토리와 파일들을 생성한다.

### 5. 파일 생성

#### 5-1. `phases/{N}-{name}/index.json`
```json
{
  "project": "<CLAUDE.md에서 참조>",
  "phase": "{N}-{name}",
  "mode": "{mode}",
  "steps": [
    { "step": 0, "name": "<step-0-name>", "status": "pending" },
    { "step": 1, "name": "<step-1-name>", "status": "pending" }
  ]
}
```

#### 5-2. `phases/{N}-{name}/step{i}.md`

Mode별 템플릿(아래 섹션)에 맞춰 각 step 파일 생성.

#### 5-3. `phases/index.json` (top-level) 갱신

기존 `phases` 배열에 추가:
```json
{ "dir": "{N}-{name}", "mode": "{mode}", "status": "pending" }
```

### 6. Stage-end 자동 커밋

파일 생성이 끝나면 `git`으로 Stage 2의 변경을 단일 커밋으로 남긴다.

```bash
git add -A
git commit -m "chore({phase}): stage 2 planning outputs"
```

변경사항이 없으면 커밋을 건너뛴다 (iterate 모드에서 실제 변경이 없었을 경우).

### 7. 검토 안내

커밋 후:

```
✓ Stage 2 (Planning) 완료. 커밋됨: chore({phase}): stage 2 planning outputs

Mode: {mode}
Phase: {N}-{name}

검토할 파일:
  📄 phases/{N}-{name}/index.json
  📄 phases/{N}-{name}/step0.md  ← <step-0-name>
  📄 phases/{N}-{name}/step1.md  ← <step-1-name>
  ...

변경 요약:
  - Step 수: <N>
  - 예상 retry: <mode에 따른 retry 횟수>

검토 후:
  ▸ step 내용 수정:   해당 step{i}.md 직접 편집
  ▸ 구조 수정:       /harness {mode} 재실행 (iterate 모드)
  ▸ PRD부터 수정:    /harness-plan {mode}
  ▸ 실행:           python3 scripts/execute.py {N}-{name}
```

---

## Mode별 Step 템플릿

### Patch 모드 (2 step, TDD)

#### step0: reproduce

```markdown
# Step 0: reproduce

## 읽어야 할 파일

버그 발생 파일과 관련 테스트를 먼저 읽어 맥락을 파악하라:

- `docs/PRD.md` (버그 정의)
- `phases/{N}-{name}/INTAKE.md` (Phase B 분석 결과)
- <Phase B에서 식별된 버그 발생 파일 경로들>
- <관련 기존 테스트 파일 경로들>

## 작업

버그를 재현하는 **실패하는** 테스트를 추가하라.

- 테스트 위치: <Phase B에서 제안한 테스트 파일 경로>
- 테스트 케이스: <Phase A Q1 재현 조건을 테스트로 변환>
- 기대 동작: 테스트를 실행하면 **실패**해야 한다 (아직 버그가 있으므로)

프로덕션 코드는 수정하지 마라. 그건 step1에서 한다.

## Acceptance Criteria

```bash
<프로젝트의 테스트 커맨드, 예: npm test -- <new-test-file>>
```

위 커맨드 실행 시 새로 추가한 테스트가 **실패**하는 것이 AC 통과이다.

## 금지사항

- 프로덕션 코드를 수정하지 마라. 이유: step1의 역할이다. 이번 step은 재현만.
- 기존 테스트를 수정하지 마라. 이유: 회귀 위험.
- 테스트 외 파일을 만들거나 수정하지 마라.
```

#### step1: fix

```markdown
# Step 1: fix

## 읽어야 할 파일

- `docs/PRD.md` (기대 동작)
- `phases/{N}-{name}/INTAKE.md` (Phase B 분석 — 특히 "수정 금지" 목록)
- `phases/{N}-{name}/step0.md` (추가된 테스트)
- <Phase B에서 식별된 버그 발생 파일>

step0에서 추가된 실패 테스트를 먼저 확인하라.

## 작업

**최소 수정**으로 step0 테스트를 통과시켜라.

- 수정 대상: <Phase B가 식별한 파일 경로 1개>
- 수정 범위: 버그를 고치는 데 꼭 필요한 변경만

## Acceptance Criteria

```bash
<프로젝트 전체 테스트 커맨드, 예: npm test>
```

위 커맨드 실행 시 **모든 테스트가 통과**해야 한다:
- step0에서 추가된 테스트 → 이제 통과
- 기존 모든 테스트 → 그대로 통과 (회귀 없음)

## 금지사항 (엄격)

- Phase B의 "수정 금지" 목록에 있는 파일을 건드리지 마라. 이유: <각 파일별 근거>
- 무관한 리팩터 금지 ("보기 싫어서", "겸사겸사" 등). 이유: patch는 최소 변경 원칙.
- 기존 테스트 수정 금지. 이유: 회귀 테스트는 그대로 지켜야 한다.
- 새 의존성 추가 금지. 이유: 버그 픽스는 기존 자산으로 해결 가능해야 한다.
```

### Feature 모드 (3~5 step, 수평 절단)

Feature는 레이어별로 얇게 잘라 새 기능을 붙인다. 표준 구조는 4 step이지만, 케이스에 따라 3(타입 변경 없음) 또는 5(DB 스키마 변경 포함)로 조정할 수 있다.

표준 step 구조:

- step 0: `types-extension` — 도메인 타입/모델 확장
- step 1: `api-endpoint` — API 레이어 (신규 또는 기존 수정)
- step 2: `ui` — UI 레이어 (신규 컴포넌트 + 기존 UI 수정)
- step 3: `regression-tests` — 새 AC 테스트 + 기존 회귀 검증

#### step0: types-extension

```markdown
# Step 0: types-extension

## 읽어야 할 파일

- `docs/PRD.md` (AC 확인)
- `phases/{N}-{name}/INTAKE.md` (Phase B 분석: 영향 파일·금지 파일)
- `docs/ADR.md` (관련 ADR, 특히 새로 추가된 ADR-<번호>)
- <Phase B 1)의 수정할 타입 파일 경로> (기존 스키마/네이밍 규칙 파악)

## 작업

<타입 파일 경로>에 필요한 필드/인터페이스를 추가한다.

- 기존 필드는 그대로 유지
- 새 필드의 네이밍은 기존 스타일을 따른다 (camelCase/snake_case 일관성)
- 호출처의 컴파일 에러는 허용 (step1-3에서 해결)

## Acceptance Criteria

```bash
<타입 체크 커맨드, 예: tsc --noEmit 또는 mypy>
```

- 위 커맨드 실행 시 대상 타입 파일은 에러 없음
- git diff가 해당 타입 파일 한 개로 국한 (다른 파일 수정 X)

## 수정 금지

- <Phase B 2)의 수정 금지 파일 1> (이유: <근거>)
- <Phase B 2)의 수정 금지 파일 2> (이유: ...)
- step1-3에서 다룰 파일 전부 (이유: 이번 step의 범위는 타입 한정)
```

#### step1: api-endpoint

```markdown
# Step 1: api-endpoint

## 읽어야 할 파일

- `docs/PRD.md` (AC)
- `phases/{N}-{name}/INTAKE.md` (Phase B 분석)
- step0에서 수정된 <타입 파일> — 최신 스키마 확인
- <기존 유사 API 라우트 경로> — 인증/에러처리/응답 형식 패턴 참고
- `docs/ARCHITECTURE.md` (API 레이어 규칙)

## 작업

<신규 또는 수정 대상 API 엔드포인트 경로>를 구현한다.

- **기존 라우트의 패턴을 그대로 따른다**: 인증 미들웨어, 에러 응답 형식, 로깅 방식
- 비즈니스 로직은 해당 레이어에만. UI는 step2, 테스트는 step3.
- 입력 검증은 경계에서 (타입 체크 + 명시적 유효성 검사)

## Acceptance Criteria

```bash
<API 통합 테스트 커맨드>
```

- 신규 엔드포인트의 기본 동작(정상/예외 경로)이 통과
- 기존 엔드포인트 테스트 모두 통과 (회귀 없음)

## 수정 금지

- <Phase B 2)의 수정 금지 파일 전체>
- UI 파일 (step2 범위)
- 테스트 파일 (step3 범위 — 단, 이 step의 AC를 위한 최소 스모크 테스트 추가는 허용)
```

#### step2: ui

```markdown
# Step 2: ui

## 읽어야 할 파일

- `docs/PRD.md` (사용자 시나리오, AC)
- `phases/{N}-{name}/INTAKE.md`
- `docs/UI_GUIDE.md` — 디자인 원칙·색상·컴포넌트 규격
- step0에서 수정된 타입 파일 (화면 데이터 형태)
- step1에서 추가/수정된 API 엔드포인트 (클라이언트 호출 경로)
- <기존 유사 컴포넌트 경로> — UI 패턴 참고

## 작업

<신규 컴포넌트 경로> 작성 및 <기존 UI 파일 경로> 수정.

- UI_GUIDE.md의 규칙 엄수 (AI 슬롭 안티패턴 금지 항목 포함)
- 상태 관리는 해당 프로젝트의 방식 따르기 (Server Components vs useState 등)
- 로딩/에러 상태 처리

## Acceptance Criteria

```bash
<빌드 커맨드, 예: npm run build>
```

- 빌드 에러 없음
- UI 컴포넌트 렌더링 스모크 테스트 통과 (있는 경우)
- 수동 확인: <PRD의 핵심 화면/인터랙션이 정상 동작>

## 수정 금지

- API 로직 변경 (step1에서 완료)
- 타입 변경 (step0에서 완료)
- <Phase B 2)의 수정 금지 파일 전체>
```

#### step3: regression-tests

```markdown
# Step 3: regression-tests

## 읽어야 할 파일

- `docs/PRD.md` — **AC 1~N을 테스트로 변환하는 것이 이 step의 전부**
- `phases/{N}-{name}/INTAKE.md`
- step0-2에서 변경된 모든 파일
- <기존 테스트 디렉토리> — 테스트 패턴 참고

## 작업

PRD의 각 AC에 대응하는 자동 테스트를 추가한다.

- AC-1 → <테스트 파일 경로>:<테스트 이름>
- AC-2 → ...
- AC-N → ...

또한 기존 테스트 전체가 통과하는지 확인한다.

## Acceptance Criteria

```bash
<프로젝트 전체 테스트 커맨드, 예: npm test>
```

- **모든 신규 AC 테스트 통과**
- **기존 모든 테스트 통과** (회귀 없음)

## 수정 금지

- 프로덕션 코드 수정 금지. 테스트 실패 시 step1/2로 돌아가 수정해야 함 (이 step은 테스트 전담)
- 기존 테스트 수정 금지. 회귀 보호 장치를 건드리면 안 됨.
- Phase B의 수정 금지 파일 전체
```

---

**step 수 조정**:
- 타입 변경이 불필요한 기능 (예: 기존 엔드포인트에 쿼리 파라미터 추가) → 3 step (step0 생략)
- DB 스키마 변경이 필요한 기능 → 5 step (step0 앞에 `db-migration` 추가, 별도 ADR 권장)
- Phase B가 제안한 step 수를 존중하되, 원칙(하나의 step은 하나의 레이어)을 깨지 말 것

### MVP 모드 (표준 7 step, 수직 레이어)

처음부터 빌드. 각 step이 다음 step의 토대가 되는 **수직 빌드업** 구조.

표준 step 순서 (프로젝트 성격에 따라 조정 가능):

- step 0: `project-setup` — 툴체인, 린트, 테스트, 초기 폴더
- step 1: `core-types` — 도메인 타입·인터페이스 정의
- step 2: `db-layer` — 스키마, DB 헬퍼, 초기 마이그레이션
- step 3: `api-layer` — CRUD 엔드포인트
- step 4: `ui-layer` — 핵심 화면 컴포넌트
- step 5: `auth` — 인증 플로우 (불필요 시 생략)
- step 6: `e2e-tests` — 핵심 시나리오 통합 테스트

#### step0: project-setup

```markdown
# Step 0: project-setup

## 읽어야 할 파일
- `docs/PRD.md` (전체 맥락)
- `docs/ARCHITECTURE.md` (디렉토리 구조)
- `docs/ADR.md` (스택 선택 근거)
- `docs/UI_GUIDE.md` (있을 경우)
- `phases/{N}-{name}/INTAKE.md`

## 작업
Phase B에서 정한 스택으로 프로젝트 기본 뼈대 구축.

- <프레임워크> 초기화
- 언어/컴파일러 세팅 (TypeScript strict 등)
- 린트·포매터 설정
- 테스트 프레임워크 설치 및 smoke 테스트 하나
- Git `.gitignore`
- `package.json` 스크립트: `dev`, `build`, `lint`, `test`

## Acceptance Criteria
```bash
npm run lint && npm run build && npm test
```
위 세 커맨드가 에러 없이 통과.

## 수정 금지
- docs/* (가드레일이다. 이 step은 코드 초기화 전담)
```

#### step1: core-types

```markdown
# Step 1: core-types

## 읽어야 할 파일
- `docs/PRD.md` (핵심 기능에서 도메인 추출)
- `docs/ARCHITECTURE.md` (types/ 폴더 위치)
- `phases/{N}-{name}/INTAKE.md` (Phase B 도메인 모델 제안)

## 작업
Phase B에서 식별한 도메인 모델을 타입으로 정의.

- `src/types/` (또는 ARCHITECTURE.md가 지정한 경로)에 Model 파일 생성
- 필드 이름·타입 명시
- 관계가 있으면 ID 참조로 표현 (JOIN은 DB 레이어에서)

## Acceptance Criteria
```bash
npm run build
```
타입 에러 없음. 새 타입이 export됨.

## 수정 금지
- src/app/, src/components/ 등 (타입만 다루는 step)
```

#### step2: db-layer

```markdown
# Step 2: db-layer

## 읽어야 할 파일
- `docs/ADR.md` (DB 선택 근거)
- `docs/ARCHITECTURE.md`
- `phases/{N}-{name}/INTAKE.md`
- step1의 types 파일들

## 작업
- `src/lib/db.ts` (또는 규약된 경로)에 DB 헬퍼
- 도메인 모델과 1:1로 대응되는 스키마 정의
- 초기 마이그레이션/seed 스크립트

## Acceptance Criteria
```bash
npm run build
<DB 초기화 커맨드>
```
DB 초기화 성공 + 기본 CRUD 스모크 테스트 통과.

## 수정 금지
- step1의 types 파일 (스키마가 타입에 맞춰 따라가야 함, 타입 변경 금지)
- UI·API 파일 (다음 step)
```

#### step3: api-layer

```markdown
# Step 3: api-layer

## 읽어야 할 파일
- `docs/PRD.md` (AC에서 어떤 endpoint 필요한지)
- `docs/ARCHITECTURE.md` (API 레이어 규칙)
- step1 types, step2 db-layer

## 작업
PRD의 핵심 기능 각각에 대응하는 CRUD 엔드포인트 작성.

- 입력 검증 (타입 + 런타임)
- 에러 응답 일관성
- 구조화된 로깅

## Acceptance Criteria
```bash
npm run build && npm test
```
각 엔드포인트의 기본 동작 테스트 통과.

## 수정 금지
- UI 파일 (step4)
- step1 types 변경 (타입은 고정, API가 맞춰야 함)
```

#### step4: ui-layer

```markdown
# Step 4: ui-layer

## 읽어야 할 파일
- `docs/PRD.md` (사용자 시나리오)
- `docs/UI_GUIDE.md` (있으면 엄수)
- `docs/ARCHITECTURE.md`
- step1 types, step3 API

## 작업
PRD의 핵심 화면/인터랙션 구현.

- UI_GUIDE.md 규칙 엄수 (색상, 컴포넌트 규격, 애니메이션 금지 항목 등)
- 로딩·에러 상태 처리
- 반응형 기본

## Acceptance Criteria
```bash
npm run build
```
빌드 통과. 수동 확인: 핵심 시나리오가 화면에서 동작.

## 수정 금지
- API 로직 (step3에서 완료)
- types 변경 (step1 고정)
```

#### step5: auth (선택)

```markdown
# Step 5: auth

## 읽어야 할 파일
- `docs/PRD.md` (인증이 비목표인지 확인)
- `docs/ADR.md` (인증 방식 결정)
- `docs/ARCHITECTURE.md`
- step3 API, step4 UI

## 작업
인증 플로우 구현 — 회원가입/로그인/세션/로그아웃.

- 미들웨어로 보호 경로 분리
- 세션/토큰 저장 방식 (ADR 따르기)
- 비밀번호 해싱 (직접 구현 금지, 검증된 라이브러리)

## Acceptance Criteria
```bash
npm run build && npm test
```
인증 플로우 통합 테스트 통과.

## 수정 금지
- DB 스키마 전면 재설계 (step2 기반 위에 user 테이블만 추가)
```

#### step6: e2e-tests

```markdown
# Step 6: e2e-tests

## 읽어야 할 파일
- `docs/PRD.md` — **AC 전체를 E2E 테스트로 변환**
- 이전 step들의 모든 주요 파일

## 작업
PRD의 각 AC에 대응하는 E2E 테스트 작성.

## Acceptance Criteria
```bash
npm test
```
모든 AC 테스트 + 기존 단위/통합 테스트 전체 통과.

## 수정 금지
- 프로덕션 코드 (이 step은 테스트 전담. 실패 시 이전 step으로 돌아가 수정)
```

### Refactor 모드 (6-7 step, 배치 이관)

동작 보존이 최우선. 테스트 안전망을 먼저 깐 뒤 배치별로 옮긴다.

표준 step 순서:

- step 0: `propose-new-structure` — 새 시그니처 문서화 (구현 X)
- step 1: `add-regression-tests` — 테스트 커버리지 확충 (리팩터 전 안전망)
- step 2-4: `migrate-batch-N` — 배치별 호출처 이관 (배치 수는 Phase B에서 결정)
- step 5: `cleanup-old-code` — 구 구조 제거
- step 6: `update-adr` — 결정 기록

#### step0: propose-new-structure

```markdown
# Step 0: propose-new-structure

## 읽어야 할 파일
- `docs/PRD.md` (목표 구조 + 동작 보존 범위)
- `phases/{N}-{name}/INTAKE.md` (리팩터 대상, 호출처, 의존 그래프)
- <리팩터 대상 파일>

## 작업
**구현하지 않는다.** 새 구조의 시그니처만 문서화.

- 새 함수/클래스의 인터페이스(파라미터, 반환, 예외)를 `phases/{N}-{name}/PROPOSAL.md`에 작성
- 호출처 마이그레이션 예시 1-2개 (Before/After)
- 이 구조로 Phase A Q4(동작 보존 범위)를 어떻게 지키는지 설명

## Acceptance Criteria
```bash
test -f phases/{N}-{name}/PROPOSAL.md
```
PROPOSAL.md 파일 존재. 시그니처와 보존 논증이 담겨있음.

## 수정 금지
- 프로덕션 코드 변경 금지. 이 step은 문서 전담.
- 기존 구조 제거 금지 (step5에서).
```

#### step1: add-regression-tests

```markdown
# Step 1: add-regression-tests

## 읽어야 할 파일
- `docs/PRD.md` (동작 보존 범위)
- `phases/{N}-{name}/INTAKE.md` (커버리지 공백 목록)
- 기존 테스트 디렉토리 (패턴 참고)

## 작업
Phase B 분석에서 "테스트 없음"으로 표시된 시나리오를 **리팩터 전에** 채운다.

- 현재 구조(구 구조)를 대상으로 테스트 작성 — 지금 동작이 "스펙"이다
- 각 테스트가 현재 코드에서 통과해야 함 (failing test 금지, 이건 patch의 TDD와 다름)

## Acceptance Criteria
```bash
npm test
```
새 테스트 + 기존 테스트 전부 통과.

## 수정 금지
- 프로덕션 코드 수정 금지 (리팩터는 step2부터).
```

#### step2 ~ stepN: migrate-batch-K

```markdown
# Step K: migrate-batch-<K>

## 읽어야 할 파일
- `phases/{N}-{name}/PROPOSAL.md` (새 구조)
- `phases/{N}-{name}/INTAKE.md` (해당 배치의 호출처 목록)
- <해당 배치에 속하는 호출처 파일들>

## 작업
배치 <K>의 호출처들을 새 구조로 이관.

- 새 구조의 구현체가 아직 없으면 이 step에서 추가 (최초 배치 처리 시)
- 각 호출처를 새 인터페이스에 맞게 수정
- 구 구조 호출은 그대로 둔다 (step5까지 남겨둠 — 병행 동작)

## Acceptance Criteria
```bash
npm test
```
**step1에서 추가한 테스트 + 기존 테스트 모두 통과**. 동작 변경 없음.

## 수정 금지
- 다른 배치의 호출처 (범위 이탈)
- 새 기능 추가 (리팩터의 비목표)
- 구 구조 자체의 제거 (step5)
```

#### step5: cleanup-old-code

```markdown
# Step 5: cleanup-old-code

## 읽어야 할 파일
- 이전 배치 step들에서 변경된 파일 목록
- 구 구조 파일

## 작업
구 구조의 정의/파일을 제거.

- 호출처가 모두 새 구조로 이관됐는지 grep으로 확인
- 남아있으면 이 step에서 **중단**하고 `blocked` 상태로 (놓친 호출처 있음)

## Acceptance Criteria
```bash
npm test && grep -r "<구 구조 심볼>" src/
```
전체 테스트 통과. grep이 빈 결과 (구 구조 참조 없음).

## 수정 금지
- 새 구조 수정 (이전 step에서 완료)
- 관련 없는 코드 정리 (스코프 이탈)
```

#### step6: update-adr

```markdown
# Step 6: update-adr

## 읽어야 할 파일
- `docs/ADR.md`
- `phases/{N}-{name}/PROPOSAL.md`
- `phases/{N}-{name}/INTAKE.md`

## 작업
`docs/ADR.md`에 이 리팩터의 결정을 append.

```
ADR-<다음번호>: <영역> 리팩터 — <새 구조로>
  결정: <...>
  이유: <Phase A Q1/Q2>
  트레이드오프: <새 구조의 단점도 솔직히>
  supersedes: <만약 번복된 기존 ADR이 있으면 그 번호>
```

구 ADR이 번복된 경우 해당 ADR에 `(superseded by ADR-<새번호>)` 주석 추가.

## Acceptance Criteria
```bash
grep "ADR-<새번호>" docs/ADR.md
```
새 ADR이 파일에 존재.

## 수정 금지
- 프로덕션 코드 (이 step은 문서 전담)
```

---

## Iterate Mode

기존 phase 중 `status`가 `pending`이거나 어떤 step이 `pending`인 phase가 있으면 이 모드로 진입.

### 출력 형식

```
━━━ Iterate Mode ━━━
Phase: phases/{N}-{name}/
Mode: {mode}

Step 상태:
  ✓ step0 (<name>): completed
  → step1 (<name>): pending
  · step2 (<name>): pending

검토할 파일:
  📄 phases/{N}-{name}/index.json
  📄 phases/{N}-{name}/step0.md
  📄 phases/{N}-{name}/step1.md
  ...

최근 에러 (있으면):
  <error_message 내용>

어떤 부분을 수정할까요? (자연어로 지시하세요)
```

### 수정 처리 규칙

사용자의 자연어 수정 지시를 받으면:

1. **영향 분석**: 변경이 어떤 파일·섹션에 미치는지 파악
2. **설계 원칙 위반 체크**: 
   - 해당 모드의 원칙에 위배되는가? (예: patch에서 리팩터 요청)
   - `docs/PRD.md`의 비목표와 충돌하는가?
   - `docs/ADR.md`의 기존 결정과 충돌하는가?
3. **파급 효과 경고**: 
   - step 수 증가/감소?
   - 새 AC 필요?
   - 다른 step도 수정 필요?
4. **위반/충돌 발견 시**: 단순 순종하지 말고 **Option A/B/C** 형식으로 대안 제시하고 사용자 판단을 요청
5. **동의 후 델타 수정**: 전체 재생성 금지. 변경 필요한 파일만 최소 수정.
6. **변경 파일 목록 안내**로 마무리

### Stage 3 에러 복구 (iterate 모드의 특수 케이스)

`phases/{task}/index.json`에서 어떤 step이 `status: error`이면, iterate 진입 시 **자동으로 에러 복구 모드**로 들어간다 (개발자가 별도 지시 없이도).

#### 흐름

**1. 에러 컨텍스트 수집**

다음을 읽어 상황 파악:
- 실패한 step의 `error_message` (index.json)
- `phases/{task}/step{N}-output.json` (있으면 — Claude 서브세션의 마지막 출력)
- 해당 `step{N}.md` (원래 지시)
- `git log` 최근 몇 개 커밋 (어디까지 진행됐나)

**2. 에러 분석 (Claude 자동 수행)**

에러를 유형별로 분류하고 원인 가설 제시:

| 유형 | 신호 | 전형적 원인 |
|------|------|-----------|
| 타입/컴파일 에러 | `tsc`, `mypy` 등의 에러 메시지 | 이전 step 변경과 불일치 |
| 테스트 실패 | 테스트 러너 출력 | AC 오해 또는 구현 누락 |
| 금지사항 위반 | "수정 금지" 파일 건드림 | step.md 금지 목록 불명확 |
| 회귀 | 기존 테스트가 실패 | 변경이 과도함 |
| 환경/의존 | `command not found`, 404 | 외부 의존 (blocked 후보) |

분석 결과 출력:
```
━━━ Stage 3 에러 복구 ━━━
Phase: {N}-{name}
실패 step: step<N> (<name>)
Mode: {mode}

에러 메시지:
<error_message 요약>

원인 가설:
<Claude 분석>

step.md의 어디가 부족했는가:
<지시문 중 모호/누락 부분 지적>
```

**3. 옵션 제시 (개발자 판단 요청)**

다음 3가지 중 하나 선택:

- **Option A** — step.md 지시 보강 (대부분의 경우)
  - Claude가 구체적 수정안 제시 (예: "수정 금지에 X 추가", "AC에 Y 명시")
  - 개발자가 자연어로 추가 요구
- **Option B** — step.md 지시 대폭 재작성 (설계 자체가 틀린 경우)
  - Phase B 분석에 누락이 있었음을 인정 → `/harness-plan {mode}` iterate 권장
- **Option C** — `blocked` 처리 (외부 입력 필요)
  - API 키, 환경 변수, 사용자 의사결정 등 Claude가 해결 불가한 사항
  - status를 `blocked`로 변경 + `blocked_reason` 기록

**4. 수정 적용**

Option A 선택 시:
- `step{N}.md` 수정 (개발자 요구 반영 + Claude 분석 반영)
- `phases/{task}/index.json`의 해당 step:
  - `status`: `error` → `pending`
  - `error_message` 삭제
  - `failed_at` 유지 (이력 기록)

Option B 선택 시:
- `/harness-plan {mode}` 재실행을 안내하고 이번 세션은 여기서 종료

Option C 선택 시:
- `status`: `error` → `blocked`
- `blocked_reason` 기록
- execute.py 재실행 금지 안내

**5. 재실행 안내 (Option A 한정)**

```
✓ step{N}.md 보강 완료.
✓ status를 pending으로 리셋했습니다.

이제 다음 커맨드로 재실행하세요:
  python3 scripts/execute.py {N}-{name}
```

#### Mode별 흔한 실패 패턴 (분석 힌트로 사용)

**Patch 모드**
- *reproduce step에서 테스트가 통과함* — Phase A Q1 재현 조건이 불완전. INTAKE.md로 돌아가 재현 방법을 명확히.
- *fix step이 기존 테스트를 깨뜨림* — 수정 범위가 과도. step.md "수정 금지"에 기존 테스트 파일 명시.

**Feature 모드**
- *타입 추가 시 호출처 컴파일 에러* — step0 AC가 "타입 파일만 에러 없음"이어야 함. 호출처 에러는 step1에서 해결되는 것이 정상.
- *UI step에서 API 호출 실패* — step1 AC 검증 누락 또는 step2가 API 경로를 잘못 가정.
- *회귀 테스트 실패* — step3가 기존 테스트도 돌려야 함. AC에 "기존 테스트 포함" 명시.

**Refactor 모드**
- *migrate-batch에서 기존 테스트 깨짐* — step1에 회귀 테스트가 부족했거나, 구 구조 의존성을 놓친 것. step1로 돌아가 테스트 보강.
- *cleanup 후 여전히 구 구조 참조* — 놓친 호출처 있음. step.md의 AC에 `grep` 명령을 넣어 강제 확인.

**MVP 모드**
- *project-setup 후 `npm test` 실패* — `package.json`의 test 스크립트 누락. step.md에 명시.
- *이전 step 기반 위에서 타입 불일치* — 이전 step의 산출물 요약(index.json의 `summary`)이 부정확. 이전 step을 열어 재확인.

---

## 금지사항 (이 명령의 규약)

- docs/*.md를 이 명령에서 **직접 수정하지 마라**. Discovery는 `/harness-plan`의 몫.
- step 파일에 이전 대화 참조("앞서 논의한…") 쓰지 마라. 각 step은 독립 Claude 세션에서 실행된다.
- 모드별 설계 원칙을 사용자 요청보다 우선시 하라 (사용자가 원칙을 깨려 하면 되묻기).
- 임의로 새 모드를 만들지 마라. mode는 `{mvp, feature, refactor, patch}` 넷 중 하나.
