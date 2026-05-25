#!/usr/bin/env bash
# verify-task.sh — antes de declarar tarefa pronta, roda lint+test
# Disparado MANUALMENTE via /verify-slice (NÃO está registrado em Stop event
# porque rodar a cada turno do agente desperdiça 5-10s mesmo quando nenhum
# código mudou). Mantido como utilitário invocável.
# Lê stdin opcional (json com stop_hook_active flag).
# Roda bun run lint && bun run test. Exit 0 se passar, 1 se falhar.
set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root"

# Bypass se já estamos dentro de um stop hook (evita loop infinito)
input="$(cat 2>/dev/null || echo '{}')"
already_active="$(printf '%s' "$input" | python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    print('1' if d.get('stop_hook_active') else '0')
except Exception:
    print('0')
" 2>/dev/null)"
if [ "$already_active" = "1" ]; then exit 0; fi

# Pula verify se nenhum arquivo .dart ou .yaml mudou (heurística)
changed="$(git diff --name-only HEAD 2>/dev/null || echo "")"
if ! printf '%s' "$changed" | grep -qE '\.(dart|yaml|json)$'; then
  exit 0
fi

if ! command -v bun >/dev/null 2>&1; then
  echo "⚠️  verify-task: bun não encontrado, pulando" >&2
  exit 0
fi

echo "🔍 verify-task: rodando bun run lint && bun run test..." >&2
if ! bun run lint >/dev/null 2>&1; then
  echo "❌ verify-task: bun run lint falhou. Veja saída acima e corrija antes de declarar pronto." >&2
  bun run lint 2>&1 | tail -20 >&2
  exit 1
fi

if ! bun run test >/dev/null 2>&1; then
  echo "❌ verify-task: bun run test falhou." >&2
  bun run test 2>&1 | tail -20 >&2
  exit 1
fi

echo "✅ verify-task: lint + test passam." >&2
exit 0
