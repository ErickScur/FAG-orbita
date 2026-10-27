#!/usr/bin/env bash
set -u

usage() {
  cat <<'EOF'
uso: tools/qa.sh <roteiro.json> [opções]

  <roteiro.json>      tests/qa/x.json ou res://tests/qa/x.json
  --scene=res://...   cena inicial (padrão: a cena principal do projeto)
  --keep-save         NÃO zera o GameState (padrão: --qa-new-game)
  --out=DIR           saída (padrão: $TMPDIR/orbita-qa/<nome-do-roteiro>)
  --timeout=N         limite em segundos (padrão: 240)
  --scale=N           amplia as capturas N vezes (nearest)

Sai 0 quando não há erro de script, nenhum marco falhou e, se o roteiro manda
o MU-7 andar e tem mais de duas capturas, a posição dele mudou entre elas.

Marcos no roteiro (o QACapture confere e loga "marco OK" ou "ERRO marco"):
  {"frame": 300, "expect_tile": [18, 37], "tolerance": 1, "label": "pe_do_painel"}
  {"frame": 900, "expect_scene": "res://scenes/ui/demo_end.tscn"}
EOF
}

GODOT="${GODOT:-/Users/BRScurPaEr/Downloads/Godot.app/Contents/MacOS/Godot}"
FOCUS_GUARD_TICKS=100
EXIT_GRACE_TICKS=50

frontmost_app() {
  osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' \
    2> /dev/null
}
cd "$(dirname "$0")/.." || exit 1

[ $# -ge 1 ] || { usage; exit 64; }
case "$1" in -h|--help) usage; exit 0 ;; esac

script="$1"; shift
script="${script#res://}"
[ -f "$script" ] || { echo "QA ABORT: roteiro não encontrado: $script"; exit 64; }

name="$(basename "$script" .json)"
scene=""
new_game="--qa-new-game"
out=""
limit=240
scale=""
for argument in "$@"; do
  case "$argument" in
    --scene=*) scene="${argument#--scene=}" ;;
    --keep-save) new_game="" ;;
    --out=*) out="${argument#--out=}" ;;
    --timeout=*) limit="${argument#--timeout=}" ;;
    --scale=*) scale="--qa-scale=${argument#--scale=}" ;;
    *) echo "QA ABORT: opção desconhecida $argument"; usage; exit 64 ;;
  esac
done
[ -n "$out" ] || out="${TMPDIR:-/tmp}/orbita-qa/$name"
rm -rf "$out"
mkdir -p "$out"
out="$(cd "$out" && pwd)"

user_args=(--qa "--qa-script=res://$script" "--qa-out=$out")
[ -n "$scene" ] && user_args+=("--qa-scene=$scene")
[ -n "$new_game" ] && user_args+=("$new_game")
[ -n "$scale" ] && user_args+=("$scale")

screen="${ORBITA_QA_SCREEN:-1}"

engine_args=(--path "$PWD" --fixed-fps 60 --windowed --screen "$screen" -- "${user_args[@]}")
app="${GODOT%/Contents/MacOS/*}"

if [ "$app" != "$GODOT" ] && [ -d "$app" ] && command -v open > /dev/null; then
  : > "$out/godot.log"
  : > "$out/godot.err"
  previous_app="$(frontmost_app)"
  open -g -n -a "$app" --stdout "$out/godot.log" --stderr "$out/godot.err" \
    --args "${engine_args[@]}"
  pid=""
  for _ in $(seq 1 50); do
    pid="$(pgrep -f -- "--qa-out=$out" | head -1)"
    [ -n "$pid" ] && break
    sleep 0.1
  done
  code=0
  if [ -z "$pid" ]; then
    echo "QA ABORT: o Godot não abriu (open -g)"
    exit 1
  fi
  waited=0
  finished_at=-1
  while kill -0 "$pid" 2> /dev/null; do
    if [ "$waited" -ge $((limit * 10)) ]; then
      kill "$pid" 2> /dev/null
      code=142
      break
    fi
    if [ "$finished_at" -lt 0 ] && grep -q "\[QA\] resumo:" "$out/godot.log"; then
      finished_at=$waited
    fi
    if [ "$finished_at" -ge 0 ] && [ $((waited - finished_at)) -ge "$EXIT_GRACE_TICKS" ]; then
      kill "$pid" 2> /dev/null
      break
    fi
    if [ "$waited" -lt "$FOCUS_GUARD_TICKS" ] && [ $((waited % 5)) -eq 0 ] \
      && [ -n "$previous_app" ] && [ "$previous_app" != "Godot" ] \
      && [ "$(frontmost_app)" = "Godot" ]; then
      open -a "$previous_app" 2> /dev/null
    fi
    sleep 0.1
    waited=$((waited + 1))
  done
  cat "$out/godot.err" >> "$out/godot.log"
  rm -f "$out/godot.err"
else
  perl -e "alarm $limit; exec @ARGV" "$GODOT" "${engine_args[@]}" > "$out/godot.log" 2>&1
  code=$?
fi

failed=0
if [ $code -eq 142 ]; then
  echo "QA FAIL tempo esgotado ($limit s) — roteiro sem {\"quit\": true} ou jogo travado"
  failed=1
fi

errors=$(grep -E "SCRIPT ERROR|Parse Error|ERROR:|\[QA\] .*ERRO" "$out/godot.log" \
  | grep -vE "resources still in use at exit|core/io/resource\.cpp")
if [ -n "$errors" ]; then
  echo "QA FAIL erros no log:"
  echo "$errors" | head -15
  failed=1
fi

echo "--- capturas (frame, arquivo, posição do MU-7 em tiles)"
grep -E "\[QA\] frame [0-9]+ screenshot" "$out/godot.log" \
  | sed -E 's/.*frame ([0-9]+) screenshot ([^ ]+) \([0-9x]+\)(.*)/  \1  \2\3/'
grep -E "\[QA\] frame [0-9]+ marco" "$out/godot.log" | sed -E 's/.*\[QA\] /  /'
grep -E "\[QA\] resumo" "$out/godot.log" | sed -E 's/.*\[QA\] /  /'

shots=$(grep -cE "\[QA\] frame [0-9]+ screenshot" "$out/godot.log")
positions=$(grep -oE "screenshot .* jogador em [0-9]+,[0-9]+" "$out/godot.log" \
  | grep -oE "[0-9]+,[0-9]+$" | sort -u | wc -l | tr -d ' ')
moves=0
grep -qE '"action": *"(move_left|move_right|move_up|move_down|jump|dash)"' "$script" && moves=1
if [ $moves -eq 1 ] && [ "$shots" -gt 2 ] && [ "$positions" -eq 1 ]; then
  echo "QA FAIL o MU-7 está na mesma posição em todas as $shots capturas — roteiro quebrado"
  echo "        (mapa mudou? save antigo? interact sobrando reabrindo log?)"
  failed=1
fi
if [ "$shots" -eq 0 ]; then
  echo "QA AVISO nenhuma captura gerada"
fi
if [ $moves -eq 1 ] && ! grep -q '"expect_' "$script"; then
  echo "QA AVISO roteiro com movimento e SEM marcos: este OK não prova que o MU-7 chegou"
  echo "         a lugar nenhum. Adicione expect_tile/expect_scene (skill godot-qa §2)."
fi

echo "saída: $out"
[ $failed -eq 0 ] && echo "QA OK $name" || echo "QA FAIL $name"
exit $failed
