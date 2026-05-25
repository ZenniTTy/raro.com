#!/usr/bin/env bash
# format-dart.sh — auto-formata arquivos .dart após Edit/Write
# Disparado em: PostToolUse (Write, Edit, MultiEdit) com matcher de path
# Recebe via stdin um JSON com {tool_input: {file_path: "..."}}
# Sai com exit 0 sempre (não bloqueia — apenas formata).
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

if [ -z "$path" ]; then
  exit 0
fi

case "$path" in
  *.dart)
    case "$path" in
      *.g.dart|*.freezed.dart)
        # arquivos gerados nunca devem ser formatados manualmente
        exit 0
        ;;
    esac
    if command -v dart >/dev/null 2>&1; then
      dart format "$path" >/dev/null 2>&1 || true
    fi
    ;;
esac

exit 0
