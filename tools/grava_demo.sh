#!/usr/bin/env bash
set -u

usage() {
  cat <<'EOF'
uso: tools/grava_demo.sh novidades|completo SAIDA.mp4 [opções do demo.sh]

Roda a demo guiada em tela cheia (padrão: --tela=1, o segundo monitor) com o gravador do Godot
(Movie Maker: quadros PNG sem perda + som do jogo, 60 fps) e converte para MP4 1920x1080
(pixel art ampliada 5x sem borrar). O jogo fecha sozinho no fim da playlist.
Teclas P/N/R funcionam, mas a pausa também fica no vídeo.

  exemplos:
    tools/grava_demo.sh completo ~/Desktop/orbita-completo.mp4
    tools/grava_demo.sh novidades ~/Desktop/orbita-novidades.mp4 --final=transmissao --tela=0
EOF
}

[ $# -ge 2 ] || { usage; exit 64; }
case "$1" in -h|--help) usage; exit 0 ;; esac
playlist="$1"; shift
output="$1"; shift
command -v ffmpeg > /dev/null || { echo "GRAVA ABORT: ffmpeg não encontrado (brew install ffmpeg)"; exit 1; }
cd "$(dirname "$0")/.." || exit 1

screen_arg="--tela=1"
for argument in "$@"; do
  case "$argument" in --tela=*) screen_arg="" ;; esac
done

work="$(mktemp -d "${TMPDIR:-/tmp}/orbita-gravacao.XXXXXX")"
frames="$work/quadros"
mkdir -p "$frames"
echo "Gravando em $frames (apague depois se quiser: ~4 MB por segundo de vídeo)"
tools/demo.sh "$playlist" ${screen_arg:+"$screen_arg"} "$@" "--gravar=$frames/q.png" "--out=$work/log"
[ -f "$frames/q.wav" ] || { echo "GRAVA ABORT: o Godot não gravou o som ($frames/q.wav)"; exit 1; }
count="$(find "$frames" -name 'q*.png' | wc -l | tr -d ' ')"
echo "Convertendo $count quadros para $output ..."
ffmpeg -hide_banner -loglevel warning -stats -y \
  -framerate 60 -i "$frames/q%08d.png" -i "$frames/q.wav" \
  -vf "scale=1920:1080:flags=neighbor" -c:v libx264 -preset medium -crf 16 -pix_fmt yuv420p \
  -c:a aac -b:a 192k -shortest -movflags +faststart "$output" || { echo "GRAVA ABORT: ffmpeg falhou"; exit 1; }
rm -rf "$frames"
echo "GRAVA OK $output (log da demo em $work/log)"
