#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$ROOT_DIR/main.swift"
TMP="$ROOT_DIR/main.build.swift"
OUT="$ROOT_DIR/Notepad++.app/Contents/MacOS/Notepad++"

WINE="$(which wine 2>/dev/null || true)"
WINEPATH="$(which winepath 2>/dev/null || true)"

if [ -z "$WINE" ]; then
  echo "error: 'wine' not found in PATH" >&2
  exit 1
fi
if [ -z "$WINEPATH" ]; then
  echo "error: 'winepath' not found in PATH" >&2
  exit 1
fi

echo "Using wine: $WINE"
echo "Using winepath: $WINEPATH"

# Use relative path from the executable to the bundled resources
# Executable lives at Notepad++.app/Contents/MacOS/Notepad++, so Resources path relative to it is ../Resources/npp.8.9.portable

# Replace the hardcoded launchPath and currentDirectoryPath assignments with detected executables and resource path
sed -E "s|task.launchPath *= *\"[^\"]*\"|task.launchPath = \"$WINE\"|" "$SRC" \
  | sed -E "s|winepath.launchPath *= *\"[^\"]*\"|winepath.launchPath = \"$WINEPATH\"|" \
  > "$TMP"

mkdir -p "$(dirname "$OUT")"
echo "Compiling $TMP -> $OUT"
# Minimum macOS version to support (target for backward compatibility)
MIN_MACOS="11.0"
export MACOSX_DEPLOYMENT_TARGET="$MIN_MACOS"

# Build for both architectures and create a universal binary when possible.
TMP_OUT_ARM="${OUT}.arm64"
TMP_OUT_X86="${OUT}.x86_64"

# Build separately so we can produce a universal binary with lipo
set +e
swiftc -target arm64-apple-macosx$MIN_MACOS -o "$TMP_OUT_ARM" "$TMP"
SWIFTC_ARM_STATUS=$?
swiftc -target x86_64-apple-macosx$MIN_MACOS -o "$TMP_OUT_X86" "$TMP"
SWIFTC_X86_STATUS=$?
set -e

if [ $SWIFTC_ARM_STATUS -eq 0 ] && [ $SWIFTC_X86_STATUS -eq 0 ] && command -v lipo >/dev/null 2>&1; then
  lipo -create -output "$OUT" "$TMP_OUT_ARM" "$TMP_OUT_X86"
  rm -f "$TMP_OUT_ARM" "$TMP_OUT_X86"
  chmod +x "$OUT"
  echo "Built universal binary: $OUT (arm64 + x86_64)"
elif [ $SWIFTC_ARM_STATUS -eq 0 ]; then
  mv "$TMP_OUT_ARM" "$OUT"
  chmod +x "$OUT"
  echo "Built arm64-only binary: $OUT"
elif [ $SWIFTC_X86_STATUS -eq 0 ]; then
  mv "$TMP_OUT_X86" "$OUT"
  chmod +x "$OUT"
  echo "Built x86_64-only binary: $OUT"
else
  echo "error: swiftc failed for both archs" >&2
  exit 1
fi

# Keep the generated build file for inspection (`main.build.swift`) as requested
rm -f "$TMP"
echo "Build complete: $OUT (removed $TMP)"
