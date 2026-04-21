이 프로젝트는 Harness 프레임워크를 사용한다. 이 명령은 **Stage 4 (Review)**를 담당한다.

Stage 3 (`python3 scripts/execute.py {task}`)가 완료된 뒤 실행한다. 현재 phase의 변경을 모드별 AC에 대조해 검증하고 PR 초안을 만든다.

---

## Usage

```
/review
```

인자 없음. 현재 진행 중인 phase (또는 가장 최근에 완료된 phase)를 자동 감지한다.

---

## 실행 흐름

### 1. 대상 Phase 식별

다음 우선순위로 대상 phase 결정:

1. `phases/index.json`에서 `status: completed`이면서 `completed_at`이 가장 최근인 phase
2. 그런 phase가 없으면, `status: pending`이면서 모든 step이 completed인 phase
3. 둘 다 없으면: "리뷰할 완료된 phase가 없습니다" 안내 후 종료

식별된 phase의 `phases/{task}/index.json`에서 `mode` 필드 읽어 이후 검증을 모드별로 분기한다.

### 2. 컨텍스트 로드

다음을 읽는다:

- `CLAUDE.md`
- `docs/PRD.md` (phase 시작 시점 스냅샷은 `phases/{task}/PRD.md`도 참고)
- `docs/ARCHITECTURE.md`
- `docs/ADR.md`
- `phases/{task}/PRD.md` (이 phase의 확정 의도)
- `phases/{task}/INTAKE.md` (Phase A+B 기록)
- `phases/{task}/index.json` (step 결과 및 summary)

### 3. Git Diff 분석

현재 브랜치와 main의 diff:
```bash
git diff main...HEAD --stat
git log main..HEAD --oneline
```

- 변경된 파일 목록
- 총 +/- 라인 수
- 커밋 수 (feat/fix/refactor prefix별 카운트)

### 4. Mode별 검증

#### 공통 체크리스트 (모든 모드)

| 항목 | 기준 |
|------|------|
| 아키텍처 준수 | `docs/ARCHITECTURE.md`의 디렉토리 구조 지켜졌는가 |
| 기술 스택 준수 | `docs/ADR.md` 결정 벗어나지 않았는가 |
| CLAUDE.md CRITICAL 규칙 | 위반 없는가 |
| 빌드/테스트 | `npm run build && npm test` (또는 해당 프로젝트 커맨드) 통과 |
| 커밋 prefix 일관성 | mode에 맞는 prefix (patch→fix:, feature→feat:, refactor→refactor:, mvp→feat:) |

#### Patch 모드 추가 체크

| 항목 | 기준 |
|------|------|
| 변경 최소성 | 변경 파일 수가 Phase B 분석과 일치하는가 (대개 1-2개) |
| TDD 순서 | step0에서 실패 테스트 추가 커밋, step1에서 fix 커밋 순서인가 |
| 회귀 없음 | 기존 테스트 전부 통과 |
| 무관한 리팩터 없음 | 지시받지 않은 정리·리네이밍 없는가 |

#### Feature 모드 추가 체크

| 항목 | 기준 |
|------|------|
| AC 전체 충족 | PRD의 AC-1 ~ AC-N 각각에 대응하는 테스트/증거 존재 |
| 회귀 없음 | 기존 테스트 전부 통과 |
| 수정 금지 영역 미수정 | Phase B의 "수정 금지" 파일이 diff에 없는가 |
| 새 ADR 반영 | Phase B가 제안한 ADR이 `docs/ADR.md`에 추가됐는가 |
| Step 분리 | 레이어별 커밋이 섞이지 않았는가 (types/api/ui/tests 각자) |

#### Refactor 모드 추가 체크

| 항목 | 기준 |
|------|------|
| **동작 보존** (핵심) | PRD의 "동작 보존 범위" 각 항목이 테스트로 증명되는가 |
| 새 기능 없음 | PR에 새 엔드포인트·새 화면·새 기능 없음 (refactor의 비목표) |
| 배치 커밋 분리 | `migrate-batch-1`, `-2`, ... 가 별도 커밋으로 존재 — 각각 revert 가능 |
| 구 구조 제거 | `grep "<구 심볼>" src/` 가 빈 결과 (step5 cleanup 성공) |
| ADR 업데이트 | 리팩터 결정이 `docs/ADR.md`에 append (supersedes 처리 포함) |

#### MVP 모드 추가 체크

| 항목 | 기준 |
|------|------|
| 출시 가능 기준 | PRD의 AC (출시 기준) 전체 충족 |
| 7 step 순서 | setup→types→db→api→ui→auth→e2e 순서로 커밋 존재 (있는 것만) |
| 초기 ADR 존재 | `docs/ADR.md`에 스택 선택 ADR 3-5개 기록됨 |
| 아키텍처 문서 | `docs/ARCHITECTURE.md`가 실제 디렉토리 구조와 일치 |
| `package.json` 스크립트 | `dev`, `build`, `lint`, `test` 모두 존재 |
| MVP 비목표 미포함 | PRD의 "MVP 제외 사항"에 해당하는 코드가 섞여있지 않음 |

### 5. 잠재 이슈 식별

체크리스트 실패 외에도 다음을 찾아 보고:

- 보안 이슈 (secret 하드코딩, SQL injection 등 OWASP)
- 성능 우려 (N+1 쿼리, 비동기 누락)
- 에러 처리 누락 (try/catch, 경계 검증)
- 테스트 커버리지 공백 (AC에는 통과하나 엣지 케이스 누락)
- docs 업데이트 누락 (새 결정이 ADR에 기록 안 됨 등)

**이슈 발견 시 분류**:
- 🔴 **Blocker**: 머지 불가 (AC 미충족, 빌드 실패, 보안)
- 🟡 **Non-blocker**: 머지 가능하나 후속 조치 권장 (잠재 버그, 리팩터 기회)
- ℹ️ **Nit**: 스타일/네이밍 등 가벼운 제안

### 6. 출력 형식

```
━━━ Review: {task} (Mode: {mode}) ━━━

## 변경 요약

- 커밋 수: N (feat: X, chore: Y, fix: Z)
- 변경 파일 수: N (수정 X, 신규 Y, 삭제 Z)
- 총 라인: +N / -N

주요 변경:
- <핵심 변경 1줄 요약 1>
- <핵심 변경 2>

## 공통 체크리스트

| 항목 | 결과 | 비고 |
|------|------|------|
| 아키텍처 준수 | ✅ | |
| 기술 스택 준수 | ✅ | |
| CLAUDE.md CRITICAL 규칙 | ✅ | |
| 빌드/테스트 | ✅ | npm test 60 passed |
| 커밋 prefix 일관성 | ✅ | 모두 feat: (feature 모드) |

## Mode별 체크리스트 ({mode})

| 항목 | 결과 | 비고 |
|------|------|------|
| <mode별 항목 1> | ✅/❌ | |
| <mode별 항목 2> | ✅/❌ | |
...

## AC 대비 검증

AC-1: <PRD의 AC-1 내용>
  → ✅ 통과 (tests/foo.test.ts:15)
AC-2: <PRD의 AC-2>
  → ✅ 통과
AC-3: <...>
  → ❌ 미충족 (이유: ...)

## 잠재 이슈

🔴 Blocker: <있으면>
🟡 Non-blocker: <있으면>
ℹ️ Nit: <있으면>

없으면 "이슈 없음" 표기.

## 결론

<머지 권장 / 수정 후 머지 / 추가 step 필요 중 하나>
```

### 7. Blocker 발견 시

Blocker가 있으면 PR 생성하지 말고 중단:

```
🔴 Blocker 발견. PR 생성 중단.

<Blocker 내용>

해결 방법:
  ▸ Stage 3 실패형 (AC 미충족): /harness {mode} (iterate 모드)로 step.md 보강
  ▸ 설계 결함형: /harness-plan {mode} (iterate)로 Phase B 재분석
  ▸ 스코프 이탈형: 문제 부분 revert 후 별도 phase로 분리
```

### 8. PR 초안 생성 (Blocker 없을 때)

체크리스트 전부 통과 또는 Non-blocker만 있을 경우 PR 초안 제시:

```
━━━ PR 초안 ━━━

제목: {commit_prefix}: <한 줄 요약> ({task})

본문:
## Summary
- <핵심 변경 1>
- <핵심 변경 2>
- <핵심 변경 3>

## Mode & Phase
- Mode: {mode}
- Phase: {task}
- 관련 ADR: <있으면 ADR-번호>

## AC 검증
- [x] AC-1: <요약>
- [x] AC-2: <요약>
- [x] AC-3: <요약>

## Test Plan
- [x] npm test — <N>개 테스트 통과
- [x] npm run build — 빌드 성공
- [x] <mode별 추가 검증 — 예: refactor의 "동작 보존">

## Non-blocker 후속 제안 (있으면)
- <...>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

이 PR을 생성할까요? (y / 수정 / 취소)
```

사용자 승인 시 `gh pr create`로 PR 생성:

```bash
gh pr create --title "<제목>" --body "$(cat <<'EOF'
<본문>
EOF
)"
```

---

## 금지사항

- 이 명령은 **리뷰와 PR 초안 전용**. 코드 수정 금지 (리팩터·린트 자동화 금지).
- Blocker가 있으면 절대 PR 생성하지 말 것. 개발자가 수정 후 다시 `/review` 실행.
- 개발자 확인 없이 `gh pr create` 실행 금지. 항상 초안 제시 → 승인 → 생성.
- PR 제목/본문을 임의로 미화하지 말 것. 실제 변경을 있는 그대로 서술.
