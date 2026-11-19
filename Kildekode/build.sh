#!/bin/bash
set -euo pipefail

src="$(cd "$(dirname "$0")" && pwd)"
app="$1"
python_runtime="$2"
extension="$app/Contents/PlugIns/NyfilFinder.appex"

# Kompilatormellomlageret legges i prosjektet mens bygget kjører og slettes
# etterpå, også hvis bygget feiler. Det sparer rundt 500 MB, men gjør hvert bygg
# tregere (rundt 40 sekunder). Sett NYFIL_BEHOLD_MELLOMLAGER=1 for å beholde det.
cache_root="$(dirname "$src")/.cache"
export CLANG_MODULE_CACHE_PATH="$cache_root/ModuleCache"
mkdir -p "$CLANG_MODULE_CACHE_PATH"
if [ "${NYFIL_BEHOLD_MELLOMLAGER:-0}" != "1" ]; then
    trap 'rm -rf "$cache_root"' EXIT
fi
"$python_runtime" "$src/prepare.py" "$app"
xcrun swift "$src/Icon.swift" "$(dirname "$app")/Nyfil.iconset"
"$python_runtime" "$src/package_icon.py" "$(dirname "$app")/Nyfil.iconset" "$app/Contents/Resources/Nyfil.icns"

# Universelt bygg: virker på både Apple Silicon (arm64) og Intel (x86_64).
parts="$(dirname "$app")/.arkitekturer"
mkdir -p "$parts"
for arch in arm64 x86_64; do
    target="$arch-apple-macos13.0"
    xcrun swiftc -O -parse-as-library -target "$target" -module-name Nyfil \
        "$src/Nyfil.swift" "$src/FileMove.swift" -o "$parts/Nyfil-$arch"
    xcrun swiftc -O -parse-as-library -target "$target" -module-name NyfilFinder \
        -Xlinker -e -Xlinker _NSExtensionMain \
        "$src/FinderExtension.swift" "$src/FileCreation.swift" "$src/FileMove.swift" -o "$parts/NyfilFinder-$arch"
done
lipo -create "$parts/Nyfil-arm64" "$parts/Nyfil-x86_64" -output "$app/Contents/MacOS/Nyfil"
lipo -create "$parts/NyfilFinder-arm64" "$parts/NyfilFinder-x86_64" -output "$extension/Contents/MacOS/NyfilFinder"
rm -rf "$parts"

codesign --force --sign - --timestamp=none --entitlements "$(dirname "$app")/NyfilFinder.entitlements" "$extension"
codesign --force --sign - --timestamp=none "$app"
codesign --verify --deep --strict "$app"
