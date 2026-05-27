#!/usr/bin/env bash
# fix-spm-ios-target.sh — workaround for flutter/flutter#162072.
# Patches FlutterGeneratedPluginSwiftPackage/Package.swift iOS target 13.0→15.0
# so Firebase 12+ and other iOS 15+ SwiftPM dependencies resolve correctly.
#
# Invoked from:
#  - Xcode Scheme Pre-action (Runner.xcscheme) — runs before SPM resolution
#  - `bun --filter @raro/mobile run pub:get` — keeps CLI flow consistent
#
# Designed to be idempotent and safe to run in any Xcode action (build, clean,
# index, archive) — exits 0 silently when the file doesn't exist yet or when
# Xcode is cleaning.

set -uo pipefail

# Skip during Xcode Clean — same guard Flutter uses in xcode_backend.dart:503
if [ "${ACTION:-}" = "clean" ]; then
  echo "[fix-spm-ios-target] skipped (ACTION=clean)"
  exit 0
fi

# Resolve project root. When invoked from Xcode, SRCROOT points at apps/mobile/ios.
# When invoked from CLI (any cwd), this script's directory anchors the path.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PKG_FILE="$MOBILE_DIR/ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift"

if [ ! -f "$PKG_FILE" ]; then
  echo "[fix-spm-ios-target] $PKG_FILE not present yet — nothing to patch (will retry on next build)"
  exit 0
fi

if grep -q '\.iOS("13.0")' "$PKG_FILE"; then
  sed -i.bak 's|\.iOS("13\.0")|\.iOS("15.0")|' "$PKG_FILE"
  rm -f "$PKG_FILE.bak"
  echo "[fix-spm-ios-target] patched $PKG_FILE → iOS 15.0"
elif grep -q '\.iOS("15.0")' "$PKG_FILE"; then
  echo "[fix-spm-ios-target] already at iOS 15.0 (no-op)"
else
  current="$(grep -E '\.iOS\("[0-9.]+"\)' "$PKG_FILE" | head -1 || true)"
  echo "[fix-spm-ios-target] WARNING: unexpected platform line: ${current:-<none>}"
  echo "[fix-spm-ios-target] file: $PKG_FILE"
  # exit 0 to avoid blocking the build; investigate manually
  exit 0
fi
