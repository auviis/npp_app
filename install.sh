#!/usr/bin/env bash
set -euo pipefail

APP_ZIP_URL="https://raw.githubusercontent.com/auviis/npp_app/refs/heads/main/Notepad%2B%2B.app.zip"
URL="https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.9/npp.8.9.portable.x64.zip"
TMPAPPZIP=$(mktemp -t nppappXXXXXX).zip
TMPZIP=$(mktemp -t nppXXXXXX).zip
DEST_DIR="Notepad++.app/Contents/Resources/npp.8.9.portable"

command -v curl >/dev/null 2>&1 || { echo "curl is required but not installed." >&2; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo "unzip is required but not installed." >&2; exit 1; }

if [ ! -d "Notepad++.app" ]; then
	echo "Downloading Notepad++.app.zip from $APP_ZIP_URL..."
	curl -L --fail -o "$TMPAPPZIP" "$APP_ZIP_URL"
	echo "Extracting Notepad++.app.zip..."
	unzip -oq "$TMPAPPZIP" -d .
	rm -f "$TMPAPPZIP"
	echo "Extracted Notepad++.app"
else
	echo "Notepad++.app already exists — skipping app download/extract"
fi

echo "Downloading portable package $URL..."
curl -L --fail -o "$TMPZIP" "$URL"

mkdir -p "$DEST_DIR"

echo "Extracting to $DEST_DIR..."
unzip -oq "$TMPZIP" -d "$DEST_DIR"

rm -f "$TMPZIP"

# If running on Apple Silicon (arm64) use the arm binary; otherwise keep x86
# Detect host architecture and move/remove bundled binaries accordingly.
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
	if [ -f "Notepad++.app/Contents/MacOS/Notepad++arm" ]; then
		rm -f "Notepad++.app/Contents/MacOS/Notepad++" || true
		mv "Notepad++.app/Contents/MacOS/Notepad++arm" "Notepad++.app/Contents/MacOS/Notepad++"
		echo "Using Apple Silicon (arm64) binary"
	else
		echo "arm64 detected but arm binary not found; leaving bundle as-is"
	fi
elif [ "$ARCH" = "x86_64" ]; then
	if [ -f "Notepad++.app/Contents/MacOS/Notepad++arm" ]; then
		rm -f "Notepad++.app/Contents/MacOS/Notepad++arm"
		echo "Removed arm binary for x86_64 host"
	else
		echo "x86_64 detected; no arm binary present"
	fi
else
	echo "Unknown architecture: $ARCH — leaving bundle as-is"
fi

xattr -cr "Notepad++.app"
rm -rf /Applications/Notepad++.app || true
mv "Notepad++.app"  /Applications/
echo "Done — files extracted to $DEST_DIR"
