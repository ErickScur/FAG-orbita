#!/usr/bin/env bash
set -u

usage() {
  cat <<'EOF'
uso: tools/demo.sh novidades|completo [opções]

  --capitulo=ID|N     começa no capítulo (id da lista abaixo ou número a partir de 1)
  --final=semeadura|transmissao   final escolhido na sala de comando (padrão: semeadura)
  --janela            em janela (padrão: tela cheia)
  --tela=N            monitor onde o jogo abre (0 = principal; projetor costuma ser 1)
  --rapido            sem ritmo de leitura (as falas passam no tempo do roteiro de QA)
  --sem-selo          não mostra o selo PAUSADO no canto
  --gravar=ARQ.avi    grava a demo inteira (vídeo + som do jogo) e fecha no fim; ver tools/grava_demo.sh

  --verificar         rodada de conferência: janela sem foco, mudo, capturas, sai no fim
  --out=DIR           (com --verificar) pasta das capturas e do log
  --pausas=C@F:S,...  (com --verificar) aperta P no capítulo C, quadro F, por S segundos
  --timeout=N         (com --verificar) limite em segundos (padrão 3600)

Teclas durante a demo:
  P            congela tudo / retoma
  N            pula para o próximo capítulo
  R            reinicia o capítulo atual
  Esc segurado 1 s (ou Cmd+Q) sai do jogo
EOF
}

GODOT="${GODOT:-/Users/BRScurPaEr/Downloads/Godot.app/Contents/MacOS/Godot}"
cd "$(dirname "$0")/.." || exit 1

[ $# -ge 1 ] || { usage; exit 64; }
case "$1" in -h|--help) usage; exit 0 ;; esac
playlist="$1"; shift
playlist_file="tests/qa/demo/$playlist.json"
[ -f "$playlist_file" ] || { echo "DEMO ABORT: playlist desconhecida '$playlist' (novidades|completo)"; exit 64; }

chapter=""
final="semeadura"
windowed=0
screen=""
fast=0
badge=1
verify=0
out=""
pauses=""
record=""
limit=3600
for argument in "$@"; do
  case "$argument" in
    --capitulo=*) chapter="${argument#--capitulo=}" ;;
    --final=*) final="${argument#--final=}" ;;
    --janela) windowed=1 ;;
    --tela=*) screen="${argument#--tela=}" ;;
    --rapido) fast=1 ;;
    --sem-selo) badge=0 ;;
    --verificar) verify=1 ;;
    --out=*) out="${argument#--out=}" ;;
    --pausas=*) pauses="${argument#--pausas=}" ;;
    --gravar=*) record="${argument#--gravar=}" ;;
    --timeout=*) limit="${argument#--timeout=}" ;;
    *) echo "DEMO ABORT: opção desconhecida $argument"; usage; exit 64 ;;
  esac
done
case "$final" in semeadura|transmissao) ;; *) echo "DEMO ABORT: final '$final' (semeadura|transmissao)"; exit 64 ;; esac

if ! "$GODOT" --version > /dev/null 2>&1; then
  echo "DEMO ABORT: Godot não encontrado em $GODOT"
  exit 1
fi

[ -n "$out" ] || out="${TMPDIR:-/tmp}/orbita-demo/$playlist"
rm -rf "$out"
mkdir -p "$out"
out="$(cd "$out" && pwd)"

echo "Preparando (import)..."
if ! perl -e 'alarm 300; exec @ARGV' "$GODOT" --headless --path . --import > "$out/import.log" 2>&1; then
  echo "DEMO ABORT: import falhou (log em $out/import.log)"
  exit 1
fi

echo
echo "ÓRBITA — demonstração guiada: $playlist (final: $final)"
echo "  P = congela/retoma   N = próximo capítulo   R = reinicia capítulo   Esc segurado 1 s = sair"
echo
python3 - "$playlist_file" "$fast" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
fast = sys.argv[2] == "1"
print("  capítulos (início aproximado%s):" % (", sem ritmo de leitura" if fast else ", com ritmo de leitura"))
for number, chapter in enumerate(data["capitulos"], 1):
    start = chapter.get("inicio_rapido_s" if fast else "inicio_s")
    clock = "%02d:%02d" % divmod(int(start), 60) if start is not None else "  -  "
    print("  %2d  %s  %-15s %s" % (number, clock, chapter["id"], chapter["titulo"]))
PY
echo

user_args=(--qa --qa-demo "--qa-playlist=res://$playlist_file" "--qa-final=$final" "--qa-out=$out")
[ -n "$chapter" ] && user_args+=("--qa-chapter=$chapter")
[ $fast -eq 1 ] && user_args+=(--qa-demo-sem-ritmo)
[ $badge -eq 0 ] && user_args+=(--qa-demo-sem-selo)

if [ $verify -eq 0 ]; then
  [ $windowed -eq 1 ] && user_args+=(--qa-demo-janela)
  engine_args=(--path "$PWD" --fixed-fps 60)
  [ -n "$screen" ] && engine_args+=(--screen "$screen")
  [ $windowed -eq 1 ] && engine_args+=(--windowed)
  if [ -n "$record" ]; then
    engine_args+=(--write-movie "$record")
    user_args+=(--qa-demo-gravar)
  fi
  echo "Abrindo o jogo. Log completo: $out/godot.log"
  perl -e 'alarm 14400; exec @ARGV' "$GODOT" "${engine_args[@]}" -- "${user_args[@]}" 2>&1 \
    | tee "$out/godot.log" | grep --line-buffered -E "\[DEMO\]|SCRIPT ERROR|ERRO"
  exit 0
fi

user_args+=(--qa-demo-verify)
[ -n "$pauses" ] && user_args+=("--qa-demo-pausas=$pauses")
screen_args=()
wanted_screen="${screen:-${ORBITA_QA_SCREEN:-1}}"
screens="$(system_profiler SPDisplaysDataType 2> /dev/null | grep -c "Resolution:")"
if [ "${screens:-0}" -gt "$wanted_screen" ]; then
  screen_args=(--screen "$wanted_screen")
fi
engine_args=(--path "$PWD" --fixed-fps 60 --windowed ${screen_args[@]+"${screen_args[@]}"} -- "${user_args[@]}")
app="${GODOT%/Contents/MacOS/*}"
frontmost_app() {
  osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' \
    2> /dev/null
}
: > "$out/godot.log"
: > "$out/godot.err"
previous_app="$(frontmost_app)"
open -g -n -a "$app" --stdout "$out/godot.log" --stderr "$out/godot.err" --args "${engine_args[@]}"
pid=""
for _ in $(seq 1 50); do
  pid="$(pgrep -f -- "--qa-out=$out" | head -1)"
  [ -n "$pid" ] && break
  sleep 0.1
done
[ -n "$pid" ] || { echo "DEMO ABORT: o Godot não abriu"; exit 1; }
waited=0
finished_at=-1
code=0
while kill -0 "$pid" 2> /dev/null; do
  if [ "$waited" -ge $((limit * 10)) ]; then
    kill "$pid" 2> /dev/null
    code=142
    break
  fi
  if [ "$finished_at" -lt 0 ] && grep -q "\[QA\] resumo:" "$out/godot.log"; then
    finished_at=$waited
  fi
  if [ "$finished_at" -ge 0 ] && [ $((waited - finished_at)) -ge 50 ]; then
    kill "$pid" 2> /dev/null
    break
  fi
  if [ "$waited" -lt 100 ] && [ $((waited % 5)) -eq 0 ] && [ -n "$previous_app" ] \
    && [ "$previous_app" != "Godot" ] && [ "$(frontmost_app)" = "Godot" ]; then
    open -a "$previous_app" 2> /dev/null
  fi
  sleep 0.1
  waited=$((waited + 1))
done
cat "$out/godot.err" >> "$out/godot.log"
rm -f "$out/godot.err"

failed=0
[ $code -eq 142 ] && { echo "DEMO FAIL tempo esgotado ($limit s)"; failed=1; }
errors=$(grep -E "SCRIPT ERROR|Parse Error|ERROR:|\[QA\] .*ERRO" "$out/godot.log" \
  | grep -vE "resources still in use at exit|core/io/resource\.cpp")
if [ -n "$errors" ]; then
  echo "DEMO FAIL erros no log:"
  echo "$errors" | head -20
  failed=1
fi
grep -E "\[DEMO\]" "$out/godot.log" | sed -E 's/^/  /'
grep -E "\[QA\] resumo" "$out/godot.log" | sed -E 's/.*\[QA\] /  /'
grep -q "\[QA\] resumo" "$out/godot.log" || { echo "DEMO FAIL sem resumo final"; failed=1; }
echo "saída: $out"
[ $failed -eq 0 ] && echo "DEMO OK $playlist" || echo "DEMO FAIL $playlist"
exit $failed
