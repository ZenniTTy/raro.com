#!/usr/bin/env bash
# fix-spm-ios-target.sh — official Flutter workaround for flutter/flutter#162072 + #162196.
#
# Invokes `flutter build ios --config-only` to regenerate
# FlutterGeneratedPluginSwiftPackage/Package.swift with the correct iOS
# minimum version (matching Runner's IPHONEOS_DEPLOYMENT_TARGET). Xcode builds
# do NOT trigger this regeneration on their own — only `flutter build`/`run`
# do. So we invoke it as a Pre-action.
#
# Falls back to a sed patch if `--config-only` fails or isn't available.
#
# Invoked from:
#  - Xcode Scheme Pre-action (Runner.xcscheme) — runs before SPM resolution
#  - `bun --filter @raro/mobile run pub:get` — keeps CLI flow consistent

set -uo pipefail

# Skip during Xcode Clean — same guard Flutter uses in xcode_backend.dart:503
if [ "${ACTION:-}" = "clean" ]; then
  echo "[fix-spm-ios-target] skipped (ACTION=clean)"
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PKG_FILE="$MOBILE_DIR/ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift"

# Resolve flutter binary. Xcode strips PATH; try common locations.
FLUTTER_BIN=""
for candidate in \
  "$(command -v flutter 2>/dev/null || true)" \
  "/usr/local/share/flutter/bin/flutter" \
  "/opt/homebrew/bin/flutter" \
  "$HOME/development/flutter/bin/flutter" \
  "$HOME/flutter/bin/flutter"
do
  if [ -n "$candidate" ] && [ -x "$candidate" ]; then
    FLUTTER_BIN="$candidate"
    break
  fi
done

# Primary path: run flutter build ios --config-only (official Flutter workaround
# per docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers)
if [ -n "$FLUTTER_BIN" ]; then
  echo "[fix-spm-ios-target] running '$FLUTTER_BIN build ios --config-only' to regenerate SPM"
  pushd "$MOBILE_DIR" > /dev/null
  if "$FLUTTER_BIN" build ios --config-only 2>&1 | tail -5; then
    popd > /dev/null
    if [ -f "$PKG_FILE" ] && grep -q '\.iOS("15.0")' "$PKG_FILE"; then
      echo "[fix-spm-ios-target] regenerated successfully → iOS 15.0"
      exit 0
    fi
    echo "[fix-spm-ios-target] config-only ran but Package.swift not at 15.0, falling back to sed"
  else
    popd > /dev/null
    echo "[fix-spm-ios-target] config-only failed, falling back to sed"
  fi
else
  echo "[fix-spm-ios-target] flutter binary not found in PATH, using sed fallback"
fi

# Fallback path: direct sed patch (works without flutter on PATH)
if [ ! -f "$PKG_FILE" ]; then
  echo "[fix-spm-ios-target] $PKG_FILE not present yet — nothing to patch"
  exit 0
fi

if grep -q '\.iOS("13.0")' "$PKG_FILE"; then
  sed -i.bak 's|\.iOS("13\.0")|\.iOS("15.0")|' "$PKG_FILE"
  rm -f "$PKG_FILE.bak"
  echo "[fix-spm-ios-target] patched via sed → iOS 15.0"
elif grep -q '\.iOS("15.0")' "$PKG_FILE"; then
  echo "[fix-spm-ios-target] already at iOS 15.0 (no-op)"
else
  current="$(grep -E '\.iOS\("[0-9.]+"\)' "$PKG_FILE" | head -1 || true)"
  echo "[fix-spm-ios-target] WARNING: unexpected platform line: ${current:-<none>}"
fi
