#!/bin/zsh
set -euo pipefail

app="$HOME/Applications/Alternar Resolucao.app"
agent="$HOME/Library/LaunchAgents/br.com.luizfilipe.alternar-resolucao.plist"

pkill -f "$app/Contents/MacOS/AlternarResolucao" 2>/dev/null || true
launchctl bootout "gui/$(id -u)" "$agent" 2>/dev/null || true

if [[ -e "$agent" ]]; then unlink "$agent"; fi
if [[ -e "$app" ]]; then find "$app" -depth -delete; fi

echo "Alternar Resolução removido."
