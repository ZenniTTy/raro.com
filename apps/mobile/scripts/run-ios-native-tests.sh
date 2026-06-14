#!/usr/bin/env bash
# run-ios-native-tests.sh — runs iOS native XCTest suite (RunnerTests) via
# xcodebuild with auto-detected Simulator destination.
#
# Idempotent and safe to run repeatedly. Encadeia o recovery flow do SPM
# antes do xcodebuild para garantir que Package.swift esteja em iOS 15.0:
#  1. flutter pub get  → garante xcconfigs presentes
#  2. fix-spm-ios-target.sh  → patcha Package.swift ephemeral 13→15
#  3. bootstrap-ios-permissions.sh  → garante PERMISSION_CAMERA macros
#  4. xcodebuild test  → roda RunnerTests scheme
#
# Auto-detecta destination: tenta iPhone 17, 16, 15, 14, 13 (qualquer
# instalado no Xcode local). Substitui o problema de "iPhone 16 not available".
#
# Uso:
#   bun --filter @raro/mobile run test:ios
# Ou direto:
#   ./scripts/run-ios-native-tests.sh
# Ou filtrar testes:
#   ./scripts/run-ios-native-tests.sh CameraPlatformViewTests

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
IOS_DIR="$MOBILE_DIR/ios"

FILTER="${1:-RunnerTests}"

echo "[run-ios-native-tests] Recovery flow: pub get + fix-spm + bootstrap"
cd "$MOBILE_DIR"
flutter pub get
"$SCRIPT_DIR/fix-spm-ios-target.sh"
"$SCRIPT_DIR/bootstrap-ios-permissions.sh"

# Auto-detect available iPhone Simulator (fallback chain)
DESTINATION=""
for MODEL in "iPhone 17 Pro" "iPhone 17" "iPhone 16 Pro" "iPhone 16" "iPhone 15 Pro" "iPhone 15" "iPhone 14" "iPhone 13"; do
  if xcrun simctl list devices available 2>/dev/null | grep -q "^    $MODEL ("; then
    DESTINATION="$MODEL"
    break
  fi
done

if [ -z "$DESTINATION" ]; then
  echo "[run-ios-native-tests] ERROR: no iPhone Simulator available"
  echo "[run-ios-native-tests] Open Xcode → Settings → Platforms → install iOS Simulator"
  exit 1
fi

echo "[run-ios-native-tests] Using destination: $DESTINATION"
echo "[run-ios-native-tests] Filter: $FILTER"

cd "$IOS_DIR"
set -o pipefail
xcodebuild test \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -destination "platform=iOS Simulator,name=$DESTINATION" \
  -only-testing:"$FILTER" \
  2>&1 | grep -iE "test (suite|case) .*(started|passed|failed)|executed [0-9]+ test|\*\* test (succeeded|failed) \*\*|testing failed:|error:|build failed"
status=${PIPESTATUS[0]}
if [ "$status" -ne 0 ]; then
  echo "[run-ios-native-tests] xcodebuild exited with status $status (FAILED)"
fi
exit "$status"
