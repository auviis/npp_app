# Building Notepad++.app for macOS
# Quick start

Review the script before running for safety. Run it directly from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/auviis/npp_app/main/install.sh | bash
```

Or download and run locally:

```bash
curl -fsSL -o install.sh https://raw.githubusercontent.com/auviis/npp_app/main/install.sh
chmod +x install.sh
./install.sh
```
# Building Notepad++.app for macOS

This document explains how to build a native macOS `.app` bundle that wraps the Windows version of Notepad++ to run via Wine.

## Prerequisites


## Directory Structure

```
npp_app/
├── Notepad++.app/
│   └── Contents/
│       ├── Info.plist          # App metadata and document type associations
│       └── MacOS/
│       │  └── Notepad++       # Compiled Swift executable
│       ├── Resources
│		    └── npp.8.9.portable/           # Windows Notepad++ portable installation
│               ├── notepad++.exe
│               └── ...
├── main.swift                  # Swift source code
└── BUILD.md                    # This file
```

## Build Steps

### 1. Create App Bundle Structure

```bash
mkdir -p Notepad++.app/Contents/MacOS
mkdir -p Notepad++.app/Contents/Resources
```

Download portable Notepad++ from its website and extract to Notepad++.app/Resources/npp.8.9.portable

### 2. Create Info.plist

Create `Notepad++.app/Contents/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>Notepad++</string>
	<key>CFBundleIdentifier</key>
	<string>com.notepadplusplus.wine</string>
	<key>CFBundleName</key>
	<string>Notepad++</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleVersion</key>
	<string>8.9</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>CFBundleSignature</key>
	<string>NPP8</string>
	<key>LSUIElement</key>
	<false/>
	<key>CFBundleDocumentTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeName</key>
			<string>Text Document</string>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>LSHandlerRank</key>
			<string>Alternate</string>
			<key>LSItemContentTypes</key>
			<array>
				<string>public.plain-text</string>
				<string>public.text</string>
				<string>public.data</string>
				<string>public.content</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
```

### 3. Compile Swift Source

Compile the Swift wrapper to a native executable:

```bash
swiftc -o Notepad++.app/Contents/MacOS/Notepad++ main.swift
```

### 4. Register with Launch Services

Register the app so it appears in "Open With" menus:

```bash
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f Notepad++.app
```

Optionally restart Finder to clear cache:

```bash
killall Finder
```

## How It Works

1. **Launch Services Integration**: The app is registered with macOS Launch Services via `Info.plist` document type declarations
2. **Apple Event Handling**: The Swift code implements `NSApplicationDelegate` methods:
   - `applicationDidFinishLaunching`: Handles direct app launch (double-click)
   - `application:openFile:`: Handles "Open With" file opening
## Troubleshooting

**"App is damaged" error**: Clear quarantine attributes:
```bash
xattr -cr Notepad++.app
```

**Not appearing in "Open With"**: Re-register and restart Finder:
```bash
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f Notepad++.app
killall Finder
```

**Files not opening**: Check Wine and winepath are correctly installed:
```bash
which wine winepath
```

## Distribution

To distribute the app:

1. Ensure all paths are absolute or properly resolved
2. Consider code-signing for Gatekeeper compatibility
3. Package the entire `Notepad++.app` bundle as a single item
4. Users will need Wine installed separately

## License

This wrapper is independent of Notepad++ licensing. Notepad++ is GPL-licensed software.
