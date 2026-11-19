#!/bin/bash
set -euo pipefail

src="$(cd "$(dirname "$0")" && pwd)"
app="$1"
python_runtime="$2"
extension="$app/Contents/PlugIns/NyfilFinder.appex"
"$python_runtime" "$src/prepare.py" "$app"
xcrun swift "$src/Icon.swift" "$(dirname "$app")/Nyfil.iconset"
"$python_runtime" "$src/package_icon.py" "$(dirname "$app")/Nyfil.iconset" "$app/Contents/Resources/Nyfil.icns"

target="$(uname -m)-apple-macos13.0"
xcrun swiftc -O -parse-as-library -target "$target" -module-name Nyfil \
    "$src/Nyfil.swift" -o "$app/Contents/MacOS/Nyfil"
xcrun swiftc -O -parse-as-library -target "$target" -module-name NyfilFinder \
    -Xlinker -e -Xlinker _NSExtensionMain \
    "$src/FinderExtension.swift" "$src/FileCreation.swift" -o "$extension/Contents/MacOS/NyfilFinder"

codesign --force --sign - --timestamp=none --entitlements "$(dirname "$app")/NyfilFinder.entitlements" "$extension"
codesign --force --sign - --timestamp=none "$app"
codesign --verify --deep --strict "$app"
