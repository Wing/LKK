#!/bin/bash
source "$(dirname "$0")/common.sh"
"$CXX" "${FLAGS[@]}" -O2 Sources/ModelTool.cpp "${SOURCES[@]}" -lsqlite3 -o build/modeltool
python3 scripts/fetch-data.py
python3 scripts/build-model.py
APP=build/LKK.app
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/Licenses"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp build/model.db build/model-metadata.json "$APP/Contents/Resources/"
cp LICENSE NOTICE "$APP/Contents/Resources/"
cp Licenses/* "$APP/Contents/Resources/Licenses/"
"$CXX" "${FLAGS[@]}" -O2 -fobjc-arc Sources/main.mm "${SOURCES[@]}" -framework Cocoa -framework InputMethodKit -lsqlite3 -o "$APP/Contents/MacOS/LKK"
"$CXX" -arch arm64 -isysroot "$SDK" -fobjc-arc Sources/IconTool.m -framework Cocoa -o build/icon-tool
build/icon-tool build/icon.png
mkdir -p build/LKK.iconset
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" build/icon.png --out "build/LKK.iconset/icon_${size}x${size}.png" >/dev/null
done
iconutil -c icns build/LKK.iconset -o "$APP/Contents/Resources/LKK.icns"
codesign --force --sign - "$APP"
"$APP/Contents/MacOS/LKK" --check-model
file "$APP/Contents/MacOS/LKK"
echo 'Built development app (ad-hoc signed; not notarized).'
