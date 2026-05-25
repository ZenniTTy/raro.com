#!/usr/bin/env bash
# block-secrets.sh — bloqueia content com strings suspeitas (API keys, tokens, private keys)
# Disparado em: PreToolUse (Write, Edit, MultiEdit)
# Recebe via stdin um JSON com {tool_input: {content|new_string: "..."}}
# Sai com exit 1 + mensagem em stderr para bloquear.
set -euo pipefail

input="$(cat)"

content="$(printf '%s' "$input" | python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    ti = d.get('tool_input') or {}
    # Cobre Write (content) e Edit/MultiEdit (new_string)
    parts = [ti.get('content',''), ti.get('new_string','')]
    print('\n'.join([p for p in parts if p]))
except Exception:
    pass
")"

if [ -z "$content" ]; then
  exit 0
fi

# Padrões de secret: atribuição com chave/token e valor base64-like longo
# OU início de chave privada PEM
# Nota: o '-' na classe de chars está no INÍCIO para não ser interpretado como range
pattern_assign='(api[_-]?key|secret[_-]?key|access[_-]?token|private[_-]?key|aws[_-]?secret|stripe[_-]?key)[[:space:]]*[:=][[:space:]]*["'"'"'][-A-Za-z0-9_/+=]{20,}["'"'"']'
pattern_pem='BEGIN[[:space:]](RSA|EC|OPENSSH|PGP|ENCRYPTED)[[:space:]]PRIVATE[[:space:]]KEY'

if printf '%s' "$content" | grep -qE "$pattern_assign" || \
   printf '%s' "$content" | grep -qE "$pattern_pem"; then
  echo "🚫 block-secrets: content has pattern suggesting a credential. Move it to env var or .env.example." >&2
  exit 1
fi

exit 0
