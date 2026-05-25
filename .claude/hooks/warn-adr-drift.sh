#!/usr/bin/env bash
# warn-adr-drift.sh — avisa quando mudança toca arquivos sensíveis sem ADR aberto
# Disparado em: PreToolUse (Write, Edit, MultiEdit)
# Saída em stderr — não bloqueia (exit 0), mas o agente vê o aviso.
# Critério: mudança em pubspec.yaml, package.json deps, schema do Blueprint
# OU em /lib/core/* + nenhum ADR novo em docs/decisions/ aberto neste branch.
set -euo pipefail

input="$(cat)"
path="$(printf '%s' "$input" | python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    p = (d.get('tool_input') or {}).get('file_path') or ''
    print(p)
except Exception:
    print('')
")"

if [ -z "$path" ]; then exit 0; fi

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
rel="${path#$root/}"

sensitive=0
case "$rel" in
  apps/mobile/pubspec.yaml|packages/shared/pubspec.yaml|package.json) sensitive=1 ;;
  docs/Blueprint.md) sensitive=1 ;;
  apps/mobile/lib/core/native_bridges/*) sensitive=1 ;;
esac

if [ "$sensitive" -eq 1 ]; then
  current_branch="$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
  new_adrs="$(git -C "$root" diff --name-only main..HEAD 2>/dev/null | grep -E 'docs/decisions/00[0-9]+-' | grep -v '0000-template\|0001-stack\|0002-camera\|0003-replay\|0004-client\|0005-state\|0006-commit\|0007-lock\|0008-scope\|0009-wake\|0010-dual\|0011-volume\|0012-xiaomi' || true)"
  if [ -z "$new_adrs" ] && [ "$current_branch" != "main" ]; then
    echo "⚠️  warn-adr-drift: editando arquivo sensível ($rel) sem ADR novo no branch $current_branch." >&2
    echo "    Considere abrir docs/decisions/00NN-<motivo>.md antes da mudança." >&2
  fi
fi

exit 0
