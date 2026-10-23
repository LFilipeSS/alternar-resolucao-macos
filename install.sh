#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h}"
destination="$HOME/Applications/Alternar Resolucao.app"

"$project_dir/build.sh"
mkdir -p "$HOME/Applications"

if [[ -e "$destination" ]]; then
  find "$destination" -depth -delete
fi

ditto "$project_dir/Alternar Resolucao.app" "$destination"
open "$destination"

echo "Instalado em: $destination"
echo "Use o menu do aplicativo para ativar a inicialização automática."
