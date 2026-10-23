#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h}"
app_bundle="$project_dir/Alternar Resolucao.app"

mkdir -p "$app_bundle/Contents/MacOS" "$app_bundle/Contents/Resources"
cp "$project_dir/Info.plist" "$app_bundle/Contents/Info.plist"

swiftc -O \
  -framework AppKit \
  -framework CoreGraphics \
  "$project_dir/ToggleResolution.swift" \
  -o "$app_bundle/Contents/MacOS/AlternarResolucao"

icon='/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/com.apple.cinema-display.icns'
if [[ -f "$icon" ]]; then
  cp "$icon" "$app_bundle/Contents/Resources/AppIcon.icns"
fi

codesign --force --deep --sign - "$app_bundle"
echo "Aplicativo criado em: $app_bundle"
