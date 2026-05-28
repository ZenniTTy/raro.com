#!/usr/bin/env bash
# bootstrap-ios-permissions.sh — reaplica macros permission_handler no Podfile.
#
# Flutter 3.44 regera Podfile (gitignored, ADR-0014) — toda execução de
# `flutter pub get` apaga nossos macros GCC_PREPROCESSOR_DEFINITIONS
# (PERMISSION_CAMERA, etc.) sem os quais permission_handler retorna `denied`
# silenciosamente sem chamar AVCaptureDevice.requestAccess.
#
# Esse script é idempotente: detecta se os macros já estão no Podfile e
# adiciona se faltarem. Roda automaticamente em `bun --filter @raro/mobile
# run pub:get`.
#
# Ver: raro-pattern-permission-handler-ios-podfile-macros (memória persistente)
# Ver: https://pub.dev/packages/permission_handler#setup-ios

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PODFILE="$MOBILE_DIR/ios/Podfile"

if [ ! -f "$PODFILE" ]; then
  echo "[bootstrap-ios-permissions] $PODFILE não existe — Flutter ainda não gerou"
  exit 0
fi

if grep -q 'PERMISSION_CAMERA=1' "$PODFILE"; then
  echo "[bootstrap-ios-permissions] macros já presentes — no-op"
  exit 0
fi

# Inserir macros dentro do post_install hook. Mais robusto que diff/patch:
# substitui o trecho inteiro do hook se ele NÃO tiver nossos macros.
if grep -q 'post_install do |installer|' "$PODFILE"; then
  python3 - <<'PYEOF' "$PODFILE"
import re
import sys

path = sys.argv[1]
text = open(path).read()

macros_block = """
      # permission_handler macros (https://pub.dev/packages/permission_handler#setup)
      # required so the plugin compiles support for these permission groups.
      # Without these, Permission.camera.request() returns denied silently.
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_MICROPHONE=1',
        'PERMISSION_PHOTOS=1',
        'PERMISSION_SPEECH_RECOGNIZER=1',
      ]
"""

pattern = re.compile(
    r'(target\.build_configurations\.each do \|config\|.*?)(\n\s*end\s*\n\s*end)',
    re.DOTALL
)
match = pattern.search(text)
if not match:
    print("[bootstrap-ios-permissions] ERRO: não encontrei build_configurations loop")
    sys.exit(1)

new_block = match.group(1) + macros_block + match.group(2)
new_text = text.replace(match.group(0), new_block)
open(path, 'w').write(new_text)
print("[bootstrap-ios-permissions] macros adicionados ao Podfile via post_install")
PYEOF
else
  echo "[bootstrap-ios-permissions] ERRO: Podfile não tem post_install hook — formato inesperado"
  exit 1
fi

# Re-rodar pod install para propagar macros aos targets dos Pods
cd "$MOBILE_DIR/ios"
if command -v pod >/dev/null 2>&1; then
  echo "[bootstrap-ios-permissions] rodando 'pod install' para propagar macros"
  pod install 2>&1 | tail -3
else
  echo "[bootstrap-ios-permissions] WARNING: 'pod' não encontrado — rode 'pod install' manualmente"
fi
