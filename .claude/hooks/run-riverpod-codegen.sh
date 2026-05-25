#!/usr/bin/env bash
# run-riverpod-codegen.sh — agenda build_runner quando arquivo .dart com @riverpod muda
# Disparado em: PostToolUse (Write, Edit, MultiEdit) com matcher de path *.dart
# Estratégia: debounce de 90s via touch em arquivo lockfile.
# Decisão: codegen NÃO roda dentro do hook (lento, ~10-30s), só sinaliza
# que precisa rodar. O agente pode então chamar `bun --filter @raro/mobile run codegen`.
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
  *.dart)
    case "$path" in
      *.g.dart|*.freezed.dart) exit 0 ;;
    esac
    ;;
  *) exit 0 ;;
esac

if [ ! -f "$path" ]; then exit 0; fi

if grep -qE "@riverpod\b" "$path" 2>/dev/null; then
  marker="/tmp/raro-codegen-pending"
  touch "$marker"
  echo "ℹ️  run-riverpod-codegen: $path tem @riverpod. Marker $marker tocado. Rode 'bun --filter @raro/mobile run codegen' quando estável." >&2
fi

exit 0
