#!/usr/bin/env bash
# warn-sfspeech-recycle-per-error.sh — avisa quando um edit em Swift mexe no
# ciclo de SFSpeechRecognitionTask perto de tratamento de erro/cancel.
# Disparado em: PreToolUse (Write, Edit, MultiEdit) em *.swift.
# Saída em stderr — NÃO bloqueia (exit 0), mas o agente vê o aviso.
#
# Por quê: o SFSpeech on-device finaliza por design ao detectar silêncio
# (kAFAssistantErrorDomain 1110 "no speech"). Reciclar a recognitionTask a cada
# 1110 gera ~6 reciclos/segundo; na janela morta de cada reinício o request fica
# nil e o comando dito ali é descartado ("raro parar" caía no vão; log: 521
# reciclos vs 1 wake matched). Custou uma quase-migração inteira de engine
# (OpenWakeWord) na S2.C antes de a 0024 achar a causa real.
# Ver memória raro-pattern-sfspeech-continuous-no-recycle-per-error.
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
  *.swift) ;;
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

# Heurística: o trecho mexe na recognitionTask E em erro/cancel/reciclo
if printf '%s' "$content" | grep -qE "recognitionTask|SFSpeechRecognitionTask" \
   && printf '%s' "$content" | grep -qE "1110|kAFAssistant|\.cancel\(\)|recycle|refreshCycle|endAudio"; then
  cat <<EOF >&2
⚠️  warn-sfspeech-recycle-per-error: $file_path

Edit mexe no ciclo de SFSpeechRecognitionTask perto de erro/cancel.

NÃO recicle a recognitionTask a cada erro benigno 1110 (no-speech): o on-device
finaliza em silêncio POR DESIGN. Reciclar a cada 1110 → ~6 reciclos/s → request
nil na janela morta → comando dito ali é descartado ("raro parar" sumia).

Padrão correto (sessão 0024, ADR-0022):
  • token de ciclo (UUID) bloqueia reciclo órfão/duplicado
  • refresh único agendado (cancela o workitem anterior, não empilha)
  • ring buffer de CMSampleBuffer replayado no request novo (fecha janela morta)
  • refresh proativo só a cada ~50s (não a cada erro)
  • backoff só em erros TERMINAIS reais (1101/1107/7/4/203/1700), não no 1110

Gate §10: confirmar install no device (devicectl) ANTES de testar + prova de log
(reciclos « N, múltiplos wake matched). Ver memória
raro-pattern-sfspeech-continuous-no-recycle-per-error (índice em MEMORY.md).
Aviso não-bloqueante — ignore se o uso for legítimo.
EOF
fi

exit 0
