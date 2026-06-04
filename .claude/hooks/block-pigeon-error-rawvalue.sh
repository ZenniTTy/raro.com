#!/usr/bin/env bash
# block-pigeon-error-rawvalue.sh — bloqueia String(<enum>.rawValue) ou .rawValue.toString()
# dentro de PigeonError() / FlutterError() em .swift e .kt.
# Preserva semântica do enum através da fronteira Pigeon (Dart não pode ver "0" opaco).
# Disparado em: PreToolUse (Write, Edit, MultiEdit)
set -euo pipefail

input="$(cat)"

file_path="$(printf '%s' "$input" | python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    ti = d.get('tool_input') or {}
    print(ti.get('file_path',''))
except Exception:
    pass
")"

if [ -z "$file_path" ]; then
  exit 0
fi

case "$file_path" in
  *.swift|*.kt) ;;
  *) exit 0 ;;
esac

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

# Padrões bloqueados dentro de PigeonError(...) / FlutterError(...):
#   code: String(<expr>.rawValue)
#   code: "...${<expr>.rawValue}..."
#   code: <expr>.rawValue.toString()
pattern='(PigeonError|FlutterError)\([^)]*code[[:space:]]*[:=][[:space:]]*(String\([^)]*\.rawValue\)|"[^"]*\$\{[^}]*\.rawValue[^}]*\}"|[A-Za-z_][A-Za-z0-9_.]*\.rawValue\.toString\(\))'

if printf '%s' "$content" | grep -qE "$pattern"; then
  cat <<EOF >&2
🚫 block-pigeon-error-rawvalue: refused write to $file_path

Cannot emit \`String(<enum>.rawValue)\` or \`.rawValue.toString()\` inside PigeonError/FlutterError.
This loses enum semantic across the Pigeon boundary (Dart sees opaque "0" instead of "permissionDenied").

Use one of:
  Swift:  PigeonError(code: "\\(code)", message: ..., details: nil)
  Kotlin: FlutterError(code = "\$code", message = ...)

Or route the typed error via the FlutterApi callback (CameraFlutterApi.onError) instead.

See: docs/decisions/0015-camera-native-bridge-strategy.md addendum + CLAUDE.md §11.
EOF
  exit 1
fi

exit 0
