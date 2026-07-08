#!/usr/bin/env bash
# Deploy do build Web pro GitHub Pages (branch gh-pages).
# Qualquer dev com push no repo pode rodar:  ./deploy.sh
# Requisitos: Godot 4.7 + export templates instalados.
# Godot: usa $GODOT se setado; senão tenta 'godot' no PATH; senão o app padrão do macOS.
set -euo pipefail
cd "$(dirname "$0")"

GODOT_BIN="${GODOT:-}"
if [ -z "$GODOT_BIN" ]; then
  if command -v godot >/dev/null 2>&1; then
    GODOT_BIN="godot"
  elif [ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
    GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
  else
    echo "Godot não encontrado. Rode com:  GODOT=/caminho/para/Godot ./deploy.sh" >&2
    exit 1
  fi
fi

echo "==> Exportando Web (nothreads)…"
rm -rf build/web && mkdir -p build/web
"$GODOT_BIN" --headless --import --quit >/dev/null 2>&1 || true
"$GODOT_BIN" --headless --export-release "Web" build/web/index.html
[ -f build/web/index.html ] || { echo "Export falhou (index.html não gerado)" >&2; exit 1; }

echo "==> Publicando na branch gh-pages…"
REF="$(git rev-parse --short HEAD)"
WT="$(mktemp -d)"
git fetch -q origin
git worktree add -f -B gh-pages "$WT" origin/gh-pages
git -C "$WT" rm -rf --quiet . 2>/dev/null || true
cp -R build/web/. "$WT"/
touch "$WT/.nojekyll"                       # impede o Jekyll de ignorar arquivos
git -C "$WT" add -A
git -C "$WT" commit -q -m "deploy: main@$REF" || echo "(sem mudanças no build)"
git -C "$WT" push -q origin gh-pages
git worktree remove "$WT" --force

echo "==> Publicado: https://lucasevero.github.io/foguete-pra-lua/"
echo "    (Pages leva ~1 min pra atualizar.)"
