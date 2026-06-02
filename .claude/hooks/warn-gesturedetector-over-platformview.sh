#!/usr/bin/env bash
# warn-gesturedetector-over-platformview.sh — avisa quando um GestureDetector
# envolve um UiKitView/AndroidView que usa EagerGestureRecognizer.
# Disparado em: PreToolUse (Write, Edit, MultiEdit) em *.dart.
# Saída em stderr — NÃO bloqueia (exit 0), mas o agente vê o aviso.
#
# Por quê: o EagerGestureRecognizer entrega o tap à view NATIVA imediatamente,
# então o onTapDown do GestureDetector pai NÃO dispara de forma confiável. Esse
# anti-pattern causou o focus ring nunca aparecer (tap caía no vão). A detecção
# de tap deve viver no nativo (UITapGestureRecognizer/setOnTouchListener).
# Ver memória raro-pattern-flutter-platformview-tap-must-be-native.
set -euo pipefail

input="$(cat)"

file_path="$(printf '%s' "$input" | python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    print((d.get('tool_input') or {}).get('file_path',''))
except Exception:
    pass
")"

[ -z "$file_path" ] && exit 0
case "$file_path" in
  *.dart) ;;
  *) exit 0 ;;
esac

content="$(printf '%s' "$input" | python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    ti = d.get('tool_input') or {}
    print('\n'.join([p for p in [ti.get('content',''), ti.get('new_string','')] if p]))
except Exception:
    pass
")"

[ -z "$content" ] && exit 0

# Heurística: o trecho menciona GestureDetector E (UiKitView OU AndroidView OU EagerGestureRecognizer)
if printf '%s' "$content" | grep -qE "GestureDetector" \
   && printf '%s' "$content" | grep -qE "UiKitView|AndroidView|EagerGestureRecognizer"; then
  cat <<EOF >&2
⚠️  warn-gesturedetector-over-platformview: $file_path

GestureDetector + (UiKitView/AndroidView/EagerGestureRecognizer) no mesmo trecho.
Com EagerGestureRecognizer, o tap é entregue à view NATIVA — o onTapDown do
GestureDetector pai NÃO dispara de forma confiável (causou o focus ring nunca
aparecer; o tap caía no vão).

Se for tap-to-focus / interação sobre o preview da câmera: detecte o tap no
NATIVO (UITapGestureRecognizer no Swift / setOnTouchListener no Kotlin), não no
GestureDetector Flutter. Mantenha o EagerGestureRecognizer.

Ver memória raro-pattern-flutter-platformview-tap-must-be-native (índice em
MEMORY.md). Aviso não-bloqueante — ignore se o uso for legítimo.
EOF
fi

exit 0
