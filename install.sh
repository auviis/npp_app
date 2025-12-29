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

xattr -cr "Notepad++.app"
rm -rf /Applications/Notepad++.app || true
mv "Notepad++.app"  /Applications/
echo "Done — files extracted to $DEST_DIR"
