#!/usr/bin/env bash
# setup.sh — bootstrap local do RARO em um clone novo do repo.
# Idempotente: pode rodar várias vezes sem efeitos colaterais.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

echo "🔧 RARO setup — Raro Camera bootstrap"
echo "    root: $ROOT"
echo ""

# ─── Pré-condições ────────────────────────────────────
need() {
  command -v "$1" >/dev/null 2>&1 || { echo "❌ missing: $1 — install before continuing"; exit 1; }
}

echo "[1/5] Checando pré-condições..."
need bun
need flutter
need dart
need git
need node
need python3

BUN_VER=$(bun --version)
FLT_VER=$(flutter --version 2>/dev/null | head -1)
NODE_VER=$(node --version)
PY_VER=$(python3 --version)
echo "    bun:     $BUN_VER"
echo "    flutter: $FLT_VER"
echo "    node:    $NODE_VER"
echo "    python3: $PY_VER (usado pelos hooks em .claude/hooks/)"

# ─── Bun workspace install ────────────────────────────
echo ""
echo "[2/5] bun install (root + workspaces)..."
bun install --frozen-lockfile 2>/dev/null || bun install

# ─── Flutter pub get ──────────────────────────────────
echo ""
echo "[3/5] flutter pub get (apps/mobile)..."
flutter pub get --directory=apps/mobile

# ─── Dart pub get (packages/shared) ───────────────────
echo ""
echo "[4/5] dart pub get (packages/shared)..."
(cd packages/shared && dart pub get)

# ─── lefthook install ─────────────────────────────────
echo ""
echo "[5/5] lefthook install (git hooks)..."
bunx lefthook install

echo ""
echo "✅ Setup completo. Próximos passos:"
echo "    bun run lint        # turbo run lint em todos workspaces"
echo "    bun run test        # turbo run test"
echo "    bun --filter @raro/mobile run codegen   # gerar *.g.dart"
echo ""
echo "📱 Para rodar o app:"
echo "    cd apps/mobile && flutter run"
