#!/usr/bin/env bash
# analyze-changed-dart.sh — roda flutter analyze incremental em arquivos editados
# Disparado em: PostToolUse (Write, Edit, MultiEdit) com matcher de path *.dart
# Saída em stderr — não bloqueia (exit 0) mas avisa.
# Decisão: análise focada no único arquivo editado, não full project (lento).
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

case "$path" in
  *.dart) ;;
  *) exit 0 ;;
esac

case "$path" in
  *.g.dart|*.freezed.dart) exit 0 ;;
esac

if [ ! -f "$path" ]; then exit 0; fi

if command -v dart >/dev/null 2>&1; then
  out="$(dart analyze "$path" 2>&1 || true)"
  if printf '%s' "$out" | grep -qE "(error|warning) •"; then
    echo "⚠️  analyze-changed-dart: $path tem issues:" >&2
    printf '%s\n' "$out" | grep -E "(error|warning) •" | head -10 >&2
  fi
fi

exit 0
