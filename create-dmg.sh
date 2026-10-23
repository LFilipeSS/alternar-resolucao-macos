#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h}"
app_name="Alternar Resolucao"
app_bundle="$project_dir/$app_name.app"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$project_dir/Info.plist")"
dist_dir="$project_dir/dist"
stage_dir="$dist_dir/dmg-root"
dmg_path="$dist_dir/Alternar-Resolucao-$version.dmg"

"$project_dir/build.sh"

mkdir -p "$dist_dir" "$stage_dir"
find "$stage_dir" -mindepth 1 -depth -delete
if [[ -e "$dmg_path" ]]; then
  rm "$dmg_path"
fi

ditto "$app_bundle" "$stage_dir/$app_name.app"
ln -s /Applications "$stage_dir/Applications"

hdiutil create \
  -volname "$app_name" \
  -srcfolder "$stage_dir" \
  -ov \
  -format UDZO \
  "$dmg_path"

find "$stage_dir" -mindepth 1 -depth -delete
rmdir "$stage_dir"

echo "DMG criado em: $dmg_path"
