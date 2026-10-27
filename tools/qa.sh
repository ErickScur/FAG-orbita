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

user_args=(--qa "--qa-script=res://$script" "--qa-out=$out")
[ -n "$scene" ] && user_args+=("--qa-scene=$scene")
[ -n "$new_game" ] && user_args+=("$new_game")
[ -n "$scale" ] && user_args+=("$scale")
[ -n "${ORBITA_QA_SCREEN:-}" ] && user_args+=("--qa-screen=$ORBITA_QA_SCREEN")

perl -e "alarm $limit; exec @ARGV" "$GODOT" --path . --fixed-fps 60 -- "${user_args[@]}" \
  > "$out/godot.log" 2>&1
code=$?

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
