#!/usr/bin/env bash
# block-forbidden-terms.sh — bloqueia termos de marca proibidos
# Trigger: PreToolUse (Write, Edit, MultiEdit)
# Recebe stdin JSON com {tool_input: {content|new_string: "..."}}
# Lista canônica precisa bater com packages/shared/lib/src/contract/forbidden_terms.dart
set -euo pipefail

input="$(cat)"

content="$(printf '%s' "$input" | python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    ti = d.get('tool_input') or {}
    parts = [ti.get('content',''), ti.get('new_string','')]
    print('\n'.join([p for p in parts if p]))
except Exception:
    pass
")"

if [ -z "$content" ]; then
  exit 0
fi

for term in 'OkCamera' 'Ok Camera' 'hey OkCamera' 'okCamera' 'ok_camera'; do
  if printf '%s' "$content" | grep -qF "$term"; then
    echo "🚫 block-forbidden-terms: detected \"$term\". Wake word is \"Raro\" — see ADR-0009 + CLAUDE.md Seção 11." >&2
    exit 1
  fi
done

exit 0
