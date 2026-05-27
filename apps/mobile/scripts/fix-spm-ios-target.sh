#!/usr/bin/env bash
set -euo pipefail

# Fix FlutterGeneratedPluginSwiftPackage iOS target from 13.0 to 15.0.
# Flutter 3.44 regenerates this file with .iOS("13.0") on every `flutter pub get`
# and `flutter analyze`, breaking Firebase 15.0+ requirement.
# Known issue: flutter/flutter#176313, #185039.
# Run before every `flutter build ios` or `flutter run` until upstream fixes.

PKG_FILE="ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift"

if [ ! -f "$PKG_FILE" ]; then
  echo "[fix-spm-ios-target] $PKG_FILE not found — run 'flutter pub get' first"
  exit 1
fi

if grep -q '.iOS("13.0")' "$PKG_FILE"; then
  sed -i.bak 's|\.iOS("13\.0")|\.iOS("15.0")|' "$PKG_FILE"
  rm -f "$PKG_FILE.bak"
  echo "[fix-spm-ios-target] patched $PKG_FILE → iOS 15.0"
elif grep -q '.iOS("15.0")' "$PKG_FILE"; then
  echo "[fix-spm-ios-target] already at iOS 15.0"
else
  echo "[fix-spm-ios-target] WARNING: no .iOS(\"13.0\") or .iOS(\"15.0\") found in $PKG_FILE"
  grep '.iOS' "$PKG_FILE" || true
  exit 2
fi
