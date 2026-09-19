#!/usr/bin/env bash
set -u

GODOT="${GODOT:-/Users/BRScurPaEr/Downloads/Godot.app/Contents/MacOS/Godot}"
cd "$(dirname "$0")/.." || exit 1

if [ ! -x "$GODOT" ]; then
  echo "SMOKE ABORT: binário do Godot não encontrado em $GODOT"
  exit 1
fi

failed=0
checked=0

while IFS= read -r scene || [ -n "$scene" ]; do
  scene="${scene%%$'\r'}"
  case "$scene" in ""|";"*) continue ;; esac
  checked=$((checked + 1))
  out=$(perl -e 'alarm 90; exec @ARGV' "$GODOT" --headless --path . --quit-after 60 "$scene" 2>&1 \
    | grep -vE "resources still in use at exit|core/io/resource\.cpp")
  if echo "$out" | grep -qE "SCRIPT ERROR|Parse Error|ERROR:"; then
    echo "SMOKE FAIL $scene"
    echo "$out" | grep -E "SCRIPT ERROR|Parse Error|ERROR:" | head -5
    failed=1
  else
    echo "SMOKE OK   $scene"
  fi
done < tests/scenes.txt

echo "$checked cena(s) verificada(s)"
exit $failed
