#!/usr/bin/env bash
# fix-spm-ios-target.sh — workaround para flutter/flutter#162072 + #162196.
#
# Patcha FlutterGeneratedPluginSwiftPackage/Package.swift para iOS 15.0.
# Flutter 3.44 hardcoda iOS 13 em `darwin.dart:71` ignorando project.pbxproj.
#
# IMPORTANTE: NÃO chama `flutter build ios --config-only` aqui dentro,
# porque rodar `flutter build` como Xcode Scheme Pre-action modifica o
# projeto durante o próprio build e o Xcode aborta silenciosamente
# (status "stopped", zero Build Phases executadas). Apenas sed direto,
# que é instantâneo e não modifica nada além do Package.swift.
#
# Invocado de:
#  - Xcode Scheme Pre-action (Runner.xcscheme) — antes da SPM resolution
#  - `bun --filter @raro/mobile run pub:get` — fluxo CLI consistente

set -uo pipefail

# Skip durante Xcode Clean — mesmo guard que Flutter usa em xcode_backend.dart:503
if [ "${ACTION:-}" = "clean" ]; then
  echo "[fix-spm-ios-target] skipped (ACTION=clean)"
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PKG_FILE="$MOBILE_DIR/ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift"

if [ ! -f "$PKG_FILE" ]; then
  echo "[fix-spm-ios-target] $PKG_FILE não existe ainda — nada a patchar"
  exit 0
fi

if grep -q '\.iOS("13.0")' "$PKG_FILE"; then
  sed -i.bak 's|\.iOS("13\.0")|\.iOS("15.0")|' "$PKG_FILE"
  rm -f "$PKG_FILE.bak"
  echo "[fix-spm-ios-target] patched via sed → iOS 15.0"
elif grep -q '\.iOS("15.0")' "$PKG_FILE"; then
  echo "[fix-spm-ios-target] já está em iOS 15.0 (no-op)"
else
  current="$(grep -E '\.iOS\("[0-9.]+"\)' "$PKG_FILE" | head -1 || true)"
  echo "[fix-spm-ios-target] WARNING: linha de plataforma inesperada: ${current:-<none>}"
fi
