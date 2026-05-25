#!/usr/bin/env bash
# block-env.sh — bloqueia escrita em arquivos com credenciais/secrets
# Disparado em: PreToolUse (Write, Edit, MultiEdit)
# Recebe via stdin um JSON com {tool_input: {file_path: "..."}}
# Sai com exit 1 + mensagem em stderr para bloquear.
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

basename="$(basename "$path")"
case "$basename" in
  .env|.env.local|.env.production|.env.staging|.env.development)
    echo "🚫 block-env: writing to '$basename' is not allowed. Use .env.example for templates." >&2
    exit 1
    ;;
  key.properties|keystore.jks|*.keystore|*.jks|*.p12|*.mobileprovision)
    echo "🚫 block-env: signing credential '$basename' must not be committed." >&2
    exit 1
    ;;
  GoogleService-Info.plist|google-services.json)
    echo "🚫 block-env: Firebase config '$basename' must come from cliente, not be written by agent." >&2
    exit 1
    ;;
esac

exit 0
