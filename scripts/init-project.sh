#!/usr/bin/env bash
# Harness Framework — 프로젝트 초기화 스크립트
#
# 현재 디렉토리에 하네스 자산(.claude/, scripts/execute.py)을 설치하고
# 기본 구조(docs/, phases/, CLAUDE.md 템플릿, git)를 만든다.
#
# Usage:
#   curl -fsSL https://github.com/itchain/harness_framework/raw/main/scripts/init-project.sh | bash
#
# 또는 이미 레포를 받은 상태에서:
#   bash scripts/init-project.sh

set -euo pipefail

REPO_URL="https://github.com/itchain/harness_framework"
BRANCH="${HARNESS_BRANCH:-main}"
TARBALL_URL="$REPO_URL/tarball/$BRANCH"
TARGET_DIR="$(pwd)"

echo ""
echo "━━━ Harness Framework 초기화 ━━━"
echo "대상 디렉토리: $TARGET_DIR"
echo ""

# ---- 1. 필수 커맨드 확인 ----
for cmd in curl tar git; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "✗ 필수 커맨드 '$cmd'이 없습니다. 설치 후 다시 실행하세요." >&2
        exit 1
    fi
done

# ---- 2. 임시 디렉토리에 tarball 다운로드 & 압축 해제 ----
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "↓ 하네스 레포 다운로드 중... ($BRANCH)"
if ! curl -fsSL "$TARBALL_URL" | tar -xz -C "$TMP_DIR" 2>/dev/null; then
    echo "✗ 다운로드 실패. 네트워크 또는 레포 URL 확인." >&2
    echo "  시도한 URL: $TARBALL_URL" >&2
    exit 1
fi

SRC="$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d -print -quit)"
if [[ -z "$SRC" || ! -d "$SRC" ]]; then
    echo "✗ tarball 압축 해제 실패 또는 비어있음" >&2
    exit 1
fi

# 안전 체크: 기대한 하네스 자산이 있는지 검증
if [[ ! -d "$SRC/.claude" || ! -f "$SRC/scripts/execute.py" ]]; then
    echo "✗ 다운로드 내용이 하네스 레포 구조와 다릅니다." >&2
    echo "  브랜치 '$BRANCH'이 올바른지 확인하세요." >&2
    exit 1
fi

# ---- 3. 자산 복사 ----
echo ""
echo "↓ 자산 복사 중..."

# 인터랙티브 prompt: curl | bash 환경에서도 동작하도록 /dev/tty 사용
prompt_yn() {
    local question="$1"
    local reply
    if [[ -r /dev/tty ]]; then
        read -p "$question (y/N) " -n 1 -r reply </dev/tty
        echo ""
    else
        reply="N"  # 비대화형 환경(CI 등) — 안전 기본값
    fi
    [[ "$reply" =~ ^[Yy]$ ]]
}

# .claude/
if [[ -d .claude ]]; then
    if prompt_yn "⚠ .claude/가 이미 있습니다. 덮어쓸까요?"; then
        rm -rf .claude
        cp -r "$SRC/.claude" .
        echo "  ✓ .claude/ (덮어씀)"
    else
        echo "  - .claude/ (건너뜀)"
    fi
else
    cp -r "$SRC/.claude" .
    echo "  ✓ .claude/"
fi

# scripts/execute.py
mkdir -p scripts
if [[ -f scripts/execute.py ]]; then
    if prompt_yn "⚠ scripts/execute.py가 이미 있습니다. 덮어쓸까요?"; then
        cp "$SRC/scripts/execute.py" scripts/
        echo "  ✓ scripts/execute.py (덮어씀)"
    else
        echo "  - scripts/execute.py (건너뜀)"
    fi
else
    cp "$SRC/scripts/execute.py" scripts/
    echo "  ✓ scripts/execute.py"
fi

# ---- 4. 빈 docs/, phases/ + .gitkeep ----
for dir in docs phases; do
    if [[ ! -d "$dir" ]]; then
        mkdir "$dir"
        touch "$dir/.gitkeep"
        echo "  ✓ $dir/ (빈 디렉토리 + .gitkeep)"
    else
        echo "  - $dir/ (이미 존재, 건너뜀)"
    fi
done

# ---- 5. CLAUDE.md 템플릿 (없을 때만) ----
if [[ ! -f CLAUDE.md ]]; then
    cat > CLAUDE.md <<'EOF'
# 프로젝트: <프로젝트명>

## 기술 스택
- <언어/런타임, 예: Python 3.9+>
- <프레임워크, 예: Next.js 15>
- <테스트, 예: pytest>

## 아키텍처 규칙
- CRITICAL: <절대 지켜야 할 규칙 1 — 예: 모든 API 로직은 app/api/ 라우트 핸들러에서만>
- CRITICAL: <절대 지켜야 할 규칙 2>
- <일반 규칙>

## 개발 프로세스
- CRITICAL: TDD — 테스트 먼저 작성, 통과하는 구현 작성
- 커밋 메시지는 conventional commits (feat:, fix:, refactor:, chore:, docs:)

## 명령어
<빌드/테스트/린트 커맨드들. 예:
npm run dev
npm run build
npm run lint
npm run test
>
EOF
    echo "  ✓ CLAUDE.md (템플릿 생성 — 반드시 프로젝트에 맞게 수정)"
else
    echo "  - CLAUDE.md (이미 존재, 건너뜀)"
fi

# ---- 6. git init (없으면) ----
if [[ ! -d .git ]]; then
    git init -q -b main 2>/dev/null || git init -q
    # older git without -b: rename default branch to main
    git symbolic-ref HEAD refs/heads/main 2>/dev/null || true
    echo "  ✓ git init (main 브랜치)"
else
    echo "  - .git/ (이미 존재)"
fi

# ---- 7. 다음 단계 안내 ----
echo ""
echo "━━━ 완료 ━━━"
echo ""
echo "다음 단계:"
echo "  1. CLAUDE.md를 프로젝트 규칙에 맞게 수정하세요."
echo "  2. Claude Code 세션에서 첫 phase를 시작하세요:"
echo ""
echo "     /harness-plan mvp       # 빈 레포에서 새 프로젝트 시작"
echo "     /harness-plan feature   # (MVP 후) 기능 추가"
echo "     /harness-plan patch     # 버그 픽스"
echo "     /harness-plan refactor  # 구조 변경"
echo ""
echo "  ℹ 문서:"
echo "     $REPO_URL/blob/$BRANCH/README.md"
echo "     $REPO_URL/blob/$BRANCH/SCENARIO.md"
echo ""
